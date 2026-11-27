#if os(macOS)
import SwiftUI
import AppKit

/// Ventana de configuración (⌘,). Cuentas, datos y seguridad.
struct ConfigView: View {
    var body: some View {
        TabView {
            CuentasConfig()
                .tabItem { Label("Cuentas", systemImage: "creditcard") }
            DatosConfig()
                .tabItem { Label("Datos", systemImage: "externaldrive") }
            SeguridadConfig()
                .tabItem { Label("Seguridad", systemImage: "lock") }
        }
        .frame(width: 780, height: 620)
    }
}

// MARK: - Cuentas

private enum ConfigFilter: String, CaseIterable, Identifiable {
    case todas = "Todas"
    case listas = "Listas"
    case incompletas = "Incompletas"
    case pausadas = "Pausadas"
    case bancos = "Bancos"

    var id: String { rawValue }
}

private struct AccountGroup: Identifiable {
    let id: String
    let title: String
    let items: [ConfiguredAccount]
}

struct CuentasConfig: View {
    @EnvironmentObject var config: ConfigStore
    @State private var query = ""
    @State private var filter: ConfigFilter = .todas
    @State private var open: UUID?

    private func matches(_ a: ConfiguredAccount, _ f: ConfigFilter) -> Bool {
        switch f {
        case .todas: return true
        case .listas: return config.state(a) == .ready || config.state(a) == .needsAuthorization
        case .incompletas: return config.state(a) == .incomplete
        case .pausadas: return a.paused
        case .bancos: return a.kind == .bank
        }
    }

    private var visible: [ConfiguredAccount] {
        let q: String = query.trimmingCharacters(in: .whitespaces).lowercased()
        return config.accounts.filter { a in
            guard matches(a, filter) else { return false }
            if q.isEmpty { return true }
            let provider: String = ProviderCatalog.provider(a.providerId)?.name.lowercased() ?? ""
            return a.name.lowercased().contains(q) || provider.contains(q)
        }
    }

    private var groups: [AccountGroup] {
        var out: [AccountGroup] = []
        for p in ProviderCatalog.all {
            let items: [ConfiguredAccount] = visible.filter { $0.providerId == p.id }
            if !items.isEmpty { out.append(AccountGroup(id: p.id, title: p.name, items: items)) }
        }
        let rest: [ConfiguredAccount] = visible.filter { ProviderCatalog.provider($0.providerId) == nil }
        if !rest.isEmpty { out.append(AccountGroup(id: "sin", title: "Sin elegir", items: rest)) }
        return out
    }

