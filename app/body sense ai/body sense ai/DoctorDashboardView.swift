//
//  DoctorDashboardView.swift
//  body sense ai
//
//  Doctor-facing dashboard with full profile, GMC credentials, consultation pricing, availability, reviews.
//  Accessed from MainTabView when store.isDoctor == true.
//

import SwiftUI
import SafariServices

// MARK: - Doctor Dashboard Root

struct DoctorDashboardView: View {
    @Environment(HealthStore.self) var store
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            DoctorHomeView()
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }
                .tag(0)
            DoctorAppointmentListView()
                .tabItem { Label("Appointments", systemImage: "calendar") }
                .tag(1)
            DoctorEarningsView()
                .tabItem { Label("Earnings", systemImage: "sterling.sign.circle.fill") }
                .tag(2)
            DoctorFullProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.square.fill") }
                .tag(3)
        }
        .tint(Color(hex: "#00BFA5"))
    }
}

// MARK: - Doctor Home

struct DoctorHomeView: View {
    @Environment(HealthStore.self) var store
    @State private var showBecky = false

    var profile: DoctorProfile? { store.userProfile.doctorProfile }

    var todaysAppts: [Appointment] {
        store.appointments.filter { Calendar.current.isDateInToday($0.date) && $0.status == .upcoming }
    }
    var upcomingAppts: [Appointment] {
        store.appointments.filter { $0.status == .upcoming }.sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    welcomeCard
                    statsRow
                    verificationBanner

                    if !todaysAppts.isEmpty {
                        sectionHeader("Today's Appointments (\(todaysAppts.count))")
                        ForEach(todaysAppts) { appt in
                            DoctorApptCard(appointment: appt).padding(.horizontal)
                        }
                    }

                    if !upcomingAppts.isEmpty {
                        sectionHeader("Upcoming (\(upcomingAppts.count))")
                        ForEach(upcomingAppts.prefix(3)) { appt in
                            DoctorApptCard(appointment: appt).padding(.horizontal)
                        }
                    }

                    if todaysAppts.isEmpty && upcomingAppts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 48)).foregroundColor(.brandTeal.opacity(0.4))
                            Text("No appointments today").font(.headline)
                            Text("New bookings from patients will appear here.").font(.subheadline).foregroundColor(.secondary)
                        }
                        .padding(.top, 20)
                    }

                    // Becky AI quick access — GATED behind approval
                    if store.isDoctorApproved {
                        Button { showBecky = true } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "stethoscope.circle.fill")
                                    .font(.title2).foregroundColor(.white)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ask Becky").font(.headline).foregroundColor(.white)
                                    Text("Your AI medical assistant").font(.caption).foregroundColor(.white.opacity(0.8))
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.6))
                            }
                            .padding()
                            .background(LinearGradient(colors: [Color(hex: "#00BFA5"), Color(hex: "#00897B")],
                                                       startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                    } else {
                        // Locked Becky — not yet approved
                        HStack(spacing: 14) {
                            Image(systemName: "lock.fill")
                                .font(.title2).foregroundColor(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Becky AI").font(.headline).foregroundColor(.secondary)
                                Text("Available after your application is approved")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray5))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .navigationTitle("Doctor Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showBecky) {
                BeckyAIView(appointment: nil)
            }
        }
    }

    @ViewBuilder
    var verificationBanner: some View {
        let status = profile?.verificationStatus ?? .pending
        if status != .verified {
            HStack(spacing: 12) {
                Image(systemName: status == .rejected ? "xmark.circle.fill" :
                                  status == .underReview ? "clock.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(status == .rejected ? .brandCoral :
                                     status == .underReview ? .brandAmber : .brandCoral)
                VStack(alignment: .leading, spacing: 2) {
                    Text(status == .rejected ? "Registration Rejected" :
                         status == .underReview ? "Under Review" : "Verification Pending")
                        .font(.subheadline).fontWeight(.semibold)
                    Text(status == .rejected
                         ? "Your registration was not approved. Please contact support@bodysenseai.co.uk."
                         : "Complete your profile and credentials to start receiving patient bookings.")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background((status == .underReview ? Color.brandAmber : Color.brandCoral).opacity(0.1))
            .cornerRadius(14)
            .padding(.horizontal)
        }
    }

    var welcomeCard: some View {
        ZStack(alignment: .leading) {
            LinearGradient(colors: [Color(hex: "#00BFA5"), Color(hex: "#1565C0")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Good \(greetingTime()), Doctor 👋")
                        .font(.headline).foregroundColor(.white)
                    Text(store.userProfile.name)
                        .font(.title2).fontWeight(.bold).foregroundColor(.white)
                    if let p = profile {
                        Text(p.specialty)
                            .font(.subheadline).foregroundColor(.white.opacity(0.8))
                    }
                }
                Spacer()
                Image(systemName: "stethoscope")
                    .font(.system(size: 48)).foregroundColor(.white.opacity(0.25))
            }
            .padding()
        }
        .frame(height: 120).cornerRadius(20).padding(.horizontal)
    }

    var statsRow: some View {
        HStack(spacing: 12) {
            statCard("Today", value: "\(todaysAppts.count)", sub: "appointments", icon: "calendar", color: .brandTeal)
            statCard("Total", value: "\(store.appointments.count)", sub: "all time", icon: "person.2.fill", color: .brandPurple)
            statCard("Earned", value: "£\(Int((store.userProfile.doctorProfile?.doctorEarnings ?? 0)))", sub: "60% share", icon: "sterling.sign", color: .brandAmber)
        }
        .padding(.horizontal)
    }

    func statCard(_ title: String, value: String, sub: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title3).foregroundColor(color)
            Text(value).font(.title2).fontWeight(.bold)
            Text(sub).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(Color(.systemBackground)).cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6)
    }

    func sectionHeader(_ title: String) -> some View {
        HStack { Text(title).font(.headline); Spacer() }.padding(.horizontal)
    }

    func greetingTime() -> String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "morning" }
        if h < 17 { return "afternoon" }
        return "evening"
    }
}

// MARK: - Doctor Appointment Card

struct DoctorApptCard: View {
    @Environment(HealthStore.self) var store
    let appointment: Appointment
    @State private var showCall = false
    @State private var showDocs = false

    var attachmentCount: Int { appointment.attachments.count }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                VStack(spacing: 2) {
                    Text(appointment.date.formatted(date: .omitted, time: .shortened)).font(.headline)
                    Text(appointment.date.formatted(.dateTime.day().month(.abbreviated))).font(.caption2).foregroundColor(.secondary)
                }
                .frame(width: 60)
                Divider().frame(height: 50)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Patient").font(.subheadline).fontWeight(.semibold)
                    Label(appointment.type.rawValue, systemImage: appointment.type.icon).font(.caption).foregroundColor(.secondary)
                    if appointment.isPaid {
                        Label("£\(Int(appointment.feeGBP)) paid", systemImage: "checkmark.circle.fill")
                            .font(.caption2).foregroundColor(.brandGreen)
                    }
                }
                Spacer()
                VStack(spacing: 8) {
                    Text(appointment.status.rawValue).font(.caption2)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(appointment.status.color.opacity(0.15))
                        .foregroundColor(appointment.status.color).cornerRadius(6)
                    if appointment.type == .video && appointment.status == .upcoming {
                        Button { showCall = true } label: {
                            Image(systemName: "video.fill").font(.caption)
                                .padding(8).background(Color.brandTeal).foregroundColor(.white).clipShape(Circle())
                        }
                    }
                }
            }
            .padding()

            // Attachment badge row
            if attachmentCount > 0 {
                Divider().padding(.horizontal)
                Button { showDocs = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.fill").font(.caption).foregroundColor(.brandPurple)
                        Text("\(attachmentCount) document\(attachmentCount == 1 ? "" : "s") attached")
                            .font(.caption).fontWeight(.medium).foregroundColor(.brandPurple)
                        Spacer()
                        Text("View").font(.caption).fontWeight(.semibold)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color.brandPurple.opacity(0.12))
                            .foregroundColor(.brandPurple).cornerRadius(8)
                    }
                    .padding(.horizontal).padding(.vertical, 10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color(.systemBackground)).cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6)
        .fullScreenCover(isPresented: $showCall) {
            if let doc = store.doctors.first(where: { $0.id == appointment.doctorId }) {
                VideoCallView(
                    session: VideoCallSession(doctor: doc, appointment: appointment,
                                             roomId: appointment.videoRoomId ?? "room_dr",
                                             startTime: Date())
                ) { showCall = false }
            }
        }
        .sheet(isPresented: $showDocs) {
            AppointmentDocumentsView(appointment: appointment)
        }
    }
}

