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
                    .padding(.leading, 20)
                    .padding(.trailing, 4)
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                GeometryReader { g in
                    ZStack(alignment: .topLeading) {
                        content
                            .id(store.module)
                            .transition(.opacity.combined(with: .offset(y: 10)))
                    }
                    .frame(width: g.size.width, height: g.size.height, alignment: .topLeading)
                    .environment(\.contentWidth, g.size.width)
                    .animation(.easeOut(duration: 0.28), value: store.module)
                }
                .padding(.top, 14)
            }
        }
        .sheet(item: $store.pending) { command in
            SignSheet(command: command)
                .environmentObject(store)
        }
        // La búsqueda cuelga de otra vista: en macOS 12, dos hojas en la misma vista se estorban.
        .background(
            Color.clear
                .sheet(isPresented: $store.showSearch) {
                    SearchSheet()
                        .environmentObject(store)
                }
        )
    }

    @ViewBuilder
    private var content: some View {
        switch store.module {
        case .torre: TorreView()
        case .envivo: EnVivoView()
        case .ordenes: OrdenesView()
        case .flota: FlotaView()
        case .cuentas: CuentasView()
        case .estrategias: EstrategiasView()
        case .resultados: ResultadosView()
        case .ajustes: AjustesView()
        case .plan: PlanView()
        case .riesgo: RiesgoView()
        }
    }
}

// MARK: - Riel (05 Indicador dentro de la Cápsula)

struct MacRail: View {
    @EnvironmentObject var store: AppStore
    @Namespace private var selection
    @State private var stopHover = false

    var body: some View {
        VStack(spacing: Layout.railGap) {
            RailButton(symbol: "magnifyingglass", label: "Buscar ⌘K", active: false, namespace: selection) {
                store.showSearch = true
            }
            Rectangle().fill(Palette.line).frame(width: 28, height: 1)
            // Las secciones se desplazan si la ventana es baja; la búsqueda, el engranaje y Parar todo siempre se ven.
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Layout.railGap) {
                    ForEach(Module.allCases) { module in
                        RailButton(
                            symbol: module.symbol,
                            label: module.title,
                            active: store.module == module,
                            namespace: selection,
                            badge: badge(for: module)
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) { store.module = module }
                        }
                    }
                }
            }
            Rectangle().fill(Palette.line).frame(width: 28, height: 1)
            RailButton(symbol: "gearshape", label: "Configuración ⌘,", active: false, namespace: selection) {
                // macOS 13 la llama «Settings»; macOS 12, «Preferences».
                if !NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) {
                    NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                }
            }
            // Parar todo: fuera del foco, gris; se pone rojo solo al pasar por encima.
            Button {
                store.requestStopAll()
            } label: {
                Image(systemName: "stop.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(stopHover ? Palette.stop : Palette.gray)
                    .frame(width: Layout.railItem, height: Layout.railItem)
                    .background(stopHover ? Palette.negBg : Color.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { h in withAnimation(.easeOut(duration: 0.15)) { stopHover = h } }
            .help("Parar todo")
            .accessibilityLabel("Parar todo")
        }
        .padding(.vertical, 12)
        .frame(width: Layout.railWidth)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.black.opacity(0.06), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 10)
        .frame(maxHeight: .infinity, alignment: .center)
    }

    private func badge(for module: Module) -> Int {
        switch module {
        case .plan: return 0
        case .riesgo: return store.data.openAlerts.count
        default: return 0
        }
    }
}

/// Botón del riel. La sección activa va rellena en grafito y el relleno se desliza al cambiar.
struct RailButton: View {
    let symbol: String
    let label: String
    let active: Bool
    let namespace: Namespace.ID
    var badge: Int = 0
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if active {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Palette.graphiteDark)
                        .shadow(color: Palette.graphiteDark.opacity(0.28), radius: 7, x: 0, y: 4)
                        .matchedGeometryEffect(id: "seleccion", in: namespace)
                } else if hover {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Palette.bg)
                }
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(active ? Color.white : Palette.ink2)
                if badge > 0 {
                    // Mismo azul para Plan y Avisos: el rojo queda para pérdidas y peligro.
                    Text("\(badge)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 4)
                        .frame(minWidth: 17, minHeight: 17)
                        .background(Palette.info, in: Capsule())
                        .overlay(Capsule().stroke(Palette.card, lineWidth: 2))
                        .offset(x: 14, y: -14)
                }
            }
            .frame(width: Layout.railItem, height: Layout.railItem)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.easeOut(duration: 0.15)) { hover = h } }
        .help(label)
        .accessibilityLabel(label)
    }
}

// MARK: - Contenedor de pantalla

/// Pantalla con desplazamiento: márgenes y huecos de la retícula de 8 puntos.
struct ScreenScroll<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.gap) {
                content()
            }
            .padding(.horizontal, Layout.page)
            .padding(.top, 8)
            .padding(.bottom, Layout.page)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Búsqueda y acciones (⌘K)

struct SearchSheet: View {
    @EnvironmentObject var store: AppStore
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

    /// Cierra la búsqueda y, si hay algo más que hacer (abrir la hoja de firma), espera a que termine de cerrarse.
    /// En macOS 12, abrir una hoja mientras otra se cierra la deja atascada.
    private func close(then action: (() -> Void)? = nil) {
        store.showSearch = false
        if let action = action {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { action() }
        }
    }

    private var items: [Item] {
        var out: [Item] = []
        for cell in store.data.cells where cell.health != .paused {
            out.append(Item(group: "Acciones", title: "Pausar \(cell.id)", subtitle: cell.accountId,
                            symbol: "pause.circle", color: Palette.stop) {
                close { store.requestPause(cell.id) }
            })
        }
        out.append(Item(group: "Acciones", title: "Parar todo", subtitle: "Todos los robots",
                        symbol: "stop.circle", color: Palette.stop) {
            close { store.requestStopAll() }
        })
        for module in Module.allCases {
            out.append(Item(group: "Ir a", title: module.title, subtitle: "Sección", symbol: module.symbol, color: module.color) {
                store.module = module
                close()
            })
        }
        for order in store.data.orders {
            out.append(Item(group: "Órdenes", title: "\(order.id) · \(order.instrument) \(order.side.label.lowercased()) \(Fmt.comma(order.lots, 2))",
                            subtitle: order.status.label, symbol: "shippingbox", color: Palette.info) {
                store.selectedOrderId = order.id
                store.module = .ordenes
                close()
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
                    .onSubmit { items.first?.run() }
                Button { close() } label: {
                    Text("esc").font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2)
                        .padding(.horizontal, 6).frame(height: 22)
                        .background(Palette.neutralBg, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
                .help("Cerrar")
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
        .onExitCommand { close() }
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
            menuRow("Abrir el plan") { store.module = .plan; NSApp.activate(ignoringOtherApps: true) }
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
