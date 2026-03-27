//
//  ContentView.swift
//  body sense ai
//
//  Auth flow: Welcome → Sign In | Register | Register as Doctor
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import CoreLocation

// MARK: - ContentView (root)

struct ContentView: View {
    @AppStorage("onboardingDone") private var onboardingDone = false
    @State private var store = HealthStore.shared

    var body: some View {
        if onboardingDone {
            MainTabView()
                .environment(store)
        } else {
            AuthRootView(onboardingDone: $onboardingDone)
                .environment(store)
        }
    }
}

// MARK: - Main Tab View (both patient & doctor use same tabs)

struct MainTabView: View {
    @Environment(HealthStore.self) var store
    @State private var tab = 0
    @AppStorage("doctorModeEnabled") private var doctorMode = false

    /// Doctor Mode is only available when the doctor is fully verified/approved
    private var showDoctorHome: Bool {
        doctorMode && store.isDoctorApproved
    }

    var body: some View {
        TabView(selection: $tab) {
            // ── Home: Patient dashboard for everyone; Doctor dashboard when Doctor Mode ON ──
            Group {
                if showDoctorHome {
                    DoctorDashboardView()
                } else {
                    DashboardView()
                }
            }
            .tabItem { Label("Home", systemImage: showDoctorHome ? "stethoscope" : "house.fill") }
            .tag(0)

            TrackView()
                .tabItem { Label("Track", systemImage: "chart.bar.fill") }
                .tag(1)

            ShopView()
                .tabItem { Label("Shop", systemImage: "bag.fill") }
                .tag(2)

            // ── Groups: everyone gets the same community view ──
            // Doctor appointment features are in the Doctor dashboard (Home tab when Doctor Mode ON)
            CommunityView()
                .tabItem { Label("Groups", systemImage: "person.3.fill") }
                .tag(3)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(4)
        }
        .tint(showDoctorHome ? .brandTeal : .brandPurple)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackgroundVisibility(.visible, for: .tabBar)
        // Ensure all tab items render at equal width
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()

            // Equal spacing for all items
            let itemAppearance = UITabBarItemAppearance()
            itemAppearance.normal.iconColor = UIColor.systemGray
            itemAppearance.selected.iconColor = store.isDoctor
                ? UIColor(Color(hex: "#00BFA5"))
                : UIColor(Color(hex: "#7C3AED"))
            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance  = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Auth Root

struct AuthRootView: View {
    @Binding var onboardingDone: Bool
    @Environment(HealthStore.self) var store

    @State private var flow: AuthFlow = .intro

    enum AuthFlow {
        case intro, welcome, profileSetup, permissions
    }

    /// Flows that use the branded purple gradient background
    private var usesGradient: Bool {
        switch flow {
        case .intro, .welcome, .profileSetup: return true
        case .permissions: return false
        }
    }

    /// After sign-in, go to profile setup if new user, otherwise straight to permissions
    private func handleSignInComplete() {
        withAnimation {
            if store.userProfile.name.isEmpty {
                flow = .profileSetup
            } else {
                flow = .permissions
            }
        }
    }

    var body: some View {
        ZStack {
            // Purple gradient for welcome/sign-in; clean background for forms
            if usesGradient {
                LinearGradient(
                    colors: [.brandPurple, Color(hex: "#4834d4")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ).ignoresSafeArea()
            } else {
                Color(.systemGroupedBackground).ignoresSafeArea()
            }

            switch flow {
            case .intro:
                IntroSlidesView(onFinish: { withAnimation { flow = .welcome } })
            case .welcome:
                WelcomeScreen(
                    onSignInComplete: { handleSignInComplete() }
                )
            case .profileSetup:
                PatientOnboardingView(onBack: { flow = .welcome }, onDone: { withAnimation { flow = .permissions } })
            case .permissions:
                HealthPermissionsView(onDone: { onboardingDone = true })
            }
        }
        .animation(.easeInOut, value: flow)
    }
}

// MARK: - Health Permissions Screen

import AVFoundation
import UserNotifications

struct HealthPermissionsView: View {
    let onDone: () -> Void

    @State private var healthKitGranted   = false
    @State private var notificationsGranted = false
    @State private var cameraGranted      = false
    @State private var micGranted         = false
    @State private var isRequestingHK     = false
    @State private var isRequestingNotif  = false
    @State private var isRequestingCamera = false

    var body: some View {
        ZStack {
            // Brand gradient background — readable in both light and dark mode
            LinearGradient(
                colors: [Color.brandPurple.opacity(0.15), Color.brandTeal.opacity(0.08), Color(.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 56))
                                .foregroundStyle(Color.brandPurple)
                            Text("Enable Health Features")
                                .font(.title2).fontWeight(.bold).foregroundColor(.primary)
                            Text("Grant permissions to unlock the full power of BodySense AI. You can change these later in Settings.")
                                .font(.subheadline).foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40).padding(.horizontal, 24)

                        // Permission cards
                        VStack(spacing: 14) {
                            // ── Apple Health ──
                            permissionCard(
                                icon: "heart.text.square.fill",
                                iconColor: .red,
                                title: "Apple Health",
                                description: "Sync glucose, blood pressure, heart rate, sleep, steps, weight, SpO2, HRV & 40+ health metrics",
                                isGranted: healthKitGranted,
                                isLoading: isRequestingHK
                            ) {
                                isRequestingHK = true
                                await HealthKitManager.shared.requestAuthorization()
                                healthKitGranted = HealthKitManager.shared.isAuthorized
                                isRequestingHK = false
                                // Enable HealthKit sync in profile
                                HealthStore.shared.userProfile.healthKitEnabled = true
                                HealthStore.shared.save()
                            }

                            // ── Notifications ──
                            permissionCard(
                                icon: "bell.badge.fill",
                                iconColor: .brandAmber,
                                title: "Notifications",
                                description: "Medication reminders, health alerts, appointment updates & AI insights",
                                isGranted: notificationsGranted,
                                isLoading: isRequestingNotif
                            ) {
                                isRequestingNotif = true
                                let center = UNUserNotificationCenter.current()
                                let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
                                notificationsGranted = granted
                                isRequestingNotif = false
                            }

                            // ── Camera & Microphone ──
                            permissionCard(
                                icon: "video.fill",
                                iconColor: .brandPurple,
                                title: "Camera & Microphone",
                                description: "Video consultations with doctors, food label scanning & voice logging",
                                isGranted: cameraGranted && micGranted,
                                isLoading: isRequestingCamera
                            ) {
                                isRequestingCamera = true
                                let camGranted = await AVCaptureDevice.requestAccess(for: .video)
                                let audioGranted = await AVCaptureDevice.requestAccess(for: .audio)
                                cameraGranted = camGranted
                                micGranted = audioGranted
                                isRequestingCamera = false
                            }
                        }
                        .padding(.horizontal, 20)

                        // Privacy note
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .font(.caption).foregroundColor(.brandGreen)
                            Text("Your data is encrypted with AES-256 and never shared without your consent.")
                                .font(.caption2).foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 24)
                    }
                }

                // Continue button
                Button {
                    onDone()
                } label: {
                    Text("Continue")
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.brandPurple)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // Skip option
                Button {
                    onDone()
                } label: {
                    Text("Skip for now")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .padding(.bottom, 24)
            }
        }
    }