// MARK: - Doctor Appointment List

struct DoctorAppointmentListView: View {
    @Environment(HealthStore.self) var store

    var upcoming: [Appointment] { store.appointments.filter { $0.status == .upcoming }.sorted { $0.date < $1.date } }
    var past: [Appointment]     { store.appointments.filter { $0.status != .upcoming }.sorted { $0.date > $1.date } }

    var body: some View {
        NavigationStack {
            Group {
                if store.appointments.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "calendar.badge.plus").font(.system(size: 56)).foregroundColor(.brandTeal.opacity(0.4))
                        Text("No appointments yet").font(.title3).fontWeight(.semibold)
                        Text("Patients will appear here after booking.").font(.subheadline).foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    List {
                        if !upcoming.isEmpty {
                            Section("Upcoming") {
                                ForEach(upcoming) { appt in
                                    DoctorApptCard(appointment: appt)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                }
                            }
                        }
                        if !past.isEmpty {
                            Section("Past") {
                                ForEach(past) { appt in
                                    DoctorApptCard(appointment: appt)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Appointments")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Doctor Earnings

struct DoctorEarningsView: View {
    @Environment(HealthStore.self) var store

    var profile: DoctorProfile? { store.userProfile.doctorProfile }
    var paidAppts: [Appointment] { store.appointments.filter { $0.isPaid } }
    var totalRevenue: Double { paidAppts.reduce(0) { $0 + $1.feeGBP } }
    var platformCut: Double  { totalRevenue * 0.40 }
    var doctorCut: Double    { totalRevenue * 0.60 }

    // Payout state
    @State private var payoutStatus: PayoutStatus = .notSetUp
    @State private var pendingBalancePence: Int = 0
    @State private var transferredBalancePence: Int = 0
    @State private var bankLast4: String = ""
    @State private var bankName: String = ""
    @State private var isLoadingPayout = false
    @State private var showPayoutSetup = false
    @State private var payoutSetupURL: URL?
    @State private var payoutError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    earningsSummaryCard
                    commissionCard
                    if !paidAppts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Transactions").font(.headline).padding(.horizontal)
                            ForEach(paidAppts.prefix(10)) { appt in transactionRow(appt) }
                        }
                    }
                    payoutStatusBanner
                    balanceCard
                    Spacer(minLength: 32)
                }
                .padding(.top)
            }
            .navigationTitle("Earnings")
            .task { await loadPayoutStatus() }
            .sheet(isPresented: $showPayoutSetup) {
                if let url = payoutSetupURL {
                    SafariViewWrapper(url: url)
                        .ignoresSafeArea()
                        .onDisappear { Task { await loadPayoutStatus() } }
                }
            }
        }
    }

    // MARK: - Payout Status Banner

    var payoutStatusBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Payouts", systemImage: "building.columns.fill").font(.headline)

            switch payoutStatus {
            case .notSetUp:
                HStack(spacing: 12) {
                    Image(systemName: "banknote")
                        .font(.title2).foregroundColor(.brandGreen)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Set up your bank account to receive your earnings")
                            .font(.subheadline)
                        Text("Connect via Stripe to get paid directly to your bank.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }

                Button { Task { await startPayoutSetup() } } label: {
                    HStack {
                        if isLoadingPayout { ProgressView().tint(.white) }
                        Text("Set Up Payouts")
                            .font(.subheadline).fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(Color.brandGreen).cornerRadius(14)
                }
                .disabled(isLoadingPayout)

            case .onboarding:
                HStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.title2).foregroundColor(.brandAmber)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Complete your bank account setup")
                            .font(.subheadline)
                        Text("Your Stripe Connect onboarding is incomplete.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }

                Button { Task { await continuePayoutSetup() } } label: {
                    HStack {
                        if isLoadingPayout { ProgressView().tint(.white) }
                        Text("Continue Setup")
                            .font(.subheadline).fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(Color.brandAmber).cornerRadius(14)
                }
                .disabled(isLoadingPayout)

            case .pendingReview:
                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .font(.title2).foregroundColor(.brandAmber)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your bank account is being verified")
                            .font(.subheadline).fontWeight(.medium)
                        Text("Stripe is reviewing your details. This usually takes 1-2 business days.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }

            case .active:
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2).foregroundColor(.brandGreen)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text("Payouts active")
                                .font(.caption).fontWeight(.semibold)
                                .foregroundColor(.brandGreen)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Color.brandGreen.opacity(0.12))
                                .cornerRadius(100)
                        }
                        if !bankName.isEmpty || !bankLast4.isEmpty {
                            Text("\(bankName)\(!bankLast4.isEmpty ? " ****\(bankLast4)" : "")")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                }

            case .restricted:
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2).foregroundColor(.brandAmber)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Action needed on your payout account")
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundColor(.brandAmber)
                        Text("Stripe requires additional information to continue payouts.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }

                Button { Task { await continuePayoutSetup() } } label: {
                    Text("Update Details")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(Color.brandAmber).cornerRadius(14)
                }

            case .disabled:
                HStack(spacing: 12) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2).foregroundColor(.brandCoral)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Payouts disabled")
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundColor(.brandCoral)
                        Text("Please contact support for assistance.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }

            if let error = payoutError {
                Text(error)
                    .font(.caption).foregroundColor(.brandCoral)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .padding(.horizontal)
    }

    // MARK: - Balance Card

    var balanceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Balance", systemImage: "sterlingsign.circle.fill").font(.headline)

            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("Pending")
                        .font(.caption).foregroundColor(.secondary)
                    Text("£\(String(format: "%.2f", Double(pendingBalancePence) / 100.0))")
                        .font(.title3).fontWeight(.bold).foregroundColor(.brandAmber)
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 40)

                VStack(spacing: 4) {
                    Text("Transferred")
                        .font(.caption).foregroundColor(.secondary)
                    Text("£\(String(format: "%.2f", Double(transferredBalancePence) / 100.0))")
                        .font(.title3).fontWeight(.bold).foregroundColor(.brandGreen)
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 40)

                VStack(spacing: 4) {
                    Text("Lifetime")
                        .font(.caption).foregroundColor(.secondary)
                    Text("£\(String(format: "%.2f", Double(pendingBalancePence + transferredBalancePence) / 100.0))")
                        .font(.title3).fontWeight(.bold).foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
            }

            if pendingBalancePence > 0 && payoutStatus != .active {
                Text("Complete payout setup to receive your pending balance.")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .padding(.horizontal)
    }

    // MARK: - Earnings Summary Card

    var earningsSummaryCard: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#26de81"), Color(hex: "#20bf6b")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 8) {
                Text("Your Earnings").font(.headline).foregroundColor(.white.opacity(0.9))
                Text("£\(String(format: "%.2f", doctorCut))").font(.system(size: 48, weight: .bold)).foregroundColor(.white)
                Text("60% of all paid consultations").font(.caption).foregroundColor(.white.opacity(0.75))
            }
            .padding()
        }
        .frame(height: 160).cornerRadius(20).padding(.horizontal)
    }

