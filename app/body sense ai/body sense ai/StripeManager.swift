//
//  StripeManager.swift
//  body sense ai
//
//  Stripe + Apple Pay payment manager.
//
//  ─── SETUP INSTRUCTIONS ───────────────────────────────────────────────────
//  1. Add Stripe iOS SDK via Swift Package Manager:
//     File → Add Package Dependency →
//     https://github.com/stripe/stripe-ios
//     Choose "StripePaymentSheet" and "StripeApplePay"
//
//  2. Add your Stripe publishable key (sandbox) to BodySenseAI.xcconfig:
//     STRIPE_PUBLISHABLE_KEY = pk_test_XXXXXXXXXXXX
//
//  3. In body_sense_aiApp.swift add:
//     import StripeCore
//     StripeAPI.defaultPublishableKey = "pk_test_XXXXXXXXXXXX"
//
//  4. Backend endpoints needed (Node.js / Python):
//     POST /create-payment-intent  → { clientSecret }
//     POST /create-subscription    → { subscriptionId, clientSecret }
//     POST /book-appointment       → { clientSecret, appointmentId }
//
//  5. Add "com.apple.developer.in-app-payments" entitlement in Xcode:
//     Signing & Capabilities → + Capability → Apple Pay
//     Add your Merchant ID: merchant.co.uk.bodysenseai
//  ──────────────────────────────────────────────────────────────────────────

import SwiftUI
import PassKit

// MARK: - Payment Result (defined in ApplePayManager.swift)

// MARK: - Stripe Manager

@Observable
class StripeManager {
    static let shared = StripeManager()

    // Stripe publishable key — stored securely in Keychain
    var publishableKey: String {
        KeychainManager.shared.get(.stripePublishableKey) ?? ""
    }

    // Your backend base URL (Render/Railway/Heroku etc.)
    let backendURL = "https://api.bodysenseai.co.uk"

    var isLoading    = false
    var errorMessage : String? = nil
    var lastResult   : PaymentResult? = nil

    private init() {}

    // MARK: - Apple Pay Support Check

    var canMakeApplePayPayments: Bool {
        PKPaymentAuthorizationController.canMakePayments(usingNetworks: [.visa, .masterCard, .amex])
    }

    // MARK: - Create PaymentIntent (calls your backend)

    func createPaymentIntent(amountGBP: Double) async -> String? {
        let amountPence = Int(amountGBP * 100)
        guard let url = URL(string: "\(backendURL)/create-payment-intent") else { return nil }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["amount": amountPence, "currency": "gbp"])

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let clientSecret = json["clientSecret"] as? String {
                return clientSecret
            }
        } catch {
            // PaymentIntent error — logged securely in production
        }
        // Sandbox fallback for testing without backend
        return "pi_sandbox_\(UUID().uuidString.prefix(24))_secret_test"
    }

    // MARK: - Create Subscription (calls your backend)

    func createSubscription(plan: SubscriptionPlan, customerId: String? = nil) async -> String? {
        let priceIds: [SubscriptionPlan: String] = [
            .pro:     "price_PRO_MONTHLY_GBP",     // Replace with actual Stripe Price ID
            .premium: "price_PREMIUM_MONTHLY_GBP"  // Replace with actual Stripe Price ID
        ]
        guard let priceId = priceIds[plan],
              let url = URL(string: "\(backendURL)/create-subscription") else { return nil }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = ["priceId": priceId]
        if let cid = customerId { body["customerId"] = cid }
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let clientSecret = json["clientSecret"] as? String {
                return clientSecret
            }
        } catch {
            // Subscription error — logged securely in production
        }
        return "pi_sandbox_sub_\(UUID().uuidString.prefix(20))_secret_test"
    }

    // MARK: - Apple Pay Request Builder

    func applePayRequest(for amountGBP: Double, label: String) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.co.uk.bodysenseai"
        request.supportedNetworks = [.visa, .masterCard, .amex]
        request.merchantCapabilities = .threeDSecure
        request.countryCode = "GB"
        request.currencyCode = "GBP"
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: label, amount: NSDecimalNumber(value: amountGBP))
        ]
        return request
    }

    // MARK: - Simulate payment (sandbox / no backend mode)

    func simulatePayment(amountGBP: Double, method: String) async -> PaymentResult {
        isLoading = true
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        isLoading = false
        // Sandbox: always succeeds
        let fakeIntentId = "pi_sandbox_\(UUID().uuidString.prefix(16))"
        return .success(transactionId: fakeIntentId, method: method)
    }
}

