# BodySense AI — Master Project Guide & Agent Team

> **Mission:** Help every person in the world — diabetic, hypertensive, overweight, underweight,
> athlete, or anyone with any health goal — understand their body, improve their health, and live better.
> AI-powered. Doctor-connected. Built for every human, every diet, every body.
>
> **Rule:** This is NOT a demo app. Every feature is production-grade. No shortcuts. No mock data. No bypasses.

---

## Architecture

```
iOS App (Swift 6 / SwiftUI / iOS 17+)
  ├─ AI: Apple Foundation Models (on-device) + Claude API via Railway (cloud fallback)
  ├─ Data: UserDefaults + EncryptedStore (local) + CloudKit (sync)
  ├─ Auth: Sign in with Apple + JWT (Keychain)
  ├─ Health: HealthKit (40+ data types) + BodySense Ring (Bluetooth LE)
  └─ Payments: StoreKit 2 (subscriptions) + Apple Pay (Ring hardware) + Stripe (backend)

Backend (Node.js + Express — Railway)
  ├─ URL: https://body-sense-ai-production.up.railway.app
  ├─ DB: Firebase Firestore
  ├─ AI Proxy: /ai-chat → Anthropic Claude claude-haiku-4-5-20251001
  └─ Push: APNs

60+ Swift files. Single HealthStore. Zero duplication. Zero tolerance for workarounds.
```

---

## Three User Roles — The Golden Rule: Additive Only

| Feature | Patient | Doctor (Pending) | Doctor (Approved) | CEO |
|---------|---------|-----------------|-------------------|-----|
| Full patient app | ✅ | ✅ | ✅ | ✅ |
| HealthSense Chat (8 personas) | ✅ | ✅ | ✅ | ✅ |
| Health Coach, Nutrition, Fitness agents | ✅ | ✅ | ✅ | ✅ |
| Shop, Sleep, Mindfulness, Customer Care | ✅ | ✅ | ✅ | ✅ |
| **Doctor Mode toggle** | ❌ | ❌ | ✅ | ✅ |
| **Becky AI (Doctor assistant)** | ❌ | ❌ LOCKED | ✅ | ✅ |
| **Doctor Dashboard, Appointments** | ❌ | ❌ | ✅ | ✅ |
| **Business Advisor, Nova** | ❌ | ❌ | ❌ | ✅ |
| **CEO Dashboard, Agent Team** | ❌ | ❌ | ❌ | ✅ |
| **Doctor Approval Panel** | ❌ | ❌ | ❌ | ✅ |

**Doctor features are ADDITIVE — doctors keep 100% of patient experience.**

---

## Non-Negotiable Security Rules

1. **`isDoctorApproved`** checks `isDoctor && isVerified && verificationStatus == "Verified"` — all three
2. **CEO access** = `CEOAccessManager.isActivated` (Keychain secret code) — NEVER email-based
3. **Becky AI** locked for unapproved doctors — `isDoctorApproved` gate only
4. **GMC number** format: `^[1-9]\d{6}$` (exactly 7 digits)
5. **Zero client trust** — all critical checks enforced server-side too
6. **Audit trail** for all doctor approval/rejection actions
7. **HealthKit data** never sent to backend without explicit user consent
8. **No PHI in backend learning endpoints** — anonymised patterns only

---

## AI System — Two Engines, One Goal

### Engine 1: HealthSense Chat (All Users)
```
Auto-routes to 8 domain personas based on intent:
Dr. Sage (Medical) → Cara (Personal Care) → Maya (Nutrition) → Alex (Fitness)
Chef Kai (Food) → Luna (Sleep) → Zen (Mental Wellness) → HealthSense (General)

Learning: UserInsight objects stored in AgentMemoryStore
          Correlations detected across health metrics
          Confidence grows with every confirmed interaction
```

