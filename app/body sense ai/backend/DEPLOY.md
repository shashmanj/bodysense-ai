# BodySense AI — Backend Deploy Guide

## Option A: Railway (Easiest — recommended) 🚀
1. Go to https://railway.app → New Project → Deploy from GitHub
2. Connect your GitHub repo (push the `backend/` folder)
3. Set environment variables in Railway dashboard:
   - `STRIPE_SECRET_KEY` = your sk_test_xxx or sk_live_xxx
   - `STRIPE_WEBHOOK_SECRET` = from Stripe Dashboard → Webhooks
4. Railway gives you a URL like: `https://bodysense-ai-backend.up.railway.app`
5. Update `backendURL` in StripeManager.swift to that URL

## Option B: Render (Free tier available)
1. Go to https://render.com → New Web Service
2. Connect GitHub repo, set root dir to `backend/`
3. Build command: `npm install`
4. Start command: `node server.js`
5. Add env vars in Render dashboard

## Option C: Your own VPS (DigitalOcean/AWS)
```bash
git clone <your-repo>
cd backend
cp .env.example .env
nano .env  # fill in your Stripe keys
npm install
npm install -g pm2
pm2 start server.js --name bodysense-backend
pm2 save
```

---

## After Deploy — Test Endpoints

```bash
# Health check
curl https://api.bodysenseai.co.uk/

# Test payment intent
curl -X POST https://api.bodysenseai.co.uk/create-payment-intent \
  -H "Content-Type: application/json" \
  -d '{"amount": 399, "currency": "gbp"}'

# Test subscription
curl -X POST https://api.bodysenseai.co.uk/create-subscription \
  -H "Content-Type: application/json" \
  -d '{"priceId": "price_YOUR_PRO_PRICE_ID"}'
```

---

## Stripe Dashboard Checklist

### Create Products & Prices (for real subscriptions):
1. Stripe Dashboard → Products → Add Product
2. **BodySense AI Pro**
   - Price: £3.99 / month recurring / GBP
   - Copy the Price ID → paste into StripeManager.swift as `price_PRO_MONTHLY_GBP`
3. **BodySense AI Premium**
   - Price: £8.99 / month recurring / GBP
   - Copy the Price ID → paste into StripeManager.swift as `price_PREMIUM_MONTHLY_GBP`

### Set up Webhooks:
1. Stripe Dashboard → Developers → Webhooks → Add endpoint
2. URL: `https://api.bodysenseai.co.uk/webhook`
3. Events to listen for:
   - `payment_intent.succeeded`
   - `customer.subscription.created`
   - `customer.subscription.deleted`
   - `invoice.payment_failed`
4. Copy the signing secret → add to `.env` as `STRIPE_WEBHOOK_SECRET`

---

## Apple Pay Setup (in Xcode)
1. Open `body sense ai.xcodeproj` in Xcode
2. Select target → Signing & Capabilities → + Capability → **Apple Pay**
3. Add Merchant ID: `merchant.co.uk.bodysenseai`
4. Register it at: https://developer.apple.com/account → Identifiers → Merchant IDs

---

## Stripe iOS SDK (Swift Package Manager)
1. Xcode → File → Add Package Dependencies
2. URL: `https://github.com/stripe/stripe-ios`
3. Select: **StripePaymentSheet** + **StripeApplePay**
4. The `#if canImport(StripeCore)` guards in the code will auto-activate ✅

---

## App Store Connect — Register the App
1. Go to https://appstoreconnect.apple.com
2. My Apps → + → New App
3. Fill in:
   - **Name**: BodySense AI
   - **Bundle ID**: com.base693c0fe8f0479560056f69f4.app  ← select from dropdown
   - **SKU**: bodysense-ai-ios-001
   - **Primary Language**: English (UK)
4. Complete App Information:
   - Category: Health & Fitness
   - Privacy Policy URL (required)
   - Description, keywords, screenshots

## New Endpoints (v2)
```
POST /register-user          — Register/sync user to Firebase
POST /submit-doctor-request  — Doctor registration for CEO approval
POST /approve-doctor         — CEO approves/rejects doctor (CEO-only)
GET  /ceo/metrics            — Business dashboard data (CEO-only)
POST /send-notification      — Push notification via FCM
POST /gdpr/export            — GDPR data export (Article 20)
DELETE /gdpr/delete          — GDPR account deletion (Article 17)
```

## Firebase Setup
1. Go to https://console.firebase.google.com
2. Create project "bodysenseai"
3. Enable **Firestore Database** (production mode)
4. Collections needed: `users`, `doctorRequests`, `orders`, `appointments`
5. Project Settings → Service Accounts → Generate new private key
6. Save as `firebase-service-account.json` in `backend/`
7. Add to `.env`: `FIREBASE_PROJECT_ID=bodysenseai`

## Before Submission Checklist
- [ ] Switch Stripe key from `pk_test_` → `pk_live_` in Keychain (Profile → API Keys)
- [ ] Switch backend to `sk_live_` Stripe secret key
- [ ] Real Stripe Price IDs in StripeManager.swift
- [ ] Stripe SDK added via SPM
- [ ] Apple Pay merchant registered
- [ ] Firebase project created and Firestore enabled
- [ ] Backend deployed with Firebase service account
- [ ] App Store Connect app registered
- [ ] Screenshots (6.7", 6.5", 5.5" iPhone + iPad 12.9")
- [ ] Privacy Policy URL live at bodysenseai.co.uk/privacy
- [ ] Terms of Service URL live at bodysenseai.co.uk/terms
- [ ] App privacy labels filled in App Store Connect
- [ ] ICO registration completed (UK data protection)
- [ ] TestFlight beta test completed
- [ ] GDPR consent flow tested end-to-end
- [ ] Account deletion verified working
- [ ] Use in-app Launch Checklist (Profile → Launch Checklist)
