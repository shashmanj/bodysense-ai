//
//  ProfileView.swift
//  body sense ai
//
//  Profile for both patients (medical records, photo, settings) and doctors (same + doctor profile view).
//

import SwiftUI
import PhotosUI

// MARK: - Profile Root

struct ProfileView: View {
    @Environment(HealthStore.self) var store

    var body: some View {
        if store.isDoctor {
            DoctorUserProfileView()
        } else {
            PatientProfileView()
        }
    }
}

// MARK: - Patient Profile View

struct PatientProfileView: View {
    @Environment(HealthStore.self) var store
    @State private var showEdit           = false
    @State private var showRecords        = false
    @State private var showSettings       = false
    @State private var showDevices        = false
    @State private var showGiftCode       = false
    @State private var showSubPlans       = false
    @State private var showSupport        = false
    @State private var showNotifSettings  = false
    @State private var showFamilySharing  = false
    @State private var showAISettings     = false
    @State private var showPrivacyData    = false
    @State private var showCEODashboard   = false
    @State private var showDoctorApproval = false
    @State private var showAPIKeys        = false
    @State private var showLaunchChecklist = false
    @State private var showAgentTeam      = false
    @State private var showCEOCodeEntry   = false
    @State private var ceoTapCount        = 0
    @AppStorage("biometricLockEnabled") private var biometricLockEnabled = false
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @State private var pickerItem         : PhotosPickerItem? = nil

    var bmi: Double {
        let h = store.userProfile.height / 100
        guard h > 0 else { return 0 }
        return store.userProfile.weight / (h * h)
    }

    func formatWeight(_ kg: Double) -> String {
        let u = store.userProfile.weightUnit
        let v = u.fromKg(kg)
        switch u {
        case .kg:     return String(format: "%.0f kg", v)
        case .lbs:    return String(format: "%.0f lbs", v)
        case .stones:
            let totalLbs = kg / 0.453592
            let st = Int(totalLbs) / 14
            let lbs = Int(totalLbs) % 14
            return "\(st)st \(lbs)lb"
        }
    }

    func formatHeight(_ cm: Double) -> String {
        store.userProfile.heightUnit.format(cm)
    }

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        // ── Avatar & name header ──
                        profileHeader

                        // ── Stats row ──
                        HStack(spacing: 0) {
                            statCell("\(store.userProfile.age)", label: "Age")
                            Divider().frame(height: 40)
                            statCell(formatWeight(store.userProfile.weight), label: "Weight")
                            Divider().frame(height: 40)
                            statCell(String(format: "%.1f", bmi), label: "BMI")
                            Divider().frame(height: 40)
                            statCell(store.userProfile.currencyCode, label: "Currency")
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16).shadow(color: .black.opacity(0.05), radius: 6)
                        .padding(.horizontal)

                        // ── Subscription badge ──
                        subscriptionCard

                        // ── Quick actions ──
                        quickActionsGrid

                        // ── Medical records ──
                        medicalRecordsPreview

                        // ── Data summary ──
                        dataSummaryCard

                        // ── Settings ──
                        settingsSection
                            .id("settingsSection")

                        // ── About ──
                        aboutSection

