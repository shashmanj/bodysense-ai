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
const stripe     = process.env.STRIPE_SECRET_KEY
  ? require("stripe")(process.env.STRIPE_SECRET_KEY)
  : null;

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
app.use("/ai/", apiLimiter);
app.use("/food-", apiLimiter);
app.use("/barcode-", apiLimiter);

// Helper: round to 2 decimal places
function round2(val) { return Math.round((val || 0) * 100) / 100; }

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
  if (!code) {
    auditLog("ceo_access_denied", { reason: "no_code" }, req);
    return res.status(403).json({ error: "CEO access code required" });
  }
  const hash = crypto.createHash("sha256").update(code).digest("hex");
  if (hash !== CEO_CODE_HASH) {
    auditLog("ceo_access_denied", { reason: "invalid_code" }, req);
    return res.status(403).json({ error: "Unauthorized — invalid CEO code" });
  }
  auditLog("ceo_access_granted", { success: true }, req);
  next();
}

// ── Firebase Auth Middleware (validates ID tokens) ────────────────────────
async function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    auditLog("auth_failure", { reason: "missing_token" }, req);
    return res.status(401).json({ error: "Authentication required. Send Firebase ID token in Authorization header." });
  }
  try {
    const admin = require("firebase-admin");
    const token = authHeader.split("Bearer ")[1];
    const decoded = await admin.auth().verifyIdToken(token);
    req.authenticatedUser = decoded;
    next();
  } catch (err) {
    auditLog("auth_failure", { reason: "invalid_token", error: err.message }, req);
    return res.status(401).json({ error: "Invalid or expired authentication token" });
  }
}

// ── CEO Rate Limiter (brute-force protection) ─────────────────────────────
const ceoLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5,                    // 5 attempts per 15 min per IP
  message: { error: "Too many CEO access attempts. Try again later." },
  keyGenerator: (req) => req.ip
});

