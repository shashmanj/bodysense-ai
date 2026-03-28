//
//  ProfileView.swift
//  body sense ai
//
//  Profile for both patients (medical records, photo, settings) and doctors (same + doctor profile view).
//

import SwiftUI
import PhotosUI
import StoreKit
import PDFKit
import UniformTypeIdentifiers

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

// MARK: - Settings Icon Helper (Apple Settings 29x29 standard)

private struct SettingsIcon: View {
    let systemName: String
    let color: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 15))
            .foregroundColor(.white)
            .frame(width: 29, height: 29)
            .background(color)
            .cornerRadius(7)
    }
}

// MARK: - Patient Profile View

struct PatientProfileView: View {
    @Environment(HealthStore.self) var store
    @State private var showEdit           = false
    @State private var showRecords        = false
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
    @State private var showDoctorRegistration = false
    @State private var showDietaryPreferences = false
    @State private var ceoTapCount        = 0
    @AppStorage("biometricLockEnabled") private var biometricLockEnabled = false
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue
    @State private var pickerItem         : PhotosPickerItem? = nil

    var body: some View {
        NavigationStack {
            List {
                profileHeaderSection
                accountSection
                dietNutritionSection
                aiSection
                healthDataSection
                devicesSection
                privacySection
                supportSection
                ceoSection
                accountActionsSection
                versionFooterSection
            }
            .listStyle(.insetGrouped)
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
        .sheet(isPresented: $showRecords) { MyDocumentsView() }
        .sheet(isPresented: $showDevices) { ManageDevicesView() }
        .sheet(isPresented: $showGiftCode) { GiftCodeView() }
        .sheet(isPresented: $showSubPlans) { SubscriptionPlansSheet() }
        .sheet(isPresented: $showSupport) { CustomerCareView() }
        .sheet(isPresented: $showNotifSettings) { NotificationsSettingsView() }
        .sheet(isPresented: $showFamilySharing) { FamilySharingView() }
        .sheet(isPresented: $showAISettings) { AIAgentSettingsView() }
        .sheet(isPresented: $showPrivacyData) { PrivacySettingsView() }
        .sheet(isPresented: $showCEODashboard) { NavigationStack { CEODashboardView() } }
        .sheet(isPresented: $showDoctorApproval) { NavigationStack { DoctorApprovalView() } }
        .sheet(isPresented: $showAPIKeys) { NavigationStack { APIKeysView() } }
        .sheet(isPresented: $showLaunchChecklist) { NavigationStack { LaunchChecklistView() } }
        .sheet(isPresented: $showAgentTeam) { NavigationStack { AgentTeamView() } }
        .sheet(isPresented: $showCEOCodeEntry) { CEOActivationSheet() }
        .sheet(isPresented: $showDoctorRegistration) {
            DoctorRegistrationView(
                onBack: { showDoctorRegistration = false },
                onDone: { showDoctorRegistration = false }
            )
        }
        .onChange(of: pickerItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    store.userProfile.profilePhotoData = data
                    store.save()
                }
            }
        }
    }

    // MARK: - Extracted List Sections

    private var profileHeaderSection: some View {
        Section {
            profileHeaderRow
        }
    }

    private var accountSection: some View {
        Section("Account") {
            Button { showEdit = true } label: {
                Label { Text("Edit Profile") } icon: { SettingsIcon(systemName: "person.fill", color: .brandPurple) }
                    .foregroundColor(.primary)
            }
            Button { showSubPlans = true } label: {
                Label { Text("Subscription & Plans") } icon: { SettingsIcon(systemName: "crown.fill", color: .brandAmber) }
                    .foregroundColor(.primary)
            }
            Button { showGiftCode = true } label: {
                Label { Text("Gift Codes") } icon: { SettingsIcon(systemName: "gift.fill", color: .brandGreen) }
                    .foregroundColor(.primary)
            }
            if !store.isDoctor {
                Button { showDoctorRegistration = true } label: {
                    Label {
                        Text("Register as a Verified Doctor")
                    } icon: {
                        SettingsIcon(systemName: "stethoscope", color: Color(hex: "#00B4D8"))
                    }
                    .foregroundColor(.primary)
                }
            }
        }
    }

    private var dietNutritionSection: some View {
        Section("Diet & Nutrition") {
            Button { showDietaryPreferences = true } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dietary Preferences")
                        let diet = store.userProfile.dietaryProfile
                        Text(diet.isConfigured ? diet.base.rawValue : "Not configured")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } icon: {
                    SettingsIcon(systemName: "leaf.fill", color: .brandGreen)
                }
                .foregroundColor(.primary)
            }
        }
        .sheet(isPresented: $showDietaryPreferences) {
            DietaryPreferencesView()
                .environment(store)
        }
    }

    private var aiSection: some View {
        Section("AI & Intelligence") {
            Button { showAISettings = true } label: {
                Label { Text("AI Agent Settings") } icon: { SettingsIcon(systemName: "brain", color: Color(hex: "#6C63FF")) }
                    .foregroundColor(.primary)
            }
            Toggle(isOn: Binding(
                get: { OnDeviceAIManager.shared.preferOnDevice },
                set: { OnDeviceAIManager.shared.preferOnDevice = $0 }
            )) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("On-Device AI")
                        Text(OnDeviceAIManager.shared.isAvailable
                             ? "Process AI privately on your device"
                             : "Not supported -- using cloud AI")
                            .font(.caption).foregroundColor(.secondary)
                    }
                } icon: { SettingsIcon(systemName: "cpu.fill", color: .brandPurple) }
            }
            .tint(.brandGreen)
            .disabled(!OnDeviceAIManager.shared.isAvailable)
        }
    }

    private var healthDataSection: some View {
        Section("Health & Data") {
            Toggle(isOn: Binding(
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
            )) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Health Sync")
                        Text("Auto-sync steps, calories, SpO2")
                            .font(.caption).foregroundColor(.secondary)
                    }
                } icon: { SettingsIcon(systemName: "heart.fill", color: .red) }
            }
            .tint(.brandGreen)

            cloudSyncRow

            LabeledContent {
                Picker("", selection: Binding(
                    get: { store.userProfile.weightUnit },
                    set: { store.userProfile.weightUnit = $0; store.save() }
                )) {
                    ForEach(WeightUnit.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                .pickerStyle(.menu).tint(.secondary)
            } label: {
                Label { Text("Weight Unit") } icon: { SettingsIcon(systemName: "scalemass.fill", color: .brandAmber) }
            }

            LabeledContent {
                Picker("", selection: Binding(
                    get: { store.userProfile.heightUnit },
                    set: { store.userProfile.heightUnit = $0; store.save() }
                )) {
                    ForEach(HeightUnit.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                .pickerStyle(.menu).tint(.secondary)
            } label: {
                Label { Text("Height Unit") } icon: { SettingsIcon(systemName: "ruler.fill", color: .brandTeal) }
            }

            Button { showRecords = true } label: {
                Label { Text("My Documents") } icon: { SettingsIcon(systemName: "folder.fill", color: .brandCoral) }
                    .foregroundColor(.primary)
            }
        }
    }

    private var devicesSection: some View {
        Section("Devices") {
            Button { showDevices = true } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Devices & Ring")
                        Text("BodySense Ring, Apple Watch & more")
                            .font(.caption).foregroundColor(.secondary)
                    }
                } icon: { SettingsIcon(systemName: "applewatch.and.arrow.forward", color: .brandPurple) }
                    .foregroundColor(.primary)
            }
        }
    }

    private var privacySection: some View {
        Section("Privacy & Security") {
            Button { showPrivacyData = true } label: {
                Label { Text("Privacy & Data") } icon: { SettingsIcon(systemName: "hand.raised.fill", color: .blue) }
                    .foregroundColor(.primary)
            }
            Button { showNotifSettings = true } label: {
                Label { Text("Notifications") } icon: { SettingsIcon(systemName: "bell.badge.fill", color: .brandCoral) }
                    .foregroundColor(.primary)
            }
            Toggle(isOn: $biometricLockEnabled) {
                Label { Text("Biometric Lock") } icon: { SettingsIcon(systemName: "faceid", color: .brandPurple) }
            }
            .tint(.brandGreen)
            Toggle(isOn: Binding(
                get: { appearanceMode == AppearanceMode.dark.rawValue },
                set: { appearanceMode = $0 ? AppearanceMode.dark.rawValue : AppearanceMode.system.rawValue }
            )) {
                Label { Text("Dark Mode") } icon: { SettingsIcon(systemName: "moon.fill", color: .indigo) }
            }
            .tint(.brandGreen)
        }
    }

    private var supportSection: some View {
        Section("Support") {
            Button { showSupport = true } label: {
                Label { Text("Help & Support") } icon: { SettingsIcon(systemName: "headphones.circle.fill", color: .brandTeal) }
                    .foregroundColor(.primary)
            }
            Button { showFamilySharing = true } label: {
                Label { Text("Family Sharing") } icon: { SettingsIcon(systemName: "person.3.fill", color: .brandGreen) }
                    .foregroundColor(.primary)
            }
            Link(destination: URL(string: "https://bodysenseai.co.uk")!) {
                Label {
                    HStack {
                        Text("bodysenseai.co.uk").foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right").font(.caption).foregroundColor(.secondary)
                    }
                } icon: { SettingsIcon(systemName: "globe", color: .brandTeal) }
            }
        }
    }

    @ViewBuilder
    private var ceoSection: some View {
        if store.userProfile.isCEO {
            Section {
                Button { showCEODashboard = true } label: {
                    Label { Text("CEO Dashboard") } icon: { SettingsIcon(systemName: "chart.bar.fill", color: .brandAmber) }
                        .foregroundColor(.primary)
                }
                Button { showAgentTeam = true } label: {
                    Label { Text("AI Agent Team") } icon: { SettingsIcon(systemName: "sparkles.rectangle.stack.fill", color: Color(hex: "#E040FB")) }
                        .foregroundColor(.primary)
                }
                Button { showDoctorApproval = true } label: {
                    HStack {
                        Label { Text("Doctor Approvals") } icon: { SettingsIcon(systemName: "checkmark.shield.fill", color: .brandTeal) }
                        Spacer()
                        if !store.pendingDoctorRequests.isEmpty {
                            Text("\(store.pendingDoctorRequests.count) pending")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.brandCoral)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .foregroundColor(.primary)
                }
                Button { showAPIKeys = true } label: {
                    Label { Text("API Keys & Security") } icon: { SettingsIcon(systemName: "key.fill", color: .orange) }
                        .foregroundColor(.primary)
                }
                Button { showLaunchChecklist = true } label: {
                    Label { Text("Launch Checklist") } icon: { SettingsIcon(systemName: "checklist", color: .brandGreen) }
                        .foregroundColor(.primary)
                }
            } header: {
                Label("CEO Controls", systemImage: "crown.fill")
                    .foregroundColor(.brandAmber)
            }
        }
    }

    private var accountActionsSection: some View {
        Section {
            Button {
                if let url = URL(string: "https://iforgot.apple.com") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Account Recovery")
                        Text("Managed by your Apple ID").font(.caption).foregroundColor(.secondary)
                    }
                } icon: { SettingsIcon(systemName: "person.badge.key.fill", color: .blue) }
                    .foregroundColor(.primary)
            }
            Button(role: .destructive) {
                FirebaseAuthManager.shared.signOut()
                AuthService.shared.signOut()
                UserDefaults.standard.set(false, forKey: "onboardingDone")
                store.userProfile = UserProfile()
                store.save()
            } label: {
                Label { Text("Sign Out") } icon: { SettingsIcon(systemName: "rectangle.portrait.and.arrow.right", color: .red) }
            }
        }
    }

    private var versionFooterSection: some View {
        Section {
        } footer: {
            Button {
                ceoTapCount += 1
                if ceoTapCount >= 5 {
                    ceoTapCount = 0
                    showCEOCodeEntry = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    ceoTapCount = 0
                }
            } label: {
                Text("BodySense AI v1.0 (Build 1)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Profile Header Row

    private var profileHeaderRow: some View {
        HStack(spacing: 14) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    if let photoData = store.userProfile.profilePhotoData,
                       let uiImg = UIImage(data: photoData) {
                        Image(uiImage: uiImg)
                            .resizable().scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(LinearGradient(colors: [.brandPurple, .brandTeal], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Text(store.userProfile.anonymousAlias.prefix(2).uppercased())
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    Image(systemName: "camera.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.brandPurple)
                        .background(Color(.systemBackground).clipShape(Circle()))
                        .offset(x: 2, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(store.userProfile.name)
                    .font(.title3).fontWeight(.semibold)
                if !store.userProfile.email.isEmpty {
                    Text(store.userProfile.email)
                        .font(.caption).foregroundColor(.secondary)
                }
                subscriptionPill
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var subscriptionPill: some View {
        let plan = store.subscription
        return Text(plan.badge)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(plan.color.opacity(0.12))
            .foregroundColor(plan.color)
            .clipShape(Capsule())
    }

    private var cloudSyncRow: some View {
        let sync = CloudSyncService.shared
        return Button {
            Task {
                await CloudSyncService.shared.syncToCloud(store: store)
            }
        } label: {
            HStack {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("iCloud Sync").foregroundColor(.primary)
                        if let progress = sync.syncProgress {
                            Text(progress).font(.caption).foregroundColor(.brandPurple)
                        } else if let lastSync = sync.lastSyncDate {
                            Text("Last synced: \(lastSync.formatted(.relative(presentation: .named)))")
                                .font(.caption).foregroundColor(.secondary)
                        } else {
                            Text(sync.syncState.label)
                                .font(.caption).foregroundColor(sync.syncState.isError ? .red : .secondary)
                        }
                    }
                } icon: { SettingsIcon(systemName: sync.syncState.icon, color: .blue) }
                Spacer()
                if sync.isSyncing {
                    ProgressView().controlSize(.small)
                } else {
                    Text(sync.syncState == .upToDate ? "SYNCED" : "SYNC")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(sync.syncState == .upToDate
                                    ? Color.green.opacity(0.12)
                                    : Color.blue.opacity(0.12))
                        .foregroundColor(sync.syncState == .upToDate ? .green : .blue)
                        .clipShape(Capsule())
                }
            }
        }
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
        NavigationStack {
            List {
                // ── Doctor Profile Header ──
                Section {
                    doctorProfileHeaderRow
                }

                // ── Doctor Mode ──
                doctorModeSection

                // ── Account ──
                Section("Account") {
                    Button { showEdit = true } label: {
                        Label { Text("Edit Profile") } icon: { SettingsIcon(systemName: "person.fill", color: .brandPurple) }
                            .foregroundColor(.primary)
                    }
                    Button { showSubPlans = true } label: {
                        Label { Text("Subscription & Plans") } icon: { SettingsIcon(systemName: "crown.fill", color: .brandAmber) }
                            .foregroundColor(.primary)
                    }
                    Button { showGiftCode = true } label: {
                        Label { Text("Gift Codes") } icon: { SettingsIcon(systemName: "gift.fill", color: .brandGreen) }
                            .foregroundColor(.primary)
                    }
                    Button { showRecords = true } label: {
                        Label { Text("My Documents") } icon: { SettingsIcon(systemName: "folder.fill", color: .brandTeal) }
                            .foregroundColor(.primary)
                    }
                }

                // ── Devices ──
                Section("Devices") {
                    Button { showDevices = true } label: {
                        Label { Text("Manage Devices") } icon: { SettingsIcon(systemName: "applewatch", color: .brandTeal) }
                            .foregroundColor(.primary)
                    }
                }

                // ── Support ──
                Section("Support") {
                    Button { showSupport = true } label: {
                        Label { Text("Help & Support") } icon: { SettingsIcon(systemName: "headphones.circle.fill", color: .brandTeal) }
                            .foregroundColor(.primary)
                    }
                }

                // ── Version ──
                Section {
                } footer: {
                    Text("BodySense AI v1.0 (Build 1)")
                        .font(.footnote).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { showEdit = true } label: { Image(systemName: "pencil") }
                }
            }
        }
        .sheet(isPresented: $showEdit) { EditProfileSheet() }
        .sheet(isPresented: $showRecords) { MyDocumentsView() }
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

    // MARK: - Doctor Mode Section

    @ViewBuilder
    private var doctorModeSection: some View {
        if store.isDoctorApproved {
            Section {
                Toggle(isOn: $doctorMode) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Doctor Mode")
                            Text(doctorMode ? "Home tab shows your doctor dashboard" : "Home tab shows your health dashboard")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    } icon: { SettingsIcon(systemName: "stethoscope", color: .brandTeal) }
                }
                .tint(.brandTeal)
            } footer: {
                Text("You have full access to all BodySense AI health features as a user. Toggle Doctor Mode to manage appointments and patients.")
            }
        } else if store.isDoctor {
            Section {
                Button { showAppStatus = true } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Application \(store.doctorApplicationStatus)")
                            Text("Tap to view your application status")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    } icon: { SettingsIcon(systemName: "clock.badge.exclamationmark.fill", color: .brandAmber) }
                        .foregroundColor(.primary)
                }
            }
        }
    }

    // MARK: - Doctor Profile Header Row

    private var doctorProfileHeaderRow: some View {
        HStack(spacing: 14) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    if let photoData = store.userProfile.profilePhotoData,
                       let uiImg = UIImage(data: photoData) {
                        Image(uiImage: uiImg).resizable().scaledToFill()
                            .frame(width: 64, height: 64).clipShape(Circle())
                    } else {
                        Circle()
                            .fill(LinearGradient(colors: [Color(hex: "#00BFA5"), .brandPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 64, height: 64)
                            .overlay(Text(String(store.userProfile.name.prefix(2)).uppercased())
                                .font(.system(size: 22, weight: .bold)).foregroundColor(.white))
                    }
                    Image(systemName: "camera.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.brandTeal)
                        .background(Color(.systemBackground).clipShape(Circle()))
                        .offset(x: 2, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(store.userProfile.name)
                        .font(.title3).fontWeight(.semibold)
                    if store.userProfile.doctorProfile?.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.brandTeal).font(.subheadline)
                    }
                }
                Text(store.userProfile.doctorProfile?.specialty ?? "Doctor")
                    .font(.caption).foregroundColor(.secondary)
                if !store.userProfile.city.isEmpty {
                    Text("\(store.userProfile.city), \(store.userProfile.country)")
                        .font(.caption).foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}


// MARK: - Manage Devices View (standalone, not linked to shop)

struct ManageDevicesView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var showRingPairing = false

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

    var ringManager: BodySenseRingManager { BodySenseRingManager.shared }

    var body: some View {
        NavigationStack {
            List {
                // ── 0. BodySense Ring BLE section (if connected via BLE) ──
                if ringManager.connectionState == .connected {
                    Section {
                        RingStatusCard(ringManager: ringManager)
                    } header: {
                        Label("BodySense Ring", systemImage: "circle.fill")
                    }
                }

                // ── 1. Active, connected devices ──
                Section("Connected") {
                    if connectedDevices.isEmpty && ringManager.connectionState != .connected {
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
                                    if device.type == .bodySenseRing {
                                        ringManager.attemptAutoReconnect()
                                    }
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
            .sheet(isPresented: $showRingPairing) {
                RingPairingView()
            }
        }
    }

    @ViewBuilder
    func addDeviceRow(type: WearableType) -> some View {
        let row = Button {
            if type == .bodySenseRing {
                showRingPairing = true
            } else {
                addDevice(type: type)
            }
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
                if type == .bodySenseRing && store.subscription < .premium {
                    Text("PREMIUM").font(.caption2).fontWeight(.bold)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.brandPurple.opacity(0.12))
                        .foregroundColor(.brandPurple)
                        .cornerRadius(100)
                } else {
                    Image(systemName: "plus.circle.fill").foregroundColor(.brandTeal)
                }
            }
        }
        // BodySense Ring pairing requires Premium subscription
        if type == .bodySenseRing {
            row.requiresSubscription(.premium, store: store)
        } else {
            row
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

// MARK: - Ring BLE Pairing View

struct RingPairingView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    var ringManager: BodySenseRingManager { BodySenseRingManager.shared }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // ── Status header ──
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(ringManager.connectionState.color.opacity(0.12))
                                .frame(width: 80, height: 80)
                            Image(systemName: ringManager.connectionState.icon)
                                .font(.system(size: 32))
                                .foregroundColor(ringManager.connectionState.color)
                        }

                        Text(ringManager.connectionState.label)
                            .font(.headline)
                            .foregroundColor(ringManager.connectionState.color)

                        if let error = ringManager.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.brandCoral)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top)

                    // ── Scan button ──
                    if ringManager.connectionState == .disconnected || ringManager.connectionState == .scanning {
                        Button {
                            if ringManager.isScanning {
                                ringManager.stopScanning()
                            } else {
                                ringManager.startScanning()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if ringManager.isScanning {
                                    ProgressView()
                                        .tint(.white)
                                }
                                Text(ringManager.isScanning ? "Stop Scanning" : "Scan for Ring")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(ringManager.isScanning ? Color(.systemGray3) : Color.brandPurple)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal)
                    }

                    // ── Discovered rings ──
                    if !ringManager.discoveredRings.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nearby Rings")
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)

                            ForEach(ringManager.discoveredRings) { ring in
                                Button {
                                    ringManager.connect(to: ring)
                                } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: "circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.brandPurple)
                                            .frame(width: 44, height: 44)
                                            .background(Color.brandPurple.opacity(0.12))
                                            .cornerRadius(12)

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(ring.name)
                                                .font(.subheadline).fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            Text(ring.signalQuality)
                                                .font(.caption).foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        // Signal strength indicator
                                        HStack(spacing: 2) {
                                            Image(systemName: ring.signalIcon)
                                                .font(.caption)
                                                .foregroundColor(ring.signalColor)
                                            Text("\(ring.rssi) dBm")
                                                .font(.caption2).foregroundColor(.secondary)
                                        }

                                        Image(systemName: "chevron.right")
                                            .font(.caption).foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(16)
                                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // ── Connecting progress ──
                    if ringManager.connectionState == .connecting || ringManager.connectionState == .reconnecting {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Pairing with your Ring...")
                                .font(.subheadline).foregroundColor(.secondary)
                            Text("Keep your Ring close to your phone.")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        .padding(.vertical, 30)
                    }

                    // ── Connected ring info ──
                    if ringManager.connectionState == .connected {
                        RingStatusCard(ringManager: ringManager)
                            .padding(.horizontal)

                        // Live readings
                        ringLiveReadings
                            .padding(.horizontal)

                        // Disconnect button
                        Button(role: .destructive) {
                            ringManager.disconnect()
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Disconnect Ring")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.brandCoral.opacity(0.12))
                            .foregroundColor(.brandCoral)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal)
                    }

                    // ── Instructions ──
                    if ringManager.connectionState == .disconnected && ringManager.discoveredRings.isEmpty && !ringManager.isScanning {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("How to pair your BodySense Ring")
                                .font(.subheadline).fontWeight(.semibold)

                            instructionRow(step: "1", text: "Ensure your Ring is charged and nearby")
                            instructionRow(step: "2", text: "Tap \"Scan for Ring\" above")
                            instructionRow(step: "3", text: "Select your Ring from the list")
                            instructionRow(step: "4", text: "Wait for pairing to complete")
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("BodySense Ring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        ringManager.stopScanning()
                        dismiss()
                    }
                }
            }
            .onDisappear {
                if ringManager.isScanning {
                    ringManager.stopScanning()
                }
            }
        }
    }

    // MARK: - Live Readings Grid

    private var ringLiveReadings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live Readings")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ringMetricCard(
                    icon: "heart.fill",
                    label: "Heart Rate",
                    value: ringManager.latestHeartRate > 0 ? "\(ringManager.latestHeartRate)" : "--",
                    unit: "bpm",
                    color: .brandCoral
                )
                ringMetricCard(
                    icon: "lungs.fill",
                    label: "SpO2",
                    value: ringManager.latestSpO2 > 0 ? "\(ringManager.latestSpO2)" : "--",
                    unit: "%",
                    color: .brandTeal
                )
                ringMetricCard(
                    icon: "thermometer.medium",
                    label: "Temperature",
                    value: ringManager.latestTemperature > 0 ? String(format: "%.1f", ringManager.latestTemperature) : "--",
                    unit: "C",
                    color: .brandAmber
                )
                ringMetricCard(
                    icon: "figure.walk",
                    label: "Steps",
                    value: ringManager.latestSteps > 0 ? "\(ringManager.latestSteps)" : "--",
                    unit: "today",
                    color: .brandGreen
                )
                ringMetricCard(
                    icon: ringManager.latestSleepState.icon,
                    label: "Sleep",
                    value: ringManager.latestSleepState.label,
                    unit: "",
                    color: ringManager.latestSleepState.color
                )
                ringMetricCard(
                    icon: "battery.75",
                    label: "Battery",
                    value: ringManager.batteryLevel > 0 ? "\(ringManager.batteryLevel)" : "--",
                    unit: "%",
                    color: ringManager.batteryLevel > 20 ? .brandGreen : .brandCoral
                )
            }
        }
    }

    private func ringMetricCard(icon: String, label: String, value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption).foregroundColor(color)
                Text(label)
                    .font(.caption2).foregroundColor(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2).fontWeight(.bold).foregroundColor(.primary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private func instructionRow(step: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(step)
                .font(.caption).fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.brandPurple)
                .cornerRadius(12)
            Text(text)
                .font(.subheadline).foregroundColor(.primary)
        }
    }
}

