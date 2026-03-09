//
//  ContentView.swift
//  body sense ai
//
//  Auth flow: Welcome → Sign In | Register | Register as Doctor
//

import SwiftUI
import AuthenticationServices

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

    var body: some View {
        TabView(selection: $tab) {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            TrackView()
                .tabItem { Label("Track", systemImage: "chart.bar.fill") }
                .tag(1)

            ShopView()
                .tabItem { Label("Shop", systemImage: "bag.fill") }
                .tag(2)

            // Everyone gets a Groups/Community tab;
            // doctors get their full hub (Community + Appointments + Find Doctors)
            if store.isDoctor {
                DoctorGroupsView()
                    .tabItem { Label("Groups", systemImage: "person.3.fill") }
                    .tag(3)
            } else {
                CommunityView()
                    .tabItem { Label("Groups", systemImage: "person.3.fill") }
                    .tag(3)
            }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(4)
        }
        .tint(store.isDoctor ? .brandTeal : .brandPurple)
        // Ensure all tab items render at equal width
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground

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
        case intro, welcome, signIn, registerPatient, registerDoctor
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.brandPurple, Color(hex: "#4834d4")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ).ignoresSafeArea()

            switch flow {
            case .intro:
                IntroSlidesView(onFinish: { withAnimation { flow = .welcome } })
            case .welcome:
                WelcomeScreen(
                    onSignIn:            { flow = .signIn },
                    onRegisterPatient:   { flow = .registerPatient },
                    onRegisterDoctor:    { flow = .registerDoctor }
                )
            case .signIn:
                SignInView(onBack: { flow = .welcome }, onDone: { onboardingDone = true })
            case .registerPatient:
                PatientOnboardingView(onBack: { flow = .welcome }, onDone: { onboardingDone = true })
            case .registerDoctor:
                DoctorRegistrationView(onBack: { flow = .welcome }, onDone: { onboardingDone = true })
            }
        }
        .animation(.easeInOut, value: flow)
    }
}

// MARK: - Welcome Screen

struct WelcomeScreen: View {
    let onSignIn: () -> Void
    let onRegisterPatient: () -> Void
    let onRegisterDoctor: () -> Void

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
                        .font(.system(size: 34, weight: .bold))
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
                }
                .padding(.bottom, 44)

                // ── Sign In label ────────────────────────────────────────────
                Text("Sign In")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.white.opacity(0.70))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 10)

                // ── Apple Sign In (native) ────────────────────────────────────
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { _ in
                    onSignIn()
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 54)
                .cornerRadius(14)
                .padding(.horizontal, 28)
                .padding(.bottom, 10)

                // ── Google Sign In ────────────────────────────────────────────
                socialBtn(icon: "g.circle.fill",
                          label: "Sign in with Google",
                          bg: .white, fg: .primary,
                          iconTint: Color(red: 0.26, green: 0.52, blue: 0.96),
                          action: onSignIn)

                // ── Facebook ──────────────────────────────────────────────────
                socialBtn(icon: "f.circle.fill",
                          label: "Continue with Facebook",
                          bg: Color(red: 0.23, green: 0.35, blue: 0.60),
                          fg: .white, iconTint: .white,
                          action: onSignIn)

                // ── Email Sign In ─────────────────────────────────────────────
                socialBtn(icon: "envelope.fill",
                          label: "Sign in with Email",
                          bg: Color.white.opacity(0.14),
                          fg: .white, iconTint: .white,
                          outlined: true, action: onSignIn)

                // ── Create Account ────────────────────────────────────────────
                Button(action: onRegisterPatient) {
                    Text("Create New Account")
                        .font(.headline)
                        .foregroundColor(.brandPurple)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                }
                .padding(.horizontal, 28)
                .padding(.top, 6)

                // ── Doctor divider ────────────────────────────────────────────
                HStack {
                    Rectangle().fill(Color.white.opacity(0.25)).frame(height: 1)
                    Text("For Doctors")
                        .font(.caption).foregroundColor(.white.opacity(0.55))
                        .padding(.horizontal, 10).fixedSize()
                    Rectangle().fill(Color.white.opacity(0.25)).frame(height: 1)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)

                // ── Doctor Sign In ────────────────────────────────────────────
                Button(action: onSignIn) {
                    HStack(spacing: 10) {
                        Image(systemName: "stethoscope")
                        Text("Sign In as a Doctor").fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundColor(.brandTeal)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.brandTeal.opacity(0.14))
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.brandTeal.opacity(0.45), lineWidth: 1.5))
                }
                .padding(.horizontal, 28)

                // ── Register as Doctor ────────────────────────────────────────
                Button(action: onRegisterDoctor) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                        Text("Register as a Verified Doctor")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.72))
                }
                .padding(.top, 14)
                .padding(.bottom, 50)
            }
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

