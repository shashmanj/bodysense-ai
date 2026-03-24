//
//  NetworkSecurity.swift
//  body sense ai
//
//  SSL Certificate Pinning, Rate Limiting, and Offline Mode handling.
//  Production-grade network security for App Store readiness.
//

import Foundation
import Network
import SwiftUI
import CryptoKit

// MARK: - SSL Certificate Pinning

/// Pins TLS certificates for critical API endpoints to prevent MITM attacks.
/// Uses public key pinning (SPKI) — more resilient to certificate rotation than full cert pinning.
final class SSLPinningSessionDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {

    /// Public key hashes (SHA-256 of SPKI) for pinned domains.
    /// Add your backend, Anthropic, and Stripe public key hashes here.
    /// Generate with: openssl s_client -connect api.anthropic.com:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
    private let pinnedHashes: [String: [String]] = [
        "api.anthropic.com": [
            // Add Anthropic's SPKI hash here when deploying to production
            // "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="
        ],
        "api.bodysenseai.co.uk": [
            // Add your backend's SPKI hash here
            // "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC="
        ]
    ]

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              let host = Optional(challenge.protectionSpace.host),
              let expectedHashes = pinnedHashes[host],
              !expectedHashes.isEmpty else {
            // No pin for this host — use default validation
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Evaluate the trust chain
        var error: CFError?
        guard SecTrustEvaluateWithError(serverTrust, &error) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Check if any certificate in the chain matches our pins
        guard let certChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        for cert in certChain {
            // Get the public key from the certificate
            guard let publicKey = SecCertificateCopyKey(cert) else { continue }
            guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as? Data else { continue }

            // SHA-256 hash of the public key
            let hash = SHA256.hash(data: publicKeyData)
            let hashBase64 = Data(hash).base64EncodedString()

            if expectedHashes.contains(hashBase64) {
                // Pin matched
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
                return
            }
        }

        // No pin matched — reject connection
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
}

/// Creates a URLSession with SSL pinning enabled.
/// Use this for all API calls in production.
enum SecureNetwork {
    private static let pinningDelegate = SSLPinningSessionDelegate()

    static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        config.httpAdditionalHeaders = [
            "X-App-Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            "X-Platform": "iOS"
        ]
        return URLSession(configuration: config, delegate: pinningDelegate, delegateQueue: nil)
    }()
}

// MARK: - Rate Limiter

/// Token bucket rate limiter to prevent AI chat abuse.
/// Configurable per-minute and per-hour limits.
actor RateLimiter {
    static let shared = RateLimiter()

    struct Config {
        let maxPerMinute: Int
        let maxPerHour: Int
        let cooldownSeconds: TimeInterval

        static let standard   = Config(maxPerMinute: 10, maxPerHour: 100, cooldownSeconds: 6)
        static let premium    = Config(maxPerMinute: 20, maxPerHour: 300, cooldownSeconds: 3)
        static let ceo        = Config(maxPerMinute: 60, maxPerHour: 1000, cooldownSeconds: 1)
    }

    private var minuteTimestamps: [Date] = []
    private var hourTimestamps: [Date] = []
    private var lastRequest: Date = .distantPast

    /// Check if a request is allowed. Returns nil if allowed, or an error message if rate limited.
    func checkLimit(config: Config = .standard) -> String? {
        let now = Date()

        // Clean old timestamps
        let oneMinuteAgo = now.addingTimeInterval(-60)
        let oneHourAgo = now.addingTimeInterval(-3600)
        minuteTimestamps.removeAll { $0 < oneMinuteAgo }
        hourTimestamps.removeAll { $0 < oneHourAgo }

        // Check cooldown
        if now.timeIntervalSince(lastRequest) < config.cooldownSeconds {
            let wait = Int(config.cooldownSeconds - now.timeIntervalSince(lastRequest)) + 1
            return "Please wait \(wait)s between messages"
        }

        // Check per-minute limit
        if minuteTimestamps.count >= config.maxPerMinute {
            return "You've reached the limit of \(config.maxPerMinute) messages per minute. Please wait a moment."
        }

        // Check per-hour limit
        if hourTimestamps.count >= config.maxPerHour {
            return "You've reached the hourly limit of \(config.maxPerHour) messages. Please try again later."
        }

        return nil // Allowed
    }

    /// Record a successful request
    func recordRequest() {
        let now = Date()
        minuteTimestamps.append(now)
        hourTimestamps.append(now)
        lastRequest = now
    }

    /// Get current usage stats (for CEO dashboard)
    func stats() -> (minuteUsed: Int, hourUsed: Int) {
        let now = Date()
        let minCount = minuteTimestamps.filter { $0 > now.addingTimeInterval(-60) }.count
        let hourCount = hourTimestamps.filter { $0 > now.addingTimeInterval(-3600) }.count
        return (minCount, hourCount)
    }

    /// Get the appropriate config based on user's subscription and email
    @MainActor static func config(for store: HealthStore) -> Config {
        if store.userProfile.isCEO {
            return .ceo
        }
        switch store.subscription {
        case .premium: return .premium
        case .pro:     return .standard
        case .free:    return .standard
        }
    }
}

// MARK: - Network Monitor (Offline Mode)

/// Monitors network connectivity and provides offline state handling.
@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    var isConnected: Bool = true
    var connectionType: ConnectionType = .unknown

    enum ConnectionType: String {
        case wifi     = "Wi-Fi"
        case cellular = "Cellular"
        case ethernet = "Ethernet"
        case unknown  = "Unknown"
    }

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "co.uk.bodysenseai.networkmonitor")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied

                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .ethernet
                } else {
                    self?.connectionType = .unknown
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

// MARK: - Offline Banner View

/// Drop-in banner that shows when the device goes offline.
/// Add this as an overlay on any root view.
struct OfflineBanner: View {
    @State private var networkMonitor = NetworkMonitor.shared

    var body: some View {
        if !networkMonitor.isConnected {
            VStack {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.caption).fontWeight(.bold)
                    Text("You're Offline")
                        .font(.caption).fontWeight(.semibold)
                    Text("· Health tracking continues locally")
                        .font(.caption2).foregroundColor(.white.opacity(0.8))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.brandCoral.opacity(0.95))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
                .padding(.top, 4)

                Spacer()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(response: 0.4), value: networkMonitor.isConnected)
        }
    }
}

// MARK: - Offline-Aware AI Response

extension HealthAIEngine {

    /// Check if AI can respond (online + rate limit)
    func canRespondCheck(store: HealthStore) async -> String? {
        // Check network
        if !NetworkMonitor.shared.isConnected {
            return nil // Will use offline fallback
        }

        // Check rate limit
        let config = RateLimiter.config(for: store)
        if let limitMsg = await RateLimiter.shared.checkLimit(config: config) {
            return limitMsg
        }

        return nil
    }
}
