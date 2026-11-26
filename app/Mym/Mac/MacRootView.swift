#if os(macOS)
import SwiftUI

/// Ventana principal del Mac: riel en cápsula a la izquierda y la pantalla elegida.
struct MacRootView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()
            HStack(alignment: .top, spacing: 0) {
                MacRail()
                    .padding(.leading, 12)
                    .padding(.top, 40)
                    .padding(.bottom, 14)
                content
                    .padding(.top, 14)
            }
        }
        .sheet(item: $store.pending) { command in
            SignSheet(command: command)
                .environmentObject(store)
        }
        .sheet(isPresented: $store.showSearch) {
            SearchSheet()
                .environmentObject(store)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.module {
        case .torre: TorreView()
        case .ordenes: OrdenesView()
        case .flota: FlotaView()
        case .cuentas: CuentasView()
        case .estrategias: EstrategiasView()
        case .ajustes: AjustesView()
        case .jev: JevView()
        case .riesgo: RiesgoView()
        }
    }
}

// MARK: - Riel (05 Indicador dentro de la Cápsula)

struct MacRail: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack(spacing: 4) {
            RailButton(symbol: "magnifyingglass", label: "Buscar ⌘K", color: Palette.graphite, active: false) {
                store.showSearch = true
            }
            Rectangle().fill(Palette.line).frame(width: 28, height: 1).padding(.vertical, 6)
            ForEach(Module.allCases) { module in
                RailButton(
                    symbol: module.symbol,
                    label: module.title,
                    color: module.color,
                    active: store.module == module,
                    badge: badge(for: module),
                    badgeColor: module == .riesgo ? Palette.neg : Palette.info
                ) {
                    store.module = module
                }
            }
            Spacer(minLength: 12)
            RailButton(symbol: "bell", label: "Avisos", color: Palette.graphite, active: false,
                       badge: store.data.openAlerts.count, badgeColor: Palette.neg) {
                store.module = .riesgo
            }
            RailButton(symbol: "person.crop.circle", label: "Perfil", color: Palette.graphite, active: false) {}
            Button {
                store.requestStopAll()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 44, height: 44)
                    .background(Palette.stop, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
            .buttonStyle(.plain)
            .help("Parar todo")
            .accessibilityLabel("Parar todo")
        }
        .padding(.vertical, 12)
        .frame(width: 64)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: Color.black.opacity(0.10), radius: 14, x: 0, y: 8)
    }

    private func badge(for module: Module) -> Int {
        switch module {
        case .jev: return store.data.pendingProposals
        case .riesgo: return store.data.openAlerts.count
        default: return 0
        }
    }
}

struct RailButton: View {
    let symbol: String
    let label: String
    let color: Color
    let active: Bool
    var badge: Int = 0
    var badgeColor: Color = Palette.neg
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(active ? Palette.bg : Color.clear)
                if active {
                    Capsule()
                        .fill(color)
                        .frame(width: 4, height: 24)
                        .offset(x: -26)
                }
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(active ? color : Palette.gray)
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 4)
                        .frame(minWidth: 17, minHeight: 17)
                        .background(badgeColor, in: Capsule())
                        .overlay(Capsule().stroke(Palette.card, lineWidth: 2))
                        .offset(x: 14, y: -14)
                }
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
    }
}

// MARK: - Contenedor de pantalla con desplazamiento

struct ScreenScroll<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                content()
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Búsqueda y acciones (⌘K)

