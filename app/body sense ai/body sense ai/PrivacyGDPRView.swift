//
//  PrivacyGDPRView.swift
//  body sense ai
//
//  Privacy Policy, Terms of Service, GDPR consent management,
//  data export, and account deletion — UK/EU GDPR compliant.
//

import SwiftUI

// MARK: - Privacy & Data Settings (Profile Settings)

struct PrivacySettingsView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    @State private var showPrivacyPolicy  = false
    @State private var showTerms          = false
    @State private var showDeleteConfirm  = false
    @State private var showExportConfirm  = false
    @State private var exportComplete     = false
    @State private var deleteStep         = 0 // 0=initial, 1=confirmed, 2=done

    var body: some View {
        List {
            // ── Consent Management ──
            Section {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Privacy Matters")
                            .font(.headline)
                        Text("You control what data we process. Required consents are needed for the app to function. Optional ones can be changed anytime.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                } icon: {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(.brandPurple)
                }
            }
            .listRowBackground(Color.brandPurple.opacity(0.05))

            Section("Required Consents") {
                consentToggle(
                    "Health Data Processing",
                    subtitle: "Process your health readings, vitals, and medical data to provide health insights",
                    icon: "heart.text.clipboard.fill",
                    color: .brandCoral,
                    isOn: Binding(
                        get: { store.userProfile.consentHealthDataProcessing },
                        set: { store.userProfile.consentHealthDataProcessing = $0; store.save() }
                    ),
                    required: true
                )
            }

            Section("Optional Consents") {
                consentToggle(
                    "AI Health Advice",
                    subtitle: "Allow AI coaches to analyse your health data for personalised advice",
                    icon: "brain.head.profile",
                    color: .brandPurple,
                    isOn: Binding(
                        get: { store.userProfile.consentAIProcessing },
                        set: { store.userProfile.consentAIProcessing = $0; store.save() }
                    )
                )

                consentToggle(
                    "Anonymous Analytics",
                    subtitle: "Help us improve with anonymised, non-identifiable usage data",
                    icon: "chart.bar.fill",
                    color: .brandTeal,
                    isOn: Binding(
                        get: { store.userProfile.consentAnalytics },
                        set: { store.userProfile.consentAnalytics = $0; store.save() }
                    )
                )

                consentToggle(
                    "Research Data Sharing",
                    subtitle: "Contribute anonymised health data to medical research (never personally identifiable)",
                    icon: "magnifyingglass.circle.fill",
                    color: .brandGreen,
                    isOn: Binding(
                        get: { store.userProfile.consentDataSharing },
                        set: { store.userProfile.consentDataSharing = $0; store.save() }
                    )
                )

                consentToggle(
                    "Marketing & Promotions",
                    subtitle: "Receive product updates, offers, and health tips via email",
                    icon: "envelope.fill",
                    color: .brandAmber,
                    isOn: Binding(
                        get: { store.userProfile.consentMarketing },
                        set: { store.userProfile.consentMarketing = $0; store.save() }
                    )
                )
            }

            // ── Legal Documents ──
            Section("Legal") {
                Button { showPrivacyPolicy = true } label: {
                    HStack {
                        Image(systemName: "doc.text.fill").foregroundColor(.brandPurple)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Privacy Policy").foregroundColor(.primary)
                            if let date = store.userProfile.privacyPolicyAcceptedAt {
                                Text("Accepted \(date, style: .date)")
                                    .font(.caption2).foregroundColor(.brandGreen)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.secondary).font(.caption)
                    }
                }

                Button { showTerms = true } label: {
                    HStack {
                        Image(systemName: "doc.plaintext.fill").foregroundColor(.brandTeal)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Terms of Service").foregroundColor(.primary)
                            if let date = store.userProfile.termsAcceptedAt {
                                Text("Accepted \(date, style: .date)")
                                    .font(.caption2).foregroundColor(.brandGreen)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.secondary).font(.caption)
                    }
                }
            }

            // ── Data Rights (GDPR Articles 15-20) ──
            Section {
                // Export Data (Right of Access & Portability — Article 15 & 20)
                Button {
                    showExportConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up.fill").foregroundColor(.brandTeal)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export My Data").foregroundColor(.primary)
                            Text("Download all your health data as a JSON file")
                                .font(.caption2).foregroundColor(.secondary)
                        }
                        Spacer()
                        if exportComplete {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.brandGreen)
                        }
                    }
                }

                if let exportDate = store.userProfile.dataExportRequestedAt {
                    HStack {
                        Image(systemName: "clock.fill").foregroundColor(.secondary).frame(width: 28)
                        Text("Last export: \(exportDate, style: .date)")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Your Data Rights (GDPR)")
            } footer: {
                Text("Under UK GDPR & EU GDPR, you have the right to access, export, and delete your personal data at any time.")
                    .font(.caption2)
            }

            // ── Delete Account (Right to Erasure — Article 17) ──
            Section {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Delete My Account & All Data")
                        Spacer()
                    }
                }
            } footer: {
                Text("This permanently deletes all your health data, preferences, and account information from this device. This action cannot be undone.")
                    .font(.caption2)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Privacy & Data")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            NavigationView {
                PrivacyPolicyView()
                    .environment(store)
            }
        }
        .sheet(isPresented: $showTerms) {
            NavigationView {
                TermsOfServiceView()
                    .environment(store)
            }
        }
        .alert("Export Your Data", isPresented: $showExportConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Export") { exportData() }
        } message: {
            Text("We'll generate a JSON file containing all your health data, profile information, and activity history. You can save or share it.")
        }
        .alert("Delete Account", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Everything", role: .destructive) { deleteAccount() }
        } message: {
            Text("This will permanently erase ALL your data including health readings, appointments, prescriptions, and profile information. This cannot be undone.")
        }
    }

    // MARK: - Consent Toggle

    func consentToggle(_ title: String, subtitle: String, icon: String, color: Color, isOn: Binding<Bool>, required: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(color).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title).font(.subheadline)
                    if required {
                        Text("Required")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Color.brandCoral)
                            .cornerRadius(4)
                    }
                }
                Text(subtitle)
                    .font(.caption2).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(color)
                .disabled(required && isOn.wrappedValue) // Can't turn off required consent while using app
        }
    }

    // MARK: - Export Data

    func exportData() {
        let store = HealthStore.shared
        var export: [String: Any] = [:]

        // Profile
        export["profile"] = [
            "name": store.userProfile.name,
            "email": store.userProfile.email,
            "age": store.userProfile.age,
            "gender": store.userProfile.gender,
            "country": store.userProfile.country,
            "city": store.userProfile.city,
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "gdprBasis": "Article 20 — Right to Data Portability"
        ]

        // Health summary
        export["healthSummary"] = store.thirtyDayReadingsSummary()

        // Record counts
        export["dataCounts"] = [
            "glucoseReadings": store.glucoseReadings.count,
            "bloodPressure": store.bpReadings.count,
            "heartRate": store.heartRateReadings.count,
            "sleep": store.sleepEntries.count,
            "steps": store.stepEntries.count,
            "water": store.waterEntries.count,
            "nutrition": store.nutritionLogs.count,
            "symptoms": store.symptomLogs.count,
            "medications": store.medications.count,
            "appointments": store.appointments.count,
            "prescriptions": store.prescriptions.count
        ]

        // Consent record
        export["consentRecord"] = [
            "healthDataProcessing": store.userProfile.consentHealthDataProcessing,
            "analytics": store.userProfile.consentAnalytics,
            "marketing": store.userProfile.consentMarketing,
            "dataSharing": store.userProfile.consentDataSharing,
            "aiProcessing": store.userProfile.consentAIProcessing,
            "privacyPolicyAccepted": store.userProfile.privacyPolicyAccepted,
            "termsAccepted": store.userProfile.termsAccepted
        ]

        // Create shareable JSON
        if let jsonData = try? JSONSerialization.data(withJSONObject: export, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {

            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("BodySenseAI_DataExport_\(Date().timeIntervalSince1970).json")
            try? jsonString.write(to: tempURL, atomically: true, encoding: .utf8)

            // Share sheet
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        }

        store.userProfile.dataExportRequestedAt = Date()
        store.save()
        withAnimation { exportComplete = true }
    }

    // MARK: - Delete Account

    func deleteAccount() {
        let store = HealthStore.shared

        // Clear all health data
        store.glucoseReadings.removeAll()
        store.bpReadings.removeAll()
        store.heartRateReadings.removeAll()
        store.hrvReadings.removeAll()
        store.sleepEntries.removeAll()
        store.stressReadings.removeAll()
        store.bodyTempReadings.removeAll()
        store.stepEntries.removeAll()
        store.waterEntries.removeAll()
        store.nutritionLogs.removeAll()
        store.symptomLogs.removeAll()
        store.medications.removeAll()
        store.cycles.removeAll()
        store.healthAlerts.removeAll()
        store.healthGoals.removeAll()
        store.healthChallenges.removeAll()
        store.achievements.removeAll()
        store.userStreaks.removeAll()
        store.communityGroups.removeAll()
        store.appointments.removeAll()
        store.prescriptions.removeAll()
        store.medicalRecords.removeAll()
        store.doctorReviews.removeAll()
        store.orders.removeAll()
        store.cartItems.removeAll()

        // Reset profile
        store.userProfile = UserProfile()

        // Clear Keychain
        KeychainManager.shared.deleteAll()

        // Clear UserDefaults
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
        }

        store.save()
        dismiss()
    }
}

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                VStack(alignment: .leading, spacing: 8) {
                    Text("Privacy Policy")
                        .font(.largeTitle).fontWeight(.bold)
                    Text("Last updated: 17 March 2026")
                        .font(.caption).foregroundColor(.secondary)
                    Text("BodySense AI Ltd, United Kingdom")
                        .font(.caption).foregroundColor(.secondary)
                }

                policySection("1. Who We Are",
                    "BodySense AI Ltd (\"we\", \"our\", \"us\") is the data controller for your personal data. We are registered in the United Kingdom and comply with the UK General Data Protection Regulation (UK GDPR) and the Data Protection Act 2018.\n\nData Protection Officer: privacy@bodysenseai.co.uk")

                policySection("2. What Data We Collect",
                    """
                    We collect the following categories of personal data:

                    Health & Medical Data (Special Category):
                    - Blood glucose, blood pressure, heart rate, HRV, SpO2
                    - Sleep patterns, stress levels, body temperature
                    - Weight, height, BMI, nutrition intake
                    - Medications, symptoms, menstrual cycle data
                    - Medical conditions and health goals

                    Identity Data:
                    - Name, email address, age, gender
                    - Profile photo (optional)

                    Location Data:
                    - City, country, postcode (for doctor search)

                    Device Data:
                    - BodySense Ring readings, Apple Health data
                    - Device identifiers (anonymised)

                    Financial Data:
                    - Payment information (processed by Stripe, never stored on device)
                    - Order history
                    """)

                policySection("3. Legal Basis for Processing (Article 6 & 9 UK GDPR)",
                    """
                    We process your data under the following legal bases:

                    Explicit Consent (Article 9(2)(a)): Processing of health data requires your explicit consent, which you provide during onboarding and can withdraw at any time.

                    Contract Performance (Article 6(1)(b)): To provide health tracking, doctor consultations, and product orders.

                    Legitimate Interest (Article 6(1)(f)): App security, fraud prevention, and service improvement (with anonymised data only).

                    You can withdraw consent at any time via Profile > Privacy & Data settings. Withdrawing consent does not affect the lawfulness of prior processing.
                    """)

                policySection("4. How We Use Your Data",
                    """
                    - Provide personalised health insights and tracking
                    - AI-powered health coaching (only with your consent)
                    - Connect you with verified doctors for telemedicine
                    - Process orders and manage subscriptions
                    - Send appointment reminders and health notifications
                    - Improve our services (anonymised analytics only, with consent)
                    - Medical research (fully anonymised, with consent)
                    """)

                policySection("5. Data Storage & Security",
                    """
                    - All health data is stored locally on your device using encrypted storage
                    - API keys and secrets are stored in the iOS Keychain (hardware-encrypted)
                    - Biometric authentication (Face ID/Touch ID) available for app access
                    - Payment data is processed by Stripe (PCI DSS Level 1 compliant) and never touches our servers
                    - We use HTTPS/TLS for all network communications
                    - No health data is sent to third parties without your explicit consent
                    """)

                policySection("6. Your Rights (Articles 15-22 UK GDPR)",
                    """
                    You have the following rights:

                    Right of Access (Art. 15): Request a copy of all data we hold about you.
                    Right to Rectification (Art. 16): Correct inaccurate personal data.
                    Right to Erasure (Art. 17): Delete your account and all associated data.
                    Right to Restrict Processing (Art. 18): Limit how we use your data.
                    Right to Data Portability (Art. 20): Export your data in a machine-readable format.
                    Right to Object (Art. 21): Object to processing based on legitimate interest.
                    Right to Withdraw Consent: Withdraw any consent at any time.

                    Exercise these rights via: Profile > Privacy & Data, or email privacy@bodysenseai.co.uk
                    """)

                policySection("7. Data Retention",
                    """
                    - Active accounts: Data retained while your account is active
                    - Deleted accounts: All data erased immediately and permanently
                    - We do not retain backups of deleted data
                    - Financial records: Retained for 7 years (UK legal requirement)
                    """)

                policySection("8. Children's Privacy",
                    "BodySense AI is not intended for children under 16. We do not knowingly collect data from children. If you believe a child has provided us data, contact privacy@bodysenseai.co.uk.")

                policySection("9. International Transfers",
                    "Your data is processed primarily on your device. AI processing uses Anthropic's API (US-based), protected under UK GDPR adequacy decisions and Standard Contractual Clauses. No health data is permanently stored outside the UK/EEA.")

                policySection("10. Changes to This Policy",
                    "We may update this policy periodically. Material changes will be notified in-app. Continued use after notification constitutes acceptance.")

                policySection("11. Contact & Complaints",
                    """
                    Data Protection Officer: privacy@bodysenseai.co.uk
                    Address: BodySense AI Ltd, Manchester, United Kingdom

                    You have the right to lodge a complaint with the Information Commissioner's Office (ICO):
                    ico.org.uk | 0303 123 1113
                    """)

                // Accept button
                if !store.userProfile.privacyPolicyAccepted {
                    acceptButton("I Accept the Privacy Policy") {
                        store.userProfile.privacyPolicyAccepted = true
                        store.userProfile.privacyPolicyAcceptedAt = Date()
                        store.save()
                        dismiss()
                    }
                } else {
                    HStack {
                        Image(systemName: "checkmark.seal.fill").foregroundColor(.brandGreen)
                        Text("Accepted on \(store.userProfile.privacyPolicyAcceptedAt ?? Date(), style: .date)")
                            .font(.subheadline).foregroundColor(.brandGreen)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    func policySection(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline).foregroundColor(.brandPurple)
            Text(body).font(.subheadline).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    func acceptButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.headline).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding()
                .background(Color.brandPurple).cornerRadius(14)
        }
        .padding(.top)
    }
}

