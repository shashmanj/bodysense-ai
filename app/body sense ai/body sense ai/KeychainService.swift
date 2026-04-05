//
//  KeychainService.swift
//  body sense ai
//
//  DEPRECATED — All functionality consolidated into KeychainManager.swift.
//  This file forwards to KeychainManager to avoid breaking any remaining references.
//  Do not add new code here.
//

import Foundation

@available(*, deprecated, message: "Use KeychainManager.shared instead")
enum KeychainService {

    static func save(key: String, data: Data) throws {
        try KeychainManager.shared.save(key: key, data: data)
    }

    static func load(key: String) throws -> Data? {
        try KeychainManager.shared.load(key: key)
    }

    static func delete(key: String) throws {
        try KeychainManager.shared.delete(key: key)
    }

    static func saveString(_ value: String, forKey key: String) throws {
        try KeychainManager.shared.saveString(value, forKey: key)
    }

    static func loadString(forKey key: String) throws -> String? {
        try KeychainManager.shared.loadString(forKey: key)
    }

    static func deleteAll() {
        KeychainManager.shared.deleteAllKeys()
    }
}