    var commissionCard: some View {
        VStack(spacing: 16) {
            Text("Revenue Breakdown").font(.headline)
            GeometryReader { geo in
                HStack(spacing: 0) {
                    Rectangle().fill(Color.brandGreen)
                        .frame(width: geo.size.width * 0.6, height: 12)
                    Rectangle().fill(Color.brandPurple)
                        .frame(maxWidth: .infinity, minHeight: 12, maxHeight: 12)
                }
                .cornerRadius(6)
            }
            .frame(height: 12).padding(.horizontal)

            HStack {
                Label("You (60%) — £\(String(format: "%.2f", doctorCut))", systemImage: "circle.fill")
                    .font(.caption).foregroundColor(.brandGreen)
                Spacer()
                Label("Platform (40%) — £\(String(format: "%.2f", platformCut))", systemImage: "circle.fill")
                    .font(.caption).foregroundColor(.brandPurple)
            }
            .padding(.horizontal)
            Divider()
            HStack {
                VStack(alignment: .leading) {
                    Text("Total revenue").font(.caption).foregroundColor(.secondary)
                    Text("£\(String(format: "%.2f", totalRevenue))").font(.headline)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Sessions").font(.caption).foregroundColor(.secondary)
                    Text("\(paidAppts.count)").font(.headline)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Avg fee").font(.caption).foregroundColor(.secondary)
                    Text("£\(paidAppts.isEmpty ? 0 : Int(totalRevenue / Double(paidAppts.count)))").font(.headline)
                }
            }
            .padding(.horizontal)
        }
        .padding().background(Color(.systemBackground)).cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8).padding(.horizontal)
    }

    func transactionRow(_ appt: Appointment) -> some View {
        HStack {
            Circle().fill(Color(hex: appt.doctorColor)).frame(width: 38, height: 38)
                .overlay(Image(systemName: "person.fill").font(.caption).foregroundColor(.white))
            VStack(alignment: .leading, spacing: 2) {
                Text("Patient Consultation").font(.subheadline)
                Text(appt.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("+£\(String(format: "%.2f", appt.feeGBP * 0.6))")
                    .font(.subheadline).fontWeight(.semibold).foregroundColor(.brandGreen)
                Text("via \(appt.paymentMethod)").font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding().background(Color(.systemBackground)).cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 4).padding(.horizontal)
    }

    // MARK: - Payout Actions

    private func loadPayoutStatus() async {
        guard let doctorId = store.userProfile.doctorProfile?.payoutAccountId,
              !doctorId.isEmpty else {
            // No account — also try fetching by user ID
            let userId = AuthService.shared.userIdentifier ?? UUID().uuidString
            do {
                let response = try await StripeManager.shared.fetchPayoutStatus(doctorId: userId)
                await MainActor.run {
                    payoutStatus = PayoutStatus(rawValue: response.payoutStatus) ?? .notSetUp
                    bankLast4 = response.bankLast4
                    bankName = response.bankName
                    pendingBalancePence = response.pendingBalance
                    transferredBalancePence = response.transferredBalance
                }
            } catch {
                // No payout account yet — keep defaults
            }
            return
        }

        do {
            let response = try await StripeManager.shared.fetchPayoutStatus(doctorId: doctorId)
            await MainActor.run {
                payoutStatus = PayoutStatus(rawValue: response.payoutStatus) ?? .notSetUp
                bankLast4 = response.bankLast4
                bankName = response.bankName
                pendingBalancePence = response.pendingBalance
                transferredBalancePence = response.transferredBalance
            }
        } catch {
            // Silent — keep current state
        }
    }

    private func startPayoutSetup() async {
        guard store.userProfile.doctorProfile != nil else { return }
        isLoadingPayout = true
        payoutError = nil

        do {
            let result = try await StripeManager.shared.createConnectAccount(
                doctorId: AuthService.shared.userIdentifier ?? UUID().uuidString,
                email: store.userProfile.email,
                firstName: store.userProfile.name.components(separatedBy: " ").first ?? "",
                lastName: store.userProfile.name.components(separatedBy: " ").dropFirst().joined(separator: " ")
            )
            await MainActor.run {
                isLoadingPayout = false
                if let url = URL(string: result.onboardingUrl) {
                    payoutSetupURL = url
                    showPayoutSetup = true
                }
            }
        } catch {
            await MainActor.run {
                isLoadingPayout = false
                payoutError = error.localizedDescription
            }
        }
    }

    private func continuePayoutSetup() async {
        isLoadingPayout = true
        payoutError = nil

        do {
            let onboardingUrl = try await StripeManager.shared.refreshOnboardingLink(
                doctorId: AuthService.shared.userIdentifier ?? UUID().uuidString
            )
            await MainActor.run {
                isLoadingPayout = false
                if let url = URL(string: onboardingUrl) {
                    payoutSetupURL = url
                    showPayoutSetup = true
                }
            }
        } catch {
            await MainActor.run {
                isLoadingPayout = false
                payoutError = error.localizedDescription
            }
        }
    }
}

// MARK: - Safari View Wrapper (SFSafariViewController)

struct SafariViewWrapper: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let safari = SFSafariViewController(url: url, configuration: config)
        return safari
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - Doctor Full Profile View

struct DoctorFullProfileView: View {
    @Environment(HealthStore.self) var store
    @State private var showEdit         = false
    @State private var showAvailability = false
    @State private var selectedTab      = 0

    var profile: DoctorProfile? { store.userProfile.doctorProfile }
    var myReviews: [DoctorReview] {
        // For the logged-in doctor, show reviews for any doctor matching their name
        // In a real app you'd match by doctor ID
        store.doctorReviews.sorted { $0.date > $1.date }
    }

    var avgRating: Double {
        myReviews.isEmpty ? 0 : myReviews.map { $0.rating }.reduce(0, +) / Double(myReviews.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // ── Profile Header ──
                    profileHeader
                    // ── Tab Picker ──
                    Picker("", selection: $selectedTab) {
                        Text("Profile").tag(0)
                        Text("Availability").tag(1)
                        Text("Reviews").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    switch selectedTab {
                    case 0: profileTab
                    case 1: availabilityTab
                    case 2: reviewsTab
                    default: EmptyView()
                    }
                }
            }
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Edit") { showEdit = true }
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            DoctorProfileEditView()
        }
    }

    var profileHeader: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [Color(hex: "#00BFA5"), Color(hex: "#1565C0")],
                           startPoint: .top, endPoint: .bottom).frame(height: 160)
            HStack(alignment: .bottom, spacing: 16) {
                Group {
                    if let photoData = profile?.profilePhotoData, let uiImg = UIImage(data: photoData) {
                        Image(uiImage: uiImg).resizable().scaledToFill()
                            .frame(width: 80, height: 80).clipShape(Circle())
                    } else {
                        Circle().fill(Color.white.opacity(0.3)).frame(width: 80, height: 80)
                            .overlay(Text(String(store.userProfile.name.prefix(2)).uppercased())
                                .font(.title.bold()).foregroundColor(.white))
                    }
                }
                .overlay(Circle().stroke(Color.white, lineWidth: 3))

                VStack(alignment: .leading, spacing: 4) {
                    Text(store.userProfile.name).font(.title2).fontWeight(.bold).foregroundColor(.white)
                    Text(profile?.specialty ?? "").font(.subheadline).foregroundColor(.white.opacity(0.9))
                    if let p = profile, !p.hospital.isEmpty {
                        Label(p.hospital, systemImage: "building.columns.fill")
                            .font(.caption).foregroundColor(.white.opacity(0.8))
                    }
                }
                Spacer()
                // Verification badge
                VStack(spacing: 4) {
                    Image(systemName: profile?.isVerified == true ? "checkmark.seal.fill" : "clock.badge.exclamationmark.fill")
                        .font(.title3)
                        .foregroundColor(profile?.isVerified == true ? .brandGreen : .brandAmber)
                    Text((profile?.verificationStatus ?? .pending).rawValue).font(.caption2).foregroundColor(.white.opacity(0.8))
                }
            }
            .padding().padding(.bottom, 12)
        }
    }

    var profileTab: some View {
        VStack(spacing: 16) {
            // Fees section
            VStack(alignment: .leading, spacing: 12) {
                Text("Consultation Fees").font(.headline).padding(.horizontal)
                HStack(spacing: 12) {
                    feeCard("Video", fee: profile?.videoConsultationFee ?? 50, icon: "video.fill", color: .brandTeal)
                    feeCard("Phone", fee: profile?.phoneConsultationFee ?? 35, icon: "phone.fill", color: .brandPurple)
                    feeCard("In Person", fee: profile?.inPersonFee ?? 75, icon: "person.fill", color: .brandAmber)
                }
                .padding(.horizontal)
            }

            // Credentials
            if let p = profile {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Credentials & Qualifications").font(.headline).padding(.horizontal).padding(.bottom, 8)
                    credSection(p)
                }
            }

            // Introduction
            if let intro = profile?.introduction, !intro.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Introduction").font(.headline)
                    Text(intro).font(.body).foregroundColor(.secondary)
                }
                .padding().frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground)).cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 6).padding(.horizontal)
            }

            Spacer(minLength: 32)
        }
        .padding(.top, 4)
    }

    var availabilityTab: some View {
        AvailabilityEditorView()
    }

    var reviewsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Summary
            HStack(spacing: 20) {
                VStack {
                    Text(myReviews.isEmpty ? "—" : String(format: "%.1f", avgRating))
                        .font(.system(size: 40, weight: .bold))
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { i in
                            Image(systemName: Double(i) < avgRating ? "star.fill" : "star")
                                .font(.caption).foregroundColor(.brandAmber)
                        }
                    }
                    Text("\(myReviews.count) reviews").font(.caption).foregroundColor(.secondary)
                }
                .frame(width: 100)
                .padding().background(Color(.systemBackground)).cornerRadius(14)
                .shadow(color: .black.opacity(0.05), radius: 6)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach([5,4,3,2,1], id: \.self) { star in
                        let count = myReviews.filter { Int($0.rating) == star }.count
                        let fraction = myReviews.isEmpty ? 0.0 : Double(count) / Double(myReviews.count)
                        HStack(spacing: 8) {
                            Text("\(star)").font(.caption2).frame(width: 12)
                            Image(systemName: "star.fill").font(.caption2).foregroundColor(.brandAmber)
                            GeometryReader { g in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color(.systemGray5)).frame(height: 6)
                                    Capsule().fill(Color.brandAmber).frame(width: g.size.width * fraction, height: 6)
                                }
                            }
                            .frame(height: 6)
                            Text("\(count)").font(.caption2).foregroundColor(.secondary).frame(width: 20)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)

            if myReviews.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "text.bubble").font(.system(size: 40)).foregroundColor(.secondary.opacity(0.4))
                    Text("No reviews yet").font(.headline)
                    Text("Reviews from patients will appear here after consultations.").font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.top, 32)
            } else {
                ForEach(myReviews) { rev in
                    ReviewCard(review: rev).padding(.horizontal)
                }
            }
            Spacer(minLength: 32)
        }
        .padding(.top, 8)
    }

    func feeCard(_ type: String, fee: Double, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title3).foregroundColor(color)
            Text("£\(Int(fee))").font(.title3).fontWeight(.bold)
            Text(type).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(color.opacity(0.08)).cornerRadius(14)
    }

    func credSection(_ p: DoctorProfile) -> some View {
        VStack(spacing: 0) {
            if !p.gmcNumber.isEmpty {
                credRow("GMC Number", value: p.gmcNumber, icon: "number.circle.fill", color: .brandTeal)
                Divider().padding(.leading, 52)
            }
            if !p.gmcRegistrationStatus.isEmpty {
                credRow("GMC Status", value: p.gmcRegistrationStatus, icon: "checkmark.shield.fill", color: .brandGreen)
                Divider().padding(.leading, 52)
            }
            if !p.qualifications.isEmpty {
                credRow("Qualifications", value: p.qualifications, icon: "graduationcap.fill", color: .brandPurple)
                Divider().padding(.leading, 52)
            }
            if !p.pmqDegree.isEmpty {
                credRow("PMQ", value: "\(p.pmqDegree) · \(p.pmqCountry) · \(p.pmqYear > 0 ? String(p.pmqYear) : "")", icon: "doc.badge.checkmark", color: .brandAmber)
                Divider().padding(.leading, 52)
            }
            if p.certificateOfGoodStanding {
                credRow("Good Standing", value: "Certificate Uploaded", icon: "checkmark.seal.fill", color: .brandGreen)
                Divider().padding(.leading, 52)
            }
            if p.ecfmgCertified && !p.ecfmgNumber.isEmpty {
                credRow("ECFMG", value: p.ecfmgNumber, icon: "rosette", color: .brandTeal)
                Divider().padding(.leading, 52)
            }
            if p.wdomListed {
                credRow("WDOM", value: "Listed in World Directory", icon: "globe.badge.chevron.backward", color: .brandPurple)
                Divider().padding(.leading, 52)
            }
            if !p.licenseNumber.isEmpty {
                credRow("License", value: p.licenseNumber, icon: "id.card.fill", color: .brandTeal)
            }
        }
        .background(Color(.systemBackground)).cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6).padding(.horizontal)
    }

    func credRow(_ label: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.body).foregroundColor(color).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundColor(.secondary)
                Text(value).font(.subheadline)
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}

