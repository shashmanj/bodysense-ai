//
//  CustomerCareView.swift
//  body sense ai
//
//  Help & Support — Customer care with AI-powered issue resolution.
//  Covers payments, subscriptions, technical issues, and general support.
//

import SwiftUI
import UserNotifications

// MARK: - Issue Category

enum SupportCategory: String, CaseIterable, Identifiable {
    case payment       = "Payment Issues"
    case subscription  = "Subscription & Plans"
    case technical     = "Technical Issues"
    case account       = "Account & Profile"
    case ring          = "BodySense Ring"
    case general       = "General Support"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .payment:      return "creditcard.fill"
        case .subscription: return "crown.fill"
        case .technical:    return "wrench.and.screwdriver.fill"
        case .account:      return "person.crop.circle.fill"
        case .ring:         return "circle.dotted.circle"
        case .general:      return "questionmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .payment:      return .brandCoral
        case .subscription: return .brandAmber
        case .technical:    return .brandPurple
        case .account:      return .brandTeal
        case .ring:         return Color(hex: "#6C63FF")
        case .general:      return .secondary
        }
    }

    var quickActions: [String] {
        switch self {
        case .payment:
            return ["Payment failed / declined", "Stuck payment — charged but no access",
                    "Request a refund", "Update payment method", "Apple Pay not working"]
        case .subscription:
            return ["Cancel my subscription", "Downgrade to free plan",
                    "Upgrade to Pro / Premium", "Subscription not activating",
                    "Gift code not working"]
        case .technical:
            return ["App crashing or freezing", "Data not syncing",
                    "Notifications not working", "App running slowly",
                    "Login / authentication issue"]
        case .account:
            return ["Update my email or name", "Delete my account",
                    "Export my health data", "Privacy & data request",
                    "Change password"]
        case .ring:
            return ["Ring not connecting via Bluetooth", "Ring battery draining fast",
                    "Ring not tracking sleep", "Ring sizing issue",
                    "Order / delivery status"]
        case .general:
            return ["How do I use BodySense AI?", "Report a bug",
                    "Feature request", "Doctor marketplace question",
                    "Other enquiry"]
        }
    }
}

// MARK: - Support Ticket

struct SupportTicket: Identifiable {
    let id          = UUID()
    let category    : SupportCategory
    let issue       : String
    let detail      : String
    let date        : Date = Date()
    var status      : TicketStatus = .open
    var aiResponse  : String? = nil
    var isEscalated : Bool = false
    var ceoReply    : String? = nil
}

enum TicketStatus: String {
    case open       = "Open"
    case inProgress = "In Progress"
    case resolved   = "Resolved"
    case escalated  = "Escalated"

    var color: Color {
        switch self {
        case .open:       return .brandAmber
        case .inProgress: return .brandPurple
        case .resolved:   return .brandGreen
        case .escalated:  return .brandCoral
        }
    }

