#if os(macOS)
import SwiftUI

// En vivo: lo que está pasando ahora. Con datos de demostración se mueve solo;
// con datos reales enseña lo que hay en los ficheros y se actualiza cuando se recargan (cada 5 minutos).

struct EnVivoView: View {
    @EnvironmentObject var accounts: AccountStore
    @EnvironmentObject var store: AppStore
    @StateObject private var feed = LiveFeed()

    private var demo: Bool { accounts.bundle.source == .demo }
    private var open: [TradeRecord] {
        accounts.bundle.trades.filter { $0.isOpen && accounts.bundle.inScope($0.cuenta, accounts.scope) }
    }

    private func current(_ t: TradeRecord) -> Double? {
        guard let base = t.pnl else { return nil }
        return demo ? base + feed.movement(t.label) : base
    }

    private var floating: Double? {
        let v: [Double] = open.compactMap { current($0) }
        return v.isEmpty ? nil : v.reduce(0, +)
    }

    private let utc: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    var body: some View {
        ScreenScroll {
            HStack(spacing: 12) {
                Heading("En vivo", info: "Lo que está pasando ahora: trades abiertos, avisos y respuesta del bróker", size: 22)
                Pill(text: demo ? "Demostración" : "Actualizado " + utc.string(from: accounts.bundle.loadedAt) + " UTC", tone: demo ? .info : .good)
            }
            ResponsiveRow {
                activityCard.frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: Layout.gap) {
                    heroCard
                    tradesCard
                }
                .frame(maxWidth: .infinity)
            }
            flowCard
            ResponsiveRow {
                metersCard.frame(maxWidth: .infinity)
                minuteCard.frame(maxWidth: .infinity)
                latencyCard.frame(maxWidth: .infinity)
            }
        }
        .onAppear { if demo { feed.start(labels: open.map { $0.label }) } }
        .onDisappear { feed.stop() }
    }

    // MARK: Piezas

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Heading("Actividad", info: "Lo más nuevo, arriba")
            ForEach(feed.events) { e in
                HStack(spacing: 12) {
                    Image(systemName: icon(e.kind))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(color(e.kind).fg)
                        .frame(width: 32, height: 32)
                        .background(color(e.kind).bg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Text(e.title).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                    Spacer()
                    Text(e.time).font(.system(size: 12)).foregroundStyle(Palette.ink2).monospacedDigit()
                }
                .padding(.vertical, 6)
                Divider()
            }
        }
        .card(Layout.card)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Flotante ahora").font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2)
            Text(Fmt.opt(floating) { Fmt.signedEur2($0) })
                .font(.system(size: 40, weight: .bold)).foregroundStyle(resultColor(floating)).monospacedDigit()
            Text("\(open.count) trades abiertos").font(.system(size: 13)).foregroundStyle(Palette.ink2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(Layout.card)
    }

    private var tradesCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Heading("Trades abiertos", info: "Resultado flotante de cada uno")
            if open.isEmpty {
                Text("No hay trades abiertos").font(.system(size: 13)).foregroundStyle(Palette.ink2).padding(.vertical, 8)
            }
            ForEach(open) { t in
                HStack(spacing: 10) {
                    Text(t.par ?? "?").font(.system(size: 13, weight: .bold, design: .monospaced)).frame(width: 76, alignment: .leading)
                    Pill(text: t.lado == "venta" ? "Venta" : "Compra", tone: t.lado == "venta" ? .bad : .good)
                    Text(maskedAccount(t.cuenta ?? "????")).font(.system(size: 12, design: .monospaced)).foregroundStyle(Palette.ink2)
                    Spacer()
                    if t.isUnprotected { Pill(text: "Sin stop", tone: .bad) }
                    Text(Fmt.opt(current(t)) { Fmt.signedEur2($0) })
                        .font(.system(size: 14, weight: .bold)).foregroundStyle(resultColor(current(t))).monospacedDigit()
                        .frame(width: 92, alignment: .trailing)
                }
                .padding(.vertical, 4)
                Divider()
            }
        }
        .card(Layout.card)
    }

    /// Cuántas señales llegan y cuántas acaban en operación. Es lo único que cuenta el embudo: Órdenes ya no lo repite.
    private var flowCard: some View {
        let f = store.data.funnel
        return VStack(alignment: .leading, spacing: 8) {
            Heading("Flujo de una orden", info: "El caudal azul se estrecha en cada paso y cada salida baja a su destino: violeta, frenada por riesgo (es protección); gris, cancelada; rojo, rechazada por el bróker")
            FlowChart(counts: [f.signals, f.riskOk, f.sent, f.filled], exits: ChartSamples.flowExits)
        }
        .card(Layout.card)
    }

    private var metersCard: some View {
        let summary: AccountSummary = accounts.bundle.summary(for: accounts.scope)
        let risk: Double = summary.riskUsed ?? 0
        let free: Double = summary.freeMarginPct ?? 0
        return VStack(alignment: .leading, spacing: 14) {
            Heading("Riesgo y margen", info: "Lo que queda antes de los límites. Riesgo: máximo 5 %")
            meter("Riesgo usado", Fmt.opt(summary.riskUsed) { Fmt.comma($0, 1) + " de 5 %" }, risk / 5, risk < 3 ? Palette.pos : Palette.warn, 0.6)
            meter("Margen libre", Fmt.opt(summary.freeMarginPct) { Fmt.pct($0, 0) }, free / 100, Palette.info, nil)
        }
        .card(Layout.card)
    }

    private func meter(_ title: String, _ text: String, _ fraction: Double, _ color: Color, _ warn: Double?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.system(size: 13))
                Spacer()
                Text(text).font(.system(size: 13, weight: .bold)).monospacedDigit()
            }
            ProgressTrack(fraction: fraction, color: color, warnAt: warn, height: 10)
        }
    }

    private var minuteCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Heading("Actividad por minuto", info: "Eventos de los últimos 24 minutos")
            DailyBarsChart(values: feed.activity, height: 110, yText: { Fmt.comma($0, 0) }, leftLabel: "hace 24 min", rightLabel: "ahora")
        }
        .card(Layout.card)
    }

    private var latencyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Heading("Respuesta del bróker", info: "Tiempo hasta que acepta la orden")
            HStack(alignment: .bottom, spacing: 14) {
                Text("\(Int(feed.latency.last ?? 0)) ms").font(.system(size: 26, weight: .bold)).monospacedDigit()
                Sparkline(values: feed.latency, color: Palette.info, lineWidth: 2.4).frame(height: 40)
            }
            Text("Normal: menos de 700 ms").font(.system(size: 12)).foregroundStyle(Palette.ink2)
        }
        .card(Layout.card)
    }

    private func icon(_ k: LiveFeed.Kind) -> String {
        switch k {
        case .open: return "plus"
        case .close: return "checkmark"
        case .reject: return "xmark"
        case .warn: return "exclamationmark"
        case .stop: return "arrow.right"
        case .signal: return "waveform.path.ecg"
        }
    }

    private func color(_ k: LiveFeed.Kind) -> (fg: Color, bg: Color) {
        switch k {
        case .open: return (Palette.infoText, Palette.infoBg)
        case .close: return (Palette.posText, Palette.posBg)
        case .reject: return (Palette.negText, Palette.negBg)
        case .warn: return (Palette.warnText, Palette.warnBg)
        case .stop: return (Palette.violet, Palette.neutralBg)
        case .signal: return (Palette.teal, Palette.neutralBg)
        }
    }
}
#endif