// MARK: - Availability Editor

struct AvailabilityEditorView: View {
    @Environment(HealthStore.self) var store
    @State private var availability: [DayAvailability] = []
    @State private var saved = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Set Your Available Hours").font(.headline).padding(.horizontal)
            Text("Times shown in your local timezone: \(TimeZone.current.localizedName(for: .standard, locale: .current) ?? "Local")")
                .font(.caption).foregroundColor(.secondary).padding(.horizontal)

            ForEach($availability) { $day in
                HStack(spacing: 14) {
                    Text(day.dayName).font(.subheadline).frame(width: 90, alignment: .leading)
                    Toggle("", isOn: $day.isAvailable).tint(.brandTeal)
                    if day.isAvailable {
                        Stepper("\(day.startHour):00", value: $day.startHour, in: 6...18)
                            .font(.caption)
                        Text("–")
                        Stepper("\(day.endHour):00", value: $day.endHour, in: 9...22)
                            .font(.caption)
                    } else {
                        Text("Unavailable").font(.caption).foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .padding()
                .background(day.isAvailable ? Color.brandTeal.opacity(0.06) : Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }

            Button {
                saveAvailability()
            } label: {
                Label("Save Availability", systemImage: "checkmark.circle.fill")
                    .font(.headline).frame(maxWidth: .infinity).padding()
                    .background(Color.brandTeal).foregroundColor(.white).cornerRadius(16)
            }
            .padding(.horizontal)
            .alert("Availability Saved!", isPresented: $saved) { Button("OK", role: .cancel) {} }

            Spacer(minLength: 32)
        }
        .padding(.top, 8)
        .onAppear {
            availability = store.userProfile.doctorProfile?.availability ?? DayAvailability.defaultSchedule
        }
    }

    func saveAvailability() {
        var p = store.userProfile.doctorProfile ?? DoctorProfile()
        p.availability = availability
        store.userProfile.doctorProfile = p
        store.save()
        saved = true
    }
}

// MARK: - Appointment Documents View (Doctor)

struct AppointmentDocumentsView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    let appointment: Appointment

