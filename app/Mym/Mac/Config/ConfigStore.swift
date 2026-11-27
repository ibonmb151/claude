#if os(macOS)
import SwiftUI

// Configuración de cuentas: a qué bróker o banco se conecta cada una y con qué datos.
// Los datos que no son secretos se guardan en los ajustes de la app.
// Las claves y los permisos NUNCA: van al Llavero (ver Keychain.swift).

enum ConnectionKind: String, Codable, CaseIterable, Identifiable {
    case broker, bank

    var id: String { rawValue }
    var label: String { self == .broker ? "Bróker" : "Banco" }
}

enum FieldKind {
    case text
    case secret
    case choice([String])
    case note(String)     // texto informativo
    case link(String)     // botón para dar permiso en la web del proveedor (texto del botón)
}

struct FieldSpec: Identifiable {
    let id: String
    let label: String
    let kind: FieldKind
    var placeholder: String = ""
    var hint: String = ""

    /// Lo que hace falta rellenar para que la cuenta quede completa.
    var isRequired: Bool {
        switch kind {
        case .text, .secret: return true
        default: return false
        }
    }
}

struct Provider: Identifiable {
    let id: String
    let name: String
    let mono: String
    let kind: ConnectionKind
    let tint: Color
    let fields: [FieldSpec]

    var needsAuthorization: Bool {
        fields.contains { f in
            if case .link = f.kind { return true }
            return false
        }
    }
}

/// Cada proveedor pide cosas distintas. Aquí está el formulario de cada uno.
enum ProviderCatalog {
    private static func bank(_ id: String, _ name: String, _ mono: String) -> Provider {
        Provider(id: id, name: name, mono: mono, kind: .bank, tint: Palette.infoText, fields: [
            FieldSpec(id: "permiso", label: "Permiso", kind: .link("Conectar con \(name)"),
                      hint: "Te lleva a tu banco para dar permiso. Mym nunca ve tu contraseña."),
            FieldSpec(id: "nota", label: "Qué verá Mym", kind: .note("Solo saldos y movimientos. El permiso dura 90 días y lo puedes quitar cuando quieras."))
        ])
    }

    static let all: [Provider] = [
        Provider(id: "ctrader", name: "cTrader", mono: "cT", kind: .broker, tint: Palette.violet, fields: [
            FieldSpec(id: "clientId", label: "Client ID", kind: .text, placeholder: "Pégalo desde el portal de cTrader"),
            FieldSpec(id: "clientSecret", label: "Secret", kind: .secret, placeholder: "Pégalo desde el portal de cTrader", hint: "Se guarda cifrado en el Llavero."),
            FieldSpec(id: "acceso", label: "Permiso", kind: .link("Autorizar con cTrader"), hint: "Entras con tu usuario de cTrader. Mym guarda un permiso, no tu contraseña."),
            FieldSpec(id: "numero", label: "Número de cuenta", kind: .text, placeholder: "Ej. 4410 2378")
        ]),
        Provider(id: "mt5", name: "MetaTrader 5", mono: "M5", kind: .broker, tint: Palette.infoText, fields: [
            FieldSpec(id: "servidor", label: "Servidor", kind: .text, placeholder: "Lo da tu firma, ej. FirmaB-Live"),
            FieldSpec(id: "numero", label: "Número de cuenta", kind: .text, placeholder: "Ej. 50 112 340"),
            FieldSpec(id: "clave", label: "Contraseña", kind: .secret, placeholder: "Contraseña de la cuenta"),
            FieldSpec(id: "tipo", label: "Tipo de contraseña", kind: .choice(["Solo ver", "Operar"]), hint: "Con la de «solo ver», Mym no puede abrir operaciones.")
        ]),
        Provider(id: "dxtrade", name: "DXtrade", mono: "DX", kind: .broker, tint: Palette.teal, fields: [
            FieldSpec(id: "direccion", label: "Dirección", kind: .text, placeholder: "Ej. trade.tufirma.com"),
            FieldSpec(id: "usuario", label: "Usuario", kind: .text, placeholder: "Tu usuario"),
            FieldSpec(id: "clave", label: "Contraseña", kind: .secret, placeholder: "Tu contraseña")
        ]),
        Provider(id: "ibkr", name: "Interactive Brokers", mono: "IB", kind: .broker, tint: Palette.negText, fields: [
            FieldSpec(id: "usuario", label: "Usuario", kind: .text, placeholder: "Tu usuario"),
            FieldSpec(id: "clave", label: "Contraseña", kind: .secret, placeholder: "Tu contraseña"),
            FieldSpec(id: "nota", label: "Al conectar", kind: .note("Te pedirá el código de tu móvil la primera vez."))
        ]),
        Provider(id: "oanda", name: "OANDA", mono: "OA", kind: .broker, tint: Palette.warnText, fields: [
            FieldSpec(id: "clave", label: "Clave de acceso", kind: .secret, placeholder: "Pega aquí tu clave", hint: "Créala en tu área de cliente. Caduca cada 90 días."),
            FieldSpec(id: "numero", label: "Número de cuenta", kind: .text, placeholder: "Ej. 001-004-7712"),
            FieldSpec(id: "entorno", label: "Entorno", kind: .choice(["Práctica", "Real"]))
        ]),
        bank("bbva", "BBVA", "BB"),
        bank("santander", "Santander", "SA"),
        bank("caixabank", "CaixaBank", "CB"),
        bank("kutxabank", "Kutxabank", "KB"),
        bank("otro", "Otro banco", "+")
    ]

