//
//  ApplePayManager.swift
//  body sense ai
//
//  Native Apple Pay manager for physical product purchases and appointments.
//  Uses PassKit framework — 100% Apple-native.
//  Merchant ID: merchant.co.uk.bodysenseai
//

import Foundation
@preconcurrency import PassKit
import SwiftUI

/// Result of an Apple Pay transaction.
enum PaymentResult {
    case success(transactionId: String, method: String)
    case failed(error: String)
    case cancelled
}

/// Manages Apple Pay for physical product purchases and doctor appointment payments.
@MainActor
@Observable
final class ApplePayManager: NSObject {

    static let shared = ApplePayManager()

    // MARK: - Configuration

    /// Apple Pay Merchant ID — must match Xcode entitlements.
    private let merchantIdentifier = "merchant.co.uk.bodysenseai"

    /// Supported payment networks.
    private let supportedNetworks: [PKPaymentNetwork] = [
        .visa, .masterCard, .amex, .discover
    ]

    /// Country code for transactions.
    private let countryCode = "GB"

    /// Currency code for transactions.
    private let currencyCode = "GBP"

    // MARK: - State

    var isProcessing: Bool = false
    var errorMessage: String?

    // MARK: - Completion Handler (stored for delegate callbacks)

    private var paymentCompletion: ((PaymentResult) -> Void)?
    private var authorizationCompletion: ((PKPaymentAuthorizationResult) -> Void)?

    // MARK: - Init

    private override init() {
        super.init()
    }

    // MARK: - Availability

    /// Check if Apple Pay is available on this device with supported cards.
    var canMakePayments: Bool {
        PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks)
    }

    /// Check if Apple Pay is set up (has cards added).
    var isApplePayAvailable: Bool {
        PKPaymentAuthorizationController.canMakePayments()
    }

    // MARK: - Create Payment Request

    /// Build a PKPaymentRequest for a given amount and label.
    func createPaymentRequest(
        items: [(label: String, amount: Double)],
        shippingCost: Double? = nil
    ) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = merchantIdentifier
        request.supportedNetworks = supportedNetworks
        request.merchantCapabilities = .threeDSecure
        request.countryCode = countryCode
        request.currencyCode = currencyCode

        var summaryItems: [PKPaymentSummaryItem] = []

        // Add line items
        var subtotal: Double = 0
        for item in items {
            let amount = NSDecimalNumber(value: item.amount)
            summaryItems.append(PKPaymentSummaryItem(label: item.label, amount: amount))
            subtotal += item.amount
        }

        // Add shipping if applicable
        var total = subtotal
        if let shipping = shippingCost, shipping > 0 {
            summaryItems.append(PKPaymentSummaryItem(
                label: "Shipping",
                amount: NSDecimalNumber(value: shipping)
            ))
            total += shipping
        }

        // Total — must be labeled with merchant name
        summaryItems.append(PKPaymentSummaryItem(
            label: "BodySense AI",
            amount: NSDecimalNumber(value: total),
            type: .final
        ))

        request.paymentSummaryItems = summaryItems
        return request
    }

    // MARK: - Process Payment

    /// Present Apple Pay sheet and process payment.
    /// - Parameters:
    ///   - items: Line items to display (label + amount in GBP).
    ///   - shippingCost: Optional shipping cost.
    ///   - completion: Called with PaymentResult when done.
    func processPayment(
        items: [(label: String, amount: Double)],
        shippingCost: Double? = nil,
        completion: @escaping (PaymentResult) -> Void
    ) {
        guard canMakePayments else {
            completion(.failed(error: "Apple Pay is not available on this device"))
            return
        }

        isProcessing = true
        errorMessage = nil
        paymentCompletion = completion

        let request = createPaymentRequest(items: items, shippingCost: shippingCost)

        let controller = PKPaymentAuthorizationController(paymentRequest: request)
        controller.delegate = self
        controller.present { presented in
            if !presented {
                Task { @MainActor [weak self] in
                    self?.isProcessing = false
                    self?.paymentCompletion?(.failed(error: "Failed to present Apple Pay"))
                }
            }
        }
    }

    // MARK: - Convenience Methods

    /// Process a single product purchase.
    func purchaseProduct(
        name: String,
        amount: Double,
        quantity: Int = 1,
        shipping: Double? = nil,
        completion: @escaping (PaymentResult) -> Void
    ) {
        let label = quantity > 1 ? "\(name) × \(quantity)" : name
        let total = amount * Double(quantity)
        processPayment(items: [(label, total)], shippingCost: shipping, completion: completion)
    }

    /// Process a doctor appointment payment.
    func payForAppointment(
        doctorName: String,
        appointmentType: String,
        fee: Double,
        completion: @escaping (PaymentResult) -> Void
    ) {
        let label = "\(appointmentType) consultation — Dr. \(doctorName)"
        processPayment(items: [(label, fee)], completion: completion)
    }

    /// Process a cart checkout.
    func checkoutCart(
        items: [(name: String, price: Double, quantity: Int)],
        shippingCost: Double,
        completion: @escaping (PaymentResult) -> Void
    ) {
        let paymentItems = items.map { item in
            let label = item.quantity > 1 ? "\(item.name) × \(item.quantity)" : item.name
            return (label: label, amount: item.price * Double(item.quantity))
        }
        processPayment(items: paymentItems, shippingCost: shippingCost, completion: completion)
    }
}