    var icon: String {
        switch self {
        case .open:       return "circle"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .resolved:   return "checkmark.circle.fill"
        case .escalated:  return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Customer Care View

struct CustomerCareView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var tickets: [SupportTicket] = []
    @State private var selectedCategory: SupportCategory? = nil
    @State private var showNewTicket = false
    @State private var showDeleteAccountAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // ── Header card ──
                    supportHeader

                    // ── Quick help categories ──
                    categoriesGrid

                    // ── FAQ section ──
                    faqSection

                    // ── Active tickets ──
                    if !tickets.isEmpty {
                        ticketsSection
                    }

                    // ── Contact info ──
                    contactSection

                    // ── Delete Account (placed in Help & Support per Apple / App Store guidelines) ──
                    deleteAccountSection

                    Spacer(minLength: 32)
                }
                .padding(.top)
            }
            .background(Color.brandBg.ignoresSafeArea())
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(item: $selectedCategory) { cat in
            SupportCategorySheet(category: cat, tickets: $tickets)
        }
        .onAppear {
            // Load persisted tickets
            tickets = store.supportTickets.map { record in
                var ticket = SupportTicket(
                    category: SupportCategory(rawValue: record.category) ?? .general,
                    issue: record.issue,
                    detail: record.detail
                )
                ticket.status = TicketStatus(rawValue: record.status) ?? .open
                ticket.aiResponse = record.aiResponse
                ticket.isEscalated = record.isEscalated
                ticket.ceoReply = record.ceoReply
                return ticket
            }
        }
    }

    // ── Delete Account Section ──
    var deleteAccountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account").font(.headline).padding(.horizontal)
            VStack(spacing: 0) {
                Button(role: .destructive) {
                    showDeleteAccountAlert = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "trash.fill")
                            .font(.body).foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.red).cornerRadius(8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Delete Account").font(.subheadline).foregroundColor(.red)
                            Text("Permanently erase all data, cloud backups, and account")
                                .font(.caption2).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                    }
                    .padding(12)
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 4)
            .padding(.horizontal)
        }
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Everything", role: .destructive) {
                Task {
                    await AuthService.shared.deleteAccount(store: store)
                    UserDefaults.standard.set(false, forKey: "onboardingDone")
                }
            }
        } message: {
            Text("This will permanently delete all your health data, cloud backups, and account. This action cannot be undone.")
        }
    }

    // ── Header ──
    var supportHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.brandPurple, Color(hex: "#4834d4")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 64, height: 64)
                Image(systemName: "headphones.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
            }
            Text("How can we help?")
                .font(.title2).fontWeight(.bold)
            Text("Get help with payments, subscriptions, technical issues, or chat with our AI support agent.")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.vertical, 8)
    }

    // ── Categories Grid ──
    var categoriesGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose a topic").font(.headline).padding(.horizontal)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(SupportCategory.allCases) { cat in
                    Button { selectedCategory = cat } label: {
                        HStack(spacing: 12) {
                            Image(systemName: cat.icon)
                                .font(.title3).foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(cat.color).cornerRadius(10)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(cat.rawValue)
                                    .font(.caption).fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Text("\(cat.quickActions.count) topics")
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.05), radius: 4)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // ── FAQ Section ──
    var faqSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Frequently Asked").font(.headline).padding(.horizontal)
            VStack(spacing: 0) {
                faqRow("How do I cancel my subscription?",
                       answer: "Go to Profile → Settings → Subscription & Plans → Cancel. You'll keep access until your billing period ends.")
                Divider().padding(.leading, 16)
                faqRow("My payment failed, what do I do?",
                       answer: "Check your card details are current. Go to Profile → Subscription → Update Payment. If the issue persists, contact us below.")
                Divider().padding(.leading, 16)
                faqRow("How do I connect my BodySense Ring?",
                       answer: "Go to Profile → Devices → Add Device → BodySense Ring. Make sure Bluetooth is on and the ring is charged.")
                Divider().padding(.leading, 16)
                faqRow("Can I export my health data?",
                       answer: "Yes! Go to Profile → Settings → Account & Profile and select 'Export my health data'. We'll generate a file for you.")
            }
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 4)
            .padding(.horizontal)
        }
    }

    // ── Tickets Section ──
    var ticketsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Tickets").font(.headline).padding(.horizontal)
            ForEach(tickets) { ticket in
                HStack(spacing: 12) {
                    Image(systemName: ticket.category.icon)
                        .foregroundColor(ticket.category.color)
                        .frame(width: 36, height: 36)
                        .background(ticket.category.color.opacity(0.12))
                        .cornerRadius(8)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(ticket.issue).font(.subheadline).fontWeight(.medium).lineLimit(1)
                        Text(ticket.date.formatted(.dateTime.day().month().hour().minute()))
                            .font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: ticket.status.icon)
                            .font(.caption2)
                        Text(ticket.status.rawValue)
                            .font(.caption2).fontWeight(.medium)
                    }
                    .foregroundColor(ticket.status.color)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(ticket.status.color.opacity(0.12))
                    .cornerRadius(8)
                }
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.04), radius: 3)
                .padding(.horizontal)
            }
        }
    }

    // ── Contact Section ──
    var contactSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Still need help?").font(.headline).padding(.horizontal)
            VStack(spacing: 0) {
                contactRow("Email us", icon: "envelope.fill", detail: "support@bodysenseai.co.uk", color: .brandTeal)
                Divider().padding(.leading, 52)
                contactRow("Visit our website", icon: "globe", detail: "bodysenseai.co.uk/help", color: .brandPurple)
                Divider().padding(.leading, 52)
                contactRow("Response time", icon: "clock.fill", detail: "Usually within 24 hours", color: .brandAmber)
            }
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 4)
            .padding(.horizontal)
        }
    }

    func faqRow(_ question: String, answer: String) -> some View {
        DisclosureGroup {
            Text(answer)
                .font(.caption).foregroundColor(.secondary)
                .padding(.bottom, 8)
        } label: {
            Text(question).font(.subheadline).foregroundColor(.primary)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    func contactRow(_ label: String, icon: String, detail: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.body).foregroundColor(.white)
                .frame(width: 32, height: 32).background(color).cornerRadius(8)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.subheadline).foregroundColor(.primary)
                Text(detail).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
    }
}