// ── Audit Logging ────────────────────────────────────────────────────────
async function auditLog(action, details, req) {
  const entry = {
    action,
    ip: req?.ip || "unknown",
    userAgent: req?.headers?.["user-agent"] || "unknown",
    timestamp: new Date().toISOString(),
    ...details
  };
  console.log(`[AUDIT] ${action}:`, JSON.stringify(entry));
  if (db) {
    try {
      await db.collection("auditLogs").add(entry);
    } catch (e) { /* audit log failure should not break the request */ }
  }
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

// Guard: returns 503 if Stripe is not configured
function requireStripe(req, res, next) {
  if (!stripe) return res.status(503).json({ error: "Stripe not configured. Set STRIPE_SECRET_KEY." });
  next();
}

// ── Deep health check (Stripe + Firebase connectivity) ──────────────────
app.get("/health", async (req, res) => {
  const checks = { stripe: false, firebase: false, overall: "unhealthy" };
  if (stripe) {
    try {
      await stripe.balance.retrieve();
      checks.stripe = true;
    } catch (e) { checks.stripeError = e.message; }
  } else { checks.stripe = null; checks.stripeError = "Not configured"; }
  if (db) {
    try {
      await db.collection("_healthcheck").limit(1).get();
      checks.firebase = true;
    } catch (e) { checks.firebaseError = e.message; }
  } else { checks.firebase = null; }
  checks.overall = (checks.firebase !== false) ? "healthy" : "degraded";
  res.status(200).json(checks);
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
app.post("/create-payment-intent", requireStripe, async (req, res) => {
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
app.post("/create-subscription", requireStripe, async (req, res) => {
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
app.post("/book-appointment", requireStripe, async (req, res) => {
  try {
    const { amount = 2500, doctorId, userId, slotISO } = req.body;
    // Default £25.00 consultation fee

    // Generate appointment reference
    const appointmentId = `appt_${Date.now()}_${Math.random().toString(36).substr(2, 8)}`;

    // transfer_group links this payment to future doctor payout
    const transferGroup = `tg_${appointmentId}`;

    const paymentIntent = await stripe.paymentIntents.create({
      amount:   Math.round(amount),
      currency: "gbp",
      automatic_payment_methods: { enabled: true },
      transfer_group: transferGroup,
      metadata: {
        app:           "bodysense_ai",
        type:          "appointment",
        doctorId:      doctorId  || "unknown",
        userId:        userId    || "unknown",
        slotISO:       slotISO   || new Date().toISOString(),
        appointmentId,
        platform:      "ios"
      }
    });

    // Create payout transaction record in Firestore
    if (db && doctorId) {
      const admin = require("firebase-admin");
      const grossPence = Math.round(amount);
      const doctorPence = Math.round(grossPence * 0.60);
      const platformPence = grossPence - doctorPence;

      await db.collection("payoutTransactions").add({
        doctorId,
        userId:          userId || "unknown",
        appointmentId,
        transferGroup,
        grossAmount:     grossPence,      // in pence
        platformFee:     platformPence,    // 40%
        doctorAmount:    doctorPence,      // 60%
        status:          "pending",
        stripePaymentId: paymentIntent.id,
        createdAt:       admin.firestore.FieldValue.serverTimestamp()
      });

      // Check if doctor has a Stripe Connected Account — if so, create immediate transfer
      const doctorPayoutDoc = await db.collection("doctorPayouts").doc(doctorId).get();
      if (doctorPayoutDoc.exists && doctorPayoutDoc.data().payoutStatus === "active") {
        const connectedAccountId = doctorPayoutDoc.data().stripeAccountId;
        try {
          const transfer = await stripe.transfers.create({
            amount:         doctorPence,
            currency:       "gbp",
            destination:    connectedAccountId,
            transfer_group: transferGroup,
            metadata:       { appointmentId, doctorId }
          });
          // Update transaction status
          const txSnap = await db.collection("payoutTransactions")
            .where("appointmentId", "==", appointmentId).limit(1).get();
          if (!txSnap.empty) {
            await txSnap.docs[0].ref.update({
              status: "transferred",
              stripeTransferId: transfer.id
            });
          }
        } catch (transferErr) {
          console.error("Auto-transfer failed:", transferErr.message);
          // Stays as pending — will be transferred later
        }
      }
    }

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
app.post("/webhook", express.raw({ type: "application/json" }), async (req, res) => {
  if (!stripe) return res.status(503).send("Stripe not configured");
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
    case "payment_intent.succeeded": {
      const pi = event.data.object;
      console.log("✅ Payment succeeded:", pi.id);
      // If this is an appointment payment, the payout transaction was already created in /book-appointment
      break;
    }
    case "customer.subscription.created":
      console.log("✅ Subscription created:", event.data.object.id);
      break;
    case "customer.subscription.deleted":
      console.log("❌ Subscription cancelled:", event.data.object.id);
      break;
    case "invoice.payment_failed":
      console.log("⚠️  Invoice payment failed:", event.data.object.id);
      break;

    // ── Stripe Connect Events ──
    case "account.updated": {
      // Doctor completed/updated Stripe Connect onboarding
      const account = event.data.object;
      const doctorId = account.metadata?.doctorId;
      console.log("🏦 Connect account updated:", account.id, "doctor:", doctorId);
      if (db && doctorId) {
        const chargesEnabled = account.charges_enabled;
        const payoutsEnabled = account.payouts_enabled;
        let status = "onboarding";
        if (chargesEnabled && payoutsEnabled) status = "active";
        else if (account.requirements?.currently_due?.length > 0) status = "restricted";
        else if (account.requirements?.pending_verification?.length > 0) status = "pendingReview";

        const updateData = { payoutStatus: status, updatedAt: new Date().toISOString() };

        // Extract bank info if available
        if (account.external_accounts?.data?.length > 0) {
          const bank = account.external_accounts.data[0];
          updateData.bankLast4 = bank.last4 || "";
          updateData.bankName = bank.bank_name || "";
        }

        await db.collection("doctorPayouts").doc(doctorId).update(updateData);

        // If newly active, trigger pending transfers
        if (status === "active") {
          console.log("🎉 Doctor payout account now active, processing pending transfers...");
          await processPendingTransfers(doctorId, account.id);
        }
      }
      break;
    }
    case "transfer.created":
      console.log("💸 Transfer created:", event.data.object.id);
      break;
    case "payout.paid": {
      console.log("✅ Payout paid to bank:", event.data.object.id);
      break;
    }
    case "payout.failed": {
      console.log("❌ Payout failed:", event.data.object.id);
      break;
    }
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
app.post("/approve-doctor", ceoLimiter, requireCEO, async (req, res) => {
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
app.get("/ceo/metrics", ceoLimiter, requireCEO, async (req, res) => {
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
// SECURED: Requires Firebase auth + email ownership verification
app.post("/gdpr/export", requireAuth, async (req, res) => {
  if (!db) return res.json({ gdprBasis: "Article 20", note: "Data stored locally on device" });
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: "Email required" });

    // Ownership check: authenticated user can only export their own data
    if (req.authenticatedUser.email !== email) {
      auditLog("gdpr_export_denied", { requestedEmail: email, authenticatedEmail: req.authenticatedUser.email }, req);
      return res.status(403).json({ error: "You can only export your own data" });
    }

    const userDoc = await db.collection("users").doc(email).get();
    if (!userDoc.exists) return res.status(404).json({ error: "User not found" });

    auditLog("gdpr_export", { email, success: true }, req);
    res.json({
      gdprBasis: "Article 20 — Right to Data Portability",
      exportDate: new Date().toISOString(),
      data: userDoc.data()
    });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ── 11. GDPR: Delete Account (Article 17 — Erasure) ────────────────────
// SECURED: Requires Firebase auth + email ownership verification
app.delete("/gdpr/delete", requireAuth, async (req, res) => {
  if (!db) return res.json({ success: true, note: "Delete from device only" });
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: "Email required" });

    // Ownership check: authenticated user can only delete their own data
    if (req.authenticatedUser.email !== email) {
      auditLog("gdpr_delete_denied", { requestedEmail: email, authenticatedEmail: req.authenticatedUser.email }, req);
      return res.status(403).json({ error: "You can only delete your own data" });
    }

    const batch = db.batch();
    batch.delete(db.collection("users").doc(email));

    const [appointments, orders] = await Promise.all([
      db.collection("appointments").where("patientEmail", "==", email).get(),
      db.collection("orders").where("email", "==", email).get()
    ]);
    appointments.forEach(doc => batch.delete(doc.ref));
    orders.forEach(doc => batch.delete(doc.ref));

    await batch.commit();
    auditLog("gdpr_delete", { email, success: true }, req);
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

function getAILimit(subscription) {
  switch (subscription) {
    case "ceo":     return AI_LIMITS.ceo;
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
    const limit = getAILimit(tier);
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

    // Sanitize filename to prevent path traversal
    const path = require("path");
    const sanitizedName = path.basename(req.file.originalname)
      .replace(/[^a-zA-Z0-9._-]/g, "_")
      .substring(0, 100);

    // Save to Firebase Storage if available
    const admin = require("firebase-admin");
    if (admin.apps.length > 0) {
      const bucket = admin.storage().bucket();
      const fileName = `doctor-applications/${userId}/documents/${documentType}/${Date.now()}_${sanitizedName}`;
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
      const dir = path.join(__dirname, "uploads", userId, documentType);
      fs.mkdirSync(dir, { recursive: true });
      const filePath = path.join(dir, sanitizedName);
      fs.writeFileSync(filePath, req.file.buffer);

      res.json({
        success: true,
        storagePath: filePath,
        fileName: sanitizedName,
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

// ── Stripe Connect: Doctor Payout Endpoints ─────────────────────────────

// Helper: Process all pending transfers for a doctor who just onboarded
async function processPendingTransfers(doctorId, connectedAccountId) {
  if (!db) return;
  try {
    const pendingSnap = await db.collection("payoutTransactions")
      .where("doctorId", "==", doctorId)
      .where("status", "==", "pending")
      .get();

    if (pendingSnap.empty) {
      console.log(`No pending transfers for doctor ${doctorId}`);
      return;
    }

    console.log(`Processing ${pendingSnap.size} pending transfers for doctor ${doctorId}`);
    for (const doc of pendingSnap.docs) {
      const tx = doc.data();
      try {
        const transfer = await stripe.transfers.create({
          amount:         tx.doctorAmount,
          currency:       "gbp",
          destination:    connectedAccountId,
          transfer_group: tx.transferGroup,
          metadata:       { appointmentId: tx.appointmentId, doctorId }
        });
        await doc.ref.update({
          status: "transferred",
          stripeTransferId: transfer.id,
          transferredAt: new Date().toISOString()
        });
        console.log(`  Transferred £${(tx.doctorAmount / 100).toFixed(2)} → ${transfer.id}`);
      } catch (err) {
        console.error(`  Transfer failed for ${doc.id}:`, err.message);
        await doc.ref.update({ status: "failed", failureReason: err.message });
      }
    }
  } catch (err) {
    console.error("processPendingTransfers error:", err.message);
  }
}

// Create Stripe Connect Express account for a doctor
// SECURED: Requires Firebase auth + ownership verification
app.post("/doctor/create-connect-account", requireAuth, requireStripe, async (req, res) => {
  try {
    const { doctorId, email, firstName, lastName } = req.body;
    if (!doctorId || !email) {
      return res.status(400).json({ error: "doctorId and email are required" });
    }

    // Ownership: authenticated user must be the doctor requesting the account
    if (req.authenticatedUser.email !== email) {
      auditLog("connect_account_denied", { doctorId, requestedEmail: email, authenticatedEmail: req.authenticatedUser.email }, req);
      return res.status(403).json({ error: "You can only create a connect account for yourself" });
    }

    // Check if account already exists
    if (db) {
      const existing = await db.collection("doctorPayouts").doc(doctorId).get();
      if (existing.exists && existing.data().stripeAccountId) {
        // Account exists — just create a new onboarding link
        const accountLink = await stripe.accountLinks.create({
          account: existing.data().stripeAccountId,
          refresh_url: "https://body-sense-ai-production.up.railway.app/connect/refresh",
          return_url: "https://body-sense-ai-production.up.railway.app/connect/complete?doctorId=" + doctorId,
          type: "account_onboarding"
        });
        return res.json({
          accountId: existing.data().stripeAccountId,
          onboardingUrl: accountLink.url,
          isExisting: true
        });
      }
    }

    // Create new Express account
    const account = await stripe.accounts.create({
      type: "express",
      country: "GB",
      email,
      capabilities: { transfers: { requested: true } },
      business_type: "individual",
      individual: {
        first_name: firstName || "",
        last_name: lastName || "",
        email
      },
      metadata: { doctorId, app: "bodysense_ai" },
      settings: {
        payouts: {
          schedule: { interval: "weekly", weekly_anchor: "monday" }
        }
      }
    });

    // Create onboarding link (expires in 5 minutes)
    const accountLink = await stripe.accountLinks.create({
      account: account.id,
      refresh_url: "https://body-sense-ai-production.up.railway.app/connect/refresh",
      return_url: "https://body-sense-ai-production.up.railway.app/connect/complete?doctorId=" + doctorId,
      type: "account_onboarding"
    });

    // Store in Firestore
    if (db) {
      const admin = require("firebase-admin");
      await db.collection("doctorPayouts").doc(doctorId).set({
        stripeAccountId: account.id,
        payoutStatus: "onboarding",
        email,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
    }

    res.json({
      accountId: account.id,
      onboardingUrl: accountLink.url,
      isExisting: false
    });
  } catch (err) {
    console.error("create-connect-account error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// Refresh an expired onboarding link
// SECURED: Requires Firebase auth + ownership verification
app.post("/doctor/refresh-onboarding-link", requireAuth, requireStripe, async (req, res) => {
  try {
    const { doctorId } = req.body;
    if (!doctorId) return res.status(400).json({ error: "doctorId required" });

    if (req.authenticatedUser.email !== doctorId) {
      return res.status(403).json({ error: "You can only refresh your own onboarding link" });
    }

    if (!db) return res.status(500).json({ error: "Firebase not configured" });

    const doc = await db.collection("doctorPayouts").doc(doctorId).get();
    if (!doc.exists || !doc.data().stripeAccountId) {
      return res.status(404).json({ error: "No payout account found. Please create one first." });
    }

    const accountLink = await stripe.accountLinks.create({
      account: doc.data().stripeAccountId,
      refresh_url: "https://body-sense-ai-production.up.railway.app/connect/refresh",
      return_url: "https://body-sense-ai-production.up.railway.app/connect/complete?doctorId=" + doctorId,
      type: "account_onboarding"
    });

    res.json({ onboardingUrl: accountLink.url });
  } catch (err) {
    console.error("refresh-onboarding-link error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// Get doctor's payout status, balance, and recent transactions
// SECURED: Requires Firebase auth + ownership verification (or CEO)
app.get("/doctor/payout-status/:doctorId", requireAuth, requireStripe, async (req, res) => {
  try {
    const { doctorId } = req.params;
    if (!db) return res.status(500).json({ error: "Firebase not configured" });

    // Ownership: only the doctor themselves or CEO can view payout status
    const isCEOReq = (() => {
      const code = req.headers["x-ceo-code"];
      if (!code) return false;
      return crypto.createHash("sha256").update(code).digest("hex") === CEO_CODE_HASH;
    })();
    if (req.authenticatedUser.email !== doctorId && !isCEOReq) {
      return res.status(403).json({ error: "You can only view your own payout status" });
    }

    // Get payout account info
    const payoutDoc = await db.collection("doctorPayouts").doc(doctorId).get();
    const payoutData = payoutDoc.exists ? payoutDoc.data() : { payoutStatus: "notSetUp" };

    // Get transactions
    const txSnap = await db.collection("payoutTransactions")
      .where("doctorId", "==", doctorId)
      .orderBy("createdAt", "desc")
      .limit(50)
      .get();

    const transactions = txSnap.docs.map(d => ({ id: d.id, ...d.data() }));

    // Calculate balances (all in pence)
    let pendingBalance = 0;
    let transferredBalance = 0;
    let totalEarnings = 0;

    for (const tx of transactions) {
      totalEarnings += tx.doctorAmount || 0;
      if (tx.status === "pending") pendingBalance += tx.doctorAmount || 0;
      if (tx.status === "transferred" || tx.status === "paid") transferredBalance += tx.doctorAmount || 0;
    }

    res.json({
      payoutStatus:       payoutData.payoutStatus || "notSetUp",
      stripeAccountId:    payoutData.stripeAccountId || null,
      bankLast4:          payoutData.bankLast4 || "",
      bankName:           payoutData.bankName || "",
      pendingBalance,         // in pence
      transferredBalance,     // in pence
      totalEarnings,          // in pence
      transactionCount:   transactions.length,
      transactions:       transactions.slice(0, 20) // last 20
    });
  } catch (err) {
    console.error("payout-status error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// Doctor requests manual payout (min £10 = 1000 pence)
// SECURED: Requires Firebase auth + ownership verification
app.post("/doctor/request-payout", requireAuth, requireStripe, async (req, res) => {
  try {
    const { doctorId } = req.body;
    if (!doctorId) return res.status(400).json({ error: "doctorId required" });
    if (!db) return res.status(500).json({ error: "Firebase not configured" });

    // Ownership: only the doctor themselves can request their payout
    if (req.authenticatedUser.email !== doctorId) {
      auditLog("payout_request_denied", { doctorId, authenticatedEmail: req.authenticatedUser.email }, req);
      return res.status(403).json({ error: "You can only request your own payout" });
    }

    const payoutDoc = await db.collection("doctorPayouts").doc(doctorId).get();
    if (!payoutDoc.exists || payoutDoc.data().payoutStatus !== "active") {
      return res.status(400).json({ error: "Payout account not active. Please complete setup first." });
    }

    const connectedAccountId = payoutDoc.data().stripeAccountId;
    await processPendingTransfers(doctorId, connectedAccountId);

    res.json({ success: true, message: "Pending transfers processed" });
  } catch (err) {
    console.error("request-payout error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// CEO: View all doctor payouts overview
app.get("/ceo/payouts", ceoLimiter, requireCEO, requireStripe, async (req, res) => {
  try {
    if (!db) return res.status(500).json({ error: "Firebase not configured" });

    // Get all payout accounts
    const payoutSnap = await db.collection("doctorPayouts").get();
    const doctors = payoutSnap.docs.map(d => ({ doctorId: d.id, ...d.data() }));

    // Get all transactions
    const txSnap = await db.collection("payoutTransactions").get();
    const allTx = txSnap.docs.map(d => d.data());

    // Aggregate
    let totalPending = 0;
    let totalTransferred = 0;
    let totalPlatformRevenue = 0;

    for (const tx of allTx) {
      totalPlatformRevenue += tx.platformFee || 0;
      if (tx.status === "pending") totalPending += tx.doctorAmount || 0;
      if (tx.status === "transferred" || tx.status === "paid") totalTransferred += tx.doctorAmount || 0;
    }

    const doctorsWithoutPayout = doctors.filter(d => d.payoutStatus !== "active").length;
    const doctorsActive = doctors.filter(d => d.payoutStatus === "active").length;

    res.json({
      totalPendingPence:      totalPending,
      totalTransferredPence:  totalTransferred,
      totalPlatformRevenuePence: totalPlatformRevenue,
      doctorsWithoutPayout,
      doctorsActive,
      totalDoctors:           doctors.length,
      transactionCount:       allTx.length,
      doctors:                doctors.map(d => ({
        doctorId:     d.doctorId,
        payoutStatus: d.payoutStatus,
        bankLast4:    d.bankLast4 || "",
        bankName:     d.bankName || ""
      }))
    });
  } catch (err) {
    console.error("ceo/payouts error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// CEO: Trigger pending transfers for all eligible doctors
app.post("/ceo/trigger-pending-transfers", ceoLimiter, requireCEO, requireStripe, async (req, res) => {
  try {
    if (!db) return res.status(500).json({ error: "Firebase not configured" });

    const activeDoctors = await db.collection("doctorPayouts")
      .where("payoutStatus", "==", "active").get();

    let processed = 0;
    for (const doc of activeDoctors.docs) {
      const data = doc.data();
      await processPendingTransfers(doc.id, data.stripeAccountId);
      processed++;
    }

    res.json({ success: true, doctorsProcessed: processed });
  } catch (err) {
    console.error("trigger-pending-transfers error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// Stripe Connect return page (doctor redirected here after onboarding)
app.get("/connect/complete", (req, res) => {
  const doctorId = req.query.doctorId || "";
  res.send(`
    <!DOCTYPE html>
    <html><head><title>BodySense AI - Payout Setup</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <style>body{font-family:-apple-system,system-ui;text-align:center;padding:60px 20px;background:#f5f5f5}
    .card{background:#fff;border-radius:16px;padding:40px;max-width:400px;margin:0 auto;box-shadow:0 2px 12px rgba(0,0,0,0.08)}
    h2{color:#333;margin-bottom:8px}p{color:#666}
    .btn{display:inline-block;margin-top:20px;padding:14px 32px;background:#00C9A7;color:#fff;border-radius:12px;text-decoration:none;font-weight:600}</style>
    </head><body><div class="card">
    <h2>Payout Setup Complete</h2>
    <p>Your bank account has been connected. You can now receive earnings from consultations.</p>
    <a class="btn" href="bodysenseai://connect/complete?doctorId=${doctorId}">Return to App</a>
    </div></body></html>
  `);
});

// Stripe Connect refresh page (link expired)
app.get("/connect/refresh", (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html><head><title>BodySense AI</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <style>body{font-family:-apple-system,system-ui;text-align:center;padding:60px 20px;background:#f5f5f5}
    .card{background:#fff;border-radius:16px;padding:40px;max-width:400px;margin:0 auto;box-shadow:0 2px 12px rgba(0,0,0,0.08)}
    h2{color:#333}p{color:#666}
    .btn{display:inline-block;margin-top:20px;padding:14px 32px;background:#7C5CFC;color:#fff;border-radius:12px;text-decoration:none;font-weight:600}</style>
    </head><body><div class="card">
    <h2>Link Expired</h2>
    <p>The setup link has expired. Please return to the app and try again.</p>
    <a class="btn" href="bodysenseai://connect/refresh">Return to App</a>
    </div></body></html>
  `);
});

// ── Layer 6: Anonymised Health Pattern Learning ─────────────────────────

// PII validator — rejects any pattern containing personal identifiers
function containsPII(obj) {
  const str = JSON.stringify(obj).toLowerCase();
  // Check for email patterns
  if (/[^\s@]+@[^\s@]+\.[^\s@]+/.test(str)) return true;
  // Check for names (common name patterns — overly strict by design)
  if (/\b(mr|mrs|ms|dr|prof)\.\s*[a-z]+/i.test(str)) return true;
  // Check for specific dates with year (e.g. "15 March 2024", "2024-03-15")
  if (/\d{4}-\d{2}-\d{2}T\d{2}/.test(str)) return false; // ISO dates in createdAt are OK
  // Check for postcodes/zip codes
  if (/\b[A-Z]{1,2}\d[A-Z\d]?\s*\d[A-Z]{2}\b/i.test(str)) return true;
  // Check for phone numbers
  if (/\b\d{10,11}\b/.test(str) || /\+\d{10,13}/.test(str)) return true;
  return false;
}

// POST /ai/upload-patterns — receives anonymised patterns from iOS clients
app.post("/ai/upload-patterns", async (req, res) => {
  try {
    const { patterns } = req.body;

    if (!patterns || !Array.isArray(patterns) || patterns.length === 0) {
      return res.status(400).json({ error: "patterns array is required and must not be empty" });
    }

    if (patterns.length > 100) {
      return res.status(400).json({ error: "Maximum 100 patterns per upload" });
    }

    // Validate each pattern and reject if PII detected
    const validPatterns = [];
    for (const p of patterns) {
      if (!p.category || !p.trigger || !p.outcome || typeof p.confidence !== "number") {
        continue; // skip malformed
      }
      if (containsPII(p)) {
        console.warn("[Layer6] PII detected in pattern — rejected:", p.category);
        continue;
      }
      validPatterns.push({
        category: String(p.category).substring(0, 100),
        trigger: String(p.trigger).substring(0, 200),
        outcome: String(p.outcome).substring(0, 200),
        confidence: Math.max(0, Math.min(1, p.confidence)),
        sampleSize: Math.max(1, parseInt(p.sampleSize) || 1),
        ageGroup: String(p.ageGroup || "unknown").substring(0, 20),
        conditions: Array.isArray(p.conditions) ? p.conditions.map(c => String(c).substring(0, 50)).slice(0, 10) : [],
        createdAt: p.createdAt || new Date().toISOString(),
        uploadedAt: new Date().toISOString()
      });
    }

    if (validPatterns.length === 0) {
      return res.status(400).json({ error: "No valid patterns after PII filtering" });
    }

    // Store in Firestore if available
    if (db) {
      const batch = db.batch();
      for (const pattern of validPatterns) {
        // Check if similar pattern exists — merge by incrementing sampleSize
        const existing = await db.collection("globalPatterns")
          .where("category", "==", pattern.category)
          .where("trigger", "==", pattern.trigger)
          .where("outcome", "==", pattern.outcome)
          .limit(1)
          .get();

        if (!existing.empty) {
          const doc = existing.docs[0];
          const data = doc.data();
          batch.update(doc.ref, {
            sampleSize: (data.sampleSize || 1) + 1,
            confidence: Math.min(1, ((data.confidence || 0.5) * (data.sampleSize || 1) + pattern.confidence) / ((data.sampleSize || 1) + 1)),
            updatedAt: new Date().toISOString()
          });
        } else {
          const ref = db.collection("globalPatterns").doc();
          batch.set(ref, pattern);
        }
      }
      await batch.commit();
    }

    res.json({ accepted: validPatterns.length, rejected: patterns.length - validPatterns.length });
  } catch (err) {
    console.error("upload-patterns error:", err.message);
    res.status(500).json({ error: "Failed to store patterns" });
  }
});

// GET /ai/global-patterns — returns top 50 highest-confidence patterns grouped by category
app.get("/ai/global-patterns", async (req, res) => {
  try {
    if (!db) {
      return res.json({ patterns: [], message: "Firebase not configured" });
    }

    const snapshot = await db.collection("globalPatterns")
      .orderBy("confidence", "desc")
      .limit(50)
      .get();

    const patterns = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      patterns.push({
        category: data.category,
        trigger: data.trigger,
        outcome: data.outcome,
        confidence: data.confidence,
        sampleSize: data.sampleSize || 1,
        ageGroup: data.ageGroup || "unknown",
        conditions: data.conditions || [],
        createdAt: data.createdAt || data.uploadedAt
      });
    });

    // Group by category for organised response
    const grouped = {};
    for (const p of patterns) {
      if (!grouped[p.category]) grouped[p.category] = [];
      grouped[p.category].push(p);
    }

    res.json({ patterns, grouped, total: patterns.length });
  } catch (err) {
    console.error("global-patterns error:", err.message);
    res.status(500).json({ error: "Failed to fetch patterns" });
  }
});

// ── Food Search (Open Food Facts) ──────────────────────────────────────
app.post("/food-search", async (req, res) => {
  try {
    const { query, page = 1, pageSize = 20 } = req.body;
    if (!query || query.trim().length < 2) {
      return res.status(400).json({ error: "Query must be at least 2 characters" });
    }

    const searchURL = `https://world.openfoodfacts.org/cgi/search.pl?search_terms=${encodeURIComponent(query)}&search_simple=1&action=process&json=1&page=${page}&page_size=${pageSize}&fields=product_name,brands,nutriments,serving_size,categories_tags,allergens_tags,code,image_front_small_url`;

    const response = await fetch(searchURL);
    if (!response.ok) throw new Error("Open Food Facts API error");

    const data = await response.json();

    const foods = (data.products || [])
      .filter(p => p.product_name && p.nutriments)
      .map(p => ({
        name: p.product_name,
        brand: p.brands || "",
        barcode: p.code || "",
        imageURL: p.image_front_small_url || "",
        servingSize: p.serving_size || "100g",
        categories: (p.categories_tags || []).slice(0, 3).map(c => c.replace("en:", "")),
        allergens: (p.allergens_tags || []).map(a => a.replace("en:", "")),
        per100g: {
          calories: Math.round(p.nutriments["energy-kcal_100g"] || p.nutriments["energy-kcal"] || 0),
          protein: round2(p.nutriments.proteins_100g || 0),
          carbs: round2(p.nutriments.carbohydrates_100g || 0),
          fat: round2(p.nutriments.fat_100g || 0),
          fiber: round2(p.nutriments.fiber_100g || 0),
          sugar: round2(p.nutriments.sugars_100g || 0),
          salt: round2(p.nutriments.salt_100g || 0),
          saturatedFat: round2(p.nutriments["saturated-fat_100g"] || 0)
        }
      }));

    res.json({ count: data.count || 0, page, foods });
  } catch (err) {
    console.error("Food search error:", err.message);
    res.status(500).json({ error: "Food search failed. Please try again." });
  }
});

// ── Barcode Lookup (Open Food Facts) ───────────────────────────────────
app.post("/barcode-lookup", async (req, res) => {
  try {
    const { barcode } = req.body;
    if (!barcode || barcode.trim().length < 4) {
      return res.status(400).json({ error: "Invalid barcode" });
    }

    const url = `https://world.openfoodfacts.org/api/v2/product/${encodeURIComponent(barcode.trim())}.json?fields=product_name,brands,nutriments,serving_size,categories_tags,allergens_tags,code,image_front_small_url,nutriscore_grade,nova_group`;

    const response = await fetch(url);
    if (!response.ok) throw new Error("Open Food Facts API error");

    const data = await response.json();

    if (data.status !== 1 || !data.product) {
      return res.status(404).json({ error: "Product not found. Try searching by name instead." });
    }

    const p = data.product;
    const food = {
      name: p.product_name || "Unknown Product",
      brand: p.brands || "",
      barcode: p.code || barcode,
      imageURL: p.image_front_small_url || "",
      servingSize: p.serving_size || "100g",
      nutriScore: p.nutriscore_grade || null,
      novaGroup: p.nova_group || null,
      categories: (p.categories_tags || []).slice(0, 3).map(c => c.replace("en:", "")),
      allergens: (p.allergens_tags || []).map(a => a.replace("en:", "")),
      per100g: {
        calories: Math.round(p.nutriments?.["energy-kcal_100g"] || p.nutriments?.["energy-kcal"] || 0),
        protein: round2(p.nutriments?.proteins_100g || 0),
        carbs: round2(p.nutriments?.carbohydrates_100g || 0),
        fat: round2(p.nutriments?.fat_100g || 0),
        fiber: round2(p.nutriments?.fiber_100g || 0),
        sugar: round2(p.nutriments?.sugars_100g || 0),
        salt: round2(p.nutriments?.salt_100g || 0),
        saturatedFat: round2(p.nutriments?.["saturated-fat_100g"] || 0)
      }
    };

    res.json({ found: true, food });
  } catch (err) {
    console.error("Barcode lookup error:", err.message);
    res.status(500).json({ error: "Barcode lookup failed. Please try again." });
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
  console.log(`    POST /gdpr/export (AUTH)`);
  console.log(`    DELETE /gdpr/delete (AUTH)`);
  console.log(`    POST /ai/chat (AI proxy → Anthropic)`);
  console.log(`    POST /ai/upload-patterns (Layer 6)`);
  console.log(`    GET  /ai/global-patterns (Layer 6)`);
  console.log(`    POST /verify-gmc (GMC live lookup)`);
  console.log(`    POST /upload-doctor-document (document upload)`);
  console.log(`    GET  /doctor-documents/:userId (CEO review)`);
  console.log(`    POST /doctor/create-connect-account (AUTH)`);
  console.log(`    POST /doctor/refresh-onboarding-link (AUTH)`);
  console.log(`    GET  /doctor/payout-status/:doctorId (AUTH)`);
  console.log(`    POST /doctor/request-payout (AUTH)`);
  console.log(`    GET  /ceo/payouts (CEO)`);
  console.log(`    POST /ceo/trigger-pending-transfers (CEO)`);
  console.log(`    POST /food-search (Open Food Facts)`);
  console.log(`    POST /barcode-lookup (Open Food Facts)`);
  console.log(`  AI: ${process.env.ANTHROPIC_API_KEY ? "Configured" : "Not configured (set ANTHROPIC_API_KEY)"}\n`);
});
