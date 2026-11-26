#if os(iOS)
import SwiftUI

/// iPhone: cuatro pestañas. Se ve y se para; reanudar y aprobar se hacen en el Mac.
struct PhoneRootView: View {
    @EnvironmentObject var store: AppStore
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack { HoyPhoneView() }
                .tabItem { Label("Hoy", systemImage: "square.grid.2x2") }
                .tag(0)
            NavigationStack { OrdenesPhoneView() }
                .tabItem { Label("Órdenes", systemImage: "shippingbox") }
                .tag(1)
            NavigationStack { AvisosPhoneView() }
                .tabItem { Label("Avisos", systemImage: "bell") }
                .badge(store.data.openAlerts.count)
                .tag(2)
            NavigationStack { JevPhoneView() }
                .tabItem { Label("Jev", systemImage: "sparkles") }
                .badge(store.data.pendingProposals)
                .tag(3)
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
            .padding(.bottom, 24)
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
        PhoneScreen(title: "Hoy", subtitle: "jue 26 nov · 10:42") {
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
            .card(16)

            HStack(spacing: 18) {
                RingsView(rings: [
                    RingSpec(progress: d.dayLimitUsed, color: Palette.warn),
                    RingSpec(progress: d.exposurePct / 100, color: Palette.graphiteDark),
                    RingSpec(progress: store.data.accounts.first { $0.id == "FND-B-50k" }?.targetUsed ?? 0, color: Palette.info)
                ], lineWidth: 10, gap: 3)
                .frame(width: 96, height: 96)
                VStack(alignment: .leading, spacing: 8) {
                    ringLine(Palette.warn, "Día", Fmt.pct(d.dayLimitUsed * 100))
                    ringLine(Palette.graphiteDark, "Exposición", Fmt.pct(d.exposurePct))
                    ringLine(Palette.info, "Objetivo B", Fmt.pct((store.data.accounts.first { $0.id == "FND-B-50k" }?.targetUsed ?? 0) * 100))
                }
                Spacer(minLength: 0)
            }
            .card(16)

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
                HStack(spacing: 8) {
                    Image(systemName: "stop.fill")
                    Text("Parar todo")
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(Palette.stop, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
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
            HStack(spacing: 8) {
                funnel("\(d.funnel.signals)", "señales")
                funnel("\(d.funnel.riskOk)", "riesgo ✓")
                funnel("\(d.funnel.sent)", "enviadas")
                funnel("\(d.funnel.filled)", "ejecutadas")
            }
            VStack(spacing: 0) {
                ForEach(d.orders) { order in
                    NavigationLink {
                        OrderDetailPhoneView(order: order)
                    } label: {
                        HStack(spacing: 11) {
                            IconTile(symbol: d.strategy(order.strategyId)?.symbol ?? "arrow.up.right",
                                     color: d.strategy(order.strategyId)?.color ?? Palette.gray, size: 32)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("\(order.instrument) \(order.side.label) \(Fmt.comma(order.lots, 2))")
                                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.ink)
                                Text("\(order.id) · \(order.cellId)")
                                    .font(.system(size: 12, design: .monospaced)).foregroundStyle(Palette.ink2)
                            }
                            Spacer(minLength: 4)
                            VStack(alignment: .trailing, spacing: 3) {
                                Pill(text: order.status.label, tone: order.status.tone)
                                Text(order.time).font(.system(size: 12)).foregroundStyle(Palette.ink2).monospacedDigit()
                            }
                        }
                        .padding(.vertical, 9)
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
        let d = store.data
        let total = d.hops.reduce(0) { $0 + $1.ms }
        PhoneScreen(title: order.instrument, subtitle: order.id) {
            HStack {
                Pill(text: order.status.label, tone: order.status.tone)
                Pill(text: order.strategyId)
                Spacer()
                if let pnl = order.pnl {
                    Text(Fmt.eurDecimals(pnl))
                        .font(.system(size: 22, weight: .bold)).monospacedDigit()
                        .foregroundStyle(pnl >= 0 ? Palette.posText : Palette.negText)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Heading("Seguimiento", info: "Las paradas de la orden, de la señal al cierre")
                StepBar(done: order.status.steps, doneColor: Palette.graphiteDark)
                HStack {
                    ForEach(["Riesgo", "Envío", "Aceptada", "Ejecutada"], id: \.self) { s in
                        Text(s).font(.system(size: 11, weight: .semibold)).foregroundStyle(Palette.ink2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .card(16)

            VStack(alignment: .leading, spacing: 8) {
                Heading("Tiempo · \(total) ms", info: "A escala: cuánto tarda cada tramo")
                GeometryReader { g in
                    HStack(spacing: 2) {
                        ForEach(d.hops) { hop in
                            RoundedRectangle(cornerRadius: 4).fill(hop.color)
                                .frame(width: max(4, (g.size.width - 8) * CGFloat(hop.ms) / CGFloat(total)))
                        }
                    }
                }
                .frame(height: 26)
                ForEach(d.hops) { hop in
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3).fill(hop.color).frame(width: 9, height: 9)
                        Text(hop.name).font(.system(size: 13)).foregroundStyle(Palette.ink)
                        Spacer()
                        Text("\(hop.ms) ms").font(.system(size: 13, weight: .semibold)).monospacedDigit()
                    }
                }
            }
            .card(16)

            VStack(alignment: .leading, spacing: 6) {
                Heading("Precio", info: "Desde la entrada, con el objetivo arriba y el stop abajo")
                PriceStrip(entry: order.entry, stop: order.stop, target: order.target, last: order.last)
                    .frame(height: 180)
            }
            .card(16)
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
            .card(16)

            LayersCard(layers: d.layers)
        }
    }
}

// MARK: - Jev (solo lectura en el móvil)

struct JevPhoneView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        let d = store.data
        PhoneScreen(title: "Jev", subtitle: "Fase 2 · aprobar se hace en el Mac") {
            VStack(spacing: 0) {
                ForEach(d.proposals) { p in
                    NavigationLink {
                        ProposalPhoneView(proposal: p)
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Circle().fill(p.unread ? Palette.magenta : Color.clear).frame(width: 8, height: 8).padding(.top, 6)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.ink)
                                Text(p.short).font(.system(size: 13)).foregroundStyle(Palette.ink2)
                                Pill(text: p.statusText, tone: p.status.tone).padding(.top, 2)
                            }
                            Spacer()
                            Text(p.time).font(.system(size: 12)).foregroundStyle(Palette.ink2)
                        }
                        .padding(.vertical, 9)
                    }
                    .buttonStyle(.plain)
                    if p.id != d.proposals.last?.id { Divider() }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

struct ProposalPhoneView: View {
    let proposal: Proposal

    var body: some View {
        PhoneScreen(title: proposal.title, subtitle: "Jev propone · \(proposal.time)") {
            Text(proposal.summary).font(.system(size: 15)).foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading).card(16)

            VStack(alignment: .leading, spacing: 8) {
                Heading("Tres respuestas", info: "Jev pregunta tres veces y se queda con la mayoría")
                ForEach(proposal.votes) { v in
                    HStack(alignment: .top, spacing: 10) {
                        Pill(text: v.label, tone: v.positive ? .good : .neutral)
                        Text(v.reason).font(.system(size: 13)).foregroundStyle(Palette.ink)
                        Spacer(minLength: 0)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(16)

            VStack(alignment: .leading, spacing: 8) {
                Heading("Validador", info: "Reglas fijas que la propuesta cumple antes de llegarte")
                ForEach(proposal.checks, id: \.self) { c in
                    HStack(spacing: 9) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.pos)
                        Text(c).font(.system(size: 14)).foregroundStyle(Palette.ink)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(16)

            HStack(spacing: 8) {
                Image(systemName: "desktopcomputer").foregroundStyle(Palette.ink2)
                Text("Para aprobar, abre Jev en el Mac.").font(.system(size: 13)).foregroundStyle(Palette.ink2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Palette.neutralBg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}
#endif