// MARK: - PKPaymentAuthorizationControllerDelegate

extension ApplePayManager: PKPaymentAuthorizationControllerDelegate {

    nonisolated func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        // Generate a transaction ID from the payment token
        let transactionId = payment.token.transactionIdentifier.isEmpty
            ? UUID().uuidString
            : payment.token.transactionIdentifier

        // Determine payment method
        let method = payment.token.paymentMethod.displayName ?? "Apple Pay"

        // Report success immediately
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.paymentCompletion?(.success(transactionId: transactionId, method: "Apple Pay (\(method))"))
        }
    }

    nonisolated func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss {
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isProcessing = false

                // If paymentCompletion hasn't been called yet, user cancelled
                if self.authorizationCompletion == nil {
                    self.paymentCompletion?(.cancelled)
                }

                // Clean up
                self.paymentCompletion = nil
                self.authorizationCompletion = nil
            }
        }
    }
}

// MARK: - Apple Pay Button (SwiftUI)

/// Native Apple Pay button for SwiftUI.
struct ApplePayButtonView: View {
    let action: () -> Void

    var body: some View {
        ApplePayButtonRepresentable(action: action)
            .frame(height: 50)
            .cornerRadius(12)
    }
}

/// UIViewRepresentable wrapper for PKPaymentButton.
struct ApplePayButtonRepresentable: UIViewRepresentable {
    let action: () -> Void

    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .automatic)
        button.addTarget(context.coordinator, action: #selector(Coordinator.handleTap), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    class Coordinator: NSObject {
        let action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func handleTap() { action() }
    }
}

// MARK: - Apple Pay Checkout View

/// Reusable checkout view with Apple Pay as the primary (and only) payment method.
/// Apple Pay checkout view for purchases and subscriptions.
struct ApplePayCheckoutView: View {
    let title: String
    let subtitle: String
    let amountGBP: Double
    let onSuccess: (String, String) -> Void  // (transactionId, method)
    var onCancel: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var payManager = ApplePayManager.shared
    @State private var showError = false
    @State private var errorText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                // ── Order Summary ──
                VStack(spacing: 8) {
                    Image(systemName: "bag.fill")
                        .font(.largeTitle)
                        .foregroundColor(.brandPurple)

                    Text(title)
                        .font(.title2.bold())

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("£\(String(format: "%.2f", amountGBP))")
                        .font(.title.bold())
                        .foregroundColor(.brandPurple)
                }
                .padding(.top, 32)

                Spacer()

                // ── Apple Pay Button ──
                if payManager.canMakePayments {
                    if payManager.isProcessing {
                        ProgressView("Processing payment...")
                    } else {
                        ApplePayButtonView {
                            ApplePayManager.shared.purchaseProduct(
                                name: title,
                                amount: amountGBP
                            ) { result in
                                handleResult(result)
                            }
                        }
                        .padding(.horizontal)
                    }
                } else {
                    // Apple Pay not available
                    VStack(spacing: 12) {
                        Image(systemName: "creditcard.trianglebadge.exclamationmark")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)

                        Text("Apple Pay Not Available")
                            .font(.headline)

                        Text("Please add a card to Apple Wallet to make purchases.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Open Wallet") {
                            PKPassLibrary().openPaymentSetup()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }

                // ── Security Badge ──
                HStack(spacing: 16) {
                    Label("Encrypted", systemImage: "lock.shield.fill")
                    Label("Apple Pay", systemImage: "apple.logo")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 24)
            }
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel?()
                        dismiss()
                    }
                }
            }
            .alert("Payment Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorText)
            }
        }
    }

    private func handleResult(_ result: PaymentResult) {
        switch result {
        case .success(let transactionId, let method):
            onSuccess(transactionId, method)
            dismiss()
        case .failed(let error):
            errorText = error
            showError = true
        case .cancelled:
            break
        }
    }
}