// MARK: - Support Category Sheet

struct SupportCategorySheet: View {
    let category: SupportCategory
    @Binding var tickets: [SupportTicket]
    @Environment(\.dismiss) var dismiss
    @State private var selectedIssue: String? = nil
    @State private var additionalDetail = ""
    @State private var isSubmitting = false
    @State private var aiReply: String? = nil
    @State private var ticketSubmitted = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Category header
                    HStack(spacing: 14) {
                        Image(systemName: category.icon)
                            .font(.title2).foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(category.color).cornerRadius(12)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.rawValue).font(.headline)
                            Text("Select your issue below").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Quick action buttons
                    VStack(spacing: 8) {
                        ForEach(category.quickActions, id: \.self) { action in
                            Button {
                                withAnimation { selectedIssue = action }
                            } label: {
                                HStack {
                                    Text(action)
                                        .font(.subheadline)
                                        .foregroundColor(selectedIssue == action ? .white : .primary)
                                    Spacer()
                                    Image(systemName: selectedIssue == action ? "checkmark.circle.fill" : "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(selectedIssue == action ? .white : .secondary)
                                }
                                .padding(14)
                                .background(selectedIssue == action
                                    ? AnyShapeStyle(LinearGradient(colors: [category.color, category.color.opacity(0.8)],
                                                       startPoint: .leading, endPoint: .trailing))
                                    : AnyShapeStyle(Color(.systemBackground)))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.04), radius: 3)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Detail input
                    if selectedIssue != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tell us more (optional)")
                                .font(.subheadline).fontWeight(.medium)
                            TextEditor(text: $additionalDetail)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        // Submit button
                        Button {
                            submitTicket()
                        } label: {
                            HStack {
                                if isSubmitting {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                    Text("Get Help")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(category.color)
                            .cornerRadius(14)
                        }
                        .disabled(isSubmitting)
                        .padding(.horizontal)
                    }

                    // AI Response
                    if let reply = aiReply {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.brandPurple)
                                Text("AI Support Agent")
                                    .font(.subheadline).fontWeight(.semibold)
                            }
                            Text(reply)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(Color.brandPurple.opacity(0.06))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.brandPurple.opacity(0.15), lineWidth: 1))
                        .padding(.horizontal)

                        if ticketSubmitted {
                            VStack(spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.brandGreen)
                                    Text("Ticket #\(tickets.count) created — we'll follow up via email if needed.")
                                        .font(.caption).foregroundColor(.secondary)
                                }

