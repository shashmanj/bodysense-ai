//
//  SubscriptionGate.swift
//  body sense ai
//
//  Subscription gating: view modifier + upgrade prompt for Pro/Premium features.
//  Enforces tier-based access control across the app.
//

import SwiftUI
import StoreKit

// MARK: - Subscription Gate View Modifier

/// Wraps any view with a subscription check. If the user's plan is below the
/// required minimum, an UpgradePromptView overlay is shown instead.
struct SubscriptionGateModifier: ViewModifier {
    let minimumPlan: SubscriptionPlan
    let store: HealthStore
    @State private var showUpgrade = false

    private var hasAccess: Bool {
        store.subscription >= minimumPlan
    }

    func body(content: Content) -> some View {
        if hasAccess {
            content
        } else {
            content
                .disabled(true)
                .blur(radius: 4)
                .overlay {
                    UpgradePromptView(
                        requiredPlan: minimumPlan,
                        store: store,
                        isPresented: .constant(true)
                    )
                }
        }
    }
}

extension View {
    /// Gate this view behind a subscription tier. Shows an upgrade overlay if the
    /// user's current plan is below `minimumPlan`.
    func requiresSubscription(_ minimumPlan: SubscriptionPlan, store: HealthStore) -> some View {
        modifier(SubscriptionGateModifier(minimumPlan: minimumPlan, store: store))
    }
}

// MARK: - Upgrade Prompt View

/// Shown when a user tries to access a feature that requires a higher subscription tier.
/// Displays the required plan, pricing, features, and a purchase button.
struct UpgradePromptView: View {
    let requiredPlan: SubscriptionPlan
    let store: HealthStore
    @Binding var isPresented: Bool
    @State private var isPurchasing = false
    @State private var purchaseError: String?

    private var storeKit: StoreKitManager { StoreKitManager.shared }

    var body: some View {
        VStack(spacing: 20) {
            // Lock icon
            Image(systemName: "lock.fill")
                .font(.system(size: 36))
                .foregroundColor(requiredPlan.color)
                .padding(.top, 8)

            // Title
            Text("\(requiredPlan.badge) Feature")
                .font(.title3)
                .fontWeight(.bold)

            // Description
            Text("This feature requires a \(requiredPlan.rawValue) subscription.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Features list
            VStack(alignment: .leading, spacing: 8) {
                ForEach(requiredPlan.features.prefix(5), id: \.self) { feature in
                    Label(feature, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 24)

            // Price badge
            Text(requiredPlan.price)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(requiredPlan.color)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(requiredPlan.color.opacity(0.12))
                .cornerRadius(100)

            // Upgrade button
            Button {
                Task { await purchasePlan() }
            } label: {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                    }
                    Text(isPurchasing ? "Processing..." : "Upgrade to \(requiredPlan.badge)")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(requiredPlan.color)
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .disabled(isPurchasing)
            .padding(.horizontal, 24)

            // Maybe Later button
            if isPresented {
                Button("Maybe Later") {
                    isPresented = false
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }

            if let error = purchaseError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 24)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .padding(.horizontal, 24)
    }

    private func purchasePlan() async {
        isPurchasing = true
        purchaseError = nil

        let product: StoreKit.Product?
        switch requiredPlan {
        case .pro:     product = storeKit.proMonthly
        case .premium: product = storeKit.premiumMonthly
        case .free:    product = nil
        }

        guard let product else {
            // If StoreKit products haven't loaded yet, try loading them
            await storeKit.loadProducts()
            let retryProduct: StoreKit.Product?
            switch requiredPlan {
            case .pro:     retryProduct = storeKit.proMonthly
            case .premium: retryProduct = storeKit.premiumMonthly
            case .free:    retryProduct = nil
            }
            guard let retryProduct else {
                purchaseError = "Unable to load subscription products. Please try again."
                isPurchasing = false
                return
            }
            let success = await storeKit.purchase(retryProduct)
            if success {
                storeKit.syncToHealthStore(store)
            }
            isPurchasing = false
            return
        }

        let success = await storeKit.purchase(product)
        if success {
            storeKit.syncToHealthStore(store)
        }
        isPurchasing = false
    }
}

// MARK: - Upgrade Prompt Sheet

/// A sheet version of the upgrade prompt, used when you want to present it modally
/// (e.g. when AI message limit is reached).
struct UpgradePromptSheet: View {
    let requiredPlan: SubscriptionPlan
    let store: HealthStore
    let reason: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Reason banner
                    Text(reason)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 16)

                    UpgradePromptView(
                        requiredPlan: requiredPlan,
                        store: store,
                        isPresented: .constant(true)
                    )
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Maybe Later") { dismiss() }
                }
            }
        }
    }
}

// MARK: - AI Message Limit Banner

/// Shows current AI usage and a warning when approaching or at the limit.
struct AIMessageLimitBanner: View {
    let store: HealthStore

    private var used: Int { store.aiMessagesUsedToday }
    private var limit: Int { store.subscription.dailyAIMessageLimit }
    private var remaining: Int { store.aiMessagesRemaining }
    private var isNearLimit: Bool { remaining <= 3 && remaining > 0 }
    private var isAtLimit: Bool { remaining <= 0 }

    var body: some View {
        if isAtLimit {
            bannerContent(
                icon: "exclamationmark.circle.fill",
                text: "You have used all \(limit) messages today. Upgrade for more.",
                color: .red
            )
        } else if isNearLimit {
            bannerContent(
                icon: "info.circle.fill",
                text: "You have used \(used) of \(limit) messages today. \(remaining) remaining.",
                color: .orange
            )
        }
    }

    private func bannerContent(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.12))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}
