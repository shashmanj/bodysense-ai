//
//  KeychainManager.swift
//  body sense ai
//
//  Secure Keychain wrapper for storing API keys, tokens, and secrets.
//  Never store secrets in UserDefaults, source code, or plain text.
//

import Foundation
import Security
import LocalAuthentication

// MARK: - Keychain Manager

final class KeychainManager {
    static let shared = KeychainManager()
    private let service = "co.uk.bodysenseai.keychain"
    private init() {}

    // MARK: - Keys

    enum Key: String {
        case anthropicAPIKey     = "anthropic_api_key"
        case stripePublishableKey = "stripe_publishable_key"
        case stripeSecretKey     = "stripe_secret_key"
        case backendAPIToken     = "backend_api_token"
        case agoraAppId         = "agora_app_id"
        case userSessionToken   = "user_session_token"
    }

    // MARK: - Save

    @discardableResult
    func save(_ value: String, for key: Key) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Delete existing item first
        delete(key)

        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String:   data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Retrieve

    func get(_ key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    // MARK: - Delete

    @discardableResult
    func delete(_ key: Key) -> Bool {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Check if key exists

    func has(_ key: Key) -> Bool {
        get(key) != nil
    }

    // MARK: - Delete all

    func deleteAll() {
        for key in Key.allCases {
            delete(key)
        }
    }

    // MARK: - Seed defaults (call once on first launch)

    func seedDefaultsIfNeeded() {
        // Stripe publishable key — test key only in DEBUG builds
        #if DEBUG
        if !has(.stripePublishableKey) {
            save("pk_test_51SegUBAHlyZLnFkwhRkInZnvnpD0nTBknw6wS0lLpDKukCzfQ3PjUgifsU4SrqjSEDoTEK0JLTVV5nExslvCvYXN00zwbRXcB0", for: .stripePublishableKey)
        }
        #endif
        // Production: Stripe key must be set via CEO settings or backend config
        // Anthropic API key — user must set via CEO settings
    }
}

// MARK: - CaseIterable

extension KeychainManager.Key: CaseIterable {}

// MARK: - Biometric Authentication

final class BiometricAuth {
    static let shared = BiometricAuth()
    private init() {}

    enum BiometricType {
        case faceID, touchID, none
    }

    var availableType: BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        switch context.biometryType {
        case .faceID:  return .faceID
        case .touchID: return .touchID
        default:       return .none
        }
    }

    var isAvailable: Bool { availableType != .none }

    var typeName: String {
        switch availableType {
        case .faceID:  return "Face ID"
        case .touchID: return "Touch ID"
        case .none:    return "Passcode"
        }
    }

    var iconName: String {
        switch availableType {
        case .faceID:  return "faceid"
        case .touchID: return "touchid"
        case .none:    return "lock.fill"
        }
    }

    func authenticate(reason: String = "Unlock BodySense AI to access your health data") async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Use Passcode"

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,  // Falls back to passcode
                localizedReason: reason
            )
        } catch {
            return false
        }
    }
}