                                // Escalate to our team button
                                Button {
                                    escalateTicket()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                        Text("Not resolved? Escalate to our team")
                                    }
                                    .font(.caption).fontWeight(.medium)
                                    .foregroundColor(.brandCoral)
                                    .padding(.horizontal, 16).padding(.vertical, 10)
                                    .background(Color.brandCoral.opacity(0.1))
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 32)
                }
                .padding(.top)
            }
            .background(Color.brandBg.ignoresSafeArea())
            .navigationTitle(category.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func submitTicket() {
        guard let issue = selectedIssue else { return }
        isSubmitting = true

        // Create the ticket
        var ticket = SupportTicket(
            category: category,
            issue: issue,
            detail: additionalDetail
        )

        // Use AI to generate an immediate response
        Task {
            let prompt = buildSupportPrompt(issue: issue, detail: additionalDetail)
            if await AIClient.shared.isConfigured() {
                do {
                    let reply = try await AIClient.shared.send(
                        system: AISystemPrompts.customerCare,
                        userMessage: prompt
                    )
                    ticket.aiResponse = reply
                    ticket.status = .inProgress
                    await MainActor.run {
                        aiReply = reply
                        tickets.append(ticket)
                        ticketSubmitted = true
                        isSubmitting = false
                        // Persist ticket
                        persistTicket(ticket)
                    }
                    return
                } catch { /* fall through to offline response */ }
            }

            // Offline fallback
            let fallback = offlineResponse(for: issue)
            ticket.aiResponse = fallback
            ticket.status = .inProgress
            await MainActor.run {
                aiReply = fallback
                tickets.append(ticket)
                ticketSubmitted = true
                isSubmitting = false
                persistTicket(ticket)
            }
        }
    }

    private func buildSupportPrompt(issue: String, detail: String) -> String {
        var prompt = "Customer support issue: \(issue)\nCategory: \(category.rawValue)\n"
        if !detail.isEmpty { prompt += "Additional details: \(detail)\n" }
        prompt += "\nPlease help resolve this issue with clear, step-by-step guidance."
        return prompt
    }

    private func persistTicket(_ ticket: SupportTicket) {
        let store = HealthStore.shared
        var record = SupportTicketRecord(
            category: category.rawValue,
            issue: ticket.issue,
            detail: ticket.detail,
            userEmail: store.userProfile.email
        )
        record.status = ticket.status.rawValue
        record.aiResponse = ticket.aiResponse
        store.supportTickets.append(record)
        store.save()
    }

    private func escalateTicket() {
        guard var lastTicket = tickets.last else { return }
        lastTicket.status = .escalated
        lastTicket.isEscalated = true
        tickets[tickets.count - 1] = lastTicket

        // Persist to HealthStore
        let store = HealthStore.shared
        var record = SupportTicketRecord(
            category: category.rawValue,
            issue: lastTicket.issue,
            detail: lastTicket.detail,
            userEmail: store.userProfile.email
        )
        record.status = "Escalated"
        record.isEscalated = true
        record.escalatedAt = Date()
        record.aiResponse = lastTicket.aiResponse
        store.supportTickets.append(record)
        store.save()

        // Send notification to CEO
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Customer Ticket Escalated"
        content.body = "Issue: \(lastTicket.issue) — Customer needs CEO attention."
        content.sound = .default
        content.userInfo = ["type": "ticketEscalation", "ticketId": record.id.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "escalation_\(record.id.uuidString)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    private func offlineResponse(for issue: String) -> String {
        let lower = issue.lowercased()
        if lower.contains("cancel") {
            return "To cancel your subscription:\n\n1. Go to Profile → Settings → Subscription & Plans\n2. Tap 'Manage Subscription'\n3. Select 'Cancel Subscription'\n\nYou'll keep access until your current billing period ends. If you've been charged incorrectly, email support@bodysenseai.co.uk and we'll sort it within 24 hours."
        } else if lower.contains("refund") {
            return "To request a refund:\n\n1. Email support@bodysenseai.co.uk with your account email and the charge date\n2. Include the reason for your refund request\n3. We process refunds within 3-5 business days\n\nFor App Store purchases, you may also request a refund through Apple at reportaproblem.apple.com."
        } else if lower.contains("stuck") || lower.contains("charged but") {
            return "If you were charged but didn't receive access:\n\n1. Close and reopen the app completely\n2. Go to Profile → Subscription → Restore Purchases\n3. If still stuck, your payment may be processing (up to 15 minutes)\n\nIf the issue persists, email support@bodysenseai.co.uk with a screenshot of the charge."
        } else if lower.contains("connect") || lower.contains("bluetooth") {
            return "To fix Bluetooth connection issues:\n\n1. Make sure your ring is charged (green LED when placed on charger)\n2. Turn Bluetooth off and on in your iPhone Settings\n3. Open BodySense AI → Profile → Devices → reconnect your ring\n4. Keep the ring close to your phone during pairing\n\nIf pairing fails, try restarting your iPhone and your ring."
        } else {
            return "Thank you for reaching out. We've logged your issue and our support team will review it shortly.\n\nFor urgent matters, email us directly at support@bodysenseai.co.uk — we typically respond within 24 hours.\n\nIn the meantime, check our FAQ section in Help & Support for quick answers."
        }
    }
}