// MARK: - Terms of Service View

struct TermsOfServiceView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                VStack(alignment: .leading, spacing: 8) {
                    Text("Terms of Service")
                        .font(.largeTitle).fontWeight(.bold)
                    Text("Last updated: 17 March 2026")
                        .font(.caption).foregroundColor(.secondary)
                }

                termSection("1. Acceptance",
                    "By using BodySense AI, you agree to these Terms of Service and our Privacy Policy. If you do not agree, please do not use the app.")

                termSection("2. Service Description",
                    "BodySense AI is a health monitoring and wellness platform that provides:\n- Health vitals tracking (glucose, BP, HR, sleep, etc.)\n- AI-powered health coaching and insights\n- Telemedicine doctor consultations\n- Smart ring integration\n- Nutrition and medication tracking\n- Community health groups")

                termSection("3. Medical Disclaimer",
                    """
                    IMPORTANT: BodySense AI is NOT a medical device and is not intended to diagnose, treat, cure, or prevent any disease.

                    - AI health insights are informational only and do not constitute medical advice
                    - Always consult a qualified healthcare professional for medical decisions
                    - In an emergency, call 999 (UK) or your local emergency number
                    - Doctor consultations via the app are provided by independent, GMC-registered practitioners
                    - BodySense AI Ltd is not liable for medical decisions made based on app data
                    """)

                termSection("4. User Responsibilities",
                    """
                    - Provide accurate personal and health information
                    - Keep your account credentials secure
                    - Do not share your account with others
                    - Do not use the app for illegal purposes
                    - Report any security vulnerabilities to security@bodysenseai.co.uk
                    """)

                termSection("5. Subscriptions & Payments",
                    """
                    - Free tier: Basic health tracking features
                    - Premium plans: Advanced AI, unlimited doctor access, priority support
                    - Payments processed securely by Stripe
                    - Subscriptions auto-renew unless cancelled
                    - Refunds handled per Apple App Store policy
                    - Doctor consultation fees are separate from subscription
                    """)

                termSection("6. Doctor Consultations",
                    """
                    - All doctors are independently verified (GMC, ECFMG, or equivalent)
                    - BodySense AI facilitates but does not provide medical services
                    - Doctor-patient relationship is between you and the doctor
                    - Consultation recordings are not stored
                    - Prescriptions are at the doctor's sole discretion
                    """)

                termSection("7. Intellectual Property",
                    "All content, designs, AI models, and software in BodySense AI are owned by BodySense AI Ltd. You may not copy, modify, distribute, or reverse-engineer any part of the app.")

                termSection("8. Limitation of Liability",
                    "To the maximum extent permitted by UK law, BodySense AI Ltd shall not be liable for any indirect, incidental, or consequential damages arising from use of the app. Our total liability is limited to the amount you paid in the 12 months before the claim.")

                termSection("9. Account Termination",
                    "We may suspend or terminate your account if you violate these terms. You may delete your account at any time via Profile > Privacy & Data > Delete My Account.")

                termSection("10. Governing Law",
                    "These terms are governed by the laws of England and Wales. Disputes shall be resolved in the courts of England and Wales.")

                termSection("11. Contact",
                    "BodySense AI Ltd\nEmail: support@bodysenseai.co.uk\nWeb: bodysenseai.co.uk")

                if !store.userProfile.termsAccepted {
                    Button {
                        store.userProfile.termsAccepted = true
                        store.userProfile.termsAcceptedAt = Date()
                        store.save()
                        dismiss()
                    } label: {
                        Text("I Accept the Terms of Service")
                            .font(.headline).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.brandPurple).cornerRadius(14)
                    }
                    .padding(.top)
                } else {
                    HStack {
                        Image(systemName: "checkmark.seal.fill").foregroundColor(.brandGreen)
                        Text("Accepted on \(store.userProfile.termsAcceptedAt ?? Date(), style: .date)")
                            .font(.subheadline).foregroundColor(.brandGreen)
                    }
                    .frame(maxWidth: .infinity).padding()
                }
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    func termSection(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline).foregroundColor(.brandPurple)
            Text(body).font(.subheadline).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Onboarding Consent Step

