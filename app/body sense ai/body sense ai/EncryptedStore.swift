//
//  EncryptedStore.swift
//  body sense ai
//
//  AES-GCM encryption layer for health data at rest.
//  Uses Apple CryptoKit (exempt from US export restrictions).
//  Encryption key is generated once and stored in Keychain.
//

import Foundation
import CryptoKit

enum EncryptionError: Error, LocalizedError {
    case keyGenerationFailed
    case encryptionFailed
    case decryptionFailed
    case invalidData

    var errorDescription: String? {
        switch self {
        case .keyGenerationFailed: return "Failed to generate encryption key"
        case .encryptionFailed:    return "Failed to encrypt data"
        case .decryptionFailed:    return "Failed to decrypt data"
        case .invalidData:         return "Invalid encrypted data format"
        }
    }
}

enum EncryptedStore {

    private static let keychainKey = "com.bodysenseai.encryption.key"

    // MARK: - Key Management

    /// Retrieve the existing AES-256 key from Keychain, or generate and store a new one.
    static func getOrCreateEncryptionKey() -> SymmetricKey {
        // Try loading existing key
        if let keyData = try? KeychainService.load(key: keychainKey) {
            return SymmetricKey(data: keyData)
        }

        // Generate a new 256-bit key
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }

        // Persist to Keychain
        do {
            try KeychainService.save(key: keychainKey, data: keyData)
        } catch {
            // If Keychain save fails, the key is still usable for this session.
            // On next launch a new key will be created, but old data won't decrypt.
            print("⚠️ EncryptedStore: Failed to save key to Keychain: \(error)")
        }

        return newKey
    }

    // MARK: - Encrypt

    /// Encrypt data using AES-GCM.
    /// Returns: nonce (12 bytes) + ciphertext + tag (16 bytes)
    static func encrypt(_ data: Data) throws -> Data {
        let key = getOrCreateEncryptionKey()
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            guard let combined = sealedBox.combined else {
                throw EncryptionError.encryptionFailed
            }
            return combined
        } catch let error as EncryptionError {
            throw error
        } catch {
            throw EncryptionError.encryptionFailed
        }
    }

    // MARK: - Decrypt

    /// Decrypt AES-GCM encrypted data.
    /// Expects: nonce (12 bytes) + ciphertext + tag (16 bytes)
    static func decrypt(_ data: Data) throws -> Data {
        let key = getOrCreateEncryptionKey()
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            throw EncryptionError.decryptionFailed
        }
    }

    // MARK: - Convenience

    /// Check if data looks like it's encrypted (vs plain JSON).
    /// AES-GCM combined data starts with a 12-byte nonce, so valid JSON (starting with '{' or '[')
    /// will never match. This helps with migration from plain to encrypted storage.
    static func isEncrypted(_ data: Data) -> Bool {
        guard data.count > 28 else { return false } // nonce(12) + tag(16) = 28 minimum
        // Plain JSON starts with '{' (0x7B) or '[' (0x5B)
        let firstByte = data[data.startIndex]
        return firstByte != 0x7B && firstByte != 0x5B
    }
}
