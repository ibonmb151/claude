import Foundation
import Security

/// Claves y permisos de las cuentas: van al Llavero de Apple, cifrados, solo en este equipo.
/// Nunca a un fichero, a los ajustes normales ni al registro. Mym las lee solo en el momento de usarlas.
enum Keychain {
    private static let service = "com.mym.claves"

    private static func base(_ account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    @discardableResult
    static func save(_ value: String, account: String) -> Bool {
        SecItemDelete(base(account) as CFDictionary)
        var item: [String: Any] = base(account)
        item[kSecValueData as String] = Data(value.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        return SecItemAdd(item as CFDictionary, nil) == errSecSuccess
    }

    static func read(account: String) -> String? {
        var query: [String: Any] = base(account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &out)
        guard status == errSecSuccess, let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Sin leer el valor: sirve para saber si hay clave guardada sin tocarla.
    static func exists(account: String) -> Bool {
        SecItemCopyMatching(base(account) as CFDictionary, nil) == errSecSuccess
    }

    @discardableResult
    static func delete(account: String) -> Bool {
        let status: OSStatus = SecItemDelete(base(account) as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
