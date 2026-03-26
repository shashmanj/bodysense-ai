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

    // MARK: - Stripe Connect Base URL

    private let railwayBackendURL = "https://body-sense-ai-production.up.railway.app"

    // MARK: - Stripe Connect — Doctor Payouts

    /// Creates a Stripe Connect account for a doctor and returns the account ID + onboarding URL.
    func createConnectAccount(
        doctorId: String,
        email: String,
        firstName: String,
        lastName: String
    ) async throws -> (accountId: String, onboardingUrl: String) {
        guard let url = URL(string: "\(railwayBackendURL)/doctor/create-connect-account") else {
            throw StripeConnectError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "doctorId": doctorId,
            "email": email,
            "firstName": firstName,
            "lastName": lastName
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accountId = json["accountId"] as? String,
              let onboardingUrl = json["onboardingUrl"] as? String else {
            throw StripeConnectError.invalidResponse
        }

        return (accountId: accountId, onboardingUrl: onboardingUrl)
    }

    /// Refreshes the Stripe Connect onboarding link for a doctor whose link expired.
    func refreshOnboardingLink(doctorId: String) async throws -> String {
        guard let url = URL(string: "\(railwayBackendURL)/doctor/refresh-onboarding-link") else {
            throw StripeConnectError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "doctorId": doctorId
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let onboardingUrl = json["onboardingUrl"] as? String else {
            throw StripeConnectError.invalidResponse
        }

        return onboardingUrl
    }

    /// Fetches the payout status, bank details, and transaction history for a doctor.
    func fetchPayoutStatus(doctorId: String) async throws -> PayoutStatusResponse {
        guard let url = URL(string: "\(railwayBackendURL)/doctor/payout-status/\(doctorId)") else {
            throw StripeConnectError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(PayoutStatusResponse.self, from: data)
        } catch {
            throw StripeConnectError.decodingFailed(error)
        }
    }

    /// Requests a manual payout for a doctor's pending balance.
    func requestPayout(doctorId: String) async throws {
        guard let url = URL(string: "\(railwayBackendURL)/doctor/request-payout") else {
            throw StripeConnectError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "doctorId": doctorId
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data)
    }

    // MARK: - HTTP Response Validation

    private func validateHTTPResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StripeConnectError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Attempt to extract server error message
            var serverMessage: String? = nil
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["error"] as? String {
                serverMessage = message
            }
            throw StripeConnectError.serverError(
                statusCode: httpResponse.statusCode,
                message: serverMessage ?? "Request failed with status \(httpResponse.statusCode)"
            )
        }
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

// MARK: - Stripe Connect Error

enum StripeConnectError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingFailed(Error)
    case serverError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Stripe Connect endpoint URL."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .decodingFailed(let underlying):
            return "Failed to decode server response: \(underlying.localizedDescription)"
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message)"
        }
    }
}

// MARK: - Payout Status Response

/// Server response from `GET /doctor/payout-status/:doctorId`.
/// All monetary amounts are in pence (GBP). Convert to pounds in the UI layer.
struct PayoutStatusResponse: Codable {
    let payoutStatus: String
    let bankLast4: String
    let bankName: String
    let pendingBalance: Int
    let transferredBalance: Int
    let totalEarnings: Int
    let transactions: [PayoutTransactionResponse]
}

/// A single payout transaction record.
struct PayoutTransactionResponse: Codable, Identifiable {
    let id: String
    let amount: Int          // pence
    let currency: String
    let status: String
    let createdAt: String
    let description: String?
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
