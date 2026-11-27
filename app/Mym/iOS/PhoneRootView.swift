#if os(iOS)
import SwiftUI

/// iPhone: cinco secciones con un dock flotante de cristal.
/// Cada dato vive en un sitio: Hoy (resumen y cuentas), En vivo (lo de ahora), Avisos, Resultados y Plan.
/// Se ve y se para; reanudar y aprobar se hacen en el Mac.
struct PhoneRootView: View {
    @EnvironmentObject var store: AppStore
    @State private var tab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $tab) {
                NavigationStack { HoyPhoneView() }
                    .toolbar(.hidden, for: .tabBar)
                    .tag(0)
                NavigationStack { EnVivoPhoneView() }
                    .toolbar(.hidden, for: .tabBar)
                    .tag(1)
                NavigationStack { AvisosPhoneView() }
                    .toolbar(.hidden, for: .tabBar)
                    .tag(2)
                NavigationStack { ResultadosPhoneView() }
                    .toolbar(.hidden, for: .tabBar)
                    .tag(3)
                NavigationStack { PlanPhoneView() }
                    .toolbar(.hidden, for: .tabBar)
                    .tag(4)
            }
            // Difumina lo que pasa por debajo del dock para que no se mezcle con los iconos.
            LinearGradient(gradient: Gradient(colors: [Palette.bg.opacity(0), Palette.bg]), startPoint: .top, endPoint: .bottom)
                .frame(height: 120)
                .allowsHitTesting(false)
                .ignoresSafeArea(edges: .bottom)
            FloatingDock(tab: $tab, alerts: store.data.openAlerts.count)
                .padding(.bottom, 8)
        }
        .tint(Palette.graphiteDark)
        .sheet(item: $store.pending) { command in
            SignSheet(command: command)
                .environmentObject(store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

/// Dock flotante: cápsula de cristal solo con iconos. La sección activa se expande y enseña su nombre.
struct FloatingDock: View {
    @Binding var tab: Int
    let alerts: Int
    @Namespace private var selection

    private let items: [(title: String, symbol: String)] = [
        ("Hoy", "square.grid.2x2"), ("En vivo", "waveform.path.ecg"), ("Avisos", "bell"), ("Resultados", "chart.bar"), ("Plan", "list.bullet.rectangle")
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<items.count, id: \.self) { i in
                let on: Bool = tab == i
                Button {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) { tab = i }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: items[i].symbol)
                            .font(.system(size: 20, weight: .semibold))
                        if on {
                            Text(items[i].title)
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                                .fixedSize()
                        }
                    }
                    .foregroundStyle(on ? Color.white : Palette.ink2)
                    .padding(.horizontal, on ? 16 : 0)
                    .frame(minWidth: 48, minHeight: 48)
                    .background {
                        if on {
                            Capsule()
                                .fill(Palette.graphiteDark)
                                .shadow(color: Palette.graphiteDark.opacity(0.3), radius: 7, x: 0, y: 4)
                                .matchedGeometryEffect(id: "seleccion", in: selection)
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        dockDot(i, on: on)
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(items[i].title)
            }
        }
        .padding(8)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.7), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.16), radius: 20, x: 0, y: 12)
    }

    /// Un punto azul (en Avisos) cuando hay algo pendiente.
    @ViewBuilder
    private func dockDot(_ i: Int, on: Bool) -> some View {
        let pending: Int = i == 2 ? alerts : 0
        if pending > 0 {
            Circle()
                .fill(Palette.info)
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(on ? Palette.graphiteDark : Color.white, lineWidth: 2))
                .offset(x: -7, y: 7)
        }
    }
}

