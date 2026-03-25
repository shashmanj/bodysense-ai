// BodySense AI — Node.js Backend (Production-Ready)
// Stripe payments + Firebase + GDPR + CEO Metrics + Push Notifications
// Deploy to: Railway / Render / Heroku / VPS
//
// ── SETUP ──────────────────────────────────────────────────────────────────
//   npm install
//   Set env vars (see .env.example)
//   node server.js
// ───────────────────────────────────────────────────────────────────────────

require("dotenv").config();
const express    = require("express");
const cors       = require("cors");
const helmet     = require("helmet");
const rateLimit  = require("express-rate-limit");
const stripe     = require("stripe")(process.env.STRIPE_SECRET_KEY);

const app  = express();
const PORT = process.env.PORT || 3000;

// ── Security Middleware ──────────────────────────────────────────────────
app.use(helmet());
app.use(cors({
  origin: [
    "https://bodysenseai.co.uk",
    "https://www.bodysenseai.co.uk",
    "https://api.bodysenseai.co.uk"
  ],
  methods: ["GET", "POST", "DELETE"]
}));

// Rate limiting — 100 req / 15 min per IP
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: { error: "Too many requests. Please try again later." }
});
app.use("/create-", apiLimiter);
app.use("/book-", apiLimiter);
app.use("/gdpr/", apiLimiter);

// JSON body (except webhooks which need raw)
app.use((req, res, next) => {
  if (req.originalUrl === "/webhook") {
    next();
  } else {
    express.json()(req, res, next);
  }
});

// ── Firebase Admin Init (optional — only if FIREBASE_PROJECT_ID is set) ──
let db = null;
try {
  if (process.env.FIREBASE_PROJECT_ID) {
    const admin = require("firebase-admin");
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId: process.env.FIREBASE_PROJECT_ID,
      storageBucket: process.env.FIREBASE_STORAGE_BUCKET || `${process.env.FIREBASE_PROJECT_ID}.firebasestorage.app`
    });
    db = admin.firestore();
    console.log("Firebase connected:", process.env.FIREBASE_PROJECT_ID);
  }
} catch (e) {
  console.log("Firebase not configured — running Stripe-only mode");
}

// ── CEO Auth Middleware (SHA-256 secret code, NOT email-based) ────────────
const crypto = require("crypto");
const CEO_CODE_HASH = "03795745ffbd9026bde41e991f91df7ebdee9a94268574601775325c864b6b30";

function requireCEO(req, res, next) {
  const code = req.headers["x-ceo-code"] || req.body?.ceoCode;
  if (!code) return res.status(403).json({ error: "CEO access code required" });
  const hash = crypto.createHash("sha256").update(code).digest("hex");
  if (hash !== CEO_CODE_HASH) {
    return res.status(403).json({ error: "Unauthorized — invalid CEO code" });
  }
  next();
}

// ── Health check (enhanced) ──────────────────────────────────────────────
app.get("/", (req, res) => {
  res.json({
    status: "BodySense AI backend running ✅",
    version: "2.0.0",
    uptime: Math.floor(process.uptime()),
    stripe: process.env.STRIPE_SECRET_KEY ? "configured" : "missing",
    firebase: db ? "connected" : "not configured",
    environment: process.env.NODE_ENV || "development",
    timestamp: new Date().toISOString()
  });
});

// ── Deep health check (Stripe + Firebase connectivity) ──────────────────
app.get("/health", async (req, res) => {
  const checks = { stripe: false, firebase: false, overall: "unhealthy" };
  try {
    await stripe.balance.retrieve();
    checks.stripe = true;
  } catch (e) { checks.stripeError = e.message; }
  if (db) {
    try {
      await db.collection("_healthcheck").limit(1).get();
      checks.firebase = true;
    } catch (e) { checks.firebaseError = e.message; }
  } else { checks.firebase = null; }
  checks.overall = checks.stripe ? "healthy" : "degraded";
  res.status(checks.stripe ? 200 : 503).json(checks);
});