                        Spacer(minLength: 32)
                    }
                    .padding(.top)
                }
                .onChange(of: showSettings) { _, show in
                    if show {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            proxy.scrollTo("settingsSection", anchor: .top)
                        }
                        showSettings = false
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { showEdit = true } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
        .sheet(isPresented: $showEdit) { EditProfileSheet() }
        .sheet(isPresented: $showRecords) { MedicalRecordsView() }
        .sheet(isPresented: $showDevices) { ManageDevicesView() }
        .sheet(isPresented: $showGiftCode) { GiftCodeView() }
        .sheet(isPresented: $showSubPlans) { SubscriptionPlansSheet() }
        .sheet(isPresented: $showSupport) { CustomerCareView() }
        .sheet(isPresented: $showNotifSettings) { NotificationsSettingsView() }
        .sheet(isPresented: $showFamilySharing) { FamilySharingView() }
        .sheet(isPresented: $showAISettings) { AIAgentSettingsView() }
        .onChange(of: pickerItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    store.userProfile.profilePhotoData = data
                    store.save()
                }
            }
        }
    }

    var profileHeader: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    if let photoData = store.userProfile.profilePhotoData,
                       let uiImg = UIImage(data: photoData) {
                        Image(uiImage: uiImg)
                            .resizable().scaledToFill()
                            .frame(width: 90, height: 90)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(LinearGradient(colors: [.brandPurple, .brandTeal], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 90, height: 90)
                            .overlay(
                                Text(store.userProfile.anonymousAlias.prefix(2).uppercased())
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    Image(systemName: "camera.circle.fill")
                        .font(.title3)
                        .foregroundColor(.brandPurple)
                        .background(Color.white.clipShape(Circle()))
                        .offset(x: 4, y: 4)
                }
            }

            VStack(spacing: 4) {
                Text(store.userProfile.name).font(.title2).fontWeight(.bold)
                if !store.userProfile.email.isEmpty {
                    Text(store.userProfile.email).font(.caption).foregroundColor(.brandPurple)
                }
                Text(store.userProfile.anonymousAlias).font(.subheadline).foregroundColor(.secondary)
                if !store.userProfile.city.isEmpty {
                    Label("\(store.userProfile.city), \(store.userProfile.country)", systemImage: "mappin.circle.fill")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical)
    }

    var subscriptionCard: some View {
        let plan = store.subscription
        // Determine how the user got the plan: redeemed gift code vs. paid subscription
        let redeemedCode = store.giftCodes.first(where: { $0.isRedeemed && $0.plan == plan })
        let acquiredLabel: String = {
            if plan == .free { return "Free tier" }
            if redeemedCode != nil { return "Gift code redeemed" }
            return "Active subscription"
        }()
        let acquiredIcon: String = redeemedCode != nil ? "gift.fill" : "checkmark.seal.fill"
        let acquiredColor: Color = redeemedCode != nil ? .brandAmber : .brandGreen

        return HStack(spacing: 14) {
            Image(systemName: plan.icon)
                .font(.title2)
                .foregroundColor(plan.color)
                .frame(width: 44, height: 44)
                .background(plan.color.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("\(plan.badge) Plan").font(.headline)
                    // Tier badge
                    if plan != .free {
                        Text(plan == .premium ? "PREMIUM" : "PRO")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(plan.color.opacity(0.18))
                            .foregroundColor(plan.color)
                            .cornerRadius(4)
                    }
                }
                HStack(spacing: 4) {
                    Image(systemName: acquiredIcon).font(.caption2).foregroundColor(acquiredColor)
                    Text(acquiredLabel).font(.caption).foregroundColor(acquiredColor)
                }
            }
            Spacer()
            if plan == .free {
                Button { showSubPlans = true } label: {
                    Text("Upgrade").font(.caption).fontWeight(.semibold)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Color.brandPurple.opacity(0.1))
                        .foregroundColor(.brandPurple).cornerRadius(10)
                }
            } else {
                Button { showSubPlans = true } label: {
                    Text("Manage").font(.caption).fontWeight(.semibold)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(plan.color.opacity(0.1))
                        .foregroundColor(plan.color).cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16).shadow(color: .black.opacity(0.05), radius: 6)
        .padding(.horizontal)
    }

    var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            quickAction("Medical Records", icon: "doc.fill", color: .brandTeal)   { showRecords = true }
            quickAction("Gift Code", icon: "gift.fill", color: .brandAmber)        { showGiftCode = true }
            quickAction("Devices", icon: "applewatch", color: .brandPurple)        { showDevices = true }
            quickAction("Settings", icon: "gearshape.fill", color: Color(.systemGray)) { showSettings = true }
        }
        .padding(.horizontal)
    }

    func quickAction(_ label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2).foregroundColor(color)
                    .frame(width: 48, height: 48).background(color.opacity(0.1)).clipShape(Circle())
                Text(label).font(.caption2).multilineTextAlignment(.center).foregroundColor(.primary)
            }
        }
    }

    var medicalRecordsPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Medical Records").font(.headline)
                Spacer()
                Button("See All") { showRecords = true }.font(.caption).foregroundColor(.brandTeal)
            }
            .padding(.horizontal)

            if store.medicalRecords.isEmpty {
                // Clean empty state — no upload button, just a subtle message
                HStack(spacing: 14) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.title2).foregroundColor(.brandTeal.opacity(0.6))
                    Text("No records yet. Tap See All to add your first medical record.")
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(14)
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(store.medicalRecords.prefix(5)) { rec in
                            MedicalRecordMiniCard(record: rec)
                        }
                        Button { showRecords = true } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(.brandTeal)
                                Text("Add More").font(.caption2)
                            }
                            .frame(width: 80, height: 90)
                            .background(Color(.systemGray6)).cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    var dataSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Data Summary").font(.headline).padding(.horizontal)
            HStack(spacing: 10) {
                dataChip("\(store.glucoseReadings.count)", label: "Glucose", icon: "drop.fill", color: .brandCoral)
                dataChip("\(store.bpReadings.count)", label: "BP", icon: "heart.fill", color: .brandTeal)
                dataChip("\(store.medications.count)", label: "Meds", icon: "pills.fill", color: .brandPurple)
                dataChip("\(store.medicalRecords.count)", label: "Records", icon: "doc.fill", color: .brandAmber)
            }
            .padding(.horizontal)
        }
    }

    func dataChip(_ value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.subheadline).foregroundColor(color)
            Text(value).font(.headline)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(color.opacity(0.08)).cornerRadius(12)
    }

    var settingsSection: some View {
        VStack(spacing: 0) {
            settingsRow("Edit Profile", icon: "person.fill", color: .brandPurple) { showEdit = true }
            Divider().padding(.leading, 52)
            settingsRow("Manage Devices", icon: "applewatch", color: .brandTeal) { showDevices = true }
            Divider().padding(.leading, 52)
            settingsRow("Subscription & Plans", icon: "crown.fill", color: .brandAmber) { showSubPlans = true }
            Divider().padding(.leading, 52)
            settingsRow("Gift Codes", icon: "gift.fill", color: .brandGreen) { showGiftCode = true }
            Divider().padding(.leading, 52)
            settingsRow("Notifications", icon: "bell.fill", color: .brandCoral) { showNotifSettings = true }
            Divider().padding(.leading, 52)
            settingsRow("Family Sharing", icon: "person.3.fill", color: .brandGreen) { showFamilySharing = true }
            Divider().padding(.leading, 52)
            settingsRow("Help & Support", icon: "headphones.circle.fill", color: .brandTeal) { showSupport = true }
            Divider().padding(.leading, 52)
            settingsRow("AI Agent Settings", icon: "brain", color: Color(hex: "#6C63FF")) { showAISettings = true }
            Divider().padding(.leading, 52)

            // ── Apple Health Sync ──
            HStack(spacing: 14) {
                Image(systemName: "heart.circle.fill").font(.body).foregroundColor(.white)
                    .frame(width: 32, height: 32).background(Color.red).cornerRadius(8)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Health Sync").font(.subheadline)
                    Text("Auto-sync steps, calories, SpO₂")
                        .font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { store.userProfile.healthKitEnabled },
                    set: { newVal in
                        store.userProfile.healthKitEnabled = newVal
                        store.save()
                        if newVal {
                            Task {
                                await HealthKitManager.shared.requestAuthorization()
                                await HealthKitManager.shared.syncAll(to: store)
                            }
                        }
                    }
                ))
                .tint(.brandGreen)
                .labelsHidden()
            }
            .padding(.horizontal).padding(.vertical, 12)

            Divider().padding(.leading, 52)

            // ── Weight Unit ──
            HStack(spacing: 14) {
                Image(systemName: "scalemass.fill").font(.body).foregroundColor(.white)
                    .frame(width: 32, height: 32).background(Color.brandAmber).cornerRadius(8)
                Text("Weight Unit").font(.subheadline)
                Spacer()
                Picker("", selection: Binding(
                    get: { store.userProfile.weightUnit },
                    set: { store.userProfile.weightUnit = $0; store.save() }
                )) {
                    ForEach(WeightUnit.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                .pickerStyle(.menu).tint(.brandPurple)
            }
            .padding(.horizontal).padding(.vertical, 12)

            Divider().padding(.leading, 52)

            // ── Height Unit ──
            HStack(spacing: 14) {
                Image(systemName: "ruler.fill").font(.body).foregroundColor(.white)
                    .frame(width: 32, height: 32).background(Color.brandTeal).cornerRadius(8)
                Text("Height Unit").font(.subheadline)
                Spacer()
                Picker("", selection: Binding(
                    get: { store.userProfile.heightUnit },
                    set: { store.userProfile.heightUnit = $0; store.save() }
                )) {
                    ForEach(HeightUnit.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                .pickerStyle(.menu).tint(.brandPurple)
            }
            .padding(.horizontal).padding(.vertical, 12)

            Divider().padding(.leading, 52)

            // ── Privacy & Data ──
            settingsRow("Privacy & Data", icon: "hand.raised.fill", color: .blue) { showPrivacyData = true }
            Divider().padding(.leading, 52)

            // ── Biometric Lock ──
            HStack(spacing: 14) {
                Image(systemName: "faceid").font(.body).foregroundColor(.white)
                    .frame(width: 32, height: 32).background(Color.brandPurple).cornerRadius(8)
                Text("Biometric Lock").font(.subheadline)
                Spacer()
                Toggle("", isOn: $biometricLockEnabled)
                    .tint(.brandGreen).labelsHidden()
            }
            .padding(.horizontal).padding(.vertical, 12)

            Divider().padding(.leading, 52)

            // ── Dark Mode ──
            HStack(spacing: 14) {
                Image(systemName: "moon.fill").font(.body).foregroundColor(.white)
                    .frame(width: 32, height: 32).background(Color.indigo).cornerRadius(8)
                Text("Dark Mode").font(.subheadline)
                Spacer()
                Toggle("", isOn: $darkModeEnabled)
                    .tint(.brandGreen).labelsHidden()
            }
            .padding(.horizontal).padding(.vertical, 12)

            // ── CEO Section (only visible to CEO) ──
            if store.userProfile.isCEO {
                Divider().padding(.leading, 52)

                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "crown.fill").foregroundColor(.brandAmber)
                        Text("CEO Controls").font(.caption.weight(.bold)).foregroundColor(.brandAmber)
                        Spacer()
                    }
                    .padding(.horizontal).padding(.top, 12).padding(.bottom, 4)

                    settingsRow("CEO Dashboard", icon: "chart.bar.fill", color: .brandAmber) { showCEODashboard = true }
                    Divider().padding(.leading, 52)
                    settingsRow("AI Agent Team", icon: "sparkles.rectangle.stack.fill", color: Color(hex: "#E040FB")) { showAgentTeam = true }
                    Divider().padding(.leading, 52)
                    Button {
                        showDoctorApproval = true
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "checkmark.shield.fill").font(.body).foregroundColor(.white)
                                .frame(width: 32, height: 32).background(Color.brandTeal).cornerRadius(8)
                            Text("Doctor Approvals").font(.subheadline).foregroundColor(.primary)
                            Spacer()
                            if !store.pendingDoctorRequests.isEmpty {
                                Text("\(store.pendingDoctorRequests.count) pending")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(Color.brandCoral)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                        }
                        .padding(.horizontal).padding(.vertical, 12)
                    }
                    Divider().padding(.leading, 52)
                    settingsRow("API Keys & Security", icon: "key.fill", color: .orange) { showAPIKeys = true }
                    Divider().padding(.leading, 52)
                    settingsRow("Launch Checklist", icon: "checklist", color: .brandGreen) { showLaunchChecklist = true }
                }
            }

            Divider().padding(.leading, 52)

            // ── Account Recovery (Apple ID) ──
            Button {
                // Sign in with Apple — password is managed by Apple ID
                if let url = URL(string: "https://iforgot.apple.com") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "person.badge.key.fill").font(.body).foregroundColor(.white)
                        .frame(width: 32, height: 32).background(Color.blue).cornerRadius(8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Account Recovery").font(.body)
                        Text("Managed by your Apple ID").font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.caption).foregroundColor(.secondary)
                }
                .padding(.horizontal).padding(.vertical, 12)
            }

            Divider().padding(.leading, 52)

            // ── Sign Out ──
            Button {
                AuthService.shared.signOut()
                UserDefaults.standard.set(false, forKey: "onboardingDone")
                store.userProfile = UserProfile()
                store.save()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "rectangle.portrait.and.arrow.right").font(.body).foregroundColor(.white)
                        .frame(width: 32, height: 32).background(Color.red).cornerRadius(8)
                    Text("Sign Out").font(.body).foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal).padding(.vertical, 12)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16).shadow(color: .black.opacity(0.05), radius: 6)
        .padding(.horizontal)
        .sheet(isPresented: $showPrivacyData) { PrivacySettingsView() }
        .sheet(isPresented: $showCEODashboard) { NavigationStack { CEODashboardView() } }
        .sheet(isPresented: $showDoctorApproval) { NavigationStack { DoctorApprovalView() } }
        .sheet(isPresented: $showAPIKeys) { NavigationStack { APIKeysView() } }
        .sheet(isPresented: $showLaunchChecklist) { NavigationStack { LaunchChecklistView() } }
        .sheet(isPresented: $showAgentTeam) { NavigationStack { AgentTeamView() } }
    }

    func settingsRow(_ label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.body).foregroundColor(.white)
                    .frame(width: 32, height: 32).background(color).cornerRadius(8)
                Text(label).font(.body).foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
            }
            .padding()
        }
    }

    var aboutSection: some View {
        VStack(spacing: 0) {
            Link(destination: URL(string: "https://bodysenseai.co.uk")!) {
                HStack {
                    Image(systemName: "globe").foregroundColor(.brandTeal).frame(width: 24)
                    Text("bodysenseai.co.uk").foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.caption).foregroundColor(.secondary)
                }
                .padding()
            }
            Divider().padding(.leading, 52)
            Button {
                // Hidden CEO activation — tap version text 5 times rapidly
                ceoTapCount += 1
                if ceoTapCount >= 5 {
                    ceoTapCount = 0
                    showCEOCodeEntry = true
                }
                // Reset counter after 3 seconds of no taps
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    ceoTapCount = 0
                }
            } label: {
                HStack {
                    Image(systemName: "info.circle").foregroundColor(.secondary).frame(width: 24)
                    Text("Version 1.0 · BodySense AI").font(.subheadline).foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
            }
            .buttonStyle(.plain)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16).shadow(color: .black.opacity(0.05), radius: 6)
        .padding(.horizontal)
        .sheet(isPresented: $showCEOCodeEntry) {
            CEOActivationSheet()
        }
    }

    func statCell(_ value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.headline)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Doctor User Profile (doctor as a user - same as patient but with doctor badge)