### Engine 2: Agent Team (Role-Gated)
```
All users:    Health Coach, Nutritionist, Fitness Coach, Sleep Coach,
              Mindfulness, Shop Advisor, Customer Care
Doctor only:  Becky (Doctor AI assistant)
CEO only:     Nova (Aggregate Intelligence), Business Advisor

CEO can append custom instructions to any agent via agentCustomPrompts[]
```

### How Agents Get Smarter Over Time (7 Learning Layers)
```
Layer 1: Individual memory     — conditions, goals, allergies, triggers remembered forever
Layer 2: Behavioural patterns  — when/how user interacts → personalises responses
Layer 3: Health correlations   — auto-detects "rice spikes your glucose" type patterns
Layer 4: Feedback signals      — thumbs up/down on every response → adjusts quality
Layer 5: Doctor corrections    — approved doctors correcting AI = highest quality signal
Layer 6: Server aggregate      — anonymised patterns across users → better global defaults
Layer 7: Prompt evolution      — underperforming prompts surface to CEO for upgrade
```

---

## CEO Access System

- Activation: Profile → tap "Version 1.0" five times rapidly → enter secret code
- Code stored as SHA-256 hash in `AppSecurity.swift` → `CEOAccessManager`
- `isCEO` = `CEOAccessManager.isActivated` (Keychain) — NEVER email
- DoctorApprovalView: double-gated (iOS + backend `requireCEO` middleware)

---

## Doctor Verification Pipeline

```
1. Register → Firestore: verificationStatus: "Pending"
2. Document upload (Phase 2): Photo ID, DBS, Insurance, Qualification
3. GMC API live check (Phase 3): ^[1-9]\d{6}$ validated against GMC register
4. CEO approves → isVerified: true + verificationStatus: "Verified" (BOTH required)
5. Push notification sent → doctor features unlock → Becky AI available
```

---

## UI Design System (NEVER DEVIATE)

```swift
// Cards
.background(Color(.secondarySystemBackground)).cornerRadius(16)
.shadow(color: .black.opacity(0.06), radius: 8, y: 2)

// Primary buttons: 54pt height, 14pt corner radius
// Input fields: Color(.tertiarySystemBackground)
// Status badges: pill shape, 12% opacity background, cornerRadius(100)
// Doctor Registration: Color(.systemBackground) — NOT purple gradient

// Rules:
// ✅ NavigationStack (never NavigationView)
// ✅ @EnvironmentObject var store: HealthStore (never @StateObject for HealthStore)
// ✅ System semantic colors only (never hardcoded)
// ✅ UK units: mmol/L, kg, cm, °C, GBP (£)
// ❌ No emoji in UI components (greeting banners only)
// ❌ No mock/seed/placeholder data
```

---

## Key Files Reference

```swift
ContentView.swift              // Root navigation, onboarding, MainTabView
HealthModels.swift             // ALL models — SINGLE SOURCE OF TRUTH — never duplicate
DashboardView.swift            // Patient home
DoctorDashboardView.swift      // Doctor home (isDoctorApproved && isDoctorModeOn)
CEODashboardView.swift         // CEO command centre (CEOAccessManager.isActivated)
AgentTeamView.swift            // CEO agent panel
ProfileView.swift              // Settings, role switching, CEO Controls access
AnthropicClient.swift          // AgentType enum, all system prompts, AI client actor
HealthSenseAgent.swift         // Domain routing, learning loop, correlation engine
AgentMemoryStore.swift         // UserInsight CRUD, confidence scoring, relevance ranking
AgentAnalytics.swift           // Analytics engine powering Nova's intelligence
AgentReportExporter.swift      // CEO PDF report generation
AppSecurity.swift              // CEOAccessManager, biometrics, jailbreak detection
HealthKitManager.swift         // Apple Health sync (40+ data types)
KeychainManager.swift          // Secure Keychain CRUD
NetworkSecurity.swift          // TLS, certificate pinning, network guards
StoreKitManager.swift          // StoreKit 2 subscriptions and entitlements
ApplePayManager.swift          // Apple Pay for BodySense Ring hardware
PaymentManager.swift           // Payment coordinator
EncryptedStore.swift           // AES-256 encrypted local health data
CloudSyncService.swift         // CloudKit cross-device sync
```