// MARK: - Ring Status Card (reusable for ManageDevicesView & PairingView)

struct RingStatusCard: View {
    var ringManager: BodySenseRingManager
    @Environment(HealthStore.self) var store

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                // Ring icon
                ZStack {
                    Circle()
                        .fill(Color.brandPurple.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: "circle.fill")
                        .font(.title2)
                        .foregroundColor(.brandPurple)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(ringManager.connectedRing?.name ?? "BodySense Ring")
                            .font(.subheadline).fontWeight(.semibold)
                        // Connection status pill
                        Text("Connected")
                            .font(.caption2).fontWeight(.medium)
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(Color.brandGreen.opacity(0.12))
                            .foregroundColor(.brandGreen)
                            .cornerRadius(100)
                    }

                    HStack(spacing: 12) {
                        // Battery
                        HStack(spacing: 3) {
                            Image(systemName: batteryIcon)
                                .font(.caption2)
                            Text("\(ringManager.batteryLevel)%")
                                .font(.caption)
                        }
                        .foregroundColor(ringManager.batteryLevel > 20 ? .brandGreen : .brandCoral)

                        // Firmware
                        if !ringManager.firmwareVersion.isEmpty {
                            Text("v\(ringManager.firmwareVersion)")
                                .font(.caption2).foregroundColor(.secondary)
                        }
                    }

