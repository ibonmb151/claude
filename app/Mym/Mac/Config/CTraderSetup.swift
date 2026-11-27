#if os(macOS)
import SwiftUI
import AppKit
import Network

// Conectar con cTrader desde la propia app.
// 1) Se crea una aplicación en el portal de cTrader (solo se hace una vez).
// 2) Se pegan aquí su Client ID y su Secret (el Secret va al Llavero).
// 3) «Autorizar» abre cTrader, tú aceptas y Mym recibe el permiso. Los permisos van al Llavero.
// Mym no ve tu contraseña de cTrader en ningún momento.

enum CTraderLinks {
    static let portal = "https://openapi.ctrader.com/apps"
    static let authorize = "https://id.ctrader.com/my/settings/openapi/grantingaccess/"
    static let token = "https://openapi.ctrader.com/apps/token"
    static let port: UInt16 = 54321
    static let redirect = "http://localhost:54321/callback"
}

/// Permisos recibidos de cTrader.
struct CTraderTokens {
    let access: String
    let refresh: String?
    let expiresIn: Double?
}

final class CTraderAuth: ObservableObject {
    enum Phase { case idle, waiting, exchanging, done, failed }

    @Published var phase: Phase = .idle
    @Published var message: String = ""

    private var listener: NWListener?
    private var timeout: DispatchWorkItem?
    private var state: String = ""
    private var clientId: String = ""
    private var secret: String = ""
    private var onTokens: ((CTraderTokens) -> Void)?

    // MARK: Empezar