    func permissionCard(
        icon: String, iconColor: Color,
        title: String, description: String,
        isGranted: Bool, isLoading: Bool,
        action: @escaping () async -> Void
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2).foregroundColor(iconColor)
                .frame(width: 44, height: 44)
                .background(iconColor.opacity(0.12))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline).fontWeight(.semibold).foregroundColor(.primary)
                Text(description).font(.caption2).foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3).foregroundColor(.brandGreen)
            } else if isLoading {
                ProgressView().tint(.brandPurple)
            } else {
                Button {
                    Task { await action() }
                } label: {
                    Text("Enable")
                        .font(.caption).fontWeight(.semibold)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Color.brandPurple.opacity(0.15))
                        .foregroundColor(.brandPurple)
                        .cornerRadius(8)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

// MARK: - Welcome Screen

struct WelcomeScreen: View {
    let onSignInComplete: () -> Void
    @State private var showPhoneSheet = false
    @State private var showEmailSheet = false
    @State private var authError: String?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {

                // ── Logo ──────────────────────────────────────────────────────
                VStack(spacing: 14) {
                    Image(systemName: "heart.text.clipboard.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.white)
                        .shadow(color: .white.opacity(0.3), radius: 20)
                        .padding(.top, 60)

                    Text("BodySense AI")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Text("Your intelligent health companion")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.80))

                    Link(destination: URL(string: "https://bodysenseai.co.uk")!) {
                        HStack(spacing: 5) {
                            Image(systemName: "globe").font(.caption)
                            Text("bodysenseai.co.uk").font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.65))
                        .padding(.horizontal, 14).padding(.vertical, 6)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(20)
                    }
                    .accessibilityLabel("Visit BodySense AI website")
                    .accessibilityHint("Opens bodysenseai.co.uk in your browser")
                }
                .padding(.bottom, 36)

                // ── Get Started label ────────────────────────────────────────
                Text("Get Started")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.white.opacity(0.70))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 10)

                // ── Sign in with Apple (primary) ──
                SignInWithAppleButton(
                    onSuccess: { onSignInComplete() }
                )
                .padding(.horizontal, 28)
                .padding(.bottom, 10)

                // ── Sign in with Google ──
                socialBtn(
                    icon: "g.circle.fill", label: "Continue with Google",
                    bg: .white, fg: Color(.darkGray), iconTint: .red
                ) {
                    Task {
                        do {
                            try await FirebaseAuthManager.shared.signInWithGoogle()
                            onSignInComplete()
                        } catch {
                            authError = error.localizedDescription
                        }
                    }
                }

                // ── Sign in with Phone ──
                socialBtn(
                    icon: "phone.fill", label: "Continue with Phone",
                    bg: Color.brandTeal, fg: .white, iconTint: .white
                ) {
                    showPhoneSheet = true
                }

                // ── Sign in with Email ──
                socialBtn(
                    icon: "envelope.fill", label: "Continue with Email",
                    bg: Color.white.opacity(0.15), fg: .white, iconTint: .white,
                    outlined: true
                ) {
                    showEmailSheet = true
                }

            }
        }
        .sheet(isPresented: $showPhoneSheet) {
            PhoneSignInSheet(onDone: onSignInComplete)
        }
        .sheet(isPresented: $showEmailSheet) {
            EmailSignInSheet(onDone: onSignInComplete)
        }
        .alert("Sign In Error", isPresented: .init(
            get: { authError != nil },
            set: { if !$0 { authError = nil } }
        )) {
            Button("OK") { authError = nil }
        } message: {
            Text(authError ?? "")
        }
    }

    @ViewBuilder
    private func socialBtn(icon: String, label: String,
                           bg: Color, fg: Color, iconTint: Color,
                           outlined: Bool = false,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconTint)
                    .frame(width: 28)
                Text(label).font(.headline).foregroundColor(fg)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(bg)
            .cornerRadius(14)
            .overlay(outlined
                     ? RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.35))
                     : nil)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 10)
    }
}

// MARK: - Phone Sign In Sheet

struct PhoneSignInSheet: View {
    let onDone: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var phoneNumber = ""
    @State private var otpCode = ""
    @State private var selectedCountry = CountryCode.uk
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var step: PhoneStep = .enterNumber

    enum PhoneStep { case enterNumber, enterOTP }

    struct CountryCode: Identifiable, Hashable {
        let id: String
        let name: String
        let dial: String
        let flag: String

        static let uk = CountryCode(id: "GB", name: "United Kingdom", dial: "+44", flag: "🇬🇧")
        static let india = CountryCode(id: "IN", name: "India", dial: "+91", flag: "🇮🇳")
        static let us = CountryCode(id: "US", name: "United States", dial: "+1", flag: "🇺🇸")

        static let all: [CountryCode] = [
            uk, india, us,
            CountryCode(id: "AE", name: "UAE", dial: "+971", flag: "🇦🇪"),
            CountryCode(id: "AU", name: "Australia", dial: "+61", flag: "🇦🇺"),
            CountryCode(id: "CA", name: "Canada", dial: "+1", flag: "🇨🇦"),
            CountryCode(id: "DE", name: "Germany", dial: "+49", flag: "🇩🇪"),
            CountryCode(id: "FR", name: "France", dial: "+33", flag: "🇫🇷"),
            CountryCode(id: "NG", name: "Nigeria", dial: "+234", flag: "🇳🇬"),
            CountryCode(id: "PK", name: "Pakistan", dial: "+92", flag: "🇵🇰"),
            CountryCode(id: "PH", name: "Philippines", dial: "+63", flag: "🇵🇭"),
            CountryCode(id: "SG", name: "Singapore", dial: "+65", flag: "🇸🇬"),
            CountryCode(id: "ZA", name: "South Africa", dial: "+27", flag: "🇿🇦"),
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if step == .enterNumber {
                    // Country picker + phone number
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Country").font(.subheadline).foregroundColor(.secondary)
                        Picker("Country", selection: $selectedCountry) {
                            ForEach(CountryCode.all) { country in
                                Text("\(country.flag) \(country.name) (\(country.dial))").tag(country)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone Number").font(.subheadline).foregroundColor(.secondary)
                        HStack {
                            Text(selectedCountry.dial)
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .frame(width: 60)
                            TextField("7700 900000", text: $phoneNumber)
                                .keyboardType(.phonePad)
                                .font(.title3)
                        }
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(14)
                    }

                    Button {
                        Task { await sendOTP() }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Send Verification Code")
                            }
                        }
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(phoneNumber.count >= 6 ? Color.brandPurple : Color.gray)
                        .cornerRadius(14)
                    }
                    .disabled(phoneNumber.count < 6 || isLoading)

                } else {
                    // OTP entry
                    VStack(spacing: 8) {
                        Text("Enter the 6-digit code sent to")
                            .font(.subheadline).foregroundColor(.secondary)
                        Text("\(selectedCountry.dial) \(phoneNumber)")
                            .font(.headline)
                    }

                    TextField("000000", text: $otpCode)
                        .keyboardType(.numberPad)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(14)

                    Button {
                        Task { await verifyOTP() }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Verify & Sign In")
                            }
                        }
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(otpCode.count == 6 ? Color.brandPurple : Color.gray)
                        .cornerRadius(14)
                    }
                    .disabled(otpCode.count != 6 || isLoading)