// ── Input validation helpers ────────────────────────────────────────────
function validateEmail(email) {
  return typeof email === "string" && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}
function validateAmount(amount) {
  return typeof amount === "number" && amount >= 50 && amount <= 99999999;
}

// ── 1. Create Payment Intent (one-off purchases) ──────────────────────────
// Called by: StripeManager.createPaymentIntent(amountGBP:)
// Body: { amount: <pence>, currency: "gbp" }
// Returns: { clientSecret: "pi_xxx_secret_xxx" }
app.post("/create-payment-intent", async (req, res) => {
  try {
    const { amount, currency = "gbp" } = req.body;

    if (!amount || amount < 50) {
      return res.status(400).json({ error: "Amount must be at least 50 pence (£0.50)" });
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount:   Math.round(amount),   // already in pence from iOS
      currency,
      automatic_payment_methods: { enabled: true },
      metadata: { app: "bodysense_ai", platform: "ios" }
    });

    res.json({ clientSecret: paymentIntent.client_secret });
  } catch (err) {
    console.error("create-payment-intent error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// ── 2. Create Subscription ────────────────────────────────────────────────
// Called by: StripeManager.createSubscription(plan:customerId:)
// Body: { priceId: "price_xxx", customerId: "cus_xxx" (optional) }
// Returns: { subscriptionId, clientSecret }
app.post("/create-subscription", async (req, res) => {
  try {
    const { priceId, customerId, email } = req.body;

    if (!priceId) {
      return res.status(400).json({ error: "priceId is required" });
    }

    // Create or reuse customer
    let customer;
    if (customerId) {
      customer = await stripe.customers.retrieve(customerId);
    } else {
      customer = await stripe.customers.create({
        email:    email || undefined,
        metadata: { app: "bodysense_ai" }
      });
    }

    // Create subscription with payment_behavior: 'default_incomplete'
    const subscription = await stripe.subscriptions.create({
      customer:         customer.id,
      items:            [{ price: priceId }],
      payment_behavior: "default_incomplete",
      payment_settings: { save_default_payment_method: "on_subscription" },
      expand:           ["latest_invoice.payment_intent"],
      metadata:         { app: "bodysense_ai", platform: "ios" }
    });

    const paymentIntent = subscription.latest_invoice.payment_intent;

    res.json({
      subscriptionId: subscription.id,
      customerId:     customer.id,
      clientSecret:   paymentIntent?.client_secret || null,
      status:         subscription.status
    });
  } catch (err) {
    console.error("create-subscription error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// ── 3. Book Appointment ───────────────────────────────────────────────────
// Called by: Doctor appointment booking flow
// Body: { amount: <pence>, doctorId, userId, slotISO }
// Returns: { clientSecret, appointmentId }
app.post("/book-appointment", async (req, res) => {
  try {
    const { amount = 2500, doctorId, userId, slotISO } = req.body;
    // Default £25.00 consultation fee

    const paymentIntent = await stripe.paymentIntents.create({
      amount:   Math.round(amount),
      currency: "gbp",
      automatic_payment_methods: { enabled: true },
      metadata: {
        app:         "bodysense_ai",
        type:        "appointment",
        doctorId:    doctorId  || "unknown",
        userId:      userId    || "unknown",
        slotISO:     slotISO   || new Date().toISOString(),
        platform:    "ios"
      }
    });

    // Generate appointment reference
    const appointmentId = `appt_${Date.now()}_${Math.random().toString(36).substr(2, 8)}`;

    res.json({
      clientSecret:  paymentIntent.client_secret,
      appointmentId
    });
  } catch (err) {
    console.error("book-appointment error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// ── 4. Stripe Webhook (optional but recommended) ─────────────────────────
// Confirms payment server-side; update DB here
app.post("/webhook", express.raw({ type: "application/json" }), (req, res) => {
  const sig    = req.headers["stripe-signature"];
  const secret = process.env.STRIPE_WEBHOOK_SECRET;

  let event;
  try {
    event = stripe.webhooks.constructEvent(req.body, sig, secret);
  } catch (err) {
    console.error("Webhook signature failed:", err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  switch (event.type) {
    case "payment_intent.succeeded":
      console.log("✅ Payment succeeded:", event.data.object.id);
      // TODO: fulfil order, unlock subscription, confirm appointment
      break;
    case "customer.subscription.created":
      console.log("✅ Subscription created:", event.data.object.id);
      break;
    case "customer.subscription.deleted":
      console.log("❌ Subscription cancelled:", event.data.object.id);
      break;
    case "invoice.payment_failed":
      console.log("⚠️  Invoice payment failed:", event.data.object.id);
      break;
    default:
      console.log(`Unhandled event: ${event.type}`);
  }

  res.json({ received: true });
});

// ── 5. User Registration (Firebase) ─────────────────────────────────────
app.post("/register-user", async (req, res) => {
  if (!db) return res.json({ success: true, mode: "local" });
  try {
    const { email, name, isDoctor, country, city } = req.body;
    if (!email) return res.status(400).json({ error: "Email required" });

    const admin = require("firebase-admin");
    await db.collection("users").doc(email).set({
      name: name || "", email, isDoctor: isDoctor || false,
      country: country || "United Kingdom", city: city || "",
      subscription: "free",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastActiveAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    res.json({ success: true, userId: email });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ── 6. Doctor Registration Request ──────────────────────────────────────
app.post("/submit-doctor-request", async (req, res) => {
  if (!db) return res.json({ success: true, mode: "local" });
  try {
    const r = req.body;
    if (!r.email || !r.gmcNumber) return res.status(400).json({ error: "Email and GMC required" });

    const admin = require("firebase-admin");
    await db.collection("doctorRequests").add({
      ...r, status: "Pending",
      submittedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ── 7. CEO: Approve/Reject Doctor ───────────────────────────────────────
app.post("/approve-doctor", requireCEO, async (req, res) => {
  if (!db) return res.json({ success: true, mode: "local" });
  try {
    const { requestId, approved } = req.body;
    const admin = require("firebase-admin");
    await db.collection("doctorRequests").doc(requestId).update({
      status: approved ? "Approved" : "Rejected",
      reviewedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ── 8. CEO: Business Metrics Dashboard ──────────────────────────────────
app.get("/ceo/metrics", requireCEO, async (req, res) => {
  if (!db) return res.json({ totalUsers: 0, note: "Firebase not configured" });
  try {
    const [users, doctors, orders, appointments] = await Promise.all([
      db.collection("users").get(),
      db.collection("doctorRequests").get(),
      db.collection("orders").get(),
      db.collection("appointments").get()
    ]);

    res.json({
      totalUsers: users.size,
      totalDoctors: doctors.docs.filter(d => d.data().status === "Approved").length,
      pendingDoctors: doctors.docs.filter(d => d.data().status === "Pending").length,
      totalOrders: orders.size,
      totalAppointments: appointments.size,
      totalRevenue: orders.docs.reduce((s, d) => s + (d.data().total || 0), 0)
    });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ── 9. Push Notification (APNs via FCM) ─────────────────────────────────
app.post("/send-notification", async (req, res) => {
  try {
    const admin = require("firebase-admin");
    const { token, title, body, data } = req.body;
    if (!token) return res.status(400).json({ error: "Device token required" });

    await admin.messaging().send({
      token, notification: { title, body }, data: data || {},
      apns: { payload: { aps: { sound: "default", badge: 1 } } }
    });
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ── 10. GDPR: Data Export (Article 20 — Portability) ────────────────────
app.post("/gdpr/export", async (req, res) => {
  if (!db) return res.json({ gdprBasis: "Article 20", note: "Data stored locally on device" });
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: "Email required" });

    const userDoc = await db.collection("users").doc(email).get();
    if (!userDoc.exists) return res.status(404).json({ error: "User not found" });

    res.json({
      gdprBasis: "Article 20 — Right to Data Portability",
      exportDate: new Date().toISOString(),
      data: userDoc.data()
    });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ── 11. GDPR: Delete Account (Article 17 — Erasure) ────────────────────
app.delete("/gdpr/delete", async (req, res) => {
  if (!db) return res.json({ success: true, note: "Delete from device only" });
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: "Email required" });

    const batch = db.batch();
    batch.delete(db.collection("users").doc(email));

    const [appointments, orders] = await Promise.all([
      db.collection("appointments").where("patientEmail", "==", email).get(),
      db.collection("orders").where("email", "==", email).get()
    ]);
    appointments.forEach(doc => batch.delete(doc.ref));
    orders.forEach(doc => batch.delete(doc.ref));

    await batch.commit();
    res.json({
      success: true,
      gdprBasis: "Article 17 — Right to Erasure",
      deletedAt: new Date().toISOString()
    });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ── 12. AI Chat Proxy (routes through backend so API key stays server-side) ─

// ── Subscription-tier AI limits ─────────────────────────────────────────
// Tracks daily AI message counts per user email (resets at midnight UTC)
const aiUsage = new Map(); // key: "email:YYYY-MM-DD", value: count

const AI_LIMITS = {
  free:    5,    // 5 messages/day  — enough to try, encourages upgrade
  pro:     50,   // 50 messages/day — power user
  premium: 500,  // 500 messages/day — virtually unlimited
  ceo:     99999 // CEO: no limit
};

function getAILimit(subscription, email) {
  if (email === "kiran.shashi47.sk@gmail.com") return AI_LIMITS.ceo;
  switch (subscription) {
    case "premium": return AI_LIMITS.premium;
    case "pro":     return AI_LIMITS.pro;
    default:        return AI_LIMITS.free;
  }
}

function getDailyKey(email) {
  const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD
  return `${email}:${today}`;
}

function checkAndIncrementUsage(email, limit) {
  const key = getDailyKey(email);
  const current = aiUsage.get(key) || 0;
  if (current >= limit) return { allowed: false, used: current, limit };
  aiUsage.set(key, current + 1);
  return { allowed: true, used: current + 1, limit };
}

// Clean up old usage entries every hour (prevent memory leak)
setInterval(() => {
  const today = new Date().toISOString().split("T")[0];
  for (const key of aiUsage.keys()) {
    if (!key.endsWith(today)) aiUsage.delete(key);
  }
}, 60 * 60 * 1000);

// Rate limit: 20 req / min per IP for AI
const aiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 20,
  message: { error: "AI rate limit reached. Please wait a moment." }
});

app.post("/ai/chat", aiLimiter, async (req, res) => {
  try {
    const anthropicKey = process.env.ANTHROPIC_API_KEY;
    if (!anthropicKey) {
      return res.status(503).json({ error: "AI service not configured on server" });
    }

    const { system, messages, model, max_tokens, userEmail, subscription } = req.body;

    // Validate required fields
    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return res.status(400).json({ error: "messages array is required" });
    }
    if (!system || typeof system !== "string") {
      return res.status(400).json({ error: "system prompt is required" });
    }

    // Validate message format
    for (const msg of messages) {
      if (!msg.role || !msg.content) {
        return res.status(400).json({ error: "Each message must have role and content" });
      }
      if (!["user", "assistant"].includes(msg.role)) {
        return res.status(400).json({ error: "Message role must be 'user' or 'assistant'" });
      }
    }

    // ── Subscription-tier daily limit check ──
    const email = (userEmail || "anonymous").toLowerCase();
    const tier = (subscription || "free").toLowerCase();
    const limit = getAILimit(tier, email);
    const usage = checkAndIncrementUsage(email, limit);

    if (!usage.allowed) {
      const upgradeMsg = tier === "free"
        ? "Upgrade to Pro (£3.99/mo) for 50 messages/day, or Premium (£8.99/mo) for 500."
        : tier === "pro"
        ? "Upgrade to Premium (£8.99/mo) for 500 messages/day."
        : "Daily limit reached. Please try again tomorrow.";

      return res.status(429).json({
        error: `Daily AI limit reached (${usage.limit} messages for ${tier} plan). ${upgradeMsg}`,
        used: usage.used,
        limit: usage.limit,
        subscription: tier,
        upgradeAvailable: tier !== "premium" && tier !== "ceo"
      });
    }

    // Cap max_tokens to prevent abuse
    const safeMaxTokens = Math.min(max_tokens || 2048, 4096);

    // Forward to Anthropic API
    const anthropicRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": anthropicKey,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json"
      },
      body: JSON.stringify({
        model: model || "claude-haiku-4-5-20251001",
        max_tokens: safeMaxTokens,
        system,
        messages
      })
    });

    const data = await anthropicRes.json();

    if (!anthropicRes.ok) {
      console.error("Anthropic API error:", anthropicRes.status, data);
      return res.status(anthropicRes.status).json({
        error: data.error?.message || "AI service error"
      });
    }

    // Return text + usage info so app can show remaining messages
    const text = data.content?.[0]?.text || "";
    res.json({
      text,
      model: data.model,
      usage: { used: usage.used, limit: usage.limit, remaining: usage.limit - usage.used }
    });

    // Log usage (no PII — only first 3 chars of email)
    console.log(`AI chat | ${tier} | ${email.substring(0, 3)}*** | msg ${usage.used}/${usage.limit} | tokens: ${data.usage?.output_tokens || "?"}`);

  } catch (err) {
    console.error("ai/chat error:", err.message);
    res.status(500).json({ error: "AI service temporarily unavailable" });
  }
});

// ── GMC Live Verification ──────────────────────────────────────────────
app.post("/verify-gmc", async (req, res) => {
  try {
    const { gmcNumber } = req.body;
    if (!gmcNumber) return res.status(400).json({ error: "GMC number required" });

    // Validate format: exactly 7 digits, first digit 1-9
    if (!/^[1-9]\d{6}$/.test(gmcNumber)) {
      return res.status(400).json({ error: "Invalid GMC format. Must be exactly 7 digits, first digit 1-9." });
    }

    // Live lookup against GMC register
    const gmcRes = await fetch(`https://www.gmc-uk.org/api/gmc/print/doctor?no=${gmcNumber}`, {
      headers: { "Accept": "application/json", "User-Agent": "BodySenseAI/1.0" }
    });

    if (!gmcRes.ok) {
      return res.json({
        valid: false,
        error: "GMC number not found on the register. Please check and try again."
      });
    }

    const data = await gmcRes.json();

    // Parse GMC response — extract key fields
    const result = {
      valid: true,
      gmcNumber,
      registeredName: data.doctorName || data.name || "",
      registrationType: data.registrationType || data.regType || "",
      licenceToPractise: !!(data.licenceToPractise || data.hasLicence),
      registrationDate: data.registrationDate || data.regDate || "",
      conditions: data.conditions || [],
      undertakings: data.undertakings || []
    };

    // Block if no licence to practise
    if (!result.licenceToPractise) {
      result.error = "Your GMC record shows no current licence to practise. You must hold a valid licence to practise in the UK before applying.";
    }

    res.json(result);

  } catch (err) {
    console.error("GMC verification error:", err.message);
    // Fallback: accept the number but flag as unverified
    res.json({
      valid: false,
      error: "Unable to verify GMC number at this time. The GMC register may be temporarily unavailable. Please try again later.",
      gmcNumber: req.body.gmcNumber
    });
  }
});

// ── Doctor Document Upload ──────────────────────────────────────────────
const multer = require("multer");
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB max
});

app.post("/upload-doctor-document", upload.single("document"), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: "No file uploaded" });

    const { userId, documentType } = req.body;
    if (!userId || !documentType) {
      return res.status(400).json({ error: "userId and documentType are required" });
    }

    const validTypes = ["photoId", "dbsCertificate", "indemnityInsurance", "qualificationCertificate", "additional"];
    if (!validTypes.includes(documentType)) {
      return res.status(400).json({ error: `Invalid documentType. Must be one of: ${validTypes.join(", ")}` });
    }

    // Save to Firebase Storage if available
    const admin = require("firebase-admin");
    if (admin.apps.length > 0) {
      const bucket = admin.storage().bucket();
      const fileName = `doctor-applications/${userId}/documents/${documentType}/${Date.now()}_${req.file.originalname}`;
      const file = bucket.file(fileName);

      await file.save(req.file.buffer, {
        metadata: { contentType: req.file.mimetype },
        public: false
      });

      // Get signed URL (valid 7 days)
      const [url] = await file.getSignedUrl({
        action: "read",
        expires: Date.now() + 7 * 24 * 60 * 60 * 1000
      });

      // Also store reference in Firestore
      if (db) {
        await db.collection("doctorApplications").doc(userId).set({
          [`documents.${documentType}`]: {
            storagePath: fileName,
            fileName: req.file.originalname,
            fileSize: req.file.size,
            mimeType: req.file.mimetype,
            uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
            url
          }
        }, { merge: true });
      }

      res.json({
        success: true,
        storagePath: fileName,
        fileName: req.file.originalname,
        fileSize: req.file.size,
        url
      });
    } else {
      // No Firebase — store locally (development fallback)
      const fs = require("fs");
      const path = require("path");
      const dir = path.join(__dirname, "uploads", userId, documentType);
      fs.mkdirSync(dir, { recursive: true });
      const filePath = path.join(dir, req.file.originalname);
      fs.writeFileSync(filePath, req.file.buffer);

      res.json({
        success: true,
        storagePath: filePath,
        fileName: req.file.originalname,
        fileSize: req.file.size,
        mode: "local"
      });
    }
  } catch (err) {
    console.error("Document upload error:", err.message);
    res.status(500).json({ error: "Upload failed: " + err.message });
  }
});

// ── Get Doctor Documents (for CEO review) ───────────────────────────────
app.get("/doctor-documents/:userId", requireCEO, async (req, res) => {
  try {
    if (!db) return res.json({ documents: {}, mode: "local" });

    const doc = await db.collection("doctorApplications").doc(req.params.userId).get();
    if (!doc.exists) return res.status(404).json({ error: "Application not found" });

    res.json({ documents: doc.data()?.documents || {} });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Start ─────────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`\nBodySense AI backend listening on port ${PORT}`);
  console.log(`  Stripe: ${process.env.STRIPE_SECRET_KEY?.startsWith("sk_live") ? "LIVE" : "TEST"}`);
  console.log(`  Firebase: ${db ? "Connected" : "Not configured (Stripe-only mode)"}`);
  console.log(`  Endpoints:`);
  console.log(`    POST /create-payment-intent`);
  console.log(`    POST /create-subscription`);
  console.log(`    POST /book-appointment`);
  console.log(`    POST /webhook`);
  console.log(`    POST /register-user`);
  console.log(`    POST /submit-doctor-request`);
  console.log(`    POST /approve-doctor (CEO)`);
  console.log(`    GET  /ceo/metrics (CEO)`);
  console.log(`    POST /send-notification`);
  console.log(`    POST /gdpr/export`);
  console.log(`    DELETE /gdpr/delete`);
  console.log(`    POST /ai/chat (AI proxy → Anthropic)`);
  console.log(`    POST /verify-gmc (GMC live lookup)`);
  console.log(`    POST /upload-doctor-document (document upload)`);
  console.log(`    GET  /doctor-documents/:userId (CEO review)`);
  console.log(`  AI: ${process.env.ANTHROPIC_API_KEY ? "Configured" : "Not configured (set ANTHROPIC_API_KEY)"}\n`);
});