    func start(clientId: String, secret: String, onTokens: @escaping (CTraderTokens) -> Void) {
        stop()
        self.clientId = clientId
        self.secret = secret
        self.onTokens = onTokens
        self.state = UUID().uuidString
        var comps = URLComponents(string: CTraderLinks.authorize)
        comps?.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: CTraderLinks.redirect),
            URLQueryItem(name: "scope", value: "trading"),
            URLQueryItem(name: "product", value: "web"),
            URLQueryItem(name: "state", value: state)
        ]
        guard let url = comps?.url else {
            fail("No se pudo preparar la dirección de cTrader.")
            return
        }
        listen()
        phase = .waiting
        message = "Acepta el permiso en la página de cTrader. Después vuelve aquí."
        NSWorkspace.shared.open(url)
        let item = DispatchWorkItem { [weak self] in
            guard let self = self, self.phase == .waiting else { return }
            self.fail("Se acabó el tiempo. Inténtalo de nuevo o pega el código a mano.")
        }
        timeout = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 300, execute: item)
    }

    func stop() {
        timeout?.cancel()
        timeout = nil
        listener?.cancel()
        listener = nil
    }

    /// Para cuando el navegador no vuelve solo: se pega la dirección completa o solo el código.
    func submitManual(_ text: String, clientId: String, secret: String, onTokens: @escaping (CTraderTokens) -> Void) {
        self.clientId = clientId
        self.secret = secret
        self.onTokens = onTokens
        guard let code = CTraderAuth.extractCode(text) else {
            fail("No encuentro el código en lo que has pegado.")
            return
        }
        exchange(code: code)
    }

    // MARK: Recibir la vuelta del navegador

    private func listen() {
        guard let port = NWEndpoint.Port(rawValue: CTraderLinks.port) else { return }
        let params = NWParameters.tcp
        params.requiredInterfaceType = .loopback
        guard let l = try? NWListener(using: params, on: port) else {
            message = "El puerto \(CTraderLinks.port) está ocupado. Puedes pegar el código a mano."
            return
        }
        l.newConnectionHandler = { [weak self] conn in self?.handle(conn) }
        l.start(queue: .main)
        listener = l
    }

    private func handle(_ conn: NWConnection) {
        conn.start(queue: .main)
        conn.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, _, _ in
            var request: String = ""
            if let d = data, let t = String(data: d, encoding: .utf8) { request = t }
            let page: String = "<html><body style=\"font-family:-apple-system,sans-serif;text-align:center;margin-top:20vh\"><h2>Listo</h2><p>Ya puedes volver a Mym.</p></body></html>"
            let head: String = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nConnection: close\r\nContent-Length: \(page.utf8.count)\r\n\r\n"
            conn.send(content: Data((head + page).utf8), completion: .contentProcessed { _ in conn.cancel() })
            self?.received(request)
        }
    }

    private func received(_ request: String) {
        guard phase == .waiting else { return }
        // Primera línea: «GET /callback?code=… HTTP/1.1»
        let first: String = request.components(separatedBy: "\r\n").first ?? ""
        let parts: [String] = first.components(separatedBy: " ")
        guard parts.count >= 2, parts[1].hasPrefix("/callback") else { return }
        guard let comps = URLComponents(string: "http://localhost" + parts[1]) else { return }
        let items: [URLQueryItem] = comps.queryItems ?? []
        if let returned = items.first(where: { $0.name == "state" })?.value, returned != state {
            fail("La respuesta no es de esta autorización. Inténtalo de nuevo.")
            return
        }
        if let err = items.first(where: { $0.name == "error" })?.value {
            fail("cTrader ha dicho: \(err).")
            return
        }
        guard let code = items.first(where: { $0.name == "code" })?.value, !code.isEmpty else {
            fail("cTrader no ha devuelto ningún código.")
            return
        }
        exchange(code: code)
    }

    /// Saca el código de una dirección completa o de un código suelto.
    static func extractCode(_ text: String) -> String? {
        let t: String = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return nil }
        if t.contains("code="), let comps = URLComponents(string: t.contains("://") ? t : "http://localhost/?" + t) {
            return comps.queryItems?.first(where: { $0.name == "code" })?.value
        }
        if t.contains(" ") || t.contains("=") { return nil }
        return t
    }

    // MARK: Cambiar el código por los permisos

    private func exchange(code: String) {
        stop()
        phase = .exchanging
        message = "Conectando con cTrader…"
        var comps = URLComponents(string: CTraderLinks.token)
        comps?.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: CTraderLinks.redirect),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "client_secret", value: secret)
        ]
        guard let url = comps?.url else {
            fail("No se pudo preparar la petición.")
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async { self?.finish(data: data, error: error) }
        }.resume()
    }

    private func finish(data: Data?, error: Error?) {
        if error != nil {
            fail("No hay conexión con cTrader.")
            return
        }
        guard let data = data,
              let object = try? JSONSerialization.jsonObject(with: data),
              let json = object as? [String: Any] else {
            fail("cTrader ha respondido algo que no entiendo.")
            return
        }
        let access: String? = (json["accessToken"] as? String) ?? (json["access_token"] as? String)
        let refresh: String? = (json["refreshToken"] as? String) ?? (json["refresh_token"] as? String)
        let expires: Double? = (json["expiresIn"] as? Double) ?? (json["expires_in"] as? Double)
        guard let token = access, !token.isEmpty else {
            let why: String = (json["description"] as? String) ?? (json["error_description"] as? String) ?? ""
            fail("cTrader no ha dado el permiso. Revisa el Client ID, el Secret y la dirección de vuelta. " + why)
            return
        }
        secret = ""
        phase = .done
        message = ""
        onTokens?(CTraderTokens(access: token, refresh: refresh, expiresIn: expires))
        onTokens = nil
    }

    private func fail(_ text: String) {
        stop()
        phase = .failed
        message = text
    }
}

// MARK: - Guía para crear la aplicación