                    Button("Resend Code") {
                        Task { await sendOTP() }
                    }
                    .font(.subheadline).foregroundColor(.brandPurple)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption).foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("Phone Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func sendOTP() async {
        isLoading = true
        errorMessage = nil
        let fullNumber = selectedCountry.dial + phoneNumber.replacingOccurrences(of: " ", with: "")
        do {
            try await FirebaseAuthManager.shared.sendOTP(to: fullNumber)
            step = .enterOTP
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func verifyOTP() async {
        isLoading = true
        errorMessage = nil
        do {
            try await FirebaseAuthManager.shared.verifyOTP(otpCode)
            dismiss()
            onDone()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Email Sign In Sheet

struct EmailSignInSheet: View {
    let onDone: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignUp = false   // auto-flips to true when no account found
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showForgotPassword = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if isSignUp {
                    TextField("Full Name", text: $name)
                        .textContentType(.name)
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(14)
                }

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(14)

                SecureField("Password", text: $password)
                    .textContentType(isSignUp ? .newPassword : .password)
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(14)

                if !isSignUp {
                    Button("Forgot password?") {
                        showForgotPassword = true
                    }
                    .font(.caption).foregroundColor(.brandPurple)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }

                Button {
                    Task { await authenticate() }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Continue")
                        }
                    }
                    .font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(isFormValid ? Color.brandPurple : Color.gray)
                    .cornerRadius(14)
                }
                .disabled(!isFormValid || isLoading)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption).foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("Email Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Reset Password", isPresented: $showForgotPassword) {
                TextField("Email", text: $email)
                Button("Send Reset Link") {
                    Task {
                        try? await FirebaseAuthManager.shared.sendPasswordReset(to: email)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter your email address and we'll send you a password reset link.")
            }
        }
    }

    private var isFormValid: Bool {
        let emailOK = email.contains("@") && email.contains(".")
        let passOK = password.count >= 6
        if isSignUp {
            return emailOK && passOK && name.trimmingCharacters(in: .whitespaces).count >= 2
        }
        return emailOK && passOK
    }

    private func authenticate() async {
        isLoading = true
        errorMessage = nil
        do {
            if isSignUp {
                // Already in sign-up mode — create account
                try await FirebaseAuthManager.shared.signUpWithEmail(email, password: password, name: name)
                dismiss()
                onDone()
            } else {
                // Try sign-in first
                try await FirebaseAuthManager.shared.signInWithEmail(email, password: password)
                dismiss()
                onDone()
            }
        } catch let error as NSError {
            if error.code == 17011 /* userNotFound */ && !isSignUp {
                // No account found — switch to sign-up mode
                isSignUp = true
                errorMessage = "No account found. Enter your name to create one."
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }
}

// MARK: - Patient Onboarding

struct PatientOnboardingView: View {
    let onBack: () -> Void
    let onDone: () -> Void
    @Environment(HealthStore.self) var store

    @State private var page         = 0
    @State private var name         = ""
    @State private var email        = ""
    @State private var age          = 25
    @State private var gender       = "Female"
    @State private var condition    = "General Wellness"
    @State private var country      = "United Kingdom"
    @State private var city         = ""
    @State private var customCity   = ""
    @State private var postcode     = ""
    @State private var selectedGoals: [String] = []
    @State private var weightText   = "70"
    @State private var heightText   = "165"
    @State private var weightUnit   : WeightUnit = .kg
    @State private var heightUnit   : HeightUnit = .cm
    @State private var locationManager = CLLocationManager()
    @State private var isDetectingLocation = false

    var body: some View {
        VStack(spacing: 0) {
            // Back + Progress
            HStack {
                Button(action: { if page == 0 { onBack() } else { withAnimation { page -= 1 } } }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                .accessibilityLabel(page == 0 ? "Go back" : "Previous step")
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { i in
                        Capsule()
                            .fill(i <= page ? Color.white : Color.white.opacity(0.35))
                            .frame(width: i == page ? 24 : 8, height: 8)
                    }
                }
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 50)

            TabView(selection: $page) {
                // Page 0: About You
                onboardStep(icon: "person.crop.circle.fill", title: "About You") {
                    AnyView(VStack(spacing: 16) {
                        onboardField("Your full name", text: $name, icon: "person")
                        HStack {
                            Image(systemName: "envelope").foregroundColor(.white.opacity(0.7))
                            TextField("Email address", text: $email)
                                .foregroundColor(.white).tint(.white)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        .padding().background(Color.white.opacity(0.15)).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.3)))
                        Picker("Gender", selection: $gender) {
                            Text("Female").tag("Female")
                            Text("Male").tag("Male")
                            Text("Other").tag("Other")
                        }
                        .pickerStyle(.segmented)
                        Stepper("Age: \(age)", value: $age, in: 16...100)
                            .foregroundColor(.white)

                        // ── Weight ──
                        HStack {
                            Image(systemName: "scalemass").foregroundColor(.white.opacity(0.7))
                            TextField("Weight", text: $weightText)
                                .keyboardType(.decimalPad).foregroundColor(.white).tint(.white)
                            Picker("", selection: $weightUnit) {
                                ForEach(WeightUnit.allCases, id: \.self) { Text($0.label).tag($0) }
                            }.pickerStyle(.menu).tint(.white)
                        }
                        .padding().background(Color.white.opacity(0.15)).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.3)))

                        // ── Height ──
                        HStack {
                            Image(systemName: "ruler").foregroundColor(.white.opacity(0.7))
                            TextField("Height", text: $heightText)
                                .keyboardType(.decimalPad).foregroundColor(.white).tint(.white)
                            Picker("", selection: $heightUnit) {
                                ForEach(HeightUnit.allCases, id: \.self) { Text($0.label).tag($0) }
                            }.pickerStyle(.menu).tint(.white)
                        }
                        .padding().background(Color.white.opacity(0.15)).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.3)))
                    })
                } next: { withAnimation { page = 1 } }
                .tag(0)

                // Page 1: Health Goals (new)
                GoalPickerPage(
                    selectedGoals: $selectedGoals,
                    onNext: { withAnimation { page = 2 } }
                )
                .tag(1)

                // Page 2: Your Health (was page 1)
                onboardStep(icon: "heart.text.clipboard.fill", title: "Your Health") {
                    AnyView(VStack(spacing: 12) {
                        ForEach(["General Wellness","Type 2 Diabetes","Type 1 Diabetes",
                                 "Hypertension","Type 2 Diabetes & Hypertension"], id: \.self) { cond in
                            Button { condition = cond } label: {
                                HStack {
                                    Text(cond).foregroundColor(.white)
                                    Spacer()
                                    if condition == cond {
                                        Image(systemName: "checkmark.circle.fill").foregroundColor(.brandGreen)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(condition == cond ? 0.25 : 0.12))
                                .cornerRadius(12)
                            }
                        }
                    })
                } next: { withAnimation { page = 3 } }
                .tag(2)

                // Page 3: Location (was page 2)
                onboardStep(icon: "mappin.and.ellipse", title: "Your Location") {
                    AnyView(VStack(spacing: 16) {
                        // Auto-detect location button
                        Button {
                            detectLocation()
                        } label: {
                            HStack {
                                if isDetectingLocation {
                                    ProgressView().tint(.brandPurple)
                                } else {
                                    Image(systemName: "location.fill")
                                }
                                Text(isDetectingLocation ? "Detecting..." : "Use My Location")
                            }
                            .font(.headline).foregroundColor(.brandPurple)
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.white).cornerRadius(12)
                        }
                        .disabled(isDetectingLocation)

                        let cities = CurrencyService.countryCities[country] ?? []
                        HStack {
                            Image(systemName: "globe").foregroundColor(.white.opacity(0.7))
                            Picker("Country", selection: $country) {
                                ForEach(CurrencyService.supportedCountries, id: \.self) { c in
                                    Text(c).tag(c)
                                }
                            }.tint(.white)
                        }
                        .padding().background(Color.white.opacity(0.15)).cornerRadius(12)

                        if !cities.isEmpty {
                            HStack {
                                Image(systemName: "building.2").foregroundColor(.white.opacity(0.7))
                                Picker("City", selection: $city) {
                                    Text("Select city").tag("")
                                    ForEach(cities, id: \.self) { c in Text(c).tag(c) }
                                }.tint(.white)
                            }
                            .padding().background(Color.white.opacity(0.15)).cornerRadius(12)
                        }

                        onboardField("Postcode (e.g. SW1A 1AA)", text: $postcode, icon: "location")
                    })
                } next: { withAnimation { page = 4 } }
                .tag(3)

                // Page 4: Done (was page 3)
                VStack(spacing: 28) {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80)).foregroundColor(.brandGreen).shadow(radius: 10)
                    Text("All Set!").font(.largeTitle.bold()).foregroundColor(.white)
                    Text("Your BodySense AI journey starts now.\nTrack your health, consult doctors, and thrive.")
                        .font(.body).multilineTextAlignment(.center).foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 32)
                    Spacer()
                    nextBtn("Start Tracking") { completePatientOnboarding() }
                }
                .padding()
                .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    func onboardStep(icon: String, title: String, @ViewBuilder content: () -> AnyView, next: @escaping () -> Void) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: icon).font(.system(size: 60)).foregroundColor(.white).shadow(radius: 10)
            Text(title).font(.title.bold()).foregroundColor(.white)
            content().padding(.horizontal, 28)
            Spacer()
            nextBtn("Continue", action: next)
        }.padding()
    }

    func nextBtn(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.headline).frame(maxWidth: .infinity).padding()
                .background(Color.white).foregroundColor(.brandPurple)
                .cornerRadius(16).shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
        .padding(.horizontal, 28).padding(.bottom, 40)
    }

    func onboardField(_ placeholder: String, text: Binding<String>, icon: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(.white.opacity(0.7))
            TextField(placeholder, text: text).foregroundColor(.white).tint(.white)
        }
        .padding().background(Color.white.opacity(0.15)).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.3)))
    }

    func detectLocation() {
        isDetectingLocation = true
        locationManager.requestWhenInUseAuthorization()

        if let location = locationManager.location {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                isDetectingLocation = false
                if let placemark = placemarks?.first {
                    if let detectedCountry = placemark.country {
                        let mapped = CurrencyService.supportedCountries.first {
                            detectedCountry.contains($0) || $0.contains(detectedCountry)
                        }
                        if let mapped { country = mapped }
                    }
                    if let detectedCity = placemark.locality {
                        city = detectedCity
                        customCity = detectedCity
                    }
                    if let detectedPostcode = placemark.postalCode {
                        postcode = detectedPostcode
                    }
                }
            }
        } else {
            isDetectingLocation = false
        }
    }

    func completePatientOnboarding() {
        var profile = store.userProfile
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.name          = InputValidator.isValidName(cleanedName) ? cleanedName : "Friend"
        profile.email         = email.lowercased().trimmingCharacters(in: .whitespaces)
        profile.age           = age
        profile.gender        = gender
        profile.diabetesType  = condition
        profile.country       = country
        profile.city          = (city == "__other__" || city.isEmpty) ? customCity : city
        profile.postcode      = postcode.uppercased()
        profile.currencyCode  = CurrencyService.currency(for: country)
        profile.isDoctor      = false
        profile.selectedGoals = selectedGoals
        profile.weightUnit    = weightUnit
        profile.heightUnit    = heightUnit
        // Convert entered value to internal kg/cm
        if let w = Double(weightText) { profile.weight = weightUnit.toKg(w) }
        if let h = Double(heightText) { profile.height = heightUnit.toCm(h) }
        store.userProfile = profile
        store.ensureAnonymousAlias()
        store.save()
        onDone()
    }
}