struct DoctorUserProfileView: View {
    @Environment(HealthStore.self) var store
    @AppStorage("doctorModeEnabled") private var doctorMode = false
    @State private var showEdit       = false
    @State private var showRecords    = false
    @State private var showDevices    = false
    @State private var showGiftCode   = false
    @State private var showSubPlans   = false
    @State private var showSupport    = false
    @State private var showAppStatus  = false
    @State private var pickerItem     : PhotosPickerItem? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Doctor profile header
                    doctorProfileHeader

                    // ── Doctor Mode toggle (only when approved) ──
                    if store.isDoctorApproved {
                        HStack(spacing: 14) {
                            Image(systemName: "stethoscope.circle.fill")
                                .font(.title2).foregroundColor(.brandTeal)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Doctor Mode").font(.headline)
                                Text(doctorMode ? "Home tab shows your doctor dashboard" : "Home tab shows your health dashboard")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $doctorMode).tint(.brandTeal).labelsHidden()
                        }
                        .padding(14)
                        .background(doctorMode ? Color.brandTeal.opacity(0.08) : Color(.secondarySystemBackground))
                        .cornerRadius(14)
                        .padding(.horizontal)
                    } else if store.isDoctor {
                        // Doctor registered but not yet approved — show status
                        Button { showAppStatus = true } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.badge.exclamationmark.fill")
                                    .font(.title3).foregroundColor(.brandAmber)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Application \(store.doctorApplicationStatus)")
                                        .font(.headline)
                                    Text("Tap to view your application status")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(.secondary)
                            }
                            .padding(14)
                            .background(Color.brandAmber.opacity(0.08))
                            .cornerRadius(14)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                    }

                    // Info banner
                    VStack(spacing: 0) {
                        Text("You have full access to all BodySense AI health features as a user. Toggle Doctor Mode above to manage appointments and patients.")
                            .font(.caption).foregroundColor(.secondary)
                            .padding()
                            .background(Color.brandTeal.opacity(0.06))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Quick actions (same as patient)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        quickAction("Medical Records", icon: "doc.fill", color: .brandTeal) { showRecords = true }
                        quickAction("Gift Code", icon: "gift.fill", color: .brandAmber) { showGiftCode = true }
                        quickAction("Devices", icon: "applewatch", color: .brandPurple) { showDevices = true }
                        quickAction("Subscription", icon: "crown.fill", color: .brandGreen) { showSubPlans = true }
                    }
                    .padding(.horizontal)

                    // Medical records section
                    medicalRecordsPreview

                    // Settings
                    settingsSection

                    Spacer(minLength: 32)
                }
                .padding(.top)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { showEdit = true } label: { Image(systemName: "pencil") }
                }
            }
        }
        .sheet(isPresented: $showEdit) { EditProfileSheet() }
        .sheet(isPresented: $showRecords) { MedicalRecordsView() }
        .sheet(isPresented: $showDevices) { ManageDevicesView() }
        .sheet(isPresented: $showGiftCode) { GiftCodeView() }
        .sheet(isPresented: $showSubPlans) { SubscriptionPlansSheet() }
        .sheet(isPresented: $showSupport) { CustomerCareView() }
        .sheet(isPresented: $showAppStatus) { DoctorApplicationStatusView() }
        .onChange(of: pickerItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    store.userProfile.profilePhotoData = data
                    store.save()
                }
            }
        }
    }

    var doctorProfileHeader: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    if let photoData = store.userProfile.profilePhotoData,
                       let uiImg = UIImage(data: photoData) {
                        Image(uiImage: uiImg).resizable().scaledToFill()
                            .frame(width: 90, height: 90).clipShape(Circle())
                    } else {
                        Circle()
                            .fill(LinearGradient(colors: [Color(hex: "#00BFA5"), .brandPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 90, height: 90)
                            .overlay(Text(String(store.userProfile.name.prefix(2)).uppercased())
                                .font(.system(size: 32, weight: .bold)).foregroundColor(.white))
                    }
                    Image(systemName: "camera.circle.fill").font(.title3).foregroundColor(.brandTeal)
                        .background(Color.white.clipShape(Circle())).offset(x: 4, y: 4)
                }
            }
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Text(store.userProfile.name).font(.title2).fontWeight(.bold)
                    if store.userProfile.doctorProfile?.isVerified == true {
                        Image(systemName: "checkmark.seal.fill").foregroundColor(.brandTeal)
                    }
                }
                Text(store.userProfile.doctorProfile?.specialty ?? "Doctor").font(.subheadline).foregroundColor(.secondary)
                Label("\(store.userProfile.city), \(store.userProfile.country)", systemImage: "mappin.circle.fill")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.vertical)
    }

    var medicalRecordsPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Medical Records").font(.headline)
                Spacer()
                Button("See All") { showRecords = true }.font(.caption).foregroundColor(.brandTeal)
            }
            .padding(.horizontal)
            if store.medicalRecords.isEmpty {
                // Clean empty state — no upload button
                HStack(spacing: 14) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.title2).foregroundColor(.brandTeal.opacity(0.6))
                    Text("No records yet. Tap See All to add your first medical record.")
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(14)
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(store.medicalRecords.prefix(5)) { rec in MedicalRecordMiniCard(record: rec) }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    var settingsSection: some View {
        VStack(spacing: 0) {
            settingsRow("Edit Profile", icon: "person.fill", color: .brandPurple) { showEdit = true }
            Divider().padding(.leading, 52)
            settingsRow("Manage Devices", icon: "applewatch", color: .brandTeal) { showDevices = true }
            Divider().padding(.leading, 52)
            settingsRow("Subscription & Plans", icon: "crown.fill", color: .brandAmber) { showSubPlans = true }
            Divider().padding(.leading, 52)
            settingsRow("Help & Support", icon: "headphones.circle.fill", color: .brandTeal) { showSupport = true }
        }
        .background(Color(.systemBackground)).cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6).padding(.horizontal)
    }

    func quickAction(_ label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2).foregroundColor(color)
                    .frame(width: 48, height: 48).background(color.opacity(0.1)).clipShape(Circle())
                Text(label).font(.caption2).multilineTextAlignment(.center).foregroundColor(.primary)
            }
        }
    }

    func settingsRow(_ label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.body).foregroundColor(.white)
                    .frame(width: 32, height: 32).background(color).cornerRadius(8)
                Text(label).font(.body).foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