    @State private var showBecky = false
    @State private var selectedAttachment: AppointmentAttachment? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    patientHeader

                    if appointment.attachments.isEmpty {
                        emptyState
                    } else {
                        ForEach(appointment.attachments) { att in
                            attachmentCard(att)
                        }
                    }

                    // Ask Becky button
                    if !appointment.attachments.isEmpty {
                        beckyButton
                    }

                    Spacer(minLength: 32)
                }
                .padding(.top)
            }
            .navigationTitle("Patient Documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showBecky) {
            BeckyAIView(appointment: appointment)
        }
        .sheet(item: $selectedAttachment) { att in
            AttachmentDetailView(attachment: att)
        }
    }

    var patientHeader: some View {
        HStack(spacing: 14) {
            Circle().fill(Color(hex: appointment.doctorColor)).frame(width: 44, height: 44)
                .overlay(Image(systemName: "person.fill").font(.headline).foregroundColor(.white))
            VStack(alignment: .leading, spacing: 3) {
                Text("Patient Consultation").font(.headline)
                Text("\(appointment.date.formatted(date: .abbreviated, time: .shortened)) · \(appointment.type.rawValue)")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text("\(appointment.attachments.count) docs")
                .font(.caption).fontWeight(.semibold)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.brandPurple.opacity(0.12))
                .foregroundColor(.brandPurple).cornerRadius(8)
        }
        .padding().background(Color(.systemBackground)).cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6).padding(.horizontal)
    }

    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48)).foregroundColor(.secondary.opacity(0.4))
            Text("No documents shared").font(.headline)
            Text("The patient did not attach any documents to this appointment.")
                .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
        .padding(.top, 40).padding(.horizontal, 32)
    }

    func attachmentCard(_ att: AppointmentAttachment) -> some View {
        Button { selectedAttachment = att } label: {
            HStack(spacing: 14) {
                // Icon
                Image(systemName: att.type.icon)
                    .font(.title3).foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(att.type.color).cornerRadius(12)

                VStack(alignment: .leading, spacing: 3) {
                    Text(att.title).font(.subheadline).fontWeight(.semibold).foregroundColor(.primary)
                    Text(att.type.rawValue).font(.caption).foregroundColor(.secondary)
                    if !att.notes.isEmpty {
                        Text(att.notes).font(.caption2).foregroundColor(.secondary).lineLimit(1)
                    }
                }

                Spacer()

                VStack(spacing: 6) {
                    Image(systemName: "eye.fill").font(.caption).foregroundColor(.brandTeal)
                    if att.data != nil {
                        Text(formatSize(att.data!.count))
                            .font(.caption2).foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground)).cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 6)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }

    var beckyButton: some View {
        Button { showBecky = true } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(
                        LinearGradient(colors: [Color(hex: "#00BFA5"), Color(hex: "#26de81")],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    ).frame(width: 44, height: 44)
                    Image(systemName: "brain.head.profile")
                        .font(.title3).foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ask Becky").font(.headline).foregroundColor(.white)
                    Text("AI-powered medical records analysis")
                        .font(.caption).foregroundColor(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.7))
            }
            .padding()
            .background(
                LinearGradient(colors: [Color(hex: "#00BFA5"), Color(hex: "#1565C0")],
                               startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(16)
        }
        .padding(.horizontal)
    }

    func formatSize(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return "\(bytes / 1024) KB" }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }
}

// MARK: - Attachment Detail View

struct AttachmentDetailView: View {
    @Environment(\.dismiss) var dismiss
    let attachment: AppointmentAttachment

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Type badge
                    HStack(spacing: 10) {
                        Image(systemName: attachment.type.icon)
                            .font(.title3).foregroundColor(attachment.type.color)
                        Text(attachment.type.rawValue).font(.headline)
                        Spacer()
                        Text(attachment.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption).foregroundColor(.secondary)
                    }
                    .padding()
                    .background(attachment.type.color.opacity(0.08)).cornerRadius(14)
                    .padding(.horizontal)

