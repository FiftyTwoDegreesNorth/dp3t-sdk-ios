/*
 * Created by Ubique Innovation AG
 * https://www.ubique.ch
 * Copyright (c) 2020. All rights reserved.
 */

import Foundation

enum KeychainError: Error {
    case notFound
    case cannotAccess
}

protocol SecureStorageProtocol {
    func getSecretKeys() throws -> [SecretKey]
    func setSecretKeys(_ object: [SecretKey]) throws
    func getEphIds() throws -> EphIdsForDay?
    func setEphIds(_ object: EphIdsForDay) throws
    func removeAllObject()
}

class SecureStorage: SecureStorageProtocol {
    static let shared = SecureStorage()

    private let secretKeyKey: String = "org.dpppt.keylist"
    private let ephIdsTodayKey: String = "org.dpppt.ephsIds"

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {}

    func getEphIds() throws -> EphIdsForDay? {
        let data = try get(for: ephIdsTodayKey)
        return try decoder.decode(EphIdsForDay.self, from: data)
    }

    func setEphIds(_ object: EphIdsForDay) throws {
        let data = try encoder.encode(object)
        try set(data, key: ephIdsTodayKey)
    }

    func getSecretKeys() throws -> [SecretKey] {
        let data = try get(for: secretKeyKey)
        return try decoder.decode([SecretKey].self, from: data)
    }

    func setSecretKeys(_ object: [SecretKey]) throws {
        let data = try encoder.encode(object)
        try set(data, key: secretKeyKey)
    }

    private func set(_ data: Data, key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.cannotAccess
        }
    }

    private func get(for key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else {
            throw KeychainError.notFound
        }
        guard status == errSecSuccess else {
            throw KeychainError.cannotAccess
        }
        return (item as! CFData) as Data
    }

    private func removeSecretKeys() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: secretKeyKey,
        ]
        SecItemDelete(query as CFDictionary)
    }

    private func removeEphIds() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: ephIdsTodayKey,
        ]
        SecItemDelete(query as CFDictionary)
    }

    func removeAllObject() {
        removeSecretKeys()
        removeEphIds()
    }
}