struct SearchSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @FocusState private var focused: Bool

    private struct Item: Identifiable {
        let id = UUID()
        let group: String
        let title: String
        let subtitle: String
        let symbol: String
        let color: Color
        let run: () -> Void
    }

    private var items: [Item] {
        var out: [Item] = []
        for cell in store.data.cells where cell.health != .paused {
            out.append(Item(group: "Acciones", title: "Pausar \(cell.id)", subtitle: "\(cell.accountId) · comando firmado",
                            symbol: "pause.circle", color: Palette.stop) {
                dismiss()
                store.requestPause(cell.id)
            })
        }
        out.append(Item(group: "Acciones", title: "Parar todo", subtitle: "halt_all · todas las células",
                        symbol: "stop.circle", color: Palette.stop) {
            dismiss()
            store.requestStopAll()
        })
        for module in Module.allCases {
            out.append(Item(group: "Ir a", title: module.title, subtitle: "Sección", symbol: module.symbol, color: module.color) {
                store.module = module
                dismiss()
            })
        }
        for order in store.data.orders {
            out.append(Item(group: "Órdenes", title: "\(order.id) · \(order.instrument) \(order.side.label.lowercased()) \(Fmt.comma(order.lots, 2))",
                            subtitle: order.status.label, symbol: "shippingbox", color: Palette.info) {
                store.selectedOrderId = order.id
                store.module = .ordenes
                dismiss()
            })
        }
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return out }
        return out.filter { $0.title.lowercased().contains(q) || $0.subtitle.lowercased().contains(q) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass").font(.system(size: 18)).foregroundStyle(Palette.ink2)
                TextField("Buscar órdenes, células o acciones", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18))
                    .focused($focused)
                Text("esc").font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2)
                    .padding(.horizontal, 6).frame(height: 22)
                    .background(Palette.neutralBg, in: RoundedRectangle(cornerRadius: 6))
            }
            .padding(.horizontal, 20)
            .frame(height: 60)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(groups, id: \.self) { group in
                        Text(group)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Palette.ink2)
                            .padding(.horizontal, 22)
                            .padding(.top, 10)
                            .padding(.bottom, 2)
                        ForEach(items.filter { $0.group == group }) { item in
                            Button(action: item.run) {
                                HStack(spacing: 12) {
                                    IconTile(symbol: item.symbol, color: item.color, size: 28)
                                    Text(item.title).font(.system(size: 14, weight: .medium)).foregroundStyle(Palette.ink)
                                    Spacer()
                                    Text(item.subtitle).font(.system(size: 12)).foregroundStyle(Palette.ink2)
                                }
                                .padding(.horizontal, 14)
                                .frame(height: 44)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 8)
                        }
                    }
                }
                .padding(.bottom, 10)
            }
            .frame(maxHeight: 420)
        }
        .frame(width: 640)
        .background(Palette.card)
        .onAppear { focused = true }
    }

    private var groups: [String] {
        var seen: [String] = []
        for item in items where !seen.contains(item.group) { seen.append(item.group) }
        return seen
    }
}

// MARK: - Barra de menús

struct MenuBarView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: store.data.criticalCount > 0 ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(store.data.criticalCount > 0 ? Palette.neg : Palette.pos)
                VStack(alignment: .leading, spacing: 1) {
                    Text(store.data.criticalCount > 0 ? "Hay una incidencia" : "Todo en marcha")
                        .font(.system(size: 14, weight: .bold))
                    Text("\(store.data.openAlerts.count) avisos · Londres principal")
                        .font(.system(size: 12)).foregroundStyle(Palette.ink2)
                }
                Spacer()
                Text(Fmt.signedPct(store.data.dayPct, 2))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(store.data.dayPct < 0 ? Palette.negText : Palette.posText)
                    .monospacedDigit()
            }
            .padding(14)
            Divider()
            ForEach(store.data.cells) { cell in
                HStack(spacing: 9) {
                    StatusDot(color: cell.health.color)
                    Text(cell.id).font(.system(size: 12, design: .monospaced))
                    Spacer()
                    Text(Fmt.signedPct(cell.dayPct, 1))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(cell.dayPct < 0 ? Palette.negText : Palette.ink2)
                        .monospacedDigit()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
            }
            Divider().padding(.top, 6)
            menuRow("Abrir Torre") { store.module = .torre; NSApp.activate(ignoringOtherApps: true) }
            menuRow("Revisar propuesta de Jev (\(store.data.pendingProposals))") { store.module = .jev; NSApp.activate(ignoringOtherApps: true) }
            menuRow("Buscar y actuar…") { store.showSearch = true; NSApp.activate(ignoringOtherApps: true) }
            Divider()
            Button {
                NSApp.activate(ignoringOtherApps: true)
                store.requestStopAll()
            } label: {
                Text("Parar todo…")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.stop)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 320)
    }

    private func menuRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}
#endif