/// Fondo y título grande común a las pantallas del iPhone.
struct PhoneScreen<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Palette.ink2)
                    }
                    Text(title)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Palette.ink)
                }
                .padding(.horizontal, 4)
                content()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 96)
        }
        .background(Palette.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Hoy

struct HoyPhoneView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        let d = store.data
        PhoneScreen(title: "Hoy") {
            if d.criticalCount > 0 {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Palette.neg)
                    Text("\(d.criticalCount) crítico · posición sin stop")
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(Palette.negText)
                    Spacer()
                }
                .padding(12)
                .background(Palette.negBg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 6) {
                Heading("Equity", info: "Suma de todas las cuentas") {
                    Pill(text: Fmt.signedPct(d.equityDeltaPct), tone: .good)
                }
                Text(Fmt.eur(d.equity))
                    .font(.system(size: 34, weight: .bold)).monospacedDigit().foregroundStyle(Palette.ink)
                Sparkline(values: d.equitySeries, color: Palette.pos, lineWidth: 2.4, fill: true)
                    .frame(height: 56)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(Layout.card)

            CuentaPhoneCard()

            HStack(spacing: 18) {
                RingsView(rings: [
                    RingSpec(progress: d.dayLimitUsed, color: Palette.warn),
                    RingSpec(progress: d.exposurePct / 100, color: Palette.graphiteDark),
                    RingSpec(progress: store.data.accounts.first { $0.id == "Fondeo B · 50k" }?.targetUsed ?? 0, color: Palette.info)
                ], lineWidth: 10, gap: 3)
                .frame(width: 96, height: 96)
                VStack(alignment: .leading, spacing: 8) {
                    ringLine(Palette.warn, "Día", Fmt.pct(d.dayLimitUsed * 100))
                    ringLine(Palette.graphiteDark, "Exposición", Fmt.pct(d.exposurePct))
                    ringLine(Palette.info, "Objetivo B", Fmt.pct((store.data.accounts.first { $0.id == "Fondeo B · 50k" }?.targetUsed ?? 0) * 100))
                }
                Spacer(minLength: 0)
            }
            .card(Layout.card)

            VStack(spacing: 0) {
                ForEach(d.cells) { cell in
                    HStack(spacing: 10) {
                        StatusDot(color: cell.health.color)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(cell.id).font(.system(size: 14, weight: .semibold, design: .monospaced))
                            Text(cell.accountId).font(.system(size: 12)).foregroundStyle(Palette.ink2)
                        }
                        Spacer()
                        Text(Fmt.signedPct(cell.dayPct, 1))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(cell.dayPct < 0 ? Palette.negText : Palette.ink)
                            .monospacedDigit()
                    }
                    .padding(.vertical, 9)
                    if cell.id != d.cells.last?.id { Divider() }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button {
                store.requestStopAll()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "stop.circle")
                    Text("Parar todo")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.ink2)
                .padding(.horizontal, 18)
                .frame(minHeight: 40)
                .overlay(Capsule().stroke(Palette.graphiteSoft, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            Text("Desde el móvil se puede ver y parar. Reanudar y aprobar se hacen en el Mac.")
                .font(.system(size: 12)).foregroundStyle(Palette.ink2)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
        }
    }

    private func ringLine(_ color: Color, _ label: String, _ value: String) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 9, height: 9)
            Text(label).font(.system(size: 14)).foregroundStyle(Palette.ink)
            Spacer(minLength: 12)
            Text(value).font(.system(size: 14, weight: .bold)).monospacedDigit().foregroundStyle(Palette.ink)
        }
    }
}

// MARK: - Órdenes

