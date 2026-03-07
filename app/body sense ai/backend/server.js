// BodySense AI — Node.js Backend
// Stripe payment endpoints for iOS app
// Deploy to: Railway / Render / Heroku / VPS
//
// ── SETUP ──────────────────────────────────────────────────────────────────
//   npm install
//   Set env vars (see .env.example)
//   node server.js
// ───────────────────────────────────────────────────────────────────────────

require("dotenv").config();
const express  = require("express");
const cors     = require("cors");
const stripe   = require("stripe")(process.env.STRIPE_SECRET_KEY);

const app  = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// ── Health check ──────────────────────────────────────────────────────────
app.get("/", (req, res) => {
  res.json({ status: "BodySense AI backend running ✅", version: "1.0.0" });
});

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

// ── Start ─────────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`\n🚀 BodySense AI backend listening on port ${PORT}`);
  console.log(`   Stripe mode: ${process.env.STRIPE_SECRET_KEY?.startsWith("sk_live") ? "🟢 LIVE" : "🟡 TEST"}`);
  console.log(`   Endpoints:`);
  console.log(`     POST /create-payment-intent`);
  console.log(`     POST /create-subscription`);
  console.log(`     POST /book-appointment`);
  console.log(`     POST /webhook\n`);
});
