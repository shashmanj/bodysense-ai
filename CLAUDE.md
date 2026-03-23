# BodySense AI — Project Guide

## Architecture
- SwiftUI iOS app, 60+ Swift files
- Data: UserDefaults + EncryptedStore (local) + CloudKit (sync)
- Auth: Sign in with Apple (native, no third-party)
- AI: Apple Foundation Models (on-device)
- Backend: Node.js + Express + Stripe + Firebase Admin (optional)
- Payments: Stripe + Apple Pay + StoreKit 2

## Three User Roles
1. **Patient** — health tracking, nutrition, community, booking appointments
2. **Doctor** — ALSO a full patient user + appointments, earnings, Becky AI assistant
3. **CEO** — ALSO a full patient user + business dashboard, doctor approvals

**Critical rule:** Doctors and CEO keep the FULL patient app experience. Doctor features are ADDITIVE, not a replacement.

## Doctor Verification Pipeline (IN PROGRESS)
- Doctor registration collects credentials but currently has NO real verification
- GMC number validation, document upload, and CEO approval are being hardened
- See the full specification in this file for target state

## Non-Negotiable Security Rules
1. No doctor access to Becky/patient data without CEO approval
2. `isDoctorApproved` must check `verificationStatus == "Verified"`, not just `isDoctor`
3. GMC number must be 7 digits (live API verification coming in Phase 3)
4. Document upload (Photo ID, DBS, Insurance, Qualification) required (Phase 2)
5. Audit trail for all approval/rejection actions
6. Zero trust on client — server-side enforcement as final layer (Phase 5)

## Key Files
- `ContentView.swift` — Navigation, onboarding, doctor registration form
- `HealthModels.swift` — All data models, HealthStore, persistence
- `DoctorDashboardView.swift` — Doctor dashboard + BeckyAIView
- `DoctorApprovalView.swift` — CEO review panel
- `DoctorAppointmentsView.swift` — Patient-facing doctor list + booking
- `ProfileView.swift` — Patient and doctor profile views
- `HealthSenseAgent.swift` — AI agent with correlation engine
- `HealthKitManager.swift` — Apple Health sync (40+ data types)

## UI Rules
- Cards: `.background(Color(.secondarySystemBackground)).cornerRadius(16).shadow(color: .black.opacity(0.06), radius: 8, y: 2)`
- Buttons: 54pt height, 14pt corner radius, brandTeal for primary CTA
- Status badges: pill shape with 12% opacity background
- No hardcoded colors — use system semantic colors for dark mode
- No emoji in UI components (allowed in greeting banners only)