// MARK: - Doctor Registration (GMC Credentials)

struct DoctorRegistrationView: View {
    let onBack: () -> Void
    let onDone: () -> Void
    @Environment(HealthStore.self) var store

    @State private var page         = 0
    // Personal
    @State private var fullName     = ""
    @State private var email        = ""
    @State private var phoneNumber  = ""
    @State private var phoneCountryCode = "+44"
    @State private var phoneOTPCode = ""
    @State private var isPhoneVerified = false
    @State private var isEmailVerified = false
    @State private var isSendingOTP = false
    @State private var isVerifyingOTP = false
    @State private var verificationError: String?
    @State private var age          = 30
    @State private var gender       = "Male"
    @State private var country      = "United Kingdom"
    @State private var city         = ""
    @State private var postcode     = ""
    // Professional
    @State private var specialty    = "General Practice"
    @State private var hospital     = ""
    @State private var pmqDegree    = ""
    @State private var pmqCountry   = "United Kingdom"
    @State private var pmqYear      = 2010
    // GMC
    @State private var gmcNumber    = ""
    @State private var gmcStatus    = "Full"
    @State private var gmcDate      = ""
    @State private var hasCGOS      = false
    @State private var plabPassed   = false
    // International
    @State private var ecfmgNumber  = ""
    @State private var ecfmgCerted  = false
    @State private var wdomListed   = false
    @State private var regulatoryBody = "GMC"
    // Fees
    @State private var videoFee     = "50"
    @State private var phoneFee     = "35"
    @State private var inPersonFee  = "75"
    // Bio
    @State private var intro        = ""
    // Document Upload
    @State private var photoIDImage: UIImage?
    @State private var dbsCertImage: UIImage?
    @State private var insuranceImage: UIImage?
    @State private var qualificationImage: UIImage?
    @State private var showDocPicker: DocumentType?
    @State private var isUploading = false
    @State private var uploadProgress: [DocumentType: Bool] = [:]
    // GMC Live Verification
    @State private var isVerifyingGMC = false
    @State private var gmcVerificationResult: GMCVerificationResult?

    enum GMCVerificationResult {
        case verified(name: String)
        case notFound
        case error(String)
    }