    private func count(_ f: ConfigFilter) -> Int {
        config.accounts.filter { matches($0, f) }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                TextField("Buscar cuenta, bróker o banco", text: $query)
                    .textFieldStyle(.roundedBorder)
                Button {
                    let id: UUID = config.add()
                    filter = .todas
                    query = ""
                    open = id
                } label: {
                    Text("+ Añadir cuenta")
                }
                .buttonStyle(MymButtonStyle(kind: .primary, compact: true))
            }
            Picker("", selection: $filter) {
                ForEach(ConfigFilter.allCases) { f in
                    Text("\(f.rawValue) \(count(f))").tag(f)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if config.accounts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "creditcard").font(.system(size: 28)).foregroundStyle(Palette.ink2)
                    Text("Aún no hay cuentas").font(.system(size: 15, weight: .semibold))
                    Text("Añade la primera y elige su bróker o su banco.").font(.system(size: 13)).foregroundStyle(Palette.ink2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if visible.isEmpty {
                Text("Ninguna cuenta coincide.").font(.system(size: 13)).foregroundStyle(Palette.ink2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(groups) { g in
                            groupView(g)
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .padding(20)
    }

    private func groupView(_ g: AccountGroup) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(g.title).font(.system(size: 13, weight: .bold))
                Text(g.items.count == 1 ? "1 cuenta" : "\(g.items.count) cuentas").font(.system(size: 12)).foregroundStyle(Palette.ink2)
                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(Palette.bg)
            ForEach(g.items) { a in
                row(a)
                Divider()
            }
        }
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func row(_ a: ConfiguredAccount) -> some View {
        let p: Provider? = ProviderCatalog.provider(a.providerId)
        let state: AccountConfigState = config.state(a)
        let number: Int = (config.accounts.firstIndex { $0.id == a.id } ?? 0) + 1
        let isOpen: Bool = open == a.id
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.2)) { open = isOpen ? nil : a.id }
            } label: {
                HStack(spacing: 12) {
                    Text("\(number)").font(.system(size: 13, weight: .bold)).foregroundStyle(Palette.ink2).frame(width: 24, alignment: .leading)
                    Text(p?.mono ?? "?")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(p?.tint ?? Palette.ink2)
                        .frame(width: 28, height: 28)
                        .background((p?.tint ?? Palette.gray).opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Text(a.name).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                    Spacer()
                    Text(p?.name ?? "—").font(.system(size: 13)).foregroundStyle(Palette.ink2)
                    Pill(text: state.label, tone: state.tone)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Palette.ink2)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                .padding(.horizontal, 14)
                .frame(height: 46)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if isOpen {
                AccountForm(id: a.id, onRemoved: { open = nil })
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - Formulario de una cuenta

struct AccountForm: View {
    @EnvironmentObject var config: ConfigStore
    let id: UUID
    var onRemoved: () -> Void
    @State private var message: String?
    @State private var confirmRemove = false

    private var account: ConfiguredAccount { config.account(id) ?? ConfiguredAccount() }

    private var nameBinding: Binding<String> {
        Binding<String>(get: { config.account(id)?.name ?? "" },
                        set: { v in config.update(id) { $0.name = v } })
    }

    private var pausedBinding: Binding<Bool> {
        Binding<Bool>(get: { config.account(id)?.paused ?? false },
                      set: { v in config.update(id) { $0.paused = v } })
    }

    private var tradeBinding: Binding<Bool> {
        Binding<Bool>(get: { config.account(id)?.canTrade ?? false },
                      set: { v in config.update(id) { $0.canTrade = v } })
    }

    private var kindBinding: Binding<ConnectionKind?> {
        Binding<ConnectionKind?>(get: { config.account(id)?.kind },
                                 set: { v in
                                     config.update(id) { acc in
                                         if acc.kind != v {
                                             acc.providerId = nil
                                             acc.values = [:]
                                         }
                                         acc.kind = v
                                     }
                                 })
    }

    private func valueBinding(_ fieldId: String, _ fallback: String) -> Binding<String> {
        Binding<String>(get: { config.account(id)?.values[fieldId] ?? fallback },
                        set: { v in config.update(id) { $0.values[fieldId] = v } })
    }

    var body: some View {
        let a: ConfiguredAccount = account
        let provider: Provider? = ProviderCatalog.provider(a.providerId)
        VStack(alignment: .leading, spacing: 14) {
            labeled("Nombre") {
                TextField("Nombre", text: nameBinding).textFieldStyle(.roundedBorder)
            }
            labeled("Qué vas a conectar") {
                Picker("", selection: kindBinding) {
                    Text("Elegir").tag(ConnectionKind?.none)
                    ForEach(ConnectionKind.allCases) { k in Text(k.label).tag(ConnectionKind?.some(k)) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 300)
            }
            if let kind = a.kind {
                labeled(kind == .bank ? "Tu banco" : "Tu bróker") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: 8)], spacing: 8) {
                        ForEach(ProviderCatalog.list(kind)) { p in
                            providerButton(p, selected: p.id == a.providerId)
                        }
                    }
                }
            } else {
                Text("Elige si es un bróker o un banco.").font(.system(size: 13)).foregroundStyle(Palette.ink2)
            }
            if let p = provider {
                ForEach(p.fields) { f in
                    fieldView(f, p)
                }
                if p.kind == .broker {
                    labeled("Qué puede hacer Mym") {
                        Picker("", selection: tradeBinding) {
                            Text("Solo ver").tag(false)
                            Text("Ver y operar").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(maxWidth: 300)
                    }
                }
                footer(a)
            }
        }
        .padding(.top, 4)
        .alert(isPresented: $confirmRemove) {
            Alert(title: Text("¿Quitar esta cuenta?"),
                  message: Text("Se borran también sus claves del Llavero."),
                  primaryButton: .destructive(Text("Quitar")) { config.remove(id); onRemoved() },
                  secondaryButton: .cancel(Text("Cancelar")))
        }
    }

    private func labeled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2)
            content()
        }
    }

