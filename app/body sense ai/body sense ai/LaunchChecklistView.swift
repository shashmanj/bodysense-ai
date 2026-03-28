//
//  LaunchChecklistView.swift
//  body sense ai
//
//  CEO-only App Store launch preparation checklist.
//  Interactive tracking of all steps needed to go live.
//

import SwiftUI

// MARK: - Launch Checklist Item

struct LaunchItem: Identifiable {
    let id = UUID()
    let category: String
    let title: String
    let detail: String
    let priority: Priority
    var isComplete: Bool = false

    enum Priority: String {
        case critical = "Critical"
        case important = "Important"
        case recommended = "Recommended"

        var color: Color {
            switch self {
            case .critical:    return .brandCoral
            case .important:   return .brandAmber
            case .recommended: return .brandTeal
            }
        }
    }
}

// MARK: - Launch Checklist View

struct LaunchChecklistView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("launchChecklist") private var checklistData: Data = Data()

    @State private var items: [LaunchItem] = LaunchChecklistView.defaultItems
    @State private var expandedCategory: String? = nil

    var completedCount: Int { items.filter(\.isComplete).count }
    var totalCount: Int { items.count }
    var progress: Double { totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0 }

    var categories: [String] {
        var seen: [String] = []
        for item in items {
            if !seen.contains(item.category) { seen.append(item.category) }
        }
        return seen
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Progress header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 8)
                            .frame(width: 100, height: 100)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(progress == 1 ? Color.brandGreen : Color.brandPurple, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 100, height: 100)
                            .animation(.spring, value: progress)
                        VStack(spacing: 2) {
                            Text("\(Int(progress * 100))%")
                                .font(.title2).fontWeight(.bold)
                            Text("\(completedCount)/\(totalCount)")
                                .font(.caption2).foregroundColor(.secondary)
                        }
                    }

                    Text(progress == 1 ? "Ready to Launch!" : "Launch Preparation")
                        .font(.headline)
                    Text("Complete all critical items before App Store submission")
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding(.top)

                // Categories
                ForEach(categories, id: \.self) { category in
                    categorySection(category)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Launch Checklist")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        .onAppear { loadState() }
        .onChange(of: items.map(\.isComplete)) { _, _ in saveState() }
    }

    func categorySection(_ category: String) -> some View {
        let categoryItems = items.filter { $0.category == category }
        let completed = categoryItems.filter(\.isComplete).count
        let isExpanded = expandedCategory == category || expandedCategory == nil

        return VStack(spacing: 0) {
            // Category header
            Button {
                withAnimation(.spring(response: 0.3)) {
                    expandedCategory = expandedCategory == category ? nil : category
                }
            } label: {
                HStack {
                    Text(category).font(.subheadline).fontWeight(.semibold)
                    Spacer()
                    Text("\(completed)/\(categoryItems.count)")
                        .font(.caption).fontWeight(.medium)
                        .foregroundColor(completed == categoryItems.count ? .brandGreen : .secondary)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(Array(categoryItems.enumerated()), id: \.element.id) { idx, item in
                    if let globalIdx = items.firstIndex(where: { $0.id == item.id }) {
                        Divider().padding(.leading, 52)
                        checklistRow(item: item, index: globalIdx)
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4)
    }

    func checklistRow(item: LaunchItem, index: Int) -> some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.2)) {
                    items[index].isComplete.toggle()
                }
            } label: {
                Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(item.isComplete ? .brandGreen : .secondary.opacity(0.4))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.title)
                        .font(.subheadline)
                        .strikethrough(item.isComplete)
                        .foregroundColor(item.isComplete ? .secondary : .primary)
                    Text(item.priority.rawValue)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(item.priority.color)
                        .cornerRadius(3)
                }
                Text(item.detail)
                    .font(.caption2).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    // MARK: - Persistence

    func saveState() {
        let completedIDs = items.filter(\.isComplete).map(\.title)
        if let data = try? JSONEncoder().encode(completedIDs) {
            checklistData = data
        }
    }

    func loadState() {
        guard let completedTitles = try? JSONDecoder().decode([String].self, from: checklistData) else { return }
        for i in items.indices {
            if completedTitles.contains(items[i].title) {
                items[i].isComplete = true
            }
        }
    }

    // MARK: - Default Checklist

    static let defaultItems: [LaunchItem] = [
        // Apple Developer
        LaunchItem(category: "Apple Developer Account", title: "Apple Developer Program enrolled", detail: "developer.apple.com — £79/year membership required for App Store", priority: .critical),
        LaunchItem(category: "Apple Developer Account", title: "Bundle ID registered", detail: "com.base693c0fe8f0479560056f69f4.app — Certificates, IDs & Profiles", priority: .critical),
        LaunchItem(category: "Apple Developer Account", title: "App ID capabilities configured", detail: "HealthKit, Push Notifications, Apple Pay, Associated Domains", priority: .critical),
        LaunchItem(category: "Apple Developer Account", title: "Apple Pay Merchant ID registered", detail: "merchant.co.uk.bodysenseai — Identifiers → Merchant IDs", priority: .critical),
        LaunchItem(category: "Apple Developer Account", title: "Push notification certificates", detail: "APNs key (.p8) for production push notifications", priority: .important),

        // Stripe
        LaunchItem(category: "Stripe Setup", title: "Stripe account verified", detail: "Business verification, bank account linked for GBP payouts", priority: .critical),
        LaunchItem(category: "Stripe Setup", title: "Live API keys generated", detail: "Switch from pk_test_ / sk_test_ to pk_live_ / sk_live_", priority: .critical),
        LaunchItem(category: "Stripe Setup", title: "Products & Prices created", detail: "Pro (£4.99/mo) and Premium (£8.99/mo) — copy Price IDs to app", priority: .critical),
        LaunchItem(category: "Stripe Setup", title: "Webhook endpoint configured", detail: "api.bodysenseai.co.uk/webhook — listen for payment events", priority: .important),
        LaunchItem(category: "Stripe Setup", title: "Apple Pay domain verified", detail: "Stripe Dashboard → Settings → Apple Pay → Verify domain", priority: .important),

        // Backend
        LaunchItem(category: "Backend Server", title: "Backend deployed (Railway/Render)", detail: "api.bodysenseai.co.uk — Node.js + Express + Stripe", priority: .critical),
        LaunchItem(category: "Backend Server", title: "SSL certificate active (HTTPS)", detail: "Auto-provided by Railway/Render — verify in browser", priority: .critical),
        LaunchItem(category: "Backend Server", title: "Environment variables set", detail: "STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, PORT", priority: .critical),
        LaunchItem(category: "Backend Server", title: "Firebase project created", detail: "console.firebase.google.com — Firestore enabled for user data sync", priority: .important),
        LaunchItem(category: "Backend Server", title: "Health check endpoint tested", detail: "curl https://api.bodysenseai.co.uk/ → should return JSON", priority: .important),

        // App Security
        LaunchItem(category: "Security & Privacy", title: "API keys in Keychain (not hardcoded)", detail: "Profile → API Keys & Security — all keys stored securely", priority: .critical),
        LaunchItem(category: "Security & Privacy", title: "Biometric lock working", detail: "Face ID / Touch ID toggle in Profile → Settings", priority: .important),
        LaunchItem(category: "Security & Privacy", title: "Privacy Policy published online", detail: "bodysenseai.co.uk/privacy — linked from app and App Store", priority: .critical),
        LaunchItem(category: "Security & Privacy", title: "Terms of Service published online", detail: "bodysenseai.co.uk/terms — linked from app and App Store", priority: .critical),
        LaunchItem(category: "Security & Privacy", title: "GDPR consent flow in onboarding", detail: "Privacy consent page shown before account creation", priority: .critical),
        LaunchItem(category: "Security & Privacy", title: "Data export working (Article 20)", detail: "Profile → Privacy & Data → Export My Data", priority: .important),
        LaunchItem(category: "Security & Privacy", title: "Account deletion working (Article 17)", detail: "Profile → Privacy & Data → Delete My Account", priority: .critical),
        LaunchItem(category: "Security & Privacy", title: "No print/NSLog in production", detail: "All debug logs removed from release builds", priority: .important),
        LaunchItem(category: "Security & Privacy", title: "SSL certificate pinning configured", detail: "Add SPKI hashes for api.anthropic.com and your backend", priority: .recommended),

        // App Store Connect
        LaunchItem(category: "App Store Connect", title: "App registered in App Store Connect", detail: "Name: BodySense AI, Category: Health & Fitness, SKU set", priority: .critical),
        LaunchItem(category: "App Store Connect", title: "App description written", detail: "Short description + detailed description with keywords", priority: .critical),
        LaunchItem(category: "App Store Connect", title: "Keywords optimised", detail: "Health, fitness, glucose, blood pressure, ring, wearable, AI, doctor", priority: .important),
        LaunchItem(category: "App Store Connect", title: "Screenshots uploaded", detail: "6.7\" (iPhone 16 Pro Max), 6.1\" (iPhone 16), 5.5\" (iPhone 8+)", priority: .critical),
        LaunchItem(category: "App Store Connect", title: "App preview video (optional)", detail: "15-30 second video showcasing key features", priority: .recommended),
        LaunchItem(category: "App Store Connect", title: "App icon uploaded (1024x1024)", detail: "Single PNG, no alpha, no rounded corners (Apple adds them)", priority: .critical),
        LaunchItem(category: "App Store Connect", title: "Privacy nutrition labels filled", detail: "Declare all data types: Health, Name, Email, Payment, Location", priority: .critical),
        LaunchItem(category: "App Store Connect", title: "Privacy Policy URL set", detail: "Required field — link to bodysenseai.co.uk/privacy", priority: .critical),
        LaunchItem(category: "App Store Connect", title: "Age rating configured", detail: "Medical/Health information → 17+ if diagnosing, otherwise 12+", priority: .important),
        LaunchItem(category: "App Store Connect", title: "Contact & support URL set", detail: "support@bodysenseai.co.uk or help page URL", priority: .important),

        // Testing
        LaunchItem(category: "Testing & QA", title: "TestFlight beta uploaded", detail: "Archive → Upload → TestFlight → Internal testing", priority: .critical),
        LaunchItem(category: "Testing & QA", title: "Internal testing (team)", detail: "Test all flows: onboarding, tracking, shop, doctors, chat", priority: .critical),
        LaunchItem(category: "Testing & QA", title: "External beta testers invited", detail: "Add 10-50 external testers via TestFlight public link", priority: .important),
        LaunchItem(category: "Testing & QA", title: "Payment flow tested end-to-end", detail: "Product purchase, subscription, doctor booking — all via Stripe sandbox", priority: .critical),
        LaunchItem(category: "Testing & QA", title: "Offline mode tested", detail: "App works without internet — health tracking continues", priority: .important),
        LaunchItem(category: "Testing & QA", title: "Dark mode verified (if supported)", detail: "All screens readable in dark mode", priority: .recommended),
        LaunchItem(category: "Testing & QA", title: "Accessibility audit", detail: "VoiceOver support, Dynamic Type, contrast ratios", priority: .recommended),

        // Business & Legal
        LaunchItem(category: "Business & Legal", title: "Company registered (UK)", detail: "BodySense AI Ltd — Companies House registration", priority: .critical),
        LaunchItem(category: "Business & Legal", title: "ICO registration (Data Protection)", detail: "ico.org.uk — Required for processing personal data in UK", priority: .critical),
        LaunchItem(category: "Business & Legal", title: "Business bank account", detail: "For Stripe payouts and company finances", priority: .critical),
        LaunchItem(category: "Business & Legal", title: "Medical disclaimer reviewed", detail: "\"Not a medical device\" disclaimer in Terms of Service", priority: .critical),
        LaunchItem(category: "Business & Legal", title: "Domain bodysenseai.co.uk active", detail: "Website with privacy policy, terms, and support info", priority: .important),
        LaunchItem(category: "Business & Legal", title: "Support email configured", detail: "support@bodysenseai.co.uk — responding to user queries", priority: .important),

        // Final Submission
        LaunchItem(category: "Final Submission", title: "Switch Stripe to LIVE keys", detail: "pk_live_ in Keychain, sk_live_ on backend server", priority: .critical),
        LaunchItem(category: "Final Submission", title: "Archive with Release config", detail: "Product → Archive → Validate → Upload to App Store Connect", priority: .critical),
        LaunchItem(category: "Final Submission", title: "Submit for App Review", detail: "App Store Connect → Submit for Review — typically 24-48 hours", priority: .critical),
        LaunchItem(category: "Final Submission", title: "Prepare launch marketing", detail: "Social media posts, Product Hunt, press kit ready", priority: .recommended),
    ]
}