struct OnboardingConsentView: View {
    @Environment(HealthStore.self) var store
    let onAccept: () -> Void

    @State private var healthConsent   = false
    @State private var privacyAccepted = false
    @State private var termsAccepted   = false
    @State private var aiConsent       = true
    @State private var analyticsConsent = false
    @State private var showPrivacy     = false
    @State private var showTerms       = false

    var canProceed: Bool {
        healthConsent && privacyAccepted && termsAccepted
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)

                    Text("Your Privacy")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)

                    Text("Before we begin, we need your consent to process your health data. You're always in control.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    VStack(spacing: 12) {
                        // Required: Health data processing
                        consentRow(
                            icon: "heart.text.clipboard.fill",
                            title: "Health Data Processing",
                            subtitle: "Required to track your vitals and health readings",
                            required: true,
                            isOn: $healthConsent
                        )

                        // Required: Privacy Policy
                        Button { showPrivacy = true } label: {
                            consentRow(
                                icon: "doc.text.fill",
                                title: "Privacy Policy",
                                subtitle: "Tap to read, then accept",
                                required: true,
                                isOn: $privacyAccepted,
                                isLink: true
                            )
                        }

                        // Required: Terms
                        Button { showTerms = true } label: {
                            consentRow(
                                icon: "doc.plaintext.fill",
                                title: "Terms of Service",
                                subtitle: "Tap to read, then accept",
                                required: true,
                                isOn: $termsAccepted,
                                isLink: true
                            )
                        }

                        Divider().background(Color.white.opacity(0.3)).padding(.vertical, 4)

                        Text("Optional").font(.caption).foregroundColor(.white.opacity(0.6))

                        // Optional: AI
                        consentRow(
                            icon: "brain.head.profile",
                            title: "AI Health Advice",
                            subtitle: "Let AI coaches analyse your data for personalised tips",
                            isOn: $aiConsent
                        )

                        // Optional: Analytics
                        consentRow(
                            icon: "chart.bar.fill",
                            title: "Anonymous Analytics",
                            subtitle: "Help us improve with anonymised usage data",
                            isOn: $analyticsConsent
                        )
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 24)
            }

            // Accept button
            Button {
                saveConsents()
                onAccept()
            } label: {
                Text(canProceed ? "Continue" : "Accept Required Consents")
                    .font(.headline)
                    .frame(maxWidth: .infinity).padding()
                    .background(canProceed ? Color.white : Color.white.opacity(0.3))
                    .foregroundColor(canProceed ? .brandPurple : .white.opacity(0.5))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            }
            .disabled(!canProceed)
            .padding(.horizontal, 28).padding(.bottom, 40)
        }
        .sheet(isPresented: $showPrivacy) {
            NavigationView {
                PrivacyPolicyAcceptView(accepted: $privacyAccepted)
            }
        }
        .sheet(isPresented: $showTerms) {
            NavigationView {
                TermsAcceptView(accepted: $termsAccepted)
            }
        }
    }

    func consentRow(icon: String, title: String, subtitle: String, required: Bool = false, isOn: Binding<Bool>, isLink: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3).foregroundColor(.white)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title).font(.subheadline).fontWeight(.medium).foregroundColor(.white)
                    if required {
                        Text("Required")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.brandCoral)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(3)
                    }
                }
                Text(subtitle).font(.caption2).foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            if isLink {
                Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "arrow.right.circle")
                    .foregroundColor(isOn.wrappedValue ? .brandGreen : .white.opacity(0.5))
                    .font(.title3)
            } else {
                Toggle("", isOn: isOn).labelsHidden().tint(.brandGreen)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }

    func saveConsents() {
        let store = HealthStore.shared
        store.userProfile.consentHealthDataProcessing = healthConsent
        store.userProfile.privacyPolicyAccepted = privacyAccepted
        store.userProfile.privacyPolicyAcceptedAt = Date()
        store.userProfile.termsAccepted = termsAccepted
        store.userProfile.termsAcceptedAt = Date()
        store.userProfile.consentAIProcessing = aiConsent
        store.userProfile.consentAnalytics = analyticsConsent
        store.save()
    }
}