// MARK: - Medical Records View

struct MedicalRecordsView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var showAdd      = false
    @State private var selectedType : MedicalRecordType = .report
    @State private var search       = ""

    var filtered: [MedicalRecord] {
        store.medicalRecords.filter { rec in
            search.isEmpty || rec.title.localizedCaseInsensitiveContains(search) ||
            rec.notes.localizedCaseInsensitiveContains(search)
        }
        .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search records…", text: $search)
                }
                .padding(12).background(Color(.systemGray6)).cornerRadius(12)
                .padding(.horizontal).padding(.top, 8)

                if filtered.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 56)).foregroundColor(.brandTeal.opacity(0.4))
                        Text("No medical records").font(.headline)
                        Text("Upload photos, PDFs, lab results,\nprescriptions and more.").font(.subheadline)
                            .foregroundColor(.secondary).multilineTextAlignment(.center)
                        Button { showAdd = true } label: {
                            Label("Upload Record", systemImage: "plus")
                                .font(.headline).padding().frame(maxWidth: .infinity)
                                .background(Color.brandTeal).foregroundColor(.white).cornerRadius(14)
                        }
                        .padding(.horizontal, 32)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filtered) { rec in
                            MedicalRecordRow(record: rec)
                        }
                        .onDelete { idx in
                            let toDelete = idx.map { filtered[$0].id }
                            store.medicalRecords.removeAll { toDelete.contains($0.id) }
                            store.save()
                        }
                    }
                }
            }
            .navigationTitle("Medical Records")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddMedicalRecordView() }
    }
}

// MARK: - Medical Record Row

struct MedicalRecordRow: View {
    let record: MedicalRecord

