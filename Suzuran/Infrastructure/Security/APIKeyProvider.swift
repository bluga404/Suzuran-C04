import Foundation
import Security

protocol APIKeyProvider {
    func getAPIKey() -> String?
}

final class KeychainHelper {
    static let shared = KeychainHelper()

    func save(_ value: String, service: String, account: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data

        let status = SecItemAdd(attributes as CFDictionary, nil)
        return status == errSecSuccess
    }

    func get(_ service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data, let str = String(data: data, encoding: .utf8) else {
            return nil
        }
        return str
    }
}

struct KeychainAPIKeyProvider: APIKeyProvider {
    private let service: String
    private let account: String

    init(service: String = "com.suzuran.gemini", account: String = AppConstants.geminiApiKeyInfoPlistKey) {
        self.service = service
        self.account = account
    }

    func getAPIKey() -> String? {
        KeychainHelper.shared.get(service, account: account)
    }
}
