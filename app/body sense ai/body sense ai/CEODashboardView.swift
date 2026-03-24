//
//  CEODashboardView.swift
//  body sense ai
//
//  CEO-only business intelligence dashboard with daily metrics,
//  revenue tracking, user analytics, and operational overview.
//  Visible only to users who activated CEO mode via secret code (Keychain-backed).
//

import SwiftUI

// MARK: - CEO Dashboard

struct CEODashboardView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ceoHeader
                dailySnapshot
                revenueSection
                doctorMetrics
                productMetrics
                operationalAlerts
            }
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("CEO Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    // MARK: - Header

    var ceoHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.brandPurple, Color(hex: "#4834d4")],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 52, height: 52)
                    Image(systemName: "crown.fill")
                        .font(.title2).foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Good \(greeting), Kiran")
                        .font(.title3).fontWeight(.bold)
                    Text(Date(), style: .date)
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding()
        .background(
            LinearGradient(colors: [.brandPurple.opacity(0.08), .brandTeal.opacity(0.05)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(16)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Morning" }
        if hour < 17 { return "Afternoon" }
        return "Evening"
    }

    // MARK: - Daily Snapshot

    var dailySnapshot: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Daily Snapshot", icon: "chart.bar.fill")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                metricCard(
                    "Total Revenue",
                    value: formatGBP(totalRevenue),
                    icon: "sterlingsign.circle.fill",
                    color: .brandGreen,
                    subtitle: "\(store.orders.count) orders"
                )
                metricCard(
                    "Appointments",
                    value: "\(store.appointments.count)",
                    icon: "calendar.badge.clock",
                    color: .brandPurple,
                    subtitle: "\(upcomingAppointments) upcoming"
                )
                metricCard(
                    "Verified Doctors",
                    value: "\(verifiedDoctors)",
                    icon: "stethoscope.circle.fill",
                    color: .brandTeal,
                    subtitle: "\(pendingDoctors) pending approval"
                )
                metricCard(
                    "Products",
                    value: "\(store.products.count)",
                    icon: "bag.fill",
                    color: .brandAmber,
                    subtitle: "\(store.cartItems.count) in carts"
                )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Revenue

    var revenueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Revenue Breakdown", icon: "sterlingsign.circle.fill")

            VStack(spacing: 0) {
                revenueRow("Product Sales", amount: productRevenue, icon: "bag.fill", color: .brandGreen)
                Divider().padding(.leading, 48)
                revenueRow("Consultations", amount: consultationRevenue, icon: "video.fill", color: .brandPurple)
                Divider().padding(.leading, 48)
                revenueRow("Platform Commission (50%)", amount: platformCommission, icon: "percent", color: .brandAmber)
                Divider().padding(.leading, 48)
                revenueRow("Total Revenue", amount: totalRevenue, icon: "chart.line.uptrend.xyaxis", color: .brandTeal, bold: true)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.04), radius: 4)
        }
        .padding(.horizontal)
    }

    // MARK: - Doctor Metrics

    var doctorMetrics: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Doctor Network", icon: "stethoscope.circle.fill")

            VStack(spacing: 0) {
                statRow("Total Registered", value: "\(store.doctors.count + store.doctorRequests.count)")
                Divider().padding(.leading, 16)
                statRow("Verified & Active", value: "\(verifiedDoctors)", color: .brandGreen)
                Divider().padding(.leading, 16)
                statRow("Pending Approval", value: "\(pendingDoctors)", color: pendingDoctors > 0 ? .brandCoral : .secondary)
                Divider().padding(.leading, 16)
                statRow("Rejected", value: "\(rejectedDoctors)", color: .secondary)
                Divider().padding(.leading, 16)
                statRow("Total Appointments", value: "\(store.appointments.count)")
                Divider().padding(.leading, 16)
                statRow("Completed", value: "\(completedAppointments)")
                Divider().padding(.leading, 16)
                statRow("Avg Consultation Fee", value: formatGBP(avgConsultFee))
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.04), radius: 4)
        }
        .padding(.horizontal)
    }

    // MARK: - Product Metrics

    var productMetrics: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Shop & Products", icon: "bag.fill")

            VStack(spacing: 0) {
                statRow("Products Listed", value: "\(store.products.count)")
                Divider().padding(.leading, 16)
                statRow("Total Orders", value: "\(store.orders.count)")
                Divider().padding(.leading, 16)
                statRow("Confirmed Orders", value: "\(confirmedOrders)")
                Divider().padding(.leading, 16)
                statRow("Shipped", value: "\(shippedOrders)")
                Divider().padding(.leading, 16)
                statRow("Delivered", value: "\(deliveredOrders)")
                Divider().padding(.leading, 16)
                statRow("Cancelled", value: "\(cancelledOrders)", color: cancelledOrders > 0 ? .brandCoral : .secondary)
                Divider().padding(.leading, 16)
                statRow("Avg Order Value", value: formatGBP(avgOrderValue))
                Divider().padding(.leading, 16)
                statRow("Community Groups", value: "\(store.communityGroups.count)")
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.04), radius: 4)
        }
        .padding(.horizontal)
    }

    // MARK: - Operational Alerts

    var operationalAlerts: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Action Required", icon: "exclamationmark.triangle.fill")

            VStack(spacing: 8) {
                if pendingDoctors > 0 {
                    alertCard(
                        "\(pendingDoctors) doctor\(pendingDoctors == 1 ? "" : "s") awaiting approval",
                        icon: "stethoscope",
                        color: .brandCoral
                    )
                }

                if !store.userProfile.privacyPolicyAccepted {
                    alertCard("Privacy Policy not yet accepted", icon: "hand.raised.fill", color: .brandAmber)
                }

                if KeychainManager.shared.get(.anthropicAPIKey) == nil || KeychainManager.shared.get(.anthropicAPIKey)?.isEmpty == true {
                    alertCard("Anthropic API key not configured", icon: "key.fill", color: .brandAmber)
                }

                if pendingDoctors == 0 && store.userProfile.privacyPolicyAccepted {
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.brandGreen)
                        Text("All clear — no actions needed").font(.subheadline).foregroundColor(.brandGreen)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brandGreen.opacity(0.08))
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Computed Metrics

    var totalRevenue: Double {
        productRevenue + consultationRevenue
    }

    var productRevenue: Double {
        store.orders.filter { $0.status != .cancelled }.reduce(0) { $0 + $1.total }
    }

    var consultationRevenue: Double {
        store.appointments.filter { $0.isPaid }.reduce(0) { $0 + $1.feeGBP }
    }

    var platformCommission: Double {
        consultationRevenue * 0.5
    }

    var verifiedDoctors: Int {
        store.doctors.filter { $0.isVerified }.count
    }

    var pendingDoctors: Int {
        store.pendingDoctorRequests.count
    }

    var rejectedDoctors: Int {
        store.doctorRequests.filter { $0.status == .rejected }.count
    }

    var upcomingAppointments: Int {
        store.appointments.filter { $0.status == .upcoming && $0.date > Date() }.count
    }

    var completedAppointments: Int {
        store.appointments.filter { $0.status == .completed }.count
    }

    var avgConsultFee: Double {
        let paid = store.appointments.filter { $0.isPaid }
        guard !paid.isEmpty else { return 0 }
        return paid.reduce(0) { $0 + $1.feeGBP } / Double(paid.count)
    }

    var confirmedOrders: Int {
        store.orders.filter { $0.status == .confirmed }.count
    }

    var shippedOrders: Int {
        store.orders.filter { $0.status == .shipped }.count
    }

    var deliveredOrders: Int {
        store.orders.filter { $0.status == .delivered }.count
    }

    var cancelledOrders: Int {
        store.orders.filter { $0.status == .cancelled }.count
    }

    var avgOrderValue: Double {
        let valid = store.orders.filter { $0.status != .cancelled }
        guard !valid.isEmpty else { return 0 }
        return valid.reduce(0) { $0 + $1.total } / Double(valid.count)
    }

    // MARK: - Helper Views

    func sectionTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(.brandPurple)
            Text(title).font(.headline)
        }
    }

    func metricCard(_ title: String, value: String, icon: String, color: Color, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.title2).fontWeight(.bold)
                .foregroundColor(color)
            Text(title).font(.caption).foregroundColor(.primary)
            Text(subtitle).font(.caption2).foregroundColor(.secondary)
        }
        .padding(14)
        .background(color.opacity(0.06))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.15), lineWidth: 1))
    }

    func revenueRow(_ label: String, amount: Double, icon: String, color: Color, bold: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)
            Text(label)
                .font(bold ? .subheadline.bold() : .subheadline)
            Spacer()
            Text(formatGBP(amount))
                .font(bold ? .subheadline.bold() : .subheadline)
                .foregroundColor(bold ? color : .primary)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    func statRow(_ label: String, value: String, color: Color = .primary) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.subheadline).fontWeight(.medium).foregroundColor(color)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    func alertCard(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(color)
            Text(text).font(.subheadline).foregroundColor(color)
            Spacer()
            Image(systemName: "chevron.right").font(.caption2).foregroundColor(color.opacity(0.5))
        }
        .padding(12)
        .background(color.opacity(0.08))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.2), lineWidth: 1))
    }

    func formatGBP(_ amount: Double) -> String {
        String(format: "£%.2f", amount)
    }
}
