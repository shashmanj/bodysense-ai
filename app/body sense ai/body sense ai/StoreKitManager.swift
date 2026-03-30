//
//  StoreKitManager.swift
//  body sense ai
//
//  Native StoreKit 2 subscription manager for in-app purchases.
//  Handles Pro (£4.99/mo) and Premium (£8.99/mo) auto-renewable subscriptions.
//  100% Apple-native — no third-party payment SDKs.
//

import Foundation
import StoreKit

/// Manages StoreKit 2 subscriptions and in-app purchases.
@MainActor
@Observable
final class StoreKitManager {

    static let shared = StoreKitManager()

    // MARK: - Product IDs

    /// StoreKit product identifiers — must match App Store Connect configuration.
    enum ProductID {
        static let proMonthly     = "co.uk.bodysenseai.pro.monthly"
        static let premiumMonthly = "co.uk.bodysenseai.premium.monthly"
        static let proYearly      = "co.uk.bodysenseai.pro.yearly"
        static let premiumYearly  = "co.uk.bodysenseai.premium.yearly"

        static let all: [String] = [proMonthly, premiumMonthly, proYearly, premiumYearly]

        static let subscriptionGroupID = "bodysenseai_subscriptions"
    }

    // MARK: - State

    /// Available products from the App Store.
    var products: [StoreKit.Product] = []

    /// The user's current active subscription, if any.
    var currentSubscription: StoreKit.Product?

    /// Whether the user has an active Pro or Premium subscription.
    var isPro: Bool = false
    var isPremium: Bool = false

    /// Convenience: user has any paid subscription.
    var hasActiveSubscription: Bool { isPro || isPremium }

    /// Loading state.
    var isLoading: Bool = false

    /// Error message for display.
    var errorMessage: String?

    /// Purchase in progress.
    var isPurchasing: Bool = false

    // MARK: - Transaction Listener

    /// Transaction listener task.
    nonisolated(unsafe) private var transactionListener: Task<Void, Error>?

    // MARK: - Init

    private init() {
        // Start listening for transaction updates
        transactionListener = listenForTransactions()

        // Load products and check entitlements
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    /// Fetch available products from the App Store.
    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let storeProducts = try await StoreKit.Product.products(for: Set(ProductID.all))
            products = storeProducts.sorted { $0.price < $1.price }
            isLoading = false
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            isLoading = false
            #if DEBUG
            print("❌ StoreKit: Failed to load products: \(error)")
            #endif
        }
    }

    // MARK: - Purchase

    /// Purchase a subscription product.
    func purchase(_ product: StoreKit.Product) async -> Bool {
        isPurchasing = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                // Finish the transaction
                await transaction.finish()

                // Update subscription status
                await updateSubscriptionStatus()

                isPurchasing = false
                return true

            case .userCancelled:
                isPurchasing = false
                return false

            case .pending:
                isPurchasing = false
                errorMessage = "Purchase is pending approval."
                return false

            @unknown default:
                isPurchasing = false
                return false
            }
        } catch {
            isPurchasing = false
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            #if DEBUG
            print("❌ StoreKit: Purchase failed: \(error)")
            #endif
            return false
        }
    }

    // MARK: - Restore Purchases

    /// Restore previously purchased subscriptions.
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Subscription Status

    /// Check current entitlements and update subscription state.
    /// Automatically syncs the result to HealthStore.
    func updateSubscriptionStatus() async {
        var foundPro = false
        var foundPremium = false
        var activeProduct: StoreKit.Product?

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if transaction.revocationDate == nil {
                switch transaction.productID {
                case ProductID.proMonthly, ProductID.proYearly:
                    foundPro = true
                    activeProduct = products.first { $0.id == transaction.productID }
                case ProductID.premiumMonthly, ProductID.premiumYearly:
                    foundPremium = true
                    foundPro = true // Premium includes Pro features
                    activeProduct = products.first { $0.id == transaction.productID }
                default:
                    break
                }
            }
        }

        isPro = foundPro
        isPremium = foundPremium
        currentSubscription = activeProduct

        // Keep HealthStore in sync with StoreKit state
        syncToHealthStore(HealthStore.shared)
    }

    // MARK: - Map to SubscriptionPlan

    /// Convert current StoreKit subscription state to HealthModels SubscriptionPlan.
    var currentPlan: SubscriptionPlan {
        if isPremium { return .premium }
        if isPro { return .pro }
        return .free
    }

    /// Sync StoreKit subscription status to HealthStore.
    func syncToHealthStore(_ store: HealthStore) {
        store.subscription = currentPlan
        store.save()
    }

    // MARK: - Product Helpers

    /// Get the monthly Pro product.
    var proMonthly: StoreKit.Product? {
        products.first { $0.id == ProductID.proMonthly }
    }

    /// Get the monthly Premium product.
    var premiumMonthly: StoreKit.Product? {
        products.first { $0.id == ProductID.premiumMonthly }
    }

    /// Get the yearly Pro product.
    var proYearly: StoreKit.Product? {
        products.first { $0.id == ProductID.proYearly }
    }

    /// Get the yearly Premium product.
    var premiumYearly: StoreKit.Product? {
        products.first { $0.id == ProductID.premiumYearly }
    }

    // MARK: - Private

    /// Verify a StoreKit transaction.
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    /// Listen for transaction updates (renewals, revocations, refunds).
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { break }

                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.updateSubscriptionStatus()
                }
            }
        }
    }
}

// MARK: - Custom Errors

enum StoreKitError: Error, LocalizedError {
    case failedVerification
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .failedVerification: return "Transaction verification failed"
        case .productNotFound: return "Product not found in the App Store"
        }
    }
}
