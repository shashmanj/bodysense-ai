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
3. **CEO** — ALSO a full patient user + business dashboard, doctor approvals, all AI agents

**Critical rule:** Doctors and CEO keep the FULL patient app experience. Doctor/CEO features are ADDITIVE, not a replacement.

## AI Agent Access Rules (ENFORCED)

### System 1: HealthSense Chat (Home tab → Chat)
Auto-routes to the right persona. ALL users get access.
- Dr. Sage (Medical), Cara (Personal Care), Maya (Nutrition), Alex (Fitness)
- Chef Kai (Food), Luna (Sleep), Zen (Mental Wellness), HealthSense (General)

### System 2: Named Agent Team (AgentTeamView)
Role-gated access:

| Agent | Patient | Doctor (pending) | Doctor (approved) | CEO |
|-------|---------|-------------------|-------------------|-----|
| Health Coach | ✅ | ✅ | ✅ | ✅ |
| Nutritionist | ✅ | ✅ | ✅ | ✅ |
| Fitness Coach | ✅ | ✅ | ✅ | ✅ |
| Sleep Coach | ✅ | ✅ | ✅ | ✅ |
| Mindfulness | ✅ | ✅ | ✅ | ✅ |
| Shop Advisor | ✅ | ✅ | ✅ | ✅ |
| Customer Care | ✅ | ✅ | ✅ | ✅ |
| **Becky (Doctor AI)** | ❌ | ❌ LOCKED | ✅ | ✅ |
| **Business Advisor** | ❌ | ❌ | ❌ | ✅ |
| **Nova (CEO Intelligence)** | ❌ | ❌ | ❌ | ✅ |
| **Team Meeting** | limited | limited | limited | ✅ all agents |
| **CEO Report (PDF)** | ❌ | ❌ | ❌ | ✅ |
| **Escalated Tickets** | ❌ | ❌ | ❌ | ✅ |

### Where agents are accessed:
- **Patients**: HealthSense Chat on Home tab (auto-routed, all 8 personas)
- **Approved Doctors**: Becky via Doctor Dashboard (Doctor Mode ON → Home tab)
- **CEO**: Agent Team via Profile → CEO Controls → "AI Agent Team"
- **Everyone**: AI Agent Settings in Profile (customise which domains are active)

## CEO Access System
- NOT based on email. Uses secret activation code + SHA-256 hash + Keychain.
- Activation: Profile → tap "Version 1.0" 5 times rapidly → enter code
- Code hash stored in `AppSecurity.swift` → `CEOAccessManager`
- `isCEO` computed property uses `CEOAccessManager.isActivated`
- DoctorApprovalView has hard gate — checks CEO status directly

## Doctor Verification Pipeline
- Doctor registration collects credentials
- GMC number must be 7 digits, format: `^[1-9]\d{6}$` (live API Phase 3)
- Document upload (Photo ID, DBS, Insurance, Qualification) required (Phase 2)
- CEO approval required before doctor features unlock
- `isDoctorApproved` checks BOTH `isVerified` AND `verificationStatus == "Verified"`
- Becky LOCKED for unapproved doctors
- Doctor Mode toggle in Profile (only visible when approved)

## Non-Negotiable Security Rules
1. No doctor access to Becky/patient data without CEO approval
2. `isDoctorApproved` must check `verificationStatus == "Verified"`, not just `isDoctor`
3. GMC number must be 7 digits (live API verification coming in Phase 3)
4. Document upload (Photo ID, DBS, Insurance, Qualification) required (Phase 2)
5. Audit trail for all approval/rejection actions
6. Zero trust on client — server-side enforcement as final layer (Phase 5)
7. CEO role via Keychain secret code, NEVER via email check
8. All agent access must respect the role table above — no exceptions

## Key Files
- `ContentView.swift` — Navigation, onboarding, doctor registration form, MainTabView
- `HealthModels.swift` — All data models, HealthStore, persistence, isDoctorApproved
- `DoctorDashboardView.swift` — Doctor dashboard + BeckyAIView (gated)
- `DoctorApprovalView.swift` — CEO review panel (hard-gated on CEOAccessManager)
- `DoctorAppointmentsView.swift` — Patient-facing doctor list + booking
- `ProfileView.swift` — Patient/doctor profile, Doctor Mode toggle, CEO Controls, agent access
- `AgentTeamView.swift` — CEO agent command centre (Nova, Business Advisor, Team Meeting)
- `AnthropicClient.swift` — AgentType enum, system prompts, isCEOOnly flag
- `HealthSenseAgent.swift` — AI agent with correlation engine + domain routing
- `AppSecurity.swift` — CEOAccessManager, biometric auth, jailbreak detection
- `HealthKitManager.swift` — Apple Health sync (40+ data types)

## UI Rules
- Cards: `.background(Color(.secondarySystemBackground)).cornerRadius(16).shadow(color: .black.opacity(0.06), radius: 8, y: 2)`
- Buttons: 54pt height, 14pt corner radius, brandTeal for primary CTA
- Status badges: pill shape with 12% opacity background
- No hardcoded colors — use system semantic colors for dark mode
- No emoji in UI components (allowed in greeting banners only)
- Doctor Registration: clean white background (NOT purple gradient)
- Forms: use `Color(.tertiarySystemBackground)` for input fields