    private func providerButton(_ p: Provider, selected: Bool) -> some View {
        Button {
            config.update(id) { acc in
                if acc.providerId != p.id { acc.values = [:] }
                acc.providerId = p.id
            }
        } label: {
            HStack(spacing: 8) {
                Text(p.mono).font(.system(size: 10, weight: .heavy)).foregroundStyle(p.tint)
                    .frame(width: 26, height: 26)
                    .background(p.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                Text(p.name).font(.system(size: 13, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 8)
            .frame(height: 40)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(selected ? Palette.graphiteDark : Palette.graphiteSoft, lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func fieldView(_ f: FieldSpec, _ p: Provider) -> some View {
        switch f.kind {
        case .text:
            labeled(f.label) {
                TextField(f.placeholder, text: valueBinding(f.id, "")).textFieldStyle(.roundedBorder)
                if !f.hint.isEmpty { Text(f.hint).font(.system(size: 12)).foregroundStyle(Palette.ink2) }
            }
        case .secret:
            labeled(f.label) {
                SecretFieldView(accountId: id, accountName: account.name, field: f)
                if !f.hint.isEmpty { Text(f.hint).font(.system(size: 12)).foregroundStyle(Palette.ink2) }
            }
        case .choice(let options):
            labeled(f.label) {
                Picker("", selection: valueBinding(f.id, options[0])) {
                    ForEach(options, id: \.self) { o in Text(o).tag(o) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 300)
                if !f.hint.isEmpty { Text(f.hint).font(.system(size: 12)).foregroundStyle(Palette.ink2) }
            }
        case .note(let text):
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle").foregroundStyle(Palette.ink2)
                Text(text).font(.system(size: 13)).foregroundStyle(Palette.ink)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.bg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        case .link(let title):
            labeled(f.label) {
                HStack(spacing: 10) {
                    Button(title) {}
                        .buttonStyle(MymButtonStyle(kind: .secondary, compact: true))
                        .disabled(true)
                    Pill(text: "Próximamente", tone: .info)
                }
                Text("Se activa cuando Mym esté registrada en \(p.name). Todavía no se puede conectar.")
                    .font(.system(size: 12)).foregroundStyle(Palette.ink2)
            }
        }
    }

    private func footer(_ a: ConfiguredAccount) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            HStack(spacing: 10) {
                Toggle("Pausada", isOn: pausedBinding)
                Button("Comprobar datos") {
                    let missing: [String] = config.missingFields(account)
                    config.update(id) { $0.checkedAt = Date() }
                    message = missing.isEmpty ? "Los datos están completos." : "Falta: " + missing.joined(separator: ", ") + "."
                }
                .buttonStyle(MymButtonStyle(kind: .secondary, compact: true))
                Spacer()
                Button("Quitar cuenta") { confirmRemove = true }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.negText)
            }
            if let m = message {
                Text(m).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2)
            }
        }
    }
}

// MARK: - Campo de clave (va al Llavero)

struct SecretFieldView: View {
    @EnvironmentObject var config: ConfigStore
    @AppStorage("mym.requireBiometric") private var requireBiometric = true
    let accountId: UUID
    let accountName: String
    let field: FieldSpec

    @State private var draft = ""
    @State private var editing = false
    @State private var revealed: String?
    @State private var failed = false

    private var key: String { config.secretKey(accountId, field.id) }

    var body: some View {
        let saved: Bool = Keychain.exists(account: key)
        VStack(alignment: .leading, spacing: 6) {
            if saved && !editing {
                HStack(spacing: 10) {
                    Text(revealed ?? "••••••••••••")
                        .font(.system(size: 13, design: .monospaced))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Pill(text: "En el Llavero", tone: .good)
                    Button(revealed == nil ? "Mostrar" : "Ocultar") { toggleReveal() }
                        .buttonStyle(MymButtonStyle(kind: .secondary, compact: true))
                    Button("Cambiar") { editing = true; revealed = nil }
                        .buttonStyle(MymButtonStyle(kind: .secondary, compact: true))
                }
                .padding(.horizontal, 10)
                .frame(height: 38)
                .background(Palette.bg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                HStack(spacing: 8) {
                    SecureField(field.placeholder, text: $draft).textFieldStyle(.roundedBorder)
                    Button("Guardar") { save() }
                        .buttonStyle(MymButtonStyle(kind: .primary, compact: true))
                        .disabled(draft.isEmpty)
                    if saved {
                        Button("Cancelar") { draft = ""; editing = false }
                            .buttonStyle(MymButtonStyle(kind: .secondary, compact: true))
                    }
                }
            }
            if failed {
                Text("No se pudo guardar en el Llavero.").font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.negText)
            }
        }
    }

    private func save() {
        let ok: Bool = Keychain.save(draft, account: key)
        failed = !ok
        if ok {
            draft = ""        // la clave no se queda en memoria de la pantalla
            editing = false
            config.objectWillChange.send()
        }
    }

    private func toggleReveal() {
        if revealed != nil {
            revealed = nil
            return
        }
        let k: String = key
        let show: () -> Void = {
            revealed = Keychain.read(account: k)
            // Se oculta sola a los 20 segundos.
            DispatchQueue.main.asyncAfter(deadline: .now() + 20) { revealed = nil }
        }
        if requireBiometric {
            Biometrics.confirm(reason: "Ver la clave de \(accountName)") { ok in
                if ok { show() }
            }
        } else {
            show()
        }
    }
}

// MARK: - Datos

struct DatosConfig: View {
    @EnvironmentObject var accounts: AccountStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(isOn: $accounts.useDemo) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Modo demostración").font(.system(size: 14, weight: .semibold))
                    Text("Usa datos de ejemplo. Desactívalo para leer tus ficheros.").font(.system(size: 12)).foregroundStyle(Palette.ink2)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Carpeta de datos").font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2)
                HStack(spacing: 10) {
                    Text(accounts.folderName ?? "Sin elegir")
                        .font(.system(size: 13, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .frame(height: 32)
                        .background(Palette.bg, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Button("Elegir carpeta…") { accounts.chooseFolder() }
                        .buttonStyle(MymButtonStyle(kind: .secondary, compact: true))
                    Button("Olvidar") {
                        DataFolder.forget()
                        accounts.folderName = nil
                        accounts.useDemo = true
                    }
                    .buttonStyle(MymButtonStyle(kind: .secondary, compact: true))
                    .disabled(accounts.folderName == nil)
                }
                Text("Mym solo lee esta carpeta. No escribe nada.").font(.system(size: 12)).foregroundStyle(Palette.ink2)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Ficheros").font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2)
                    Spacer()
                    Text("Se actualiza solo cada 5 minutos").font(.system(size: 12)).foregroundStyle(Palette.ink2)
                    Button("Recargar ahora") { accounts.reload() }
                        .buttonStyle(MymButtonStyle(kind: .secondary, compact: true))
                }
                ForEach(accounts.bundle.files) { f in
                    HStack {
                        Text(f.name).font(.system(size: 12, design: .monospaced))
                        Spacer()
                        Pill(text: f.state == .ok ? "Al día" : (f.state == .missing ? "Falta" : "No se lee"), tone: f.state == .ok ? .good : .bad)
                    }
                    .padding(.vertical, 2)
                    Divider()
                }
            }
            Spacer()
        }
        .padding(20)
    }
}

// MARK: - Seguridad

struct SeguridadConfig: View {
    @EnvironmentObject var config: ConfigStore
    @AppStorage("mym.requireBiometric") private var requireBiometric = true
    @State private var confirmDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Tus claves").font(.system(size: 15, weight: .semibold))
                Text("Se guardan cifradas en el Llavero de este Mac, solo en este equipo. No van a ningún fichero ni se envían a nadie. Mym las lee solo en el momento de usarlas.")
                    .font(.system(size: 13)).foregroundStyle(Palette.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Toggle(isOn: $requireBiometric) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Pedir Touch ID para ver una clave").font(.system(size: 14, weight: .semibold))
                    Text("Mostrar una clave guardada siempre se hace con tu huella o tu contraseña del Mac.").font(.system(size: 12)).foregroundStyle(Palette.ink2)
                }
            }
            HStack {
                Text("\(config.savedSecretsCount) claves guardadas").font(.system(size: 13)).foregroundStyle(Palette.ink2)
                Spacer()
                Button("Borrar todas las claves") { confirmDelete = true }
                    .buttonStyle(MymButtonStyle(kind: .danger, compact: true))
                    .disabled(config.savedSecretsCount == 0)
            }
            Spacer()
        }
        .padding(20)
        .alert(isPresented: $confirmDelete) {
            Alert(title: Text("¿Borrar todas las claves?"),
                  message: Text("Tendrás que volver a escribirlas para conectar las cuentas."),
                  primaryButton: .destructive(Text("Borrar")) { config.deleteAllSecrets() },
                  secondaryButton: .cancel(Text("Cancelar")))
        }
    }
}
#endif
