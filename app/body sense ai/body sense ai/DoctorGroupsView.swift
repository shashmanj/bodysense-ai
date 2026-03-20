//
//  DoctorGroupsView.swift
//  body sense ai
//
//  Verified-doctor version of the Groups tab.
//  Three segments:
//    • Explore                 — browse community groups
//    • My Groups               — posts from joined groups
//    • Upcoming Appointments   — patient appointments + Becky AI quick access
//

import SwiftUI

// MARK: - DoctorGroupsView

struct DoctorGroupsView: View {
    @Environment(HealthStore.self) var store

    @State private var segment        = 0
    @State private var showPost       = false
    @State private var showCreateGroup = false
    @State private var selectedGroup  : CommunityGroup? = nil

    private let segments = ["Explore", "My Groups", "Upcoming Appointments"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ── Segment picker ────────────────────────────────────────────
                Picker("", selection: $segment) {
                    ForEach(0..<segments.count, id: \.self) { i in
                        Text(segments[i]).tag(i)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .background(Color.brandBg)

                // ── Content ──────────────────────────────────────────────────
                ScrollView {
                    VStack(spacing: 16) {
                        switch segment {
                        case 0:
                            DiscoverTab(selectedGroup: $selectedGroup,
                                        showCreateGroup: $showCreateGroup)
                        case 1:
                            MyGroupsTab(selectedGroup: $selectedGroup,
                                        showPost: $showPost,
                                        switchToDiscover: { segment = 0 })
                        case 2:
                            DoctorAppointmentsSection()
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .padding(.bottom, 100)
                }
                .background(Color.brandBg)
            }
            .navigationTitle(segments[segment])
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if segment == 1 && !store.joinedGroups.isEmpty {
                        Button { showPost = true } label: {
                            Label("New Post", systemImage: "square.and.pencil")
                                .font(.subheadline.bold())
                                .foregroundColor(.brandTeal)
                        }
                    }
                }
            }
            .sheet(item: $selectedGroup) { group in GroupDetailView(group: group) }
            .sheet(isPresented: $showPost)        { NewPostSheet() }
            .sheet(isPresented: $showCreateGroup) { CreateGroupSheet() }
        }
    }
}

// MARK: - Doctor Appointments Section

struct DoctorAppointmentsSection: View {
    @Environment(HealthStore.self) var store
    @State private var beckyAppt: Appointment? = nil

    private var upcoming: [Appointment] {
        store.appointments.filter { $0.status == .upcoming }.sorted { $0.date < $1.date }
    }
    private var past: [Appointment] {
        store.appointments.filter { $0.status != .upcoming }.sorted { $0.date > $1.date }
    }

    var body: some View {
        Group {
            if upcoming.isEmpty && past.isEmpty {
                emptyState
            } else {
                appointmentsList
            }
        }
        .sheet(item: $beckyAppt) { appt in
            BeckyAIView(appointment: appt)
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.largeTitle)
                .foregroundColor(.brandTeal.opacity(0.45))
            Text("No upcoming appointments")
                .font(.headline)
            Text("Patients who book with you will appear here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }

    // MARK: Appointments list

    @ViewBuilder
    private var appointmentsList: some View {
        if !upcoming.isEmpty {
            sectionLabel("Upcoming (\(upcoming.count))")
            ForEach(upcoming) { appt in
                DoctorPatientApptCard(appointment: appt)
            }
        }
        if !past.isEmpty {
            sectionLabel("Past")
            ForEach(past.prefix(10)) { appt in
                DoctorPatientApptCard(appointment: appt)
            }
        }

        // Becky quick-access banner at the very bottom of the list
        if let anchor = upcoming.first ?? past.first {
            BeckyQuickAccessBanner {
                beckyAppt = anchor
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        HStack { Text(text).font(.headline); Spacer() }.padding(.top, 4)
    }
}

// MARK: - Doctor Patient Appointment Card

struct DoctorPatientApptCard: View {
    let appointment: Appointment
    @State private var showDetail = false
    @State private var showBecky  = false

    var body: some View {
        Button(action: { showDetail = true }) {
            BSCard {
                VStack(alignment: .leading, spacing: 10) {

                    // ── Header row ───────────────────────────────────────────
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: appointment.doctorColor).opacity(0.2))
                                .frame(width: 44, height: 44)
                            Image(systemName: "person.fill")
                                .font(.headline)
                                .foregroundColor(Color(hex: appointment.doctorColor))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Patient Appointment")
                                .font(.subheadline.bold())
                            Text(appointment.type.rawValue)
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(appointment.isPaid ? "Paid" : "Pending")
                            .font(.caption.bold())
                            .foregroundColor(appointment.isPaid ? .brandTeal : .orange)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background((appointment.isPaid ? Color.brandTeal : Color.orange).opacity(0.15))
                            .cornerRadius(8)
                    }

                    // ── Date / fee ───────────────────────────────────────────
                    HStack {
                        Label(appointment.date.formatted(date: .abbreviated, time: .shortened),
                              systemImage: "calendar")
                            .font(.caption).foregroundColor(.secondary)
                        Spacer()
                        Text("£\(appointment.feeGBP, specifier: "%.0f")")
                            .font(.caption.bold()).foregroundColor(.brandPurple)
                    }

                    // ── Patient notes / message ──────────────────────────────
                    if !appointment.notes.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "message.fill")
                                .font(.caption).foregroundColor(.brandPurple)
                            Text(appointment.notes)
                                .font(.caption).foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(8)
                        .background(Color.brandPurple.opacity(0.06))
                        .cornerRadius(8)
                    }

                    // ── Files badge + Becky button ───────────────────────────
                    HStack(spacing: 10) {
                        if !appointment.attachments.isEmpty {
                            Label("\(appointment.attachments.count) file\(appointment.attachments.count == 1 ? "" : "s")",
                                  systemImage: "doc.fill")
                                .font(.caption)
                                .foregroundColor(.brandTeal)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.brandTeal.opacity(0.1))
                                .cornerRadius(8)
                        }
                        Spacer()
                        Button {
                            showBecky = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "brain.head.profile")
                                Text("Ask Becky")
                            }
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Color.brandTeal)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            AppointmentDocumentsView(appointment: appointment)
        }
        .sheet(isPresented: $showBecky) {
            BeckyAIView(appointment: appointment)
        }
    }
}

// MARK: - Becky Quick-Access Banner (sticky footer below appointment list)

struct BeckyQuickAccessBanner: View {
    let onAskBecky: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider().padding(.vertical, 8)

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.brandTeal.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                        .foregroundColor(.brandTeal)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ask Becky AI")
                        .font(.subheadline.bold())
                    Text("Summarise patient files or get medical insights")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: onAskBecky) {
                    Text("Open")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Color.brandTeal)
                        .cornerRadius(10)
                }
            }
            .padding(14)
            .background(Color.brandTeal.opacity(0.07))
            .cornerRadius(16)
        }
    }
}