                    // Content
                    if attachment.type == .healthReadings, let data = attachment.data,
                       let text = String(data: data, encoding: .utf8) {
                        Text(text)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.primary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6)).cornerRadius(12)
                            .padding(.horizontal)
                    } else if let data = attachment.data, let uiImg = UIImage(data: data) {
                        Image(uiImage: uiImg)
                            .resizable().scaledToFit()
                            .cornerRadius(12)
                            .padding(.horizontal)
                    } else if let thumbData = attachment.thumbnailData, let uiImg = UIImage(data: thumbData) {
                        Image(uiImage: uiImg)
                            .resizable().scaledToFit()
                            .cornerRadius(12)
                            .padding(.horizontal)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text").font(.system(size: 48)).foregroundColor(.secondary.opacity(0.4))
                            Text("No preview available").font(.subheadline).foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                    }

                    if !attachment.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes").font(.headline)
                            Text(attachment.notes).font(.body).foregroundColor(.secondary)
                        }
                        .padding().frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground)).cornerRadius(14)
                        .shadow(color: .black.opacity(0.05), radius: 6)
                        .padding(.horizontal)
                    }

                    // Share button
                    if let data = attachment.data {
                        ShareLink(item: data, preview: SharePreview(attachment.title)) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Download / Share").fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.brandTeal).foregroundColor(.white).cornerRadius(14)
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 32)
                }
                .padding(.top)
            }
            .navigationTitle(attachment.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Becky AI View (Doctor's Medical Records Assistant)

struct BeckyAIView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    let appointment: Appointment?

    @State private var messages: [BeckyMessage] = []
    @State private var inputText = ""
    @State private var isTyping  = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                beckyHeader

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(messages) { msg in
                                BeckyBubble(message: msg)
                                    .id(msg.id)
                            }
                            if isTyping {
                                beckyTypingIndicator
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let last = messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                // Quick chips
                if let last = messages.last, !last.isUser, !last.chips.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(last.chips, id: \.self) { chip in
                                Button { sendMessage(chip) } label: {
                                    Text(chip).font(.caption).fontWeight(.medium)
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(Color(hex: "#00BFA5").opacity(0.12))
                                        .foregroundColor(Color(hex: "#00BFA5"))
                                        .cornerRadius(20)
                                        .overlay(RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color(hex: "#00BFA5").opacity(0.3)))
                                }
                            }
                        }
                        .padding(.horizontal).padding(.vertical, 8)
                    }
                }

                // Input
                HStack(spacing: 10) {
                    TextField("Ask Becky about this patient…", text: $inputText)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color(.systemGray6)).cornerRadius(12)
                    Button { sendMessage(inputText) } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(inputText.isEmpty ? .secondary : Color(hex: "#00BFA5"))
                    }
                    .disabled(inputText.isEmpty)
                }
                .padding(.horizontal).padding(.vertical, 10)
                .background(Color(.systemBackground))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            if appointment != nil {
                generateInitialSummary()
            } else {
                messages.append(BeckyMessage(
                    content: "Hello, Doctor. I'm Becky, your AI medical assistant. Ask me anything — clinical queries, drug interactions, patient prep, or evidence-based guidance.",
                    isUser: false,
                    chips: ["Drug interactions", "Clinical guidelines", "Patient prep", "Evidence check"]
                ))
            }
        }
    }

    var beckyHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(
                    LinearGradient(colors: [Color(hex: "#00BFA5"), Color(hex: "#26de81")],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                ).frame(width: 42, height: 42)
                Image(systemName: "brain.head.profile")
                    .font(.title3).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Becky").font(.headline)
                Text("Medical Records Assistant").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "waveform.circle.fill")
                .font(.title3).foregroundColor(Color(hex: "#00BFA5"))
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    var beckyTypingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle().fill(Color(hex: "#00BFA5").opacity(0.5))
                    .frame(width: 8, height: 8)
            }
            Spacer()
        }
        .padding(.leading, 20)
    }

    // MARK: - Logic

    // MARK: - Appointment context for Claude

    private var appointmentContext: String {
        guard let appointment = appointment else {
            return "General consultation support. No specific appointment selected — the doctor is asking a general clinical question."
        }
        var ctx = """
        Appointment type: \(appointment.type.rawValue)
        Date: \(appointment.date.formatted(date: .abbreviated, time: .shortened))
        Payment: \(appointment.isPaid ? "Paid" : "Pending") — £\(Int(appointment.feeGBP))
        """
        if !appointment.notes.isEmpty { ctx += "\nPatient message: \(appointment.notes)" }
        let atts = appointment.attachments
        if !atts.isEmpty {
            ctx += "\n\nShared documents (\(atts.count)):"
            for att in atts {
                ctx += "\n• \(att.type.rawValue): \(att.title)"
                if !att.notes.isEmpty { ctx += " — \(att.notes)" }
                if let data = att.data, let txt = String(data: data, encoding: .utf8) {
                    // Include first 600 chars of text attachments as context
                    ctx += "\n  Content excerpt: \(txt.prefix(600))"
                }
            }
        }
        return ctx
    }

    // MARK: - Send message (Claude → rule-based fallback)

    func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append(BeckyMessage(content: trimmed, isUser: true))
        inputText = ""
        isTyping = true

        Task {
            // ── Try Claude ────────────────────────────────────────────────
            if AIClient.shared.isConfigured() {
                let ctx = appointmentContext
                do {
                    let reply = try await AIClient.shared.send(
                        system: AISystemPrompts.becky(appointmentContext: ctx),
                        userMessage: trimmed
                    )
                    await MainActor.run {
                        isTyping = false
                        messages.append(BeckyMessage(content: reply, isUser: false))
                    }
                    return
                } catch { /* fall through */ }
            }

            // ── Rule-based fallback ───────────────────────────────────────
            try? await Task.sleep(for: .milliseconds(Int.random(in: 800...1500)))
            let reply = beckyRespond(to: trimmed)
            await MainActor.run {
                isTyping = false
                messages.append(reply)
            }
        }
    }

    // MARK: - Initial summary (Claude → rule-based fallback)

    func generateInitialSummary() {
        isTyping = true
        Task {
            // ── Try Claude ────────────────────────────────────────────────
            if AIClient.shared.isConfigured() {
                let ctx = appointmentContext
                do {
                    let reply = try await AIClient.shared.send(
                        system: AISystemPrompts.becky(appointmentContext: ctx),
                        userMessage: "Please provide a full clinical summary of this patient's appointment and shared documents. Highlight key health metrics, any risk factors, and what I should focus on during the consultation."
                    )
                    await MainActor.run {
                        isTyping = false
                        messages.append(BeckyMessage(
                            content: reply, isUser: false,
                            chips: ["Glucose trends", "BP analysis", "Medication review", "Risk flags"]
                        ))
                    }
                    return
                } catch { /* fall through */ }
            }

            // ── Rule-based fallback ───────────────────────────────────────
            try? await Task.sleep(for: .milliseconds(600))
            let summary = buildFullSummary()
            await MainActor.run {
                isTyping = false
                messages.append(summary)
            }
        }
    }

    func buildFullSummary() -> BeckyMessage {
        var lines: [String] = []
        lines.append("**Becky — Patient Records Analysis**\n")

        let atts = appointment?.attachments ?? []
        lines.append(atts.isEmpty
            ? "No patient documents available. Ask me any clinical question and I'll assist.\n"
            : "I've reviewed **\(atts.count) document\(atts.count == 1 ? "" : "s")** shared for this appointment.\n")

        // Summarize health readings if present
        if let readingsAtt = atts.first(where: { $0.type == .healthReadings }),
           let data = readingsAtt.data, let text = String(data: data, encoding: .utf8) {
            lines.append("**📋 Health Readings Summary**")
            let readingLines = text.components(separatedBy: "\n")
            // Extract key stats
            for line in readingLines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("Average:") || trimmed.hasPrefix("Range:")
                    || trimmed.hasPrefix("Average duration:") || trimmed.hasPrefix("Average level:")
                    || trimmed.hasPrefix("Daily average:") || trimmed.contains("adherence") {
                    lines.append("  \(trimmed)")
                }
            }
            lines.append("")

            // Correlations & flags
            lines.append(analyzeCorrelations(text))
        }

        // Medical records
        let records = atts.filter { $0.type == .medicalRecord }
        if !records.isEmpty {
            lines.append("**📄 Medical Records (\(records.count))**")
            for rec in records {
                lines.append("  • \(rec.title)\(rec.notes.isEmpty ? "" : " — _\(rec.notes)_")")
            }
            lines.append("")
        }

        // Scans
        let scans = atts.filter { $0.type == .uploadedScan }
        if !scans.isEmpty {
            lines.append("**🔬 Uploaded Scans (\(scans.count))**")
            for scan in scans {
                let size = scan.data.map { "\(($0.count / 1024)) KB" } ?? "N/A"
                lines.append("  • \(scan.title) (\(size))")
            }
            lines.append("")
        }

        lines.append("_Tap a quick action below for detailed analysis on a specific area._")

        return BeckyMessage(
            content: lines.joined(separator: "\n"),
            isUser: false,
            chips: ["Glucose Trends", "BP Analysis", "Medication Review", "Risk Flags", "Full Summary"]
        )
    }

    func analyzeCorrelations(_ readingsText: String) -> String {
        var flags: [String] = []
        flags.append("**⚠️ Key Observations**")

        let hasHighGlucose = readingsText.contains("Very High") || readingsText.contains("High")
        let hasPoorSleep = readingsText.contains("Poor")
        let hasHighStress = readingsText.localizedCaseInsensitiveContains("level: 7") ||
                            readingsText.localizedCaseInsensitiveContains("level: 8") ||
                            readingsText.localizedCaseInsensitiveContains("level: 9") ||
                            readingsText.localizedCaseInsensitiveContains("level: 10")
        let hasHighBP = readingsText.contains("High (Stage")
        let hasLowAdherence = readingsText.contains("adherence") && !readingsText.contains("100% adherence")

        if hasHighGlucose && hasPoorSleep {
            flags.append("  • Elevated glucose readings correlate with poor sleep entries — consider sleep management.")
        }
        if hasHighGlucose && hasHighStress {
            flags.append("  • High glucose combined with high stress — cortisol-driven hyperglycemia possible.")
        }
        if hasHighBP && hasHighStress {
            flags.append("  • Elevated BP with high stress readings — recommend stress reduction strategies.")
        }
        if hasLowAdherence {
            flags.append("  • Medication adherence below 100% — discuss barriers with patient.")
        }
        if hasHighGlucose {
            flags.append("  • Glucose readings above target range — review dietary intake and medication dosing.")
        }
        if hasHighBP {
            flags.append("  • Blood pressure in hypertensive range — monitor and consider treatment adjustment.")
        }

        if flags.count == 1 {
            flags.append("  • No major red flags identified in the available data.")
        }

        flags.append("")
        return flags.joined(separator: "\n")
    }

    func beckyRespond(to input: String) -> BeckyMessage {
        let q = input.lowercased()

        if q.contains("glucose") || q.contains("sugar") || q.contains("blood sugar") {
            return glucoseAnalysis()
        } else if q.contains("bp") || q.contains("blood pressure") || q.contains("hypertension") {
            return bpAnalysis()
        } else if q.contains("medication") || q.contains("adherence") || q.contains("pill") || q.contains("drug") {
            return medicationAnalysis()
        } else if q.contains("risk") || q.contains("flag") || q.contains("warning") || q.contains("concern") {
            return riskAnalysis()
        } else if q.contains("summary") || q.contains("full") || q.contains("overview") {
            return buildFullSummary()
        } else if q.contains("sleep") {
            return sleepAnalysis()
        } else if q.contains("stress") {
            return stressAnalysis()
        } else {
            return BeckyMessage(
                content: "I can help you analyze this patient's records. Try asking about **glucose trends**, **BP analysis**, **medication review**, **risk flags**, or request a **full summary**.",
                isUser: false,
                chips: ["Glucose Trends", "BP Analysis", "Medication Review", "Risk Flags"]
            )
        }
    }

    func glucoseAnalysis() -> BeckyMessage {
        guard let att = (appointment?.attachments ?? []).first(where: { $0.type == .healthReadings }),
              let data = att.data, let text = String(data: data, encoding: .utf8) else {
            return BeckyMessage(content: "No health readings data available for glucose analysis.", isUser: false)
        }

        var lines: [String] = ["**🩸 Glucose Trend Analysis**\n"]

        let readingLines = text.components(separatedBy: "\n")
        let glucoseSection = readingLines.drop(while: { !$0.contains("GLUCOSE") })
            .prefix(while: { !$0.isEmpty || $0.contains("GLUCOSE") })

        for line in glucoseSection {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                lines.append(trimmed)
            }
        }

        lines.append("")
        lines.append("_Consider reviewing post-meal readings for patterns and HbA1c estimation._")

        return BeckyMessage(content: lines.joined(separator: "\n"), isUser: false,
                           chips: ["BP Analysis", "Medication Review", "Risk Flags"])
    }

    func bpAnalysis() -> BeckyMessage {
        guard let att = (appointment?.attachments ?? []).first(where: { $0.type == .healthReadings }),
              let data = att.data, let text = String(data: data, encoding: .utf8) else {
            return BeckyMessage(content: "No health readings data available for BP analysis.", isUser: false)
        }

        var lines: [String] = ["**❤️ Blood Pressure Analysis**\n"]

        let readingLines = text.components(separatedBy: "\n")
        let bpSection = readingLines.drop(while: { !$0.contains("BLOOD PRESSURE") })
            .prefix(while: { !$0.isEmpty || $0.contains("BLOOD PRESSURE") })

        for line in bpSection {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty { lines.append(trimmed) }
        }

        lines.append("")
        lines.append("_Monitor for white-coat hypertension vs. sustained readings. Consider ambulatory monitoring if borderline._")

        return BeckyMessage(content: lines.joined(separator: "\n"), isUser: false,
                           chips: ["Glucose Trends", "Medication Review", "Risk Flags"])
    }

    func medicationAnalysis() -> BeckyMessage {
        guard let att = (appointment?.attachments ?? []).first(where: { $0.type == .healthReadings }),
              let data = att.data, let text = String(data: data, encoding: .utf8) else {
            return BeckyMessage(content: "No health readings data available for medication review.", isUser: false)
        }

        var lines: [String] = ["**💊 Medication & Adherence Review**\n"]

        let readingLines = text.components(separatedBy: "\n")
        let medSection = readingLines.drop(while: { !$0.contains("ACTIVE MEDICATIONS") })
            .prefix(while: { !$0.isEmpty || $0.contains("ACTIVE MEDICATIONS") })

        for line in medSection {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty { lines.append(trimmed) }
        }

        lines.append("")
        lines.append("_Review adherence patterns and discuss any side effects with the patient._")

        return BeckyMessage(content: lines.joined(separator: "\n"), isUser: false,
                           chips: ["Glucose Trends", "BP Analysis", "Risk Flags"])
    }

    func riskAnalysis() -> BeckyMessage {
        guard let att = (appointment?.attachments ?? []).first(where: { $0.type == .healthReadings }),
              let data = att.data, let text = String(data: data, encoding: .utf8) else {
            return BeckyMessage(content: "No health readings data available for risk analysis.", isUser: false)
        }

        let correlation = analyzeCorrelations(text)
        var lines: [String] = ["**🚨 Risk Flags & Correlations**\n"]
        lines.append(correlation)
        lines.append("_These are AI-generated observations. Always apply clinical judgment._")

        return BeckyMessage(content: lines.joined(separator: "\n"), isUser: false,
                           chips: ["Glucose Trends", "BP Analysis", "Full Summary"])
    }

    func sleepAnalysis() -> BeckyMessage {
        guard let att = (appointment?.attachments ?? []).first(where: { $0.type == .healthReadings }),
              let data = att.data, let text = String(data: data, encoding: .utf8) else {
            return BeckyMessage(content: "No sleep data available.", isUser: false)
        }

        var lines: [String] = ["**😴 Sleep Analysis**\n"]
        let readingLines = text.components(separatedBy: "\n")
        let section = readingLines.drop(while: { !$0.contains("SLEEP") })
            .prefix(while: { !$0.isEmpty || $0.contains("SLEEP") })
        for line in section {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty { lines.append(trimmed) }
        }
        lines.append("")
        lines.append("_Poor sleep can impair glucose regulation and elevate cortisol. Consider sleep hygiene assessment._")

        return BeckyMessage(content: lines.joined(separator: "\n"), isUser: false,
                           chips: ["Glucose Trends", "Stress Analysis", "Risk Flags"])
    }

    func stressAnalysis() -> BeckyMessage {
        guard let att = (appointment?.attachments ?? []).first(where: { $0.type == .healthReadings }),
              let data = att.data, let text = String(data: data, encoding: .utf8) else {
            return BeckyMessage(content: "No stress data available.", isUser: false)
        }

        var lines: [String] = ["**🧠 Stress Analysis**\n"]
        let readingLines = text.components(separatedBy: "\n")
        let section = readingLines.drop(while: { !$0.contains("STRESS") })
            .prefix(while: { !$0.isEmpty || $0.contains("STRESS") })
        for line in section {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty { lines.append(trimmed) }
        }
        lines.append("")
        lines.append("_Chronic stress impacts cardiovascular health and glycaemic control. Consider CBT or mindfulness referral._")

        return BeckyMessage(content: lines.joined(separator: "\n"), isUser: false,
                           chips: ["Sleep Analysis", "BP Analysis", "Risk Flags"])
    }
}