struct CTraderGuide: View {
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Antes de empezar, una sola vez").font(.system(size: 13, weight: .bold))
            step(1, "Entra en el portal de cTrader y crea una aplicación. Ponle el nombre que quieras.") {
                Button("Abrir el portal") {
                    if let url = URL(string: CTraderLinks.portal) { NSWorkspace.shared.open(url) }
                }
                .buttonStyle(MymButtonStyle(kind: .secondary, compact: true))
            }
            step(2, "Cuando pida la «dirección de vuelta» (redirect URI), pon esta:") {
                HStack(spacing: 8) {
                    Text(CTraderLinks.redirect)
                        .font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(Palette.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Button(copied ? "Copiada" : "Copiar") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(CTraderLinks.redirect, forType: .string)
                        copied = true
                    }
                    .buttonStyle(MymButtonStyle(kind: .secondary, compact: true))
                }
            }
            step(3, "Copia su Client ID y su Secret y pégalos aquí abajo.") { EmptyView() }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.bg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func step<Extra: View>(_ n: Int, _ text: String, @ViewBuilder extra: () -> Extra) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(n)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 22, height: 22)
                .background(Palette.graphiteDark, in: Circle())
            VStack(alignment: .leading, spacing: 6) {
                Text(text).font(.system(size: 13)).foregroundStyle(Palette.ink)
                extra()
            }
        }
    }
}

// MARK: - Autorizar

struct CTraderAuthorizeView: View {
    @EnvironmentObject var config: ConfigStore
    @StateObject private var auth = CTraderAuth()
    @State private var manual = ""
    let accountId: UUID

    private var clientId: String {
        (config.account(accountId)?.values["clientId"] ?? "").trimmingCharacters(in: .whitespaces)
    }

    private var secretKey: String { config.secretKey(accountId, "clientSecret") }

    private var authorized: Bool { config.isAuthorized(accountId) }

    private var expiryText: String? {
        guard let raw = config.account(accountId)?.values["caduca"],
              let date = ISO8601DateFormatter().date(from: raw) else { return nil }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }

    private var ready: Bool { !clientId.isEmpty && Keychain.exists(account: secretKey) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                if authorized {
                    Pill(text: "Autorizada", tone: .good)
                    if let d = expiryText {
                        Text("El permiso dura hasta el \(d)").font(.system(size: 12)).foregroundStyle(Palette.ink2)
                    }
                    Spacer()
                    Button("Quitar permiso") { revoke() }
                        .buttonStyle(MymButtonStyle(kind: .secondary, compact: true))
                } else {
                    Button(auth.phase == .waiting ? "Esperando a cTrader…" : "Autorizar con cTrader") { begin() }
                        .buttonStyle(MymButtonStyle(kind: .primary, compact: true))
                        .disabled(!ready || auth.phase == .waiting || auth.phase == .exchanging)
                    if !ready {
                        Text("Rellena antes el Client ID y el Secret.").font(.system(size: 12)).foregroundStyle(Palette.ink2)
                    }
                }
            }
            if !auth.message.isEmpty {
                Text(auth.message)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(auth.phase == .failed ? Palette.negText : Palette.ink2)
            }
            if !authorized && (auth.phase == .waiting || auth.phase == .failed) {
                HStack(spacing: 8) {
                    TextField("¿No vuelve solo? Pega aquí la dirección o el código", text: $manual)
                        .textFieldStyle(.roundedBorder)
                    Button("Usar") { useManual() }
                        .buttonStyle(MymButtonStyle(kind: .secondary, compact: true))
                        .disabled(manual.isEmpty)
                }
            }
        }
        .onDisappear { auth.stop() }
    }

    private func begin() {
        guard let secret = Keychain.read(account: secretKey) else { return }
        auth.start(clientId: clientId, secret: secret) { tokens in save(tokens) }
    }

    private func useManual() {
        guard let secret = Keychain.read(account: secretKey) else { return }
        auth.submitManual(manual, clientId: clientId, secret: secret) { tokens in save(tokens) }
        manual = ""
    }

    private func save(_ tokens: CTraderTokens) {
        Keychain.save(tokens.access, account: config.secretKey(accountId, "accessToken"))
        if let r = tokens.refresh { Keychain.save(r, account: config.secretKey(accountId, "refreshToken")) }
        let seconds: Double = tokens.expiresIn ?? 2_628_000
        let until: String = ISO8601DateFormatter().string(from: Date().addingTimeInterval(seconds))
        config.update(accountId) { $0.values["caduca"] = until }
        config.objectWillChange.send()
    }

    private func revoke() {
        config.clearTokens(accountId)
        auth.phase = .idle
        auth.message = ""
    }
}
#endif