// MARK: - Sign In View (local profile lookup)

struct SignInView: View {
    let onBack: () -> Void
    let onDone: () -> Void
    @Environment(HealthStore.self) var store

    @State private var name = ""
    @State private var showError = false

    var body: some View {
        VStack(spacing: 28) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 50)

            Spacer()

            Image(systemName: "person.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(.white)

            Text("Welcome Back").font(.system(size: 30, weight: .bold)).foregroundColor(.white)
            Text("Enter your name to continue").font(.subheadline).foregroundColor(.white.opacity(0.8))

            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "person").foregroundColor(.white.opacity(0.7))
                    TextField("Your name", text: $name)
                        .foregroundColor(.white)
                        .tint(.white)
                }
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.3)))
            }
            .padding(.horizontal, 28)

            if showError {
                Text("Please enter your name to continue")
                    .font(.caption).foregroundColor(.yellow)
            }

            Spacer()

            Button {
                guard !name.isEmpty else { showError = true; return }
                var p = store.userProfile
                p.name = name
                store.userProfile = p
                store.save()
                onDone()
            } label: {
                Text("Sign In")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.brandPurple)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Patient Onboarding

struct PatientOnboardingView: View {
    let onBack: () -> Void
    let onDone: () -> Void
    @Environment(HealthStore.self) var store

    @State private var page         = 0
    @State private var name         = ""
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
                                    Text("Other").tag("__other__")
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
                    Text("All Set!").font(.system(size: 34, weight: .bold)).foregroundColor(.white)
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
            Text(title).font(.system(size: 30, weight: .bold)).foregroundColor(.white)
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