    var body: some View {
        HStack(spacing: 14) {
            if let thumbData = record.thumbnailData, let uiImg = UIImage(data: thumbData) {
                Image(uiImage: uiImg).resizable().scaledToFill()
                    .frame(width: 48, height: 48).clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: record.fileType.icon).font(.title2)
                    .foregroundColor(record.fileType.color)
                    .frame(width: 48, height: 48)
                    .background(record.fileType.color.opacity(0.12))
                    .cornerRadius(10)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(record.title).font(.subheadline).fontWeight(.semibold)
                Text(record.fileType.rawValue).font(.caption).foregroundColor(.secondary)
                Text(record.date.formatted(date: .abbreviated, time: .omitted)).font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            if record.isShared {
                Image(systemName: "person.2.fill").font(.caption).foregroundColor(.brandTeal)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Medical Record Mini Card

struct MedicalRecordMiniCard: View {
    let record: MedicalRecord

    var body: some View {
        VStack(spacing: 6) {
            if let thumbData = record.thumbnailData, let uiImg = UIImage(data: thumbData) {
                Image(uiImage: uiImg).resizable().scaledToFill()
                    .frame(width: 60, height: 60).clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: record.fileType.icon).font(.title2)
                    .foregroundColor(record.fileType.color)
                    .frame(width: 60, height: 60)
                    .background(record.fileType.color.opacity(0.12))
                    .cornerRadius(10)
            }
            Text(record.title).font(.caption2).lineLimit(2).multilineTextAlignment(.center).frame(width: 70)
        }
        .frame(width: 80, height: 95)
        .background(Color(.systemBackground)).cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 4)
    }
}

// MARK: - Add Medical Record

struct AddMedicalRecordView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    @State private var title        = ""
    @State private var fileType     : MedicalRecordType = .report
    @State private var notes        = ""
    @State private var pickerItem   : PhotosPickerItem? = nil
    @State private var fileData     : Data? = nil
    @State private var thumbData    : Data? = nil
    @State private var saved        = false

    var body: some View {
        NavigationView {
            Form {
                Section("Record Details") {
                    TextField("Title (e.g. Blood Test Results)", text: $title)
                    Picker("Type", selection: $fileType) {
                        ForEach(MedicalRecordType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                }
                Section("Upload File") {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        HStack {
                            let hasFile = fileData != nil
                            Image(systemName: hasFile ? "checkmark.circle.fill" : "arrow.up.doc.fill")
                                .foregroundColor(hasFile ? .brandGreen : .brandTeal)
                            Text(hasFile ? "File selected ✓" : "Tap to select a photo")
                                .foregroundColor(hasFile ? .brandGreen : .brandTeal)
                        }
                    }
                    .onChange(of: pickerItem) { _, item in
                        Task {
                            if let data = try? await item?.loadTransferable(type: Data.self) {
                                fileData = data
                                // Create thumbnail if it's an image
                                if let uiImg = UIImage(data: data) {
                                    let thumb = uiImg.preparingThumbnail(of: CGSize(width: 120, height: 120))
                                    thumbData = thumb?.jpegData(compressionQuality: 0.7)
                                }
                            }
                        }
                    }
                }
                Section("Notes (optional)") {
                    TextEditor(text: $notes).frame(height: 80)
                }
                Section {
                    Button { saveRecord() } label: {
                        Label("Save Record", systemImage: "checkmark.circle.fill").foregroundColor(.brandTeal)
                    }
                    .disabled(title.isEmpty)
                }
            }
            .navigationTitle("Add Medical Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .alert("Record Saved!", isPresented: $saved) { Button("OK") { dismiss() } }
        }
    }

    func saveRecord() {
        let rec = MedicalRecord(
            title: title,
            fileType: fileType,
            fileName: title,
            fileData: fileData,
            thumbnailData: thumbData,
            notes: notes,
            date: Date(),
            addedBy: "Me"
        )
        store.medicalRecords.append(rec)
        store.save()
        saved = true
    }
}

// MARK: - Manage Devices View (standalone, not linked to shop)

struct ManageDevicesView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    let allDeviceTypes: [WearableType] = WearableType.allCases

    // Active / connected devices
    var connectedDevices: [WearableDevice] {
        store.wearableDevices.filter { $0.isConnected }
    }
    // Devices that were added but are now disconnected
    var disconnectedDevices: [WearableDevice] {
        store.wearableDevices.filter { !$0.isConnected }
    }
    // Device types not yet added at all
    var unaddedTypes: [WearableType] {
        allDeviceTypes.filter { type in
            !store.wearableDevices.contains(where: { $0.type == type })
        }
    }

    var body: some View {
        NavigationView {
            List {
                // ── 1. Active, connected devices ──
                Section("Connected") {
                    if connectedDevices.isEmpty {
                        Text("No devices currently connected.")
                            .font(.subheadline).foregroundColor(.secondary)
                    } else {
                        ForEach(connectedDevices) { device in
                            ConnectedDeviceRow(device: device) {
                                store.wearableDevices.removeAll { $0.id == device.id }
                                store.save()
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    store.wearableDevices.removeAll { $0.id == device.id }
                                    store.save()
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete { idx in
                            let ids = connectedDevices.map { $0.id }
                            let toRemove = idx.map { ids[$0] }
                            store.wearableDevices.removeAll { toRemove.contains($0.id) }
                            store.save()
                        }
                    }
                }

                // ── 2. Added but disconnected devices ──
                if !disconnectedDevices.isEmpty {
                    Section("Added Devices") {
                        ForEach(disconnectedDevices) { device in
                            HStack(spacing: 14) {
                                Image(systemName: device.type.icon)
                                    .font(.title3).foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(device.type.color.opacity(0.5)).cornerRadius(10)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(device.type.rawValue).font(.subheadline).fontWeight(.medium)
                                    Text("Disconnected").font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                // Reconnect button
                                Button {
                                    if let idx = store.wearableDevices.firstIndex(where: { $0.id == device.id }) {
                                        store.wearableDevices[idx].isConnected = true
                                        store.wearableDevices[idx].lastSync = Date()
                                        store.save()
                                    }
                                } label: {
                                    Text("Reconnect")
                                        .font(.caption).fontWeight(.semibold)
                                        .padding(.horizontal, 10).padding(.vertical, 5)
                                        .background(Color.brandTeal.opacity(0.12))
                                        .foregroundColor(.brandTeal).cornerRadius(8)
                                }
                            }
                        }
                        .onDelete { idx in
                            let ids = disconnectedDevices.map { $0.id }
                            let toRemove = idx.map { ids[$0] }
                            store.wearableDevices.removeAll { toRemove.contains($0.id) }
                            store.save()
                        }
                    }
                }

                // ── 3. Types not yet added ──
                if !unaddedTypes.isEmpty {
                    Section("Add a Device") {
                        ForEach(unaddedTypes, id: \.self) { type in
                            addDeviceRow(type: type)
                        }
                    }
                }
            }
            .navigationTitle("Manage Devices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { EditButton() }
            }
        }
    }

    func addDeviceRow(type: WearableType) -> some View {
        Button {
            addDevice(type: type)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: type.icon)
                    .font(.title3).foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(type.color).cornerRadius(10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.rawValue).font(.subheadline).fontWeight(.medium).foregroundColor(.primary)
                    Text(type.category.rawValue).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "plus.circle.fill").foregroundColor(.brandTeal)
            }
        }
    }

    func addDevice(type: WearableType) {
        var device = WearableDevice(
            type: type,
            isConnected: true,
            batteryLevel: Int.random(in: 60...100),
            lastSync: Date()
        )
        // Auto-assign ring colour from last shop purchase, default silver
        if type == .bodySenseRing {
            device.ringColor = store.lastPurchasedRingColor ?? .silver
        }
        store.wearableDevices.append(device)
        store.save()
    }
}

// MARK: - Connected Device Row

struct ConnectedDeviceRow: View {
    let device: WearableDevice
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 14) {
            // Show actual ring photo if it's a BodySense Ring with a colour
            if device.type == .bodySenseRing, let rc = device.ringColor {
                Image(rc.frontPhotoName)
                    .resizable().scaledToFit()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: rc.glowColor.opacity(0.3), radius: 4, y: 2)
            } else {
                Image(systemName: device.type.icon)
                    .font(.title3).foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(device.type.color).cornerRadius(10)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(device.type.rawValue).font(.subheadline).fontWeight(.semibold)
                    if let rc = device.ringColor {
                        Text(rc.rawValue)
                            .font(.caption2).foregroundColor(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(rc.color).cornerRadius(6)
                    }
                }
                Text("Synced \(device.lastSync?.formatted(.relative(presentation: .numeric)) ?? "Never")")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: "battery.75").font(.caption)
                    Text("\(device.batteryLevel)%").font(.caption)
                }
                .foregroundColor(device.batteryLevel > 20 ? .brandGreen : .brandCoral)
                Text(device.isConnected ? "Connected" : "Disconnected").font(.caption2)
                    .foregroundColor(device.isConnected ? .brandGreen : .secondary)
            }
        }
    }
}