---

## Build Order — Every Feature, Every Time

```
1. HealthModels.swift      → Define model + @Published var + save/load (ALWAYS FIRST)
2. backend/server.js       → API endpoints (if cloud data needed)
3. HealthKitManager.swift  → Health data integration (if HealthKit involved)
4. AI context update       → AnthropicClient / HealthSenseAgent (if agents should know)
5. SwiftUI views           → Build UI (model MUST exist before view)
6. Security gates          → isDoctorApproved / CEOAccessManager / StoreKit
7. Connect & validate      → All layers working together end-to-end
```

---

## The Complete Agent Team

12 specialist agents. Every one knows your exact codebase, rules, and architecture.

### 🏗️ Building Agents

| Agent | Invoke When |
|-------|-------------|
| **app-builder-orchestrator** | "Build feature X end-to-end", "I want users to be able to Y", complete new features touching multiple layers |
| **ios-swiftui-engineer** | Any SwiftUI screen, navigation, UI component, Swift 6 concurrency issue |
| **backend-engineer** | Node.js server, Firebase, JWT, Railway deploy, new API endpoints |
| **healthkit-data-engineer** | HealthKit types, HealthModels changes, CloudKit, data export, new metrics |
| **payments-engineer** | StoreKit 2, Apple Pay, Stripe, subscription gating, pricing |

### 🧠 Intelligence Agents

| Agent | Invoke When |
|-------|-------------|
| **ai-learning-engineer** | "Make agents smarter", feedback loops, memory/correlation improvements, prompt evolution, user insight extraction |
| **ai-prompt-engineer** | System prompt editing, new agent personas, response quality tuning, new health domains |

### 🏥 Platform Agents

| Agent | Invoke When |
|-------|-------------|
| **doctor-platform-engineer** | Doctor registration, GMC, CEO approval, Becky AI, appointments, video calls |
| **security-engineer** | CEO system, Keychain, biometrics, JWT, jailbreak detection, network security |

### 🚀 Delivery Agents

| Agent | Invoke When |
|-------|-------------|
| **qa-debug-engineer** | Bug fixes, Xcode warnings (including 2 active async issues), crashes, regressions |
| **devops-deployment-engineer** | Railway deploy, Docker, Firebase config, TestFlight, App Store submission |
| **app-store-compliance-engineer** | App Store review, GDPR, HealthKit justification, privacy manifest, accessibility |

---

## Quick Decision Guide

```
"Build a whole new feature"            → app-builder-orchestrator
"Build / fix a SwiftUI screen"         → ios-swiftui-engineer
"Make the AI give better answers"      → ai-learning-engineer + ai-prompt-engineer
"The AI forgot what I told it"         → ai-learning-engineer
"Fix Xcode warning or crash"           → qa-debug-engineer
"Doctor feature not working"           → doctor-platform-engineer
"CEO access broken"                    → security-engineer
"Deploy the backend"                   → devops-deployment-engineer
"Add new health metric tracking"       → healthkit-data-engineer
"Subscription or payment issue"        → payments-engineer
"App Store review question"            → app-store-compliance-engineer
"New backend API needed"               → backend-engineer
"Improve Dr. Sage / Maya / Alex"       → ai-prompt-engineer
"Add user feedback to AI responses"    → ai-learning-engineer
```

---

## The Goal Behind Every Line of Code

BodySense AI exists to help **every person on earth** — Type 1 or Type 2 diabetic, hypertensive,
heart patient, someone trying to lose weight, someone trying to build muscle, someone with PCOS,
someone who just wants to eat better — understand their own body through the power of AI correlation.

**No health goal too small. No condition too complex. No person left behind.**

Build it like it matters. Because it does.