    func completePatientOnboarding() {
        var profile = store.userProfile
        profile.name          = name.isEmpty ? "Friend" : name
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
    @State private var age          = 30
    @State private var gender       = "Male"
    @State private var country      = "United Kingdom"
    @State private var city         = ""
    @State private var postcode     = ""
    // Professional
    @State private var specialty    = "General Practice"
    @State private var hospital     = ""
    @State private var pmqDegree    = ""    // e.g. "MBBS"
    @State private var pmqCountry   = "United Kingdom"
    @State private var pmqYear      = 2010
    // GMC
    @State private var gmcNumber    = ""
    @State private var gmcStatus    = "Full"
    @State private var gmcDate      = ""
    @State private var hasCGOS      = false  // Certificate of Good Standing
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

    let specialties = ["General Practice","Cardiologist","Diabetologist","Endocrinologist",
                       "Nephrologist","Nutritionist","Psychiatrist","Neurologist",
                       "Oncologist","Dermatologist","Orthopaedic Surgeon","Paediatrician",
                       "Gynaecologist","Urologist","Ophthalmologist","ENT Specialist"]
    let gmcStatuses = ["Full","Provisional","Specialist Register","GP Register"]
    let regulatoryBodies = ["GMC","ECFMG","EPIC","AHPRA","MCC","IMC","HPCSA"]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { if page == 0 { onBack() } else { withAnimation { page -= 1 } } }) {
                    Image(systemName: "chevron.left").foregroundColor(.white)
                        .padding(10).background(Color.white.opacity(0.2)).clipShape(Circle())
                }
                Spacer()
                VStack(spacing: 4) {
                    Text("Doctor Registration")
                        .font(.headline).foregroundColor(.white)
                    HStack(spacing: 6) {
                        ForEach(0..<5, id: \.self) { i in
                            Capsule()
                                .fill(i <= page ? Color.white : Color.white.opacity(0.35))
                                .frame(width: i == page ? 20 : 6, height: 6)
                        }
                    }
                }
                Spacer()
                Color.clear.frame(width: 40)
            }
            .padding(.horizontal, 24).padding(.top, 50)

            TabView(selection: $page) {
                // ── Page 0: Personal Info ──
                ScrollView {
                    VStack(spacing: 20) {
                        regSectionTitle("Personal Information")
                        regField("Full Name (Dr. ...)", text: $fullName, icon: "person")
                        Stepper("Age: \(age)", value: $age, in: 25...80).foregroundColor(.white)
                        Picker("Gender", selection: $gender) {
                            Text("Male").tag("Male"); Text("Female").tag("Female")
                        }.pickerStyle(.segmented)
                        regField("City", text: $city, icon: "building.2")
                        regField("Country", text: $country, icon: "globe")
                        regField("Postcode", text: $postcode, icon: "location")
                        nextBtn("Continue") { withAnimation { page = 1 } }
                    }.padding(.horizontal, 28).padding(.vertical, 24)
                }.tag(0)

                // ── Page 1: Professional Details ──
                ScrollView {
                    VStack(spacing: 20) {
                        regSectionTitle("Professional Details")
                        Text("Specialty").font(.caption).foregroundColor(.white.opacity(0.7))
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(specialties, id: \.self) { spec in
                                Button { specialty = spec } label: {
                                    Text(spec).font(.caption).multilineTextAlignment(.center)
                                        .padding(10).frame(maxWidth: .infinity)
                                        .background(Color.white.opacity(specialty == spec ? 0.3 : 0.12))
                                        .foregroundColor(.white).cornerRadius(10)
                                }
                            }
                        }
                        regField("Hospital / Clinic", text: $hospital, icon: "building.columns")
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Primary Medical Qualification (PMQ)").font(.caption).foregroundColor(.white.opacity(0.7))
                            regField("Degree (e.g. MBBS, MBBCh, MD)", text: $pmqDegree, icon: "graduationcap")
                            regField("Country of Award", text: $pmqCountry, icon: "globe")
                            Stepper("Year: \(pmqYear)", value: $pmqYear, in: 1970...2024).foregroundColor(.white)
                        }
                        nextBtn("Continue") { withAnimation { page = 2 } }
                    }.padding(.horizontal, 28).padding(.vertical, 24)
                }.tag(1)

                // ── Page 2: GMC Registration (UK) ──
                ScrollView {
                    VStack(spacing: 20) {
                        regSectionTitle("UK Registration (GMC)")
                        VStack(alignment: .leading, spacing: 6) {
                            Text("This information is verified against the GMC List of Registered Medical Practitioners.")
                                .font(.caption).foregroundColor(.white.opacity(0.75))
                                .multilineTextAlignment(.leading)
                            Link("View GMC Register →", destination: URL(string: "https://www.gmc-uk.org/registration-and-licensing/the-medical-register")!)
                                .font(.caption).foregroundColor(.white.opacity(0.85))
                        }
                        .padding().background(Color.white.opacity(0.1)).cornerRadius(12)

                        regField("GMC Reference Number", text: $gmcNumber, icon: "number")
                        VStack(alignment: .leading, spacing: 8) {
                            Text("GMC Registration Status").font(.caption).foregroundColor(.white.opacity(0.7))
                            Picker("Status", selection: $gmcStatus) {
                                ForEach(gmcStatuses, id: \.self) { Text($0).tag($0) }
                            }.pickerStyle(.segmented)
                        }
                        regField("Date of First Registration (DD/MM/YYYY)", text: $gmcDate, icon: "calendar")

                        VStack(spacing: 12) {
                            toggleRow("Certificate of Good Standing uploaded", value: $hasCGOS)
                            toggleRow("PLAB / UKMLA passed (international graduates)", value: $plabPassed)
                        }

                        nextBtn("Continue") { withAnimation { page = 3 } }
                    }.padding(.horizontal, 28).padding(.vertical, 24)
                }.tag(2)

                // ── Page 3: International Credentials ──
                ScrollView {
                    VStack(spacing: 20) {
                        regSectionTitle("International Credentials")
                        Text("For doctors qualified outside the UK. Provide your international registration details.")
                            .font(.caption).foregroundColor(.white.opacity(0.75))
                            .padding().background(Color.white.opacity(0.1)).cornerRadius(12)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Primary Regulatory Body").font(.caption).foregroundColor(.white.opacity(0.7))
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(regulatoryBodies, id: \.self) { body in
                                        Button { regulatoryBody = body } label: {
                                            Text(body).font(.caption).fontWeight(.medium)
                                                .padding(.horizontal, 14).padding(.vertical, 8)
                                                .background(regulatoryBody == body ? Color.white.opacity(0.35) : Color.white.opacity(0.15))
                                                .foregroundColor(.white).cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        }

                        regField("ECFMG Certificate Number (if applicable)", text: $ecfmgNumber, icon: "doc.badge.checkmark")

                        VStack(spacing: 12) {
                            toggleRow("ECFMG Certified", value: $ecfmgCerted)
                            toggleRow("Listed in World Directory of Medical Schools (WDOM)", value: $wdomListed)
                        }

                        nextBtn("Continue") { withAnimation { page = 4 } }
                    }.padding(.horizontal, 28).padding(.vertical, 24)
                }.tag(3)

                // ── Page 4: Fees & Introduction ──
                ScrollView {
                    VStack(spacing: 20) {
                        regSectionTitle("Consultation Fees & Introduction")

                        VStack(spacing: 12) {
                            feeRow("Video Consultation (£)", fee: $videoFee, icon: "video.fill")
                            feeRow("Phone Consultation (£)", fee: $phoneFee, icon: "phone.fill")
                            feeRow("In-Person (£)", fee: $inPersonFee, icon: "person.fill")
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Introduction (shown to patients)").font(.caption).foregroundColor(.white.opacity(0.7))
                            ZStack(alignment: .topLeading) {
                                if intro.isEmpty {
                                    Text("Tell patients about yourself, your experience, and approach to care...")
                                        .font(.subheadline).foregroundColor(.white.opacity(0.5))
                                        .padding(.top, 4).padding(.leading, 4)
                                }
                                TextEditor(text: $intro)
                                    .frame(height: 120)
                                    .foregroundColor(.white)
                                    .tint(.white)
                                    .scrollContentBackground(.hidden)
                            }
                            .padding()
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                        }

                        nextBtn("Complete Registration") { completeDocReg() }
                    }.padding(.horizontal, 28).padding(.vertical, 24)
                }.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    func regSectionTitle(_ t: String) -> some View {
        HStack {
            Text(t).font(.system(size: 24, weight: .bold)).foregroundColor(.white)
            Spacer()
        }
    }

    func regField(_ placeholder: String, text: Binding<String>, icon: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(.white.opacity(0.7))
            TextField(placeholder, text: text).foregroundColor(.white).tint(.white)
        }
        .padding().background(Color.white.opacity(0.15)).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.3)))
    }

    func toggleRow(_ label: String, value: Binding<Bool>) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundColor(.white)
            Spacer()
            Toggle("", isOn: value).tint(.brandGreen)
        }
        .padding().background(Color.white.opacity(0.12)).cornerRadius(12)
    }

    func feeRow(_ label: String, fee: Binding<String>, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(.white.opacity(0.7))
            Text(label).font(.subheadline).foregroundColor(.white)
            Spacer()
            TextField("50", text: fee).keyboardType(.numberPad)
                .foregroundColor(.white).tint(.white)
                .multilineTextAlignment(.trailing).frame(width: 60)
        }
        .padding().background(Color.white.opacity(0.12)).cornerRadius(12)
    }

    func nextBtn(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.headline).frame(maxWidth: .infinity).padding()
                .background(Color.white).foregroundColor(.brandPurple)
                .cornerRadius(16).shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
        .padding(.top, 8)
    }

    func completeDocReg() {
        var profile = store.userProfile
        profile.name        = fullName.isEmpty ? "Doctor" : fullName
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
        dp.verificationStatus   = "Under Review"
        dp.postcode             = postcode.uppercased()
        dp.country              = country
        dp.timeZoneIdentifier   = TimeZone.current.identifier

        profile.doctorProfile = dp
        store.userProfile = profile
        store.ensureAnonymousAlias()
        store.save()
        onDone()
    }
}

#Preview {
    ContentView()
}
