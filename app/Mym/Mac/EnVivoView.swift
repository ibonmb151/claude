#if os(macOS)
import SwiftUI

// En vivo: lo que está pasando ahora. Con datos de demostración se mueve solo;
// con datos reales enseña lo que hay en los ficheros y se actualiza cuando se recargan (cada 5 minutos).

final class LiveFeed: ObservableObject {
    enum Kind { case open, close, reject, warn, stop, signal }

    struct Event: Identifiable {
        let id = UUID()
        let time: String
        let kind: Kind
        let title: String
        let detail: String
    }

    @Published var events: [Event] = []
    @Published var jitter: [String: Double] = [:]      // lo que se ha movido cada trade desde su valor base
    @Published var activity: [Double] = []
    @Published var latency: [Double] = []
    @Published var signals = 142
    @Published var executed = 121
    @Published var rejected = 7
    @Published var lastUpdate = Date()

    private var timer: Timer?
    private let clock: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private let pool: [(Kind, String, String)] = [
        (.open, "Apertura · Compra GBPJPY 0,10", "···2511 · Ruptura"),
        (.close, "Cierre · EURUSD · +8,60 €", "···4152 · Rebote"),
        (.stop, "Stop movido a breakeven · US500", "···4152 · Impulso"),
        (.signal, "Señal nueva · AUDUSD · confianza 0,66", "Rebote"),
        (.reject, "Rechazada por el bróker · USDJPY", "···2511 · Tendencia"),
        (.close, "Cierre · XAUUSD · −9,40 €", "···4152 · Ruptura"),
        (.warn, "Hora del bróker desfasada 1,4 s", "···4152")
    ]

    init() {
        activity = (0..<24).map { Double(2 + Int(5 * abs(sin(Double($0) * 1.3)))) }
        latency = [380, 410, 395, 430, 412, 405, 398, 420, 412]
        events = [
            Event(time: "10:41:58", kind: .open, title: "Apertura · Venta US500 0,20", detail: "···4152 · Impulso"),
            Event(time: "10:41:07", kind: .reject, title: "Rechazada por el bróker · EURUSD", detail: "···2511 · Rebote"),
            Event(time: "10:30:00", kind: .close, title: "Cierre · GBPUSD · +4,10 €", detail: "···2511 · Tendencia"),
            Event(time: "10:12:31", kind: .warn, title: "Hora del bróker desfasada 1,4 s", detail: "···4152")
        ]
    }

    func start(labels: [String]) {
        stop()
        var seeded: [String: Double] = [:]
        for l in labels { seeded[l] = jitter[l] ?? 0 }
        jitter = seeded
        timer = Timer.scheduledTimer(withTimeInterval: 2.3, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        lastUpdate = Date()
        var next: [String: Double] = jitter
        for k in jitter.keys { next[k] = (jitter[k] ?? 0) + Double.random(in: -1.6...1.4) }
        jitter = next
        activity = Array(activity.dropFirst()) + [Double(1 + Int.random(in: 0...6))]
        latency = Array(latency.dropFirst()) + [Double(380 + Int.random(in: 0...90))]
        if Double.random(in: 0...1) < 0.7, let p = pool.randomElement() {
            events.insert(Event(time: clock.string(from: Date()), kind: p.0, title: p.1, detail: p.2), at: 0)
            if events.count > 9 { events.removeLast() }
            if p.0 == .signal { signals += 1 }
            if p.0 == .close { executed += 1 }
            if p.0 == .reject { rejected += 1 }
        }
    }

    func movement(_ label: String) -> Double { jitter[label] ?? 0 }
}

struct EnVivoView: View {
    @EnvironmentObject var accounts: AccountStore
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
            ResponsiveRow {
                countersCard.frame(maxWidth: .infinity)
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
                    VStack(alignment: .leading, spacing: 1) {
                        Text(e.title).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                        Text(e.detail).font(.system(size: 12)).foregroundStyle(Palette.ink2)
                    }
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

    private var countersCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Heading("Hoy", info: "Cuántas señales llegan y cuántas acaban en operación")
            HStack(spacing: 18) {
                counter("Señales", feed.signals, Palette.ink)
                counter("Ejecutadas", feed.executed, Palette.posText)
                counter("Rechazadas", feed.rejected, Palette.negText)
            }
        }
        .card(Layout.card)
    }

    private func counter(_ label: String, _ value: Int, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2)
            Text("\(value)").font(.system(size: 26, weight: .bold)).foregroundStyle(color).monospacedDigit()
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