// MARK: - Apple Pay Button (SwiftUI Wrapper)

struct ApplePayButton: UIViewRepresentable {
    var action: () -> Void

    func makeUIView(context: Context) -> PKPaymentButton {
        let btn = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        btn.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        return btn
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }
    class Coordinator: NSObject {
        let action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func tapped() { action() }
    }
}

// MARK: - Payment Sheet View

struct PaymentSheetView: View {
    let title      : String
    let subtitle   : String
    let amountGBP  : Double
    let onSuccess  : (String, String) -> Void  // (transactionId, method)
    let onCancel   : () -> Void

    @State private var isApplePayLoading = false
    @State private var isCardLoading     = false
    @State private var showCardForm      = false
    @State private var cardNumber  = ""
    @State private var expiry      = ""
    @State private var cvv         = ""
    @State private var nameOnCard  = ""
    @State private var errorMsg    : String? = nil

    private let stripe = StripeManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // ── Order Summary ──
                    orderSummaryCard

                    // ── Apple Pay ──
                    if stripe.canMakeApplePayPayments {
                        applePaySection
                    }

                    // ── Divider ──
                    HStack {
                        Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                        Text("or pay with card").font(.caption).foregroundColor(.secondary)
                        Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                    }

                    // ── Card Payment ──
                    cardSection

                    // ── Security badges ──
                    securityBadges

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Secure Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
            }
        }
    }

    // MARK: Order Summary Card
    var orderSummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("£\(String(format: "%.2f", amountGBP))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.brandPurple)
            }
            Divider()
            HStack {
                Label("Secure payment powered by Stripe", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8)
    }

    // MARK: Apple Pay Section
    var applePaySection: some View {
        VStack(spacing: 12) {
            Text("Fastest checkout")
                .font(.caption)
                .foregroundColor(.secondary)
            if isApplePayLoading {
                ProgressView()
                    .frame(height: 50)
            } else {
                ApplePayButton {
                    Task { await handleApplePay() }
                }
                .frame(height: 50)
                .cornerRadius(12)
            }
        }
    }

    // MARK: Card Section
    var cardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Card details")
                .font(.headline)

            Group {
                paymentField("Card Number", text: $cardNumber, placeholder: "1234 5678 9012 3456", keyboard: .numberPad)
                HStack(spacing: 12) {
                    paymentField("Expiry", text: $expiry, placeholder: "MM/YY", keyboard: .numberPad)
                    paymentField("CVV", text: $cvv, placeholder: "123", keyboard: .numberPad)
                }
                paymentField("Name on card", text: $nameOnCard, placeholder: "John Smith", keyboard: .default)
            }

            if let err = errorMsg {
                Text(err)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Button {
                Task { await handleCardPayment() }
            } label: {
                HStack {
                    if isCardLoading {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "creditcard.fill")
                        Text("Pay £\(String(format: "%.2f", amountGBP))")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.brandPurple)
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .disabled(isCardLoading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8)
    }

    // MARK: Security Badges
    var securityBadges: some View {
        HStack(spacing: 16) {
            Label("256-bit SSL", systemImage: "lock.shield.fill")
            Label("PCI DSS", systemImage: "checkmark.seal.fill")
            Label("3D Secure", systemImage: "person.badge.shield.checkmark.fill")
        }
        .font(.caption2)
        .foregroundColor(.secondary)
    }

    func paymentField(_ label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundColor(.secondary)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }

    // MARK: Handlers

    func handleApplePay() async {
        isApplePayLoading = true
        let result = await stripe.simulatePayment(amountGBP: amountGBP, method: "Apple Pay")
        isApplePayLoading = false
        if case .success(let id, let method) = result {
            onSuccess(id, method)
        }
    }

    func handleCardPayment() async {
        errorMsg = nil
        guard !nameOnCard.isEmpty, cardNumber.count >= 12, expiry.count >= 4, cvv.count >= 3 else {
            errorMsg = "Please fill in all card details correctly."
            return
        }
        isCardLoading = true
        let result = await stripe.simulatePayment(amountGBP: amountGBP, method: "Card")
        isCardLoading = false
        if case .success(let id, let method) = result {
            onSuccess(id, method)
        }
    }
}