// MARK: - Gift Code View

struct GiftCodeView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    @State private var redeemCode   = ""
    @State private var showError    = false
    @State private var errorMsg     = ""
    @State private var showSuccess  = false
    @State private var quantity     = 1
    @State private var selectedPlan : SubscriptionPlan = .premium
    @State private var showGenerate = false

    var myGiftCodes: [GiftCode] { store.giftCodes.filter { !$0.isRedeemed } }

    var body: some View {
        NavigationView {
            List {
                // ── Redeem a code ──
                Section("Redeem a Gift Code") {
                    HStack {
                        Image(systemName: "gift.fill").foregroundColor(.brandAmber)
                        TextField("Enter code (e.g. BS-GIFT-ABC123)", text: $redeemCode)
                            .autocapitalization(.allCharacters)
                            .autocorrectionDisabled()
                        Button("Redeem") { redeemGiftCode() }
                            .foregroundColor(.brandTeal).fontWeight(.semibold)
                    }
                    if showError { Text(errorMsg).font(.caption).foregroundColor(.brandCoral) }
                }

                // ── Buy gift codes ──
                Section("Buy a Yearly Gift Subscription") {
                    Picker("Plan", selection: $selectedPlan) {
                        Text("Pro (£\(String(format: "%.0f", SubscriptionPlan.pro.basePriceGBP * 12))/yr)").tag(SubscriptionPlan.pro)
                        Text("Premium (£\(String(format: "%.0f", SubscriptionPlan.premium.basePriceGBP * 12))/yr)").tag(SubscriptionPlan.premium)
                    }
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...10)
                    Button { showGenerate = true } label: {
                        Label("Generate Gift Codes", systemImage: "plus.circle.fill")
                            .foregroundColor(.brandGreen)
                    }
                }

                // ── My codes ──
                if !myGiftCodes.isEmpty {
                    Section("Your Gift Codes") {
                        ForEach(myGiftCodes) { code in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(code.code).font(.system(.body, design: .monospaced)).fontWeight(.bold)
                                    Spacer()
                                    Text(code.plan.badge).font(.caption)
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(code.plan.color.opacity(0.15))
                                        .foregroundColor(code.plan.color).cornerRadius(6)
                                }
                                Text("\(code.plan.rawValue) · 12 months")
                                    .font(.caption).foregroundColor(.secondary)
                                Text("Generated \(code.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption2).foregroundColor(.secondary)
                                ShareLink(item: "Use code \(code.code) to get a free \(code.plan.rawValue) subscription on BodySense AI! bodysenseai.co.uk") {
                                    Label("Share Code", systemImage: "square.and.arrow.up")
                                        .font(.caption).foregroundColor(.brandTeal)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Gift Codes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .alert("Subscription Activated!", isPresented: $showSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your gift subscription has been applied to your account.")
            }
            .alert("Generate \(quantity) Code\(quantity > 1 ? "s" : "")?", isPresented: $showGenerate) {
                Button("Generate") { generateCodes() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will generate \(quantity) gift code\(quantity > 1 ? "s" : "") for \(selectedPlan.rawValue) (12 months each).")
            }
        }
    }

    func redeemGiftCode() {
        let code = redeemCode.trimmingCharacters(in: .whitespaces).uppercased()
        if let idx = store.giftCodes.firstIndex(where: { $0.code == code && !$0.isRedeemed }) {
            store.giftCodes[idx].redeemedAt = Date()
            store.giftCodes[idx].redeemedBy = store.userProfile.anonymousAlias
            store.subscription = store.giftCodes[idx].plan
            store.save()
            redeemCode = ""
            showSuccess = true
        } else {
            errorMsg = "Invalid or already redeemed code."
            showError = true
        }
    }

    func generateCodes() {
        for _ in 0..<quantity {
            let gc = GiftCode(
                code: GiftCode.generateCode(),
                plan: selectedPlan,
                durationMonths: 12,
                createdAt: Date()
            )
            store.giftCodes.append(gc)
        }
        store.save()
    }
}

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    @State private var name     = ""
    @State private var email    = ""
    @State private var age      = 30
    @State private var gender   = "Female"
    @State private var city     = ""
    @State private var country  = "United Kingdom"
    @State private var postcode = ""
    @State private var weight   = ""
    @State private var height   = ""
    @State private var emergencyName  = ""
    @State private var emergencyPhone = ""
    @State private var saved    = false

    var body: some View {
        NavigationView {
            Form {
                Section("Personal") {
                    TextField("Name", text: $name)
                    HStack {
                        Image(systemName: "envelope").foregroundColor(.secondary)
                        TextField("Email address", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    Stepper("Age: \(age)", value: $age, in: 16...100)
                    Picker("Gender", selection: $gender) {
                        Text("Female").tag("Female")
                        Text("Male").tag("Male")
                        Text("Other").tag("Other")
                    }
                }
                Section("Body Measurements") {
                    HStack {
                        Text("Weight (\(store.userProfile.weightUnit.label))")
                        Spacer()
                        TextField("70", text: $weight).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                    Picker("Weight Unit", selection: Binding(
                        get: { store.userProfile.weightUnit },
                        set: { newUnit in
                            // Convert displayed value to new unit
                            if let val = Double(weight) {
                                let kg = store.userProfile.weightUnit.toKg(val)
                                let converted = newUnit.fromKg(kg)
                                weight = String(format: "%.1f", converted)
                            }
                            store.userProfile.weightUnit = newUnit
                        }
                    )) {
                        ForEach(WeightUnit.allCases, id: \.self) { Text($0.label).tag($0) }
                    }.pickerStyle(.segmented)

                    HStack {
                        Text("Height (\(store.userProfile.heightUnit.label))")
                        Spacer()
                        TextField("165", text: $height).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                    Picker("Height Unit", selection: Binding(
                        get: { store.userProfile.heightUnit },
                        set: { newUnit in
                            if let val = Double(height) {
                                let cm = store.userProfile.heightUnit.toCm(val)
                                let converted = newUnit.fromCm(cm)
                                height = String(format: "%.1f", converted)
                            }
                            store.userProfile.heightUnit = newUnit
                        }
                    )) {
                        ForEach(HeightUnit.allCases, id: \.self) { Text($0.label).tag($0) }
                    }.pickerStyle(.segmented)
                }
                Section("Location") {
                    TextField("City", text: $city)
                    TextField("Country", text: $country)
                    TextField("Postcode", text: $postcode)
                }
                Section("Emergency Contact") {
                    TextField("Name", text: $emergencyName)
                    TextField("Phone", text: $emergencyPhone).keyboardType(.phonePad)
                }
                Section {
                    Button { saveProfile() } label: {
                        Label("Save Changes", systemImage: "checkmark.circle.fill").foregroundColor(.brandTeal)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .onAppear(perform: load)
            .alert("Saved!", isPresented: $saved) { Button("OK") { dismiss() } }
        }
    }

    func load() {
        let p = store.userProfile
        name     = p.name; email = p.email; age = p.age; gender = p.gender
        city     = p.city; country = p.country; postcode = p.postcode
        // Display weight/height in user's preferred unit
        let displayWeight = p.weightUnit.fromKg(p.weight)
        let displayHeight = p.heightUnit.fromCm(p.height)
        weight   = String(format: "%.1f", displayWeight)
        height   = String(format: "%.1f", displayHeight)
        emergencyName = p.emergencyName; emergencyPhone = p.emergencyPhone
    }

    func saveProfile() {
        var p = store.userProfile
        p.name = name; p.email = email.lowercased().trimmingCharacters(in: .whitespaces)
        p.age = age; p.gender = gender
        p.city = city; p.country = country; p.postcode = postcode.uppercased()
        // Convert from displayed unit back to kg/cm for storage
        if let w = Double(weight) { p.weight = p.weightUnit.toKg(w) }
        if let h = Double(height) { p.height = p.heightUnit.toCm(h) }
        p.emergencyName = emergencyName; p.emergencyPhone = emergencyPhone
        store.userProfile = p; store.save(); saved = true
    }
}

// MARK: - Subscription Plans Sheet

struct SubscriptionPlansSheet: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                        subscriptionCard(plan)
                    }
                    Spacer(minLength: 32)
                }
                .padding()
            }
            .navigationTitle("Subscription Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }

    func subscriptionCard(_ plan: SubscriptionPlan) -> some View {
        let isCurrent = store.subscription == plan
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: plan.icon).font(.title2).foregroundColor(plan.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.badge).font(.headline)
                    Text(plan.priceString(currencyCode: store.userProfile.currencyCode)).font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                if isCurrent {
                    Text("Current").font(.caption).fontWeight(.semibold)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(plan.color.opacity(0.15)).foregroundColor(plan.color).cornerRadius(8)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                ForEach(plan.features, id: \.self) { feature in
                    Label(feature, systemImage: "checkmark.circle.fill")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            if !isCurrent && plan != .free {
                Button {
                    store.subscription = plan
                    store.save()
                    dismiss()
                } label: {
                    Text("Upgrade to \(plan.badge)")
                        .font(.subheadline).fontWeight(.semibold)
                        .frame(maxWidth: .infinity).padding()
                        .background(plan.color).foregroundColor(.white).cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: isCurrent ? plan.color.opacity(0.2) : .black.opacity(0.06), radius: 10)
        .overlay(
            isCurrent ? RoundedRectangle(cornerRadius: 20).stroke(plan.color, lineWidth: 2) : nil
        )
    }
}

// MARK: - API Keys Management (CEO Only)

struct APIKeysView: View {
    @Environment(\.dismiss) var dismiss
    @State private var anthropicKey  = ""
    @State private var stripeKey     = ""
    @State private var showAnthKey   = false
    @State private var showStripeKey = false
    @State private var saved         = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Security", systemImage: "lock.shield.fill")
                        .font(.headline).foregroundColor(.brandPurple)
                    Text("API keys are stored in the iOS Keychain, encrypted by the Secure Enclave. They never leave this device.")
                        .font(.caption).foregroundColor(.secondary)
                }
                .listRowBackground(Color.brandPurple.opacity(0.05))
            }

            Section("Anthropic API") {
                HStack {
                    if showAnthKey {
                        TextField("sk-ant-...", text: $anthropicKey)
                            .font(.system(.caption, design: .monospaced))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        Text(anthropicKey.isEmpty ? "Not set" : maskedKey(anthropicKey))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(anthropicKey.isEmpty ? .secondary : .primary)
                    }
                    Spacer()
                    Button { showAnthKey.toggle() } label: {
                        Image(systemName: showAnthKey ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section("Stripe Publishable Key") {
                HStack {
                    if showStripeKey {
                        TextField("pk_test_... or pk_live_...", text: $stripeKey)
                            .font(.system(.caption, design: .monospaced))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        Text(stripeKey.isEmpty ? "Not set" : maskedKey(stripeKey))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(stripeKey.isEmpty ? .secondary : .primary)
                    }
                    Spacer()
                    Button { showStripeKey.toggle() } label: {
                        Image(systemName: showStripeKey ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section {
                Button {
                    if !anthropicKey.isEmpty {
                        _ = KeychainManager.shared.save(anthropicKey, for: .anthropicAPIKey)
                    }
                    if !stripeKey.isEmpty {
                        _ = KeychainManager.shared.save(stripeKey, for: .stripePublishableKey)
                    }
                    saved = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { saved = false }
                } label: {
                    HStack {
                        Spacer()
                        Label(saved ? "Saved!" : "Save to Keychain", systemImage: saved ? "checkmark.circle.fill" : "key.fill")
                            .foregroundColor(saved ? .brandGreen : .brandPurple)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("API Keys & Security")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .onAppear {
            anthropicKey = KeychainManager.shared.get(.anthropicAPIKey) ?? ""
            stripeKey = KeychainManager.shared.get(.stripePublishableKey) ?? ""
        }
    }

    private func maskedKey(_ key: String) -> String {
        guard key.count > 8 else { return String(repeating: "•", count: key.count) }
        return key.prefix(4) + String(repeating: "•", count: key.count - 8) + key.suffix(4)
    }
}

// MARK: - Doctor Application Status View

struct DoctorApplicationStatusView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    var status: String { store.doctorApplicationStatus }
    var verificationStatus: VerificationStatus { store.doctorProfile?.verificationStatus ?? .pending }
    var dp: DoctorProfile? { store.doctorProfile }

    var statusColor: Color {
        verificationStatus.color
    }

    var statusIcon: String {
        switch verificationStatus {
        case .verified:    return "checkmark.seal.fill"
        case .underReview: return "clock.fill"
        case .rejected:    return "xmark.circle.fill"
        case .pending:     return "hourglass"
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // ── Status hero ──
                    VStack(spacing: 16) {
                        Image(systemName: statusIcon)
                            .font(.system(size: 64)).foregroundColor(statusColor)
                        Text(status)
                            .font(.title).fontWeight(.bold)
                        Text(statusSubtitle)
                            .font(.subheadline).foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 32)

                    // ── Checklist ──
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Application Checklist").font(.headline).padding(.horizontal).padding(.bottom, 8)
                        checkRow("Personal Details", done: !(store.userProfile.name.isEmpty))
                        checkRow("Professional Details", done: !(dp?.specialty.isEmpty ?? true))
                        checkRow("GMC Number", done: !(dp?.gmcNumber.isEmpty ?? true))
                        checkRow("Photo ID", done: false) // Phase 2
                        checkRow("DBS Certificate", done: false) // Phase 2
                        checkRow("Indemnity Insurance", done: false) // Phase 2
                        checkRow("Qualification Certificate", done: false) // Phase 2
                    }
                    .padding().background(Color(.secondarySystemBackground)).cornerRadius(16)
                    .padding(.horizontal)

                    // ── Timeline ──
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Timeline").font(.headline)

                        if let req = store.doctorRequests.first(where: { $0.email.lowercased() == store.userProfile.email.lowercased() }) {
                            timelineRow("Submitted", date: req.submittedAt, isActive: true)
                            if req.status == .approved || verificationStatus == .underReview {
                                timelineRow("Under Review", date: req.reviewedAt, isActive: verificationStatus == .underReview)
                            }
                            if req.status == .approved {
                                timelineRow("Approved", date: req.reviewedAt, isActive: true)
                            }
                            if req.status == .rejected {
                                timelineRow("Rejected", date: req.reviewedAt, isActive: true)
                                if !req.reviewNotes.isEmpty {
                                    Text("Reason: \(req.reviewNotes)")
                                        .font(.caption).foregroundColor(.brandCoral)
                                        .padding(.leading, 32)
                                }
                            }
                        } else {
                            Text("No application found").font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .padding().background(Color(.secondarySystemBackground)).cornerRadius(16)
                    .padding(.horizontal)

                    // ── Notice ──
                    HStack(spacing: 10) {
                        Image(systemName: "clock.fill").foregroundColor(.brandAmber)
                        Text("Applications are typically reviewed within 24-48 hours.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    .padding(12).background(Color.brandAmber.opacity(0.06)).cornerRadius(12)
                    .padding(.horizontal)

                    Spacer(minLength: 32)
                }
            }
            .navigationTitle("Application Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    var statusSubtitle: String {
        switch status {
        case "Verified": return "Your doctor profile is live. Patients can find and book you."
        case "Under Review": return "Our team is reviewing your credentials. You'll be notified when approved."
        case "Rejected": return "Your application was not approved. See the reason below."
        default: return "Your application has been submitted and is waiting for review."
        }
    }

    func checkRow(_ label: String, done: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundColor(done ? .brandGreen : .secondary)
            Text(label).font(.subheadline)
                .foregroundColor(done ? .primary : .secondary)
            Spacer()
        }
        .padding(.horizontal).padding(.vertical, 8)
    }

    func timelineRow(_ label: String, date: Date?, isActive: Bool) -> some View {
        HStack(spacing: 12) {
            Circle().fill(isActive ? Color.brandTeal : Color(.systemGray4))
                .frame(width: 10, height: 10)
            Text(label).font(.subheadline).fontWeight(isActive ? .semibold : .regular)
            Spacer()
            if let d = date {
                Text(d.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - CEO Activation Sheet (Hidden, Secret Code Entry)

struct CEOActivationSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var code = ""
    @State private var result: CEOActivationResult = .idle
    @State private var attempts = 0

    enum CEOActivationResult {
        case idle, success, failed, locked
    }

    var isAlreadyActive: Bool { CEOAccessManager.isActivated }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                if isAlreadyActive {
                    // Already activated — show deactivate option
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 64)).foregroundColor(.brandGreen)
                    Text("CEO Access Active").font(.title2).fontWeight(.bold)
                    Text("Administrative features are enabled on this device.")
                        .font(.subheadline).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        CEOAccessManager.deactivate()
                        dismiss()
                    } label: {
                        Text("Deactivate CEO Access")
                            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Color.brandCoral.opacity(0.12))
                            .foregroundColor(.brandCoral).cornerRadius(14)
                    }
                    .padding(.horizontal, 32)

                } else if result == .locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 64)).foregroundColor(.brandCoral)
                    Text("Too Many Attempts").font(.title2).fontWeight(.bold)
                    Text("Access locked. Please try again later.")
                        .font(.subheadline).foregroundColor(.secondary)

                } else {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 64)).foregroundColor(.brandPurple)
                    Text("Administrator Access").font(.title2).fontWeight(.bold)
                    Text("Enter the activation code to enable CEO features.")
                        .font(.subheadline).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    TextField("Activation Code", text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .textContentType(.oneTimeCode)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 32)

                    if result == .failed {
                        Text("Invalid code. \(3 - attempts) attempts remaining.")
                            .font(.caption).foregroundColor(.brandCoral)
                    }

                    Button {
                        if CEOAccessManager.activate(code: code) {
                            result = .success
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
                        } else {
                            attempts += 1
                            if attempts >= 3 {
                                result = .locked
                            } else {
                                result = .failed
                                code = ""
                            }
                        }
                    } label: {
                        Text("Activate")
                            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(code.count >= 4 ? Color.brandTeal : Color(.systemGray4))
                            .foregroundColor(.white).cornerRadius(14)
                    }
                    .disabled(code.count < 4)
                    .padding(.horizontal, 32)

                    if result == .success {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.brandGreen)
                            Text("CEO access activated").foregroundColor(.brandGreen).fontWeight(.medium)
                        }
                    }
                }

                Spacer()
            }
            .navigationTitle("Access Control")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