// MARK: - Becky Message Model

struct BeckyMessage: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
    var chips: [String] = []

    static func == (lhs: BeckyMessage, rhs: BeckyMessage) -> Bool { lhs.id == rhs.id }
}

// MARK: - Becky Bubble

struct BeckyBubble: View {
    let message: BeckyMessage

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if !message.isUser {
                ZStack {
                    Circle().fill(
                        LinearGradient(colors: [Color(hex: "#00BFA5"), Color(hex: "#26de81")],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    ).frame(width: 30, height: 30)
                    Image(systemName: "brain.head.profile")
                        .font(.caption).foregroundColor(.white)
                }
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(.init(message.content))
                    .font(.subheadline)
                    .padding(12)
                    .background(message.isUser ? Color(hex: "#00BFA5") : Color(.systemGray6))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(16, corners: message.isUser
                        ? [.topLeft, .topRight, .bottomLeft]
                        : [.topLeft, .topRight, .bottomRight])

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)

            if message.isUser {
                Circle().fill(Color.brandPurple.opacity(0.2))
                    .frame(width: 30, height: 30)
                    .overlay(Image(systemName: "stethoscope").font(.caption).foregroundColor(.brandPurple))
            }
        }
    }
}



// MARK: - Doctor Profile Edit View

struct DoctorProfileEditView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var page          = 0
    // Basic
    @State private var specialty     = ""
    @State private var hospital      = ""
    @State private var postcode      = ""
    @State private var qualifications = ""
    @State private var intro         = ""
    // Fees
    @State private var videoFee      = ""
    @State private var phoneFee      = ""
    @State private var inPersonFee   = ""
    // GMC
    @State private var gmcNumber     = ""
    @State private var gmcStatus     = "Full"
    @State private var gmcDate       = ""
    @State private var hasCGOS       = false
    @State private var plabPassed    = false
    // International
    @State private var ecfmgNumber   = ""
    @State private var ecfmgCerted   = false
    @State private var wdomListed    = false
    @State private var regulatoryBody = "GMC"
    // PMQ
    @State private var pmqDegree     = ""
    @State private var pmqCountry    = ""
    @State private var pmqYear       = 2010
    @State private var saved         = false

    let specialties = ["General Practice","Cardiologist","Diabetologist","Endocrinologist",
                       "Nephrologist","Nutritionist","Psychiatrist","Neurologist","Oncologist",
                       "Dermatologist","Orthopaedic Surgeon","Paediatrician","Gynaecologist"]

    var body: some View {
        NavigationStack {
            Form {
                // ── Practice Details ──
                Section("Practice Details") {
                    Picker("Specialty", selection: $specialty) {
                        ForEach(specialties, id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Hospital / Clinic", text: $hospital)
                    TextField("Qualifications (e.g. MBBS, FRCP)", text: $qualifications)
                    TextField("Postcode", text: $postcode)
                }

                // ── Consultation Fees ──
                Section("Consultation Fees (£)") {
                    HStack { Label("Video Call", systemImage: "video.fill"); Spacer(); TextField("50", text: $videoFee).keyboardType(.numberPad).multilineTextAlignment(.trailing) }
                    HStack { Label("Phone Call", systemImage: "phone.fill"); Spacer(); TextField("35", text: $phoneFee).keyboardType(.numberPad).multilineTextAlignment(.trailing) }
                    HStack { Label("In Person", systemImage: "person.fill"); Spacer(); TextField("75", text: $inPersonFee).keyboardType(.numberPad).multilineTextAlignment(.trailing) }
                }

                // ── Introduction ──
                Section("Introduction (shown to patients)") {
                    TextEditor(text: $intro).frame(height: 120)
                }

                // ── GMC Registration ──
                Section("GMC Registration") {
                    TextField("GMC Reference Number", text: $gmcNumber).keyboardType(.numberPad)
                    Picker("Registration Status", selection: $gmcStatus) {
                        ForEach(["Full","Provisional","Specialist Register","GP Register"], id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Date of First Registration (DD/MM/YYYY)", text: $gmcDate)
                    Toggle("Certificate of Good Standing", isOn: $hasCGOS)
                    Toggle("PLAB / UKMLA Passed", isOn: $plabPassed)
                }

                // ── PMQ ──
                Section("Primary Medical Qualification") {
                    TextField("Degree (e.g. MBBS, MBBCh, MD)", text: $pmqDegree)
                    TextField("Country of Award", text: $pmqCountry)
                    Stepper("Year: \(pmqYear)", value: $pmqYear, in: 1970...2024)
                }

                // ── International ──
                Section("International Credentials") {
                    Picker("Regulatory Body", selection: $regulatoryBody) {
                        ForEach(["GMC","ECFMG","EPIC","AHPRA","MCC","IMC"], id: \.self) { Text($0).tag($0) }
                    }
                    TextField("ECFMG Number", text: $ecfmgNumber)
                    Toggle("ECFMG Certified", isOn: $ecfmgCerted)
                    Toggle("WDOM Listed", isOn: $wdomListed)
                }

                // ── Save ──
                Section {
                    Button { saveProfile() } label: {
                        Label("Save Profile", systemImage: "checkmark.circle.fill").foregroundColor(.brandTeal)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .onAppear(perform: loadProfile)
            .alert("Profile Saved!", isPresented: $saved) { Button("OK") { dismiss() } }
        }
    }

    func loadProfile() {
        guard let p = store.userProfile.doctorProfile else { return }
        specialty      = p.specialty
        hospital       = p.hospital
        postcode       = p.postcode
        qualifications = p.qualifications
        intro          = p.introduction
        videoFee       = String(Int(p.videoConsultationFee))
        phoneFee       = String(Int(p.phoneConsultationFee))
        inPersonFee    = String(Int(p.inPersonFee))
        gmcNumber      = p.gmcNumber
        gmcStatus      = p.gmcRegistrationStatus.isEmpty ? "Full" : p.gmcRegistrationStatus
        gmcDate        = p.gmcRegistrationDate
        hasCGOS        = p.certificateOfGoodStanding
        plabPassed     = p.plabPassed
        ecfmgNumber    = p.ecfmgNumber
        ecfmgCerted    = p.ecfmgCertified
        wdomListed     = p.wdomListed
        regulatoryBody = p.regulatoryBody.isEmpty ? "GMC" : p.regulatoryBody
        pmqDegree      = p.pmqDegree
        pmqCountry     = p.pmqCountry
        pmqYear        = p.pmqYear == 0 ? 2010 : p.pmqYear
    }

    func saveProfile() {
        var p = store.userProfile.doctorProfile ?? DoctorProfile()
        p.specialty              = specialty
        p.hospital               = hospital
        p.postcode               = postcode.uppercased()
        p.qualifications         = qualifications
        p.introduction           = intro
        p.videoConsultationFee   = Double(videoFee) ?? 50
        p.phoneConsultationFee   = Double(phoneFee) ?? 35
        p.inPersonFee            = Double(inPersonFee) ?? 75
        p.consultationFeeGBP     = Double(videoFee) ?? 50
        p.gmcNumber              = gmcNumber
        p.gmcRegistrationStatus  = gmcStatus
        p.gmcRegistrationDate    = gmcDate
        p.certificateOfGoodStanding = hasCGOS
        p.plabPassed             = plabPassed
        p.ecfmgNumber            = ecfmgNumber
        p.ecfmgCertified         = ecfmgCerted
        p.wdomListed             = wdomListed
        p.regulatoryBody         = regulatoryBody
        p.pmqDegree              = pmqDegree
        p.pmqCountry             = pmqCountry
        p.pmqYear                = pmqYear
        store.userProfile.doctorProfile = p
        store.save()
        store.syncDoctorToPublicList()
        saved = true
    }
}