struct OrdenesPhoneView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        let d = store.data
        PhoneScreen(title: "Órdenes") {
            VStack(spacing: 0) {
                ForEach(d.orders) { order in
                    NavigationLink {
                        OrderDetailPhoneView(order: order)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: order.side == .buy ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Palette.ink)
                                .frame(width: 34, height: 34)
                                .background(Palette.neutralBg, in: Circle())
                            VStack(alignment: .leading, spacing: 1) {
                                Text("\(order.side.label) \(order.instrument)")
                                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.ink)
                                Text(order.time).font(.system(size: 12)).foregroundStyle(Palette.ink2).monospacedDigit()
                            }
                            Spacer(minLength: 4)
                            Pill(text: order.status.label, tone: order.status.tone)
                        }
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    if order.id != d.orders.last?.id { Divider() }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func funnel(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value).font(.system(size: 18, weight: .bold)).monospacedDigit().foregroundStyle(Palette.ink)
            Text(label).font(.system(size: 11, weight: .semibold)).foregroundStyle(Palette.ink2)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct OrderDetailPhoneView: View {
    @EnvironmentObject var store: AppStore
    let order: Order

    var body: some View {
        PhoneScreen(title: "\(order.side.label) \(order.instrument)") {
            HStack {
                Pill(text: order.status.label, tone: order.status.tone)
                Spacer()
                if let pnl = order.pnl {
                    Text(Fmt.eurDecimals(pnl))
                        .font(.system(size: 26, weight: .bold)).monospacedDigit()
                        .foregroundStyle(pnl >= 0 ? Palette.posText : Palette.negText)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                StepBar(done: order.status.steps, doneColor: Palette.graphiteDark)
                HStack {
                    ForEach(["Revisada", "Enviada", "Abierta", "Cerrada"], id: \.self) { s in
                        Text(s).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .card(Layout.card)

            VStack(alignment: .leading, spacing: 6) {
                Heading("Precio", info: "Desde la entrada, con el objetivo arriba y el stop abajo")
                PriceStrip(entry: order.entry, stop: order.stop, target: order.target, last: order.last)
                    .frame(height: 200)
            }
            .card(Layout.card)
        }
    }
}

// MARK: - Avisos

struct AvisosPhoneView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        let d = store.data
        PhoneScreen(title: "Avisos") {
            VStack(spacing: 0) {
                ForEach(d.alerts) { a in
                    HStack(spacing: 10) {
                        IncidentRow(alert: a)
                        if !a.acknowledged, a.action != nil {
                            Button("Reconocer") { store.acknowledge(a.id) }
                                .buttonStyle(MymButtonStyle(kind: .secondary, compact: true))
                        }
                    }
                    .padding(.vertical, 4)
                    if a.id != d.alerts.last?.id { Divider() }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Heading("Comandos", info: "Lo que se ha firmado desde tus dispositivos")
                ForEach(store.log.prefix(4)) { c in
                    HStack {
                        Text(c.name).font(.system(size: 13, weight: .semibold, design: .monospaced))
                        Spacer()
                        Pill(text: c.accepted ? "Aceptado" : "Rechazado", tone: c.accepted ? .good : .bad)
                    }
                    .padding(.vertical, 3)
                }
            }
            .card(Layout.card)

            LayersCard(layers: d.layers)
        }
    }
}

// MARK: - Plan

/// Plan: lo que queremos hacer más adelante. Tres listas que se ordenan, se mueven y se borran.
struct PlanPhoneView: View {
    @EnvironmentObject var plan: PlanStore
    @State private var state: PlanState = .next
    @State private var title = ""

    var body: some View {
        let list: [PlanItem] = plan.items(state)
        PhoneScreen(title: "Plan") {
            Picker("", selection: $state) {
                ForEach(PlanState.allCases) { s in
                    Text("\(s.title) \(plan.count(s))").tag(s)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 8) {
                TextField("Añadir a \(state.title)", text: $title)
                    .font(.system(size: 15))
                    .padding(.horizontal, 12)
                    .frame(height: 40)
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .submitLabel(.done)
                    .onSubmit(add)
                Button(action: add) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 40, height: 40)
                        .background(Palette.graphiteDark, in: Circle())
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 0) {
                if list.isEmpty {
                    Text(state == .done ? "Aún no hay nada terminado." : "Nada por aquí.")
                        .font(.system(size: 14)).foregroundStyle(Palette.ink2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 14)
                }
                ForEach(list) { item in
                    row(item)
                    if item.id != list.last?.id { Divider() }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text("Este plan se guarda solo en este iPhone.")
                .font(.system(size: 12)).foregroundStyle(Palette.ink2)
        }
    }

    private func add() {
        plan.add(title: title, note: "", kind: .idea, state: state)
        title = ""
    }

    private func row(_ item: PlanItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.kind.symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Palette.ink)
                .frame(width: 32, height: 32)
                .background(Palette.neutralBg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(item.state == .done ? Palette.ink2 : Palette.ink)
                    .strikethrough(item.state == .done)
                if !item.note.isEmpty {
                    Text(item.note).font(.system(size: 13)).foregroundStyle(Palette.ink2)
                }
            }
            Spacer(minLength: 4)
            Menu {
                if plan.canShift(item.id, by: -1) {
                    Button("Subir") { withAnimation { plan.shift(item.id, by: -1) } }
                }
                if plan.canShift(item.id, by: 1) {
                    Button("Bajar") { withAnimation { plan.shift(item.id, by: 1) } }
                }
                ForEach(PlanState.allCases.filter { $0 != item.state }) { s in
                    Button("Pasar a \(s.title)") { withAnimation { plan.move(item.id, to: s) } }
                }
                Button("Borrar") { withAnimation { plan.remove(item.id) } }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Palette.ink2)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.vertical, 10)
    }
}
#endif