                    if let lastSync = ringManager.connectedRing?.lastSyncDate {
                        Text("Last sync: \(lastSync.formatted(.relative(presentation: .numeric)))")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            // Sync Now button
            Button {
                ringManager.syncDataToHealthStore(store)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Sync Now")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.brandTeal.opacity(0.12))
                .foregroundColor(.brandTeal)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private var batteryIcon: String {
        let level = ringManager.batteryLevel
        if level > 75      { return "battery.100" }
        else if level > 50 { return "battery.75" }
        else if level > 25 { return "battery.50" }
        else if level > 10 { return "battery.25" }
        else               { return "battery.0" }
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
        NavigationStack {
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
        NavigationStack {
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
        // Validate name — must have at least 2 chars and contain a letter
        guard InputValidator.isValidName(name) else { return }
        // Validate email if provided
        let cleanEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanEmail.isEmpty && !InputValidator.isValidEmail(cleanEmail) { return }

        var p = store.userProfile
        p.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        p.email = cleanEmail
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
        NavigationStack {
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
                    Task {
                        let storeKit = StoreKitManager.shared
                        let product: StoreKit.Product?
                        switch plan {
                        case .pro:     product = storeKit.proMonthly
                        case .premium: product = storeKit.premiumMonthly
                        case .free:    product = nil
                        }
                        if let product {
                            let success = await storeKit.purchase(product)
                            if success {
                                storeKit.syncToHealthStore(store)
                                dismiss()
                            }
                        } else {
                            // StoreKit products not loaded — reload and retry
                            await storeKit.loadProducts()
                            let retryProduct: StoreKit.Product?
                            switch plan {
                            case .pro:     retryProduct = storeKit.proMonthly
                            case .premium: retryProduct = storeKit.premiumMonthly
                            case .free:    retryProduct = nil
                            }
                            if let retryProduct {
                                let success = await storeKit.purchase(retryProduct)
                                if success {
                                    storeKit.syncToHealthStore(store)
                                    dismiss()
                                }
                            }
                            // If still nil, show error — NEVER grant without payment
                        }
                    }
                } label: {
                    Text("Upgrade to \(plan.badge)")
                        .font(.subheadline).fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(plan.color).foregroundColor(.white).cornerRadius(14)
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
        NavigationStack {
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
        NavigationStack {
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

// MARK: - My Documents View

struct MyDocumentsView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var showAddSheet = false
    @State private var showPhotoPicker = false
    @State private var showFileImporter = false
    @State private var photosPickerItem: PhotosPickerItem? = nil
    @State private var selectedDocument: MedicalDocument? = nil
    @State private var editingDocument: MedicalDocument? = nil

    private var groupedDocuments: [(MedicalDocument.DocumentCategory, [MedicalDocument])] {
        let grouped = Dictionary(grouping: store.medicalDocuments) { $0.category }
        return MedicalDocument.DocumentCategory.allCases.compactMap { cat in
            guard let docs = grouped[cat], !docs.isEmpty else { return nil }
            return (cat, docs.sorted { $0.dateAdded > $1.dateAdded })
        }
    }

    var body: some View {
        Group {
            if store.medicalDocuments.isEmpty {
                emptyState
            } else {
                documentList
            }
        }
        .navigationTitle("My Documents")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
            ToolbarItem(placement: .primaryAction) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .confirmationDialog("Add Document", isPresented: $showAddSheet) {
            Button("Photo Library") { showPhotoPicker = true }
            Button("Choose PDF File") { showFileImporter = true }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Upload a medical document")
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photosPickerItem, matching: .any(of: [.images]))
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.pdf], allowsMultipleSelection: false) { result in
            handleFileImport(result)
        }
        .onChange(of: photosPickerItem) { _, item in
            Task { await handlePhotoSelection(item) }
        }
        .fullScreenCover(item: $selectedDocument) { doc in
            DocumentFullScreenViewer(document: doc)
        }
        .sheet(item: $editingDocument) { doc in
            NavigationStack {
                DocumentEditView(document: doc) { updated in
                    if let idx = store.medicalDocuments.firstIndex(where: { $0.id == updated.id }) {
                        store.medicalDocuments[idx] = updated
                        store.save()
                    }
                    editingDocument = nil
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No documents yet")
                .font(.title3).fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text("Upload medical reports from chat or tap + to add.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                showAddSheet = true
            } label: {
                Text("Add Document")
                    .font(.body).fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.brandPurple)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var documentList: some View {
        List {
            ForEach(groupedDocuments, id: \.0) { category, docs in
                Section {
                    ForEach(docs) { doc in
                        Button {
                            selectedDocument = doc
                        } label: {
                            documentRow(doc)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteDocument(doc)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                editingDocument = doc
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.brandPurple)
                        }
                        .contextMenu {
                            Button {
                                selectedDocument = doc
                            } label: {
                                Label("View", systemImage: "eye")
                            }
                            Button {
                                editingDocument = doc
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                deleteDocument(doc)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .foregroundColor(category.color)
                            .font(.caption)
                        Text(category.rawValue)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func documentRow(_ doc: MedicalDocument) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(doc.category.color.opacity(0.12))
                    .frame(width: 29, height: 29)
                Image(systemName: doc.category.icon)
                    .font(.system(size: 13))
                    .foregroundColor(doc.category.color)
            }
            if let thumbData = doc.thumbnailData, let img = UIImage(data: thumbData) {
                Image(uiImage: img)
                    .resizable().scaledToFill()
                    .frame(width: 40, height: 40)
                    .cornerRadius(6)
                    .clipped()
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(doc.name)
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(doc.dateAdded.formatted(.dateTime.day().month().year()))
                        .font(.caption2).foregroundColor(.secondary)
                    if doc.sourceChat {
                        Text("From Chat")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.brandPurple)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.brandPurple.opacity(0.1))
                            .cornerRadius(100)
                    }
                    Text(doc.fileType == .pdf ? "PDF" : "Image")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color(.systemGray5))
                        .cornerRadius(100)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption).foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func deleteDocument(_ doc: MedicalDocument) {
        store.medicalDocuments.removeAll { $0.id == doc.id }
        store.save()
    }

    private func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            let thumbnail = generateDocThumbnail(from: data, isImage: true)
            let doc = MedicalDocument(
                name: "Photo \(Date().formatted(.dateTime.month().day().hour().minute()))",
                category: .other,
                dateAdded: Date(),
                fileData: data,
                thumbnailData: thumbnail,
                notes: "",
                sourceChat: false,
                fileType: .image
            )
            await MainActor.run {
                store.medicalDocuments.append(doc)
                store.save()
                editingDocument = doc
            }
        }
        await MainActor.run { photosPickerItem = nil }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            if let data = try? Data(contentsOf: url) {
                let thumbnail = generateDocThumbnail(from: data, isImage: false)
                let fileName = url.deletingPathExtension().lastPathComponent
                let doc = MedicalDocument(
                    name: fileName,
                    category: .other,
                    dateAdded: Date(),
                    fileData: data,
                    thumbnailData: thumbnail,
                    notes: "",
                    sourceChat: false,
                    fileType: .pdf
                )
                store.medicalDocuments.append(doc)
                store.save()
                editingDocument = doc
            }
        case .failure:
            break
        }
    }

    private func generateDocThumbnail(from data: Data, isImage: Bool) -> Data? {
        if isImage, let img = UIImage(data: data) {
            let size = CGSize(width: 120, height: 120)
            let renderer = UIGraphicsImageRenderer(size: size)
            let thumb = renderer.image { _ in
                img.draw(in: CGRect(origin: .zero, size: size))
            }
            return thumb.jpegData(compressionQuality: 0.6)
        } else if !isImage {
            if let pdfDoc = PDFDocument(data: data), let page = pdfDoc.page(at: 0) {
                let bounds = page.bounds(for: .mediaBox)
                let scale: CGFloat = 120.0 / max(bounds.width, bounds.height)
                let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
                let renderer = UIGraphicsImageRenderer(size: size)
                let thumb = renderer.image { ctx in
                    ctx.cgContext.setFillColor(UIColor.white.cgColor)
                    ctx.cgContext.fill(CGRect(origin: .zero, size: size))
                    ctx.cgContext.scaleBy(x: scale, y: scale)
                    page.draw(with: .mediaBox, to: ctx.cgContext)
                }
                return thumb.jpegData(compressionQuality: 0.6)
            }
        }
        return nil
    }
}

// MARK: - Document Edit View

struct DocumentEditView: View {
    @State var document: MedicalDocument
    var onSave: (MedicalDocument) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Section("Document Name") {
                TextField("Name", text: $document.name)
            }
            Section("Category") {
                Picker("Category", selection: $document.category) {
                    ForEach(MedicalDocument.DocumentCategory.allCases, id: \.self) { cat in
                        Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
            Section("Notes") {
                TextEditor(text: $document.notes)
                    .frame(minHeight: 80)
            }
            Section {
                HStack {
                    Text("Type"); Spacer()
                    Text(document.fileType == .pdf ? "PDF" : "Image").foregroundColor(.secondary)
                }
                HStack {
                    Text("Date Added"); Spacer()
                    Text(document.dateAdded.formatted(.dateTime.day().month().year())).foregroundColor(.secondary)
                }
                if document.sourceChat {
                    HStack {
                        Text("Source"); Spacer()
                        Text("Uploaded via Chat").foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Edit Document")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { onSave(document) }
                    .fontWeight(.semibold)
                    .disabled(document.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