    static func provider(_ id: String?) -> Provider? {
        guard let id = id else { return nil }
        return all.first { $0.id == id }
    }

    static func list(_ kind: ConnectionKind) -> [Provider] {
        all.filter { $0.kind == kind }
    }
}

struct ConfiguredAccount: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String = "Cuenta nueva"
    var kind: ConnectionKind? = nil
    var providerId: String? = nil
    var values: [String: String] = [:]     // solo datos que no son secretos
    var canTrade: Bool = false
    var paused: Bool = false
    var checkedAt: Date? = nil
}

enum AccountConfigState {
    case incomplete, ready, needsAuthorization, paused

    var label: String {
        switch self {
        case .incomplete: return "Incompleta"
        case .ready: return "Datos listos"
        case .needsAuthorization: return "Falta autorizar"
        case .paused: return "Pausada"
        }
    }

    var tone: Tone {
        switch self {
        case .incomplete: return .warn
        case .ready: return .good
        case .needsAuthorization: return .info
        case .paused: return .neutral
        }
    }
}

final class ConfigStore: ObservableObject {
    @Published var accounts: [ConfiguredAccount] = []
    private let key = "mym.cuentasConfiguradas"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([ConfiguredAccount].self, from: data) {
            accounts = saved
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func account(_ id: UUID) -> ConfiguredAccount? {
        accounts.first { $0.id == id }
    }

    func update(_ id: UUID, _ change: (inout ConfiguredAccount) -> Void) {
        guard let i = accounts.firstIndex(where: { $0.id == id }) else { return }
        change(&accounts[i])
        persist()
    }

    @discardableResult
    func add() -> UUID {
        let a = ConfiguredAccount()
        accounts.append(a)
        persist()
        return a.id
    }

    func remove(_ id: UUID) {
        if let a = account(id) { deleteSecrets(of: a) }
        accounts.removeAll { $0.id == id }
        persist()
    }

    // MARK: Claves (Llavero)

    func secretKey(_ id: UUID, _ field: String) -> String {
        id.uuidString + "." + field
    }

    /// Permisos que se guardan en el Llavero sin ser un campo del formulario.
    static let tokenFields: [String] = ["accessToken", "refreshToken"]

    func isAuthorized(_ id: UUID) -> Bool {
        for f in ConfigStore.tokenFields where Keychain.exists(account: secretKey(id, f)) { return true }
        return false
    }

    func clearTokens(_ id: UUID) {
        for f in ConfigStore.tokenFields { Keychain.delete(account: secretKey(id, f)) }
        update(id) { $0.values["caduca"] = nil }
        objectWillChange.send()
    }

    func deleteSecrets(of a: ConfiguredAccount) {
        for f in ConfigStore.tokenFields { Keychain.delete(account: secretKey(a.id, f)) }
        for p in ProviderCatalog.all {
            for f in p.fields {
                if case .secret = f.kind { Keychain.delete(account: secretKey(a.id, f.id)) }
            }
        }
        objectWillChange.send()
    }

    func deleteAllSecrets() {
        for a in accounts { deleteSecrets(of: a) }
    }

    var savedSecretsCount: Int {
        var n = 0
        for a in accounts {
            for f in ConfigStore.tokenFields where Keychain.exists(account: secretKey(a.id, f)) { n += 1 }
            for p in ProviderCatalog.all {
                for f in p.fields {
                    if case .secret = f.kind, Keychain.exists(account: secretKey(a.id, f.id)) { n += 1 }
                }
            }
        }
        return n
    }

    // MARK: Estado

    func missingFields(_ a: ConfiguredAccount) -> [String] {
        guard let p = ProviderCatalog.provider(a.providerId) else { return ["bróker o banco"] }
        var out: [String] = []
        for f in p.fields where f.isRequired {
            switch f.kind {
            case .text:
                if (a.values[f.id] ?? "").trimmingCharacters(in: .whitespaces).isEmpty { out.append(f.label) }
            case .secret:
                if !Keychain.exists(account: secretKey(a.id, f.id)) { out.append(f.label) }
            default:
                break
            }
        }
        return out
    }

    func state(_ a: ConfiguredAccount) -> AccountConfigState {
        if a.paused { return .paused }
        if !missingFields(a).isEmpty { return .incomplete }
        if let p = ProviderCatalog.provider(a.providerId), p.needsAuthorization, !isAuthorized(a.id) { return .needsAuthorization }
        return .ready
    }
}
#endif
