import Foundation
import Security

/// Tiny keychain-backed key/value store shared between Runner and LoopifyWidget.
///
/// App-group UserDefaults is unreliable on free-cert sideloads (iLoader strips
/// `com.apple.security.application-groups` at re-sign). Keychain sharing via
/// `keychain-access-groups = $(AppIdentifierPrefix)com.loopify.loopify` survives
/// because the team-id prefix is auto-applied at sign time for both targets.
public enum WidgetKeychainStore {
    public static let accessGroup = "$(AppIdentifierPrefix)com.loopify.loopify"
    public static let service = "com.loopify.loopify.widget"

    // MARK: - Write

    @discardableResult
    public static func setString(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return setData(data, forKey: key)
    }

    @discardableResult
    public static func setInt(_ value: Int, forKey key: String) -> Bool {
        return setString(String(value), forKey: key)
    }

    @discardableResult
    public static func setData(_ data: Data, forKey key: String) -> Bool {
        // We don't pin to an explicit access group during writes — leaving it
        // off lets the system pick the only available group (the team-id
        // expanded value of `keychain-access-groups`). Pinning explicitly fails
        // because $(AppIdentifierPrefix) isn't substituted at runtime.
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        let attrs: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        let status = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
        if status == errSecSuccess { return true }
        if status == errSecItemNotFound {
            var add = query
            add[kSecValueData as String] = data
            add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            let addStatus = SecItemAdd(add as CFDictionary, nil)
            return addStatus == errSecSuccess
        }
        return false
    }

    // MARK: - Read

    public static func getString(forKey key: String) -> String? {
        guard let data = getData(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public static func getInt(forKey key: String) -> Int? {
        guard let s = getString(forKey: key) else { return nil }
        return Int(s)
    }

    public static func getData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
}