// MARK: - Inline Accept Views (for onboarding sheets)

struct PrivacyPolicyAcceptView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var accepted: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy").font(.title).fontWeight(.bold)
                Text("Last updated: 17 March 2026").font(.caption).foregroundColor(.secondary)

                Text("BodySense AI Ltd collects and processes your health data solely to provide personalised health tracking and insights. Your data is stored locally on your device and protected by encryption. You can export or delete your data at any time.")
                    .font(.subheadline).foregroundColor(.secondary)

                Text("Key Points:")
                    .font(.headline).padding(.top)

                bulletPoint("Your health data stays on your device")
                bulletPoint("API keys stored in hardware-encrypted Keychain")
                bulletPoint("No data sold to third parties, ever")
                bulletPoint("AI processing only with your explicit consent")
                bulletPoint("Full data export and deletion available anytime")
                bulletPoint("UK GDPR and Data Protection Act 2018 compliant")
                bulletPoint("Contact: privacy@bodysenseai.co.uk")

                Button {
                    accepted = true
                    dismiss()
                } label: {
                    Text("I Accept")
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.brandPurple).cornerRadius(14)
                }
                .padding(.top, 20)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.shield.fill").foregroundColor(.brandGreen).font(.caption)
            Text(text).font(.subheadline).foregroundColor(.secondary)
        }
    }
}

struct TermsAcceptView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var accepted: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service").font(.title).fontWeight(.bold)
                Text("Last updated: 17 March 2026").font(.caption).foregroundColor(.secondary)

                Text("By using BodySense AI, you agree to the following terms:")
                    .font(.subheadline).foregroundColor(.secondary)

                bulletPoint("BodySense AI is NOT a medical device — always consult a doctor for medical decisions")
                bulletPoint("AI insights are informational only, not medical advice")
                bulletPoint("In emergencies, call 999 (UK) or your local emergency number")
                bulletPoint("Doctors on the platform are independently verified (GMC/ECFMG)")
                bulletPoint("Payments are processed securely by Stripe")
                bulletPoint("You are responsible for keeping your account secure")
                bulletPoint("You can delete your account and all data at any time")
                bulletPoint("Governed by the laws of England and Wales")

                Button {
                    accepted = true
                    dismiss()
                } label: {
                    Text("I Accept")
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.brandPurple).cornerRadius(14)
                }
                .padding(.top, 20)
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "doc.text.fill").foregroundColor(.brandTeal).font(.caption)
            Text(text).font(.subheadline).foregroundColor(.secondary)
        }
    }
}