    enum DocumentType: String, CaseIterable, Identifiable {
        case photoId = "Photo ID"
        case dbsCertificate = "DBS Certificate"
        case indemnityInsurance = "Indemnity Insurance"
        case qualification = "Qualification Certificate"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .photoId: return "person.text.rectangle.fill"
            case .dbsCertificate: return "checkmark.shield.fill"
            case .indemnityInsurance: return "doc.text.fill"
            case .qualification: return "graduationcap.fill"
            }
        }
        var apiKey: String {
            switch self {
            case .photoId: return "photoId"
            case .dbsCertificate: return "dbsCertificate"
            case .indemnityInsurance: return "indemnityInsurance"
            case .qualification: return "qualificationCertificate"
            }
        }
    }

    let specialties = ["General Practice","Cardiologist","Diabetologist","Endocrinologist",
                       "Nephrologist","Nutritionist","Psychiatrist","Neurologist",
                       "Oncologist","Dermatologist","Orthopaedic Surgeon","Paediatrician",
                       "Gynaecologist","Urologist","Ophthalmologist","ENT Specialist"]
    let gmcStatuses = ["Full","Provisional","Specialist Register","GP Register"]
    let regulatoryBodies = ["GMC","ECFMG","EPIC","AHPRA","MCC","IMC","HPCSA"]

    private let pageLabels = ["Personal", "Professional", "GMC", "International", "Fees", "Documents", "Done"]

    var body: some View {
        ZStack {
            // ── Clean white/light background instead of gradient ──
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Compact header ──
                VStack(spacing: 8) {
                    HStack(spacing: 14) {
                        Button(action: { if page == 0 { onBack() } else { withAnimation { page -= 1 } } }) {
                            Image(systemName: "chevron.left")
                                .font(.body.bold()).foregroundColor(.primary)
                        }
                        VStack(spacing: 2) {
                            Text(page < 6 ? pageLabels[page] : "Done")
                                .font(.headline)
                            Text("Step \(min(page + 1, 6)) of 6")
                                .font(.caption2).foregroundColor(.secondary)
                        }
                        Spacer()
                        // Step indicator dots
                        HStack(spacing: 5) {
                            ForEach(0..<6, id: \.self) { i in
                                Circle()
                                    .fill(i < page ? Color.brandTeal : i == page ? Color.brandPurple : Color(.systemGray4))
                                    .frame(width: i == page ? 10 : 7, height: i == page ? 10 : 7)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Progress bar
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(.systemGray5)).frame(height: 3)
                            Capsule().fill(Color.brandTeal)
                                .frame(width: g.size.width * (Double(min(page, 5) + 1) / 6.0), height: 3)
                        }
                    }
                    .frame(height: 3)
                    .padding(.horizontal, 20)
                }
                .padding(.top, 8).padding(.bottom, 4)
                .background(Color(.systemBackground))

                // ── Form pages (no TabView — prevents swipe-to-skip) ──
                Group {
                    switch page {
                    // ── Page 0: Personal Info ──
                    case 0:
                        ScrollView {
                            VStack(spacing: 14) {
                                docRegSection("Personal Information") {
                                    docRegField("Full Name", prompt: "Dr. Jane Smith", text: $fullName, icon: "person.fill")

                                    // ── Email: Pre-filled from Firebase Auth, verified badge ──
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            docRegField("Email", prompt: "doctor@example.com", text: $email, icon: "envelope.fill")
                                                .textInputAutocapitalization(.never)
                                                .keyboardType(.emailAddress)
                                                .disabled(isEmailVerified)
                                            if isEmailVerified {
                                                Image(systemName: "checkmark.seal.fill")
                                                    .foregroundColor(.brandGreen)
                                                    .font(.title3)
                                            }
                                        }
                                        if isEmailVerified {
                                            Text("Verified via sign-in")
                                                .font(.caption).foregroundColor(.brandGreen)
                                        } else if !email.isEmpty && !InputValidator.isValidEmail(email) {
                                            Text("Enter a valid email address")
                                                .font(.caption).foregroundColor(.red).padding(.leading, 4)
                                        }
                                    }

                                    // ── Phone: With OTP verification ──
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 8) {
                                            // Country code picker
                                            Picker("", selection: $phoneCountryCode) {
                                                Text("+44 UK").tag("+44")
                                                Text("+91 IN").tag("+91")
                                                Text("+1 US").tag("+1")
                                                Text("+971 AE").tag("+971")
                                                Text("+61 AU").tag("+61")
                                                Text("+49 DE").tag("+49")
                                                Text("+33 FR").tag("+33")
                                                Text("+81 JP").tag("+81")
                                                Text("+86 CN").tag("+86")
                                                Text("+234 NG").tag("+234")
                                                Text("+27 ZA").tag("+27")
                                                Text("+55 BR").tag("+55")
                                                Text("+82 KR").tag("+82")
                                            }
                                            .frame(width: 100)
                                            .disabled(isPhoneVerified)

                                            TextField("Phone number", text: $phoneNumber)
                                                .keyboardType(.phonePad)
                                                .padding(10)
                                                .background(Color(.tertiarySystemBackground))
                                                .cornerRadius(10)
                                                .disabled(isPhoneVerified)

                                            if isPhoneVerified {
                                                Image(systemName: "checkmark.seal.fill")
                                                    .foregroundColor(.brandGreen)
                                                    .font(.title3)
                                            }
                                        }

                                        if isPhoneVerified {
                                            Text("Phone verified")
                                                .font(.caption).foregroundColor(.brandGreen)
                                        } else if !phoneNumber.isEmpty && phoneNumber.count >= 7 {
                                            if FirebaseAuthManager.shared.isAwaitingOTP {
                                                // OTP entry
                                                HStack(spacing: 8) {
                                                    TextField("Enter 6-digit code", text: $phoneOTPCode)
                                                        .keyboardType(.numberPad)
                                                        .padding(10)
                                                        .background(Color(.tertiarySystemBackground))
                                                        .cornerRadius(10)
                                                        .frame(maxWidth: 180)

                                                    Button {
                                                        Task { await verifyDoctorPhoneOTP() }
                                                    } label: {
                                                        if isVerifyingOTP {
                                                            ProgressView().tint(.white)
                                                        } else {
                                                            Text("Verify")
                                                        }
                                                    }
                                                    .font(.subheadline.bold())
                                                    .padding(.horizontal, 16).padding(.vertical, 10)
                                                    .background(phoneOTPCode.count == 6 ? Color.brandTeal : Color(.systemGray4))
                                                    .foregroundColor(.white)
                                                    .cornerRadius(10)
                                                    .disabled(phoneOTPCode.count != 6 || isVerifyingOTP)
                                                }
                                            } else {
                                                // Send OTP button
                                                Button {
                                                    Task { await sendDoctorPhoneOTP() }
                                                } label: {
                                                    HStack(spacing: 6) {
                                                        if isSendingOTP {
                                                            ProgressView().tint(.brandTeal)
                                                        }
                                                        Text(isSendingOTP ? "Sending..." : "Verify Phone Number")
                                                            .font(.caption.bold())
                                                    }
                                                    .padding(.vertical, 8).padding(.horizontal, 16)
                                                    .background(Color.brandTeal.opacity(0.12))
                                                    .foregroundColor(.brandTeal)
                                                    .cornerRadius(10)
                                                }
                                                .disabled(isSendingOTP)
                                            }
                                        }

                                        if let error = verificationError {
                                            Text(error)
                                                .font(.caption).foregroundColor(.red)
                                        }
                                    }

                                    HStack {
                                        Label("Age", systemImage: "calendar").font(.subheadline).foregroundColor(.secondary)
                                        Spacer()
                                        Stepper("\(age)", value: $age, in: 25...80).frame(width: 140)
                                    }
                                    .padding(.horizontal, 4)
                                    Picker("Gender", selection: $gender) {
                                        Text("Male").tag("Male"); Text("Female").tag("Female")
                                    }.pickerStyle(.segmented)
                                }

                                docRegSection("Location") {
                                    docRegField("City", prompt: "London", text: $city, icon: "building.2.fill")
                                    HStack(spacing: 10) {
                                        docRegField("Country", prompt: "UK", text: $country, icon: "globe")
                                        docRegField("Postcode", prompt: "SW1A 1AA", text: $postcode, icon: "location.fill")
                                            .frame(maxWidth: 130)
                                    }
                                }

                                // Validation message
                                if !canProceedPage0 {
                                    Label("Name, verified email, and verified phone required", systemImage: "exclamationmark.circle")
                                        .font(.caption).foregroundColor(.brandAmber)
                                }

                                docRegCTA("Continue") { withAnimation(.easeInOut(duration: 0.25)) { page = 1 } }
                                    .disabled(!canProceedPage0)
                                    .opacity(!canProceedPage0 ? 0.4 : 1)
                            }
                            .padding(16).padding(.bottom, 24)
                        }
                        .onAppear { prefillFromFirebaseAuth() }

                    // ── Page 1: Professional Details ──
                    case 1:
                        ScrollView {
                            VStack(spacing: 14) {
                                docRegSection("Specialty") {
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                        ForEach(specialties, id: \.self) { spec in
                                            Button { specialty = spec } label: {
                                                Text(spec).font(.caption).fontWeight(.medium)
                                                    .lineLimit(1).minimumScaleFactor(0.8)
                                                    .padding(.vertical, 10).frame(maxWidth: .infinity)
                                                    .background(specialty == spec ? Color.brandTeal.opacity(0.12) : Color(.systemGray6))
                                                    .foregroundColor(specialty == spec ? .brandTeal : .primary)
                                                    .cornerRadius(10)
                                                    .overlay(RoundedRectangle(cornerRadius: 10)
                                                        .stroke(specialty == spec ? Color.brandTeal : Color.clear, lineWidth: 1.5))
                                            }
                                        }
                                    }
                                }

                                docRegSection("Practice & Qualification") {
                                    docRegField("Hospital / Clinic", prompt: "St Mary's Hospital", text: $hospital, icon: "building.columns.fill")
                                    docRegField("Degree (PMQ)", prompt: "MBBS, MBBCh, MD", text: $pmqDegree, icon: "graduationcap.fill")
                                    docRegField("Country of Award", prompt: "United Kingdom", text: $pmqCountry, icon: "globe")
                                    HStack {
                                        Label("Year", systemImage: "calendar").font(.subheadline).foregroundColor(.secondary)
                                        Spacer()
                                        Stepper("\(pmqYear)", value: $pmqYear, in: 1970...2024).frame(width: 140)
                                    }.padding(.horizontal, 4)
                                }

                                docRegCTA("Continue") { withAnimation(.easeInOut(duration: 0.25)) { page = 2 } }
                                    .disabled(specialty.isEmpty)
                                    .opacity(specialty.isEmpty ? 0.4 : 1)
                            }
                            .padding(16).padding(.bottom, 24)
                        }

                    // ── Page 2: GMC Registration ──
                    case 2:
                        ScrollView {
                            VStack(spacing: 14) {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.shield.fill").foregroundColor(.brandTeal)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Verified against GMC Medical Register").font(.caption).fontWeight(.medium)
                                        Link("View GMC Register", destination: URL(string: "https://www.gmc-uk.org/registration-and-licensing/the-medical-register")!)
                                            .font(.caption2)
                                    }
                                    Spacer()
                                }
                                .padding(12).background(Color.brandTeal.opacity(0.06)).cornerRadius(12)

                                docRegSection("GMC Details") {
                                    docRegField("GMC Reference Number", prompt: "1234567", text: $gmcNumber, icon: "number")
                                        .keyboardType(.numberPad)
                                    if !gmcNumber.isEmpty && !InputValidator.isValidGMC(gmcNumber) {
                                        Text("GMC must be exactly 7 digits, cannot start with 0")
                                            .font(.caption).foregroundColor(.red).padding(.leading, 4)
                                    }

                                    // ── GMC Live Verification Button ──
                                    Button {
                                        Task { await verifyGMCLive() }
                                    } label: {
                                        HStack(spacing: 8) {
                                            if isVerifyingGMC {
                                                ProgressView().tint(.white)
                                            } else {
                                                Image(systemName: "checkmark.shield.fill")
                                            }
                                            Text(isVerifyingGMC ? "Verifying..." : "Verify with GMC")
                                                .fontWeight(.semibold)
                                        }
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(InputValidator.isValidGMC(gmcNumber) && !isVerifyingGMC ? Color.brandTeal : Color(.systemGray4))
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                    }
                                    .disabled(!InputValidator.isValidGMC(gmcNumber) || isVerifyingGMC)

                                    // ── GMC Verification Result ──
                                    if let result = gmcVerificationResult {
                                        HStack(spacing: 8) {
                                            switch result {
                                            case .verified(let name):
                                                Image(systemName: "checkmark.circle.fill").foregroundColor(.brandGreen)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("Verified").font(.caption).fontWeight(.semibold).foregroundColor(.brandGreen)
                                                    Text(name).font(.caption2).foregroundColor(.secondary)
                                                }
                                            case .notFound:
                                                Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                                                Text("GMC number not found on the register").font(.caption).foregroundColor(.red)
                                            case .error(let msg):
                                                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                                                Text(msg).font(.caption).foregroundColor(.orange)
                                            }
                                            Spacer()
                                        }
                                        .padding(10)
                                        .background({
                                            switch result {
                                            case .verified: return Color.brandGreen.opacity(0.08)
                                            case .notFound: return Color.red.opacity(0.08)
                                            case .error: return Color.orange.opacity(0.08)
                                            }
                                        }())
                                        .cornerRadius(10)
                                    }

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Registration Status").font(.caption).foregroundColor(.secondary)
                                        Picker("Status", selection: $gmcStatus) {
                                            ForEach(gmcStatuses, id: \.self) { Text($0).tag($0) }
                                        }.pickerStyle(.segmented)
                                    }
                                    docRegField("First Registration", prompt: "DD/MM/YYYY", text: $gmcDate, icon: "calendar")
                                }

                                docRegSection("Certifications") {
                                    docRegToggle("Certificate of Good Standing", isOn: $hasCGOS)
                                    Divider()
                                    docRegToggle("PLAB / UKMLA Passed", isOn: $plabPassed)
                                }

                                docRegCTA("Continue") { withAnimation(.easeInOut(duration: 0.25)) { page = 3 } }
                                    .disabled(!InputValidator.isValidGMC(gmcNumber))
                                    .opacity(!InputValidator.isValidGMC(gmcNumber) ? 0.4 : 1)
                            }
                            .padding(16).padding(.bottom, 24)
                        }

                    // ── Page 3: International Credentials (optional — can skip) ──
                    case 3:
                        ScrollView {
                            VStack(spacing: 14) {
                                HStack(spacing: 10) {
                                    Image(systemName: "globe.europe.africa.fill").foregroundColor(.brandPurple)
                                    Text("For doctors qualified outside the UK — skip if not applicable").font(.caption).foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(12).background(Color.brandPurple.opacity(0.05)).cornerRadius(12)

                                docRegSection("Regulatory Body") {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(regulatoryBodies, id: \.self) { rb in
                                                Button { regulatoryBody = rb } label: {
                                                    Text(rb).font(.caption).fontWeight(.semibold)
                                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                                        .background(regulatoryBody == rb ? Color.brandTeal : Color(.systemGray6))
                                                        .foregroundColor(regulatoryBody == rb ? .white : .primary)
                                                        .cornerRadius(20)
                                                }
                                            }
                                        }
                                    }
                                    docRegField("ECFMG Number", prompt: "If applicable", text: $ecfmgNumber, icon: "doc.badge.checkmark")
                                }

                                docRegSection("Credentials") {
                                    docRegToggle("ECFMG Certified", isOn: $ecfmgCerted)
                                    Divider()
                                    docRegToggle("WDOM Listed", isOn: $wdomListed)
                                }

                                docRegCTA("Continue") { withAnimation(.easeInOut(duration: 0.25)) { page = 4 } }
                            }
                            .padding(16).padding(.bottom, 24)
                        }

                    // ── Page 4: Fees & Introduction ──
                    case 4:
                        ScrollView {
                            VStack(spacing: 14) {
                                docRegSection("Consultation Fees") {
                                    docRegFee("Video Call", fee: $videoFee, icon: "video.fill", color: .brandTeal)
                                    Divider()
                                    docRegFee("Phone Call", fee: $phoneFee, icon: "phone.fill", color: .brandPurple)
                                    Divider()
                                    docRegFee("In Person", fee: $inPersonFee, icon: "person.fill", color: .brandAmber)
                                }

                                docRegSection("Introduction") {
                                    Text("Shown to patients when browsing doctors")
                                        .font(.caption).foregroundColor(.secondary)
                                    TextEditor(text: $intro)
                                        .frame(height: 100)
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray4), lineWidth: 0.5))
                                }

                                docRegCTA("Continue") { withAnimation(.easeInOut(duration: 0.25)) { page = 5 } }
                            }
                            .padding(16).padding(.bottom, 24)
                        }

                    // ── Page 5: Document Upload ──
                    case 5:
                        ScrollView {
                            VStack(spacing: 14) {
                                docRegSection("Identity & Credentials") {
                                    Text("Upload documents to verify your identity and qualifications. Photos of original documents are accepted.")
                                        .font(.caption).foregroundColor(.secondary)
                                        .padding(.bottom, 4)

                                    ForEach(DocumentType.allCases) { docType in
                                        docUploadRow(docType)
                                    }
                                }

                                // Upload status
                                if isUploading {
                                    HStack(spacing: 10) {
                                        ProgressView()
                                        Text("Uploading documents...").font(.caption).foregroundColor(.secondary)
                                    }
                                    .padding()
                                }

                                VStack(spacing: 8) {
                                    docRegCTA("Submit for Verification") { completeDocReg() }
                                        .disabled(isUploading)

                                    Button("Skip — upload later") {
                                        completeDocReg()
                                    }
                                    .font(.caption).foregroundColor(.secondary)
                                    .disabled(isUploading)
                                }
                            }
                            .padding(16).padding(.bottom, 24)
                        }
                        .sheet(item: $showDocPicker) { docType in
                            DocumentImagePicker(docType: docType) { image in
                                setDocImage(docType, image: image)
                            }
                        }

                    // ── Page 6: Submitted confirmation ──
                    default:
                        VStack(spacing: 24) {
                            Spacer()
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 72)).foregroundColor(.brandTeal)
                            Text("Registration Submitted").font(.title.bold())
                            VStack(spacing: 8) {
                                Text("Welcome, Dr. \(fullName.split(separator: " ").last.map(String.init) ?? fullName)")
                                    .font(.headline)
                                Text("Your credentials are now under review.")
                                    .font(.body).foregroundColor(.secondary)
                                Text("Once verified, your profile goes live and patients can book consultations.")
                                    .font(.subheadline).foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                HStack(spacing: 6) {
                                    Image(systemName: "clock.fill").foregroundColor(.brandAmber)
                                    Text("Typical review: 24–48 hours").font(.caption).foregroundColor(.secondary)
                                }.padding(.top, 4)
                            }.padding(.horizontal, 32)
                            Spacer()
                            docRegCTA("Continue to App") { onDone() }
                                .padding(.horizontal, 16).padding(.bottom, 32)
                        }
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
    }

    // ── Reusable components ──

    func docRegSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.subheadline).fontWeight(.semibold).foregroundColor(.secondary)
                .padding(.leading, 4)
            VStack(spacing: 14) { content() }
                .padding(14)
                .background(Color(.systemBackground))
                .cornerRadius(14)
        }
    }

    func docRegField(_ label: String, prompt: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(.brandTeal).font(.subheadline).frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.caption2).foregroundColor(.secondary)
                TextField(prompt, text: text).font(.body)
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    func docRegToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label).font(.subheadline)
        }
        .tint(.brandTeal)
    }

    func docRegFee(_ label: String, fee: Binding<String>, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(color).frame(width: 18)
            Text(label).font(.subheadline)
            Spacer()
            HStack(spacing: 2) {
                Text("£").font(.subheadline).foregroundColor(.secondary)
                TextField("50", text: fee).keyboardType(.numberPad)
                    .font(.body.bold())
                    .multilineTextAlignment(.trailing).frame(width: 50)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color(.systemGray6)).cornerRadius(8)
        }
    }

    func docRegCTA(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(Color.brandTeal)
                .foregroundColor(.white)
                .cornerRadius(14)
        }
        .padding(.top, 4)
    }

    // ── GMC Live Verification via Backend ──
    func verifyGMCLive() async {
        guard InputValidator.isValidGMC(gmcNumber) else { return }
        isVerifyingGMC = true
        gmcVerificationResult = nil
        defer { isVerifyingGMC = false }

        do {
            guard let url = URL(string: "https://body-sense-ai-production.up.railway.app/verify-gmc") else {
                gmcVerificationResult = .error("Invalid server URL")
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 15

            let body: [String: String] = ["gmcNumber": gmcNumber]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                gmcVerificationResult = .error("Unexpected server response")
                return
            }

            if httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let verified = json["verified"] as? Bool {
                    if verified {
                        let name = json["doctorName"] as? String ?? "Registered Doctor"
                        gmcVerificationResult = .verified(name: name)
                    } else {
                        gmcVerificationResult = .notFound
                    }
                } else {
                    gmcVerificationResult = .error("Could not parse verification response")
                }
            } else if httpResponse.statusCode == 404 {
                gmcVerificationResult = .notFound
            } else {
                gmcVerificationResult = .error("Server error (\(httpResponse.statusCode)). Try again later.")
            }
        } catch let error as URLError where error.code == .timedOut {
            gmcVerificationResult = .error("Request timed out. Check your connection.")
        } catch {
            gmcVerificationResult = .error("Network error. Check your connection.")
        }
    }

    func completeDocReg() {
        guard InputValidator.isValidEmail(email) else { return }
        guard InputValidator.isValidName(fullName) else { return }
        guard !specialty.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard !hospital.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard InputValidator.isValidGMC(gmcNumber) else { return }

        let cleanName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        var profile = store.userProfile
        if !cleanName.isEmpty { profile.name = cleanName }
        if !cleanEmail.isEmpty { profile.email = cleanEmail }
        profile.age         = age
        profile.gender      = gender
        profile.country     = country
        profile.city        = city
        profile.postcode    = postcode.uppercased()
        profile.currencyCode = CurrencyService.currency(for: country)
        profile.isDoctor    = true

        var dp = DoctorProfile()
        dp.specialty            = specialty
        dp.hospital             = hospital
        dp.pmqDegree            = pmqDegree
        dp.pmqCountry           = pmqCountry
        dp.pmqYear              = pmqYear
        dp.gmcNumber            = gmcNumber
        dp.gmcRegistrationStatus = gmcStatus
        dp.gmcRegistrationDate  = gmcDate
        dp.certificateOfGoodStanding = hasCGOS
        dp.plabPassed           = plabPassed
        dp.ecfmgNumber          = ecfmgNumber
        dp.ecfmgCertified       = ecfmgCerted
        dp.wdomListed           = wdomListed
        dp.regulatoryBody       = regulatoryBody
        dp.videoConsultationFee = Double(videoFee) ?? 50
        dp.phoneConsultationFee = Double(phoneFee) ?? 35
        dp.inPersonFee          = Double(inPersonFee) ?? 75
        dp.consultationFeeGBP   = Double(videoFee) ?? 50
        dp.introduction         = intro
        dp.verificationStatus   = .underReview
        dp.postcode             = postcode.uppercased()
        dp.country              = country
        dp.timeZoneIdentifier   = TimeZone.current.identifier
        dp.verifiedEmail        = cleanEmail
        dp.verifiedPhone        = isPhoneVerified ? (phoneCountryCode + phoneNumber) : ""

        profile.doctorProfile = dp
        store.userProfile = profile
        store.ensureAnonymousAlias()

        // Submit registration request for CEO approval
        let request = DoctorRegistrationRequest(
            userId: AuthService.shared.userIdentifier ?? "",
            name: cleanName.isEmpty ? "Doctor" : cleanName,
            email: cleanEmail,
            specialty: specialty,
            hospital: hospital,
            city: city,
            country: country,
            postcode: postcode.uppercased(),
            gmcNumber: gmcNumber,
            gmcStatus: gmcStatus,
            regulatoryBody: regulatoryBody,
            pmqDegree: pmqDegree,
            pmqCountry: pmqCountry,
            pmqYear: pmqYear,
            plabPassed: plabPassed,
            ecfmgCertified: ecfmgCerted,
            wdomListed: wdomListed,
            goodStanding: hasCGOS,
            videoFee: Double(videoFee) ?? 50,
            phoneFee: Double(phoneFee) ?? 35,
            inPersonFee: Double(inPersonFee) ?? 75,
            introduction: intro
        )
        store.submitDoctorRequest(request)

        // Upload any selected documents in background
        Task {
            await uploadDocuments()
        }

        // Navigate to confirmation page
        withAnimation { page = 6 }
    }

    // MARK: - Auth Verification Helpers

    /// Whether Page 0 can proceed — requires valid name, verified email, and verified phone
    private var canProceedPage0: Bool {
        InputValidator.isValidName(fullName)
        && InputValidator.isValidEmail(email)
        && isEmailVerified
        && isPhoneVerified
    }

    /// Pre-fill name, email, and phone from Firebase Auth (already verified via sign-in)
    private func prefillFromFirebaseAuth() {
        let auth = FirebaseAuthManager.shared
        // Email — verified if user signed in via email, Google, or Apple
        if let authEmail = auth.email, !authEmail.isEmpty {
            email = authEmail
            isEmailVerified = true
        }
        // Name from Firebase
        if let authName = auth.displayName, !authName.isEmpty, fullName.isEmpty {
            fullName = authName
        }
        // Phone — verified if user signed in via phone OTP
        if let authPhone = auth.phoneNumber, !authPhone.isEmpty {
            // Strip country code for display
            phoneNumber = authPhone
            isPhoneVerified = true
        }
    }

    /// Send OTP to the doctor's phone number via Firebase Auth
    private func sendDoctorPhoneOTP() async {
        let fullNumber = phoneCountryCode + phoneNumber.trimmingCharacters(in: .whitespaces)
        guard fullNumber.count >= 10 else {
            verificationError = "Enter a valid phone number"
            return
        }
        isSendingOTP = true
        verificationError = nil
        do {
            try await FirebaseAuthManager.shared.sendOTP(to: fullNumber)
        } catch {
            verificationError = error.localizedDescription
        }
        isSendingOTP = false
    }

    /// Verify the OTP code for doctor phone verification
    /// NOTE: This links the phone to the existing Firebase account, not a new sign-in
    private func verifyDoctorPhoneOTP() async {
        guard phoneOTPCode.count == 6 else { return }
        isVerifyingOTP = true
        verificationError = nil
        do {
            // Link phone credential to existing account (not sign in as new user)
            guard let verificationID = FirebaseAuthManager.shared.phoneVerificationID else {
                verificationError = "Verification expired. Please request a new code."
                isVerifyingOTP = false
                return
            }
            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: verificationID,
                verificationCode: phoneOTPCode
            )
            // Link to current user (adds phone to existing account)
            if let currentUser = FirebaseAuthManager.shared.firebaseUser {
                try await currentUser.link(with: credential)
            } else {
                // Fallback: sign in if no current user
                try await FirebaseAuthManager.shared.verifyOTP(phoneOTPCode)
            }
            isPhoneVerified = true
            FirebaseAuthManager.shared.isAwaitingOTP = false
            FirebaseAuthManager.shared.phoneVerificationID = nil
        } catch {
            verificationError = error.localizedDescription
        }
        isVerifyingOTP = false
    }

    // MARK: - Document Upload Helpers

    private func docUploadRow(_ docType: DocumentType) -> some View {
        HStack(spacing: 12) {
            Image(systemName: docType.icon)
                .font(.title3).foregroundColor(.brandTeal)
                .frame(width: 36, height: 36)
                .background(Color.brandTeal.opacity(0.12))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(docType.rawValue).font(.subheadline).fontWeight(.medium)
                if imageFor(docType) != nil {
                    Text("Selected").font(.caption).foregroundColor(.brandGreen)
                } else {
                    Text("Tap to upload").font(.caption).foregroundColor(.secondary)
                }
            }

            Spacer()

            if uploadProgress[docType] == true {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.brandGreen)
            } else if imageFor(docType) != nil {
                Image(systemName: "photo.fill")
                    .foregroundColor(.brandTeal)
            } else {
                Image(systemName: "plus.circle")
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture { showDocPicker = docType }
    }

    private func imageFor(_ docType: DocumentType) -> UIImage? {
        switch docType {
        case .photoId: return photoIDImage
        case .dbsCertificate: return dbsCertImage
        case .indemnityInsurance: return insuranceImage
        case .qualification: return qualificationImage
        }
    }

    private func setDocImage(_ docType: DocumentType, image: UIImage) {
        switch docType {
        case .photoId: photoIDImage = image
        case .dbsCertificate: dbsCertImage = image
        case .indemnityInsurance: insuranceImage = image
        case .qualification: qualificationImage = image
        }
    }

    private func uploadDocuments() async {
        let baseURL = "https://body-sense-ai-production.up.railway.app"
        let userId = AuthService.shared.userIdentifier ?? UUID().uuidString

        for docType in DocumentType.allCases {
            guard let image = imageFor(docType),
                  let data = image.jpegData(compressionQuality: 0.7) else { continue }

            isUploading = true

            var request = URLRequest(url: URL(string: "\(baseURL)/upload-doctor-document")!)
            request.httpMethod = "POST"

            let boundary = UUID().uuidString
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            var body = Data()
            // userId field
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"userId\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(userId)\r\n".data(using: .utf8)!)
            // documentType field
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"documentType\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(docType.apiKey)\r\n".data(using: .utf8)!)
            // file
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"document\"; filename=\"\(docType.apiKey).jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

            request.httpBody = body

            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    await MainActor.run { uploadProgress[docType] = true }
                }
            } catch {
                #if DEBUG
                print("Document upload failed for \(docType.rawValue): \(error)")
                #endif
            }
        }
        await MainActor.run { isUploading = false }
    }
}

// MARK: - Document Image Picker

import PhotosUI

struct DocumentImagePicker: View {
    let docType: DoctorRegistrationView.DocumentType
    let onPicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var cameraImage: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: docType.icon)
                    .font(.system(size: 48))
                    .foregroundColor(.brandTeal)
                    .padding(.top, 32)

                Text("Upload \(docType.rawValue)")
                    .font(.title3.bold())

                Text("Take a clear photo or choose from your library")
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 14) {
                    // Camera option
                    Button {
                        showCamera = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.title3).frame(width: 28)
                            Text("Take Photo").font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(14)
                    }
                    .foregroundColor(.primary)

                    // Photo library option
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title3).frame(width: 28)
                            Text("Choose from Library").font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(14)
                    }
                    .foregroundColor(.primary)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: selectedItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        onPicked(image)
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraCapture { image in
                    if let image {
                        onPicked(image)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Camera Capture (UIImagePickerController wrapper)

struct CameraCapture: UIViewControllerRepresentable {
    let onCapture: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage?) -> Void
        init(onCapture: @escaping (UIImage?) -> Void) { self.onCapture = onCapture }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            onCapture(image)
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCapture(nil)
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    ContentView()
}
