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

// MARK: - String-Key Convenience (bridging from legacy KeychainService callers)

extension KeychainManager {

    /// Save raw data to the Keychain using a string key.
    func save(key: String, data: Data) throws {
        let deleteQuery: [String: Any] = [
            kSecClass       as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass       as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData   as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    /// Load raw data from the Keychain using a string key.
    func load(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass       as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData  as String: true,
            kSecMatchLimit  as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw KeychainError.loadFailed(status)
        }
        return result as? Data
    }

    /// Delete an item from the Keychain using a string key.
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass       as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    /// Save a string value using a string key.
    func saveString(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.dataConversionFailed
        }
        try save(key: key, data: data)
    }

    /// Load a string value using a string key.
    func loadString(forKey key: String) throws -> String? {
        guard let data = try load(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Delete all generic password items for this app's service.
    func deleteAllKeys() {
        let query: [String: Any] = [
            kSecClass       as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Keychain Errors

enum KeychainError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    case dataConversionFailed

    var errorDescription: String? {
        switch self {
        case .saveFailed(let s):   return "Keychain save failed (status: \(s))"
        case .loadFailed(let s):   return "Keychain load failed (status: \(s))"
        case .deleteFailed(let s): return "Keychain delete failed (status: \(s))"
        case .dataConversionFailed: return "Keychain data conversion failed"
        }
    }
}

// MARK: - Crypto Utilities (shared across auth services)

import CryptoKit

enum CryptoUtils {

    /// Generate a random nonce string for Sign in with Apple (replay protection).
    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    /// SHA-256 hash of the input string, returned as a lowercase hex string.
    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - String Initials (shared utility)

extension String {
    /// Returns the first letter of each word (up to 2), e.g. "John Smith" -> "JS".
    var initials: String {
        components(separatedBy: " ")
            .compactMap { $0.first.map { String($0) } }
            .prefix(2)
            .joined()
    }
}

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
