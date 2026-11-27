import WidgetKit
import SwiftUI

// Widgets de cuentas: balance, actividad en vivo, avisos y resultados.
// Se refrescan unas pocas veces por hora: sirven para ver, no para operar.
// No usan Canvas (los widgets no lo dibujan bien): solo las gráficas simples de Sparkline.

struct AccountEntry: TimelineEntry {
    let date: Date
    let bundle: AccountBundle
}

struct AccountProvider: TimelineProvider {
    func placeholder(in context: Context) -> AccountEntry {
        AccountEntry(date: Date(), bundle: .demo)
    }

    func getSnapshot(in context: Context, completion: @escaping (AccountEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AccountEntry>) -> Void) {
        let now = Date()
        let next: Date = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now
        completion(Timeline(entries: [AccountEntry(date: now, bundle: .demo)], policy: .after(next)))
    }
}

private func dayLine(_ s: AccountSummary) -> String {
    guard let d = s.dayChange else { return "n.d. hoy" }
    let pct: String = s.dayChangePct.map { " · " + Fmt.signedPct($0, 2) } ?? ""
    return Fmt.signedEur2(d) + pct
}

// MARK: - Cuentas

struct CuentasWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: AccountEntry

    var body: some View {
        let s: AccountSummary = entry.bundle.summary(for: .all)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Cuentas").font(.system(size: 12, weight: .bold)).foregroundStyle(Palette.ink2)
                Spacer()
                Pill(text: s.state.label, tone: s.state == .error ? .bad : (s.state == .demo ? .info : .good))
            }
            Text(Fmt.opt(s.balance) { Fmt.eur($0) })
                .font(.system(size: family == .systemSmall ? 22 : 28, weight: .bold))
                .foregroundStyle(Palette.ink).monospacedDigit().minimumScaleFactor(0.7).lineLimit(1)
            Text(dayLine(s) + " hoy")
                .font(.system(size: 12, weight: .semibold)).foregroundStyle(resultColor(s.dayChange)).monospacedDigit().lineLimit(1)
            if family == .systemLarge {
                Sparkline(values: Array(entry.bundle.dailySeries(.all).suffix(30)).reduce(into: [Double]()) { acc, v in acc.append((acc.last ?? 0) + v) },
                          color: Palette.info, lineWidth: 2.4, fill: true)
                    .frame(height: 90)
                    .padding(.vertical, 4)
            }
            if family != .systemSmall {
                Spacer(minLength: 2)
                ForEach(entry.bundle.accounts) { a in
                    HStack {
                        Text(maskedAccount(a.cuenta)).font(.system(size: 12)).foregroundStyle(Palette.ink2)
                        Spacer()
                        Text(Fmt.opt(a.balance) { Fmt.eur($0) }).font(.system(size: 13, weight: .semibold)).monospacedDigit()
                        Text(Fmt.opt(a.pnlRealizadoHoy) { Fmt.signedEur2($0) })
                            .font(.system(size: 12, weight: .semibold)).foregroundStyle(resultColor(a.pnlRealizadoHoy)).monospacedDigit()
                            .frame(width: 84, alignment: .trailing)
                    }
                }
            }
        }
        .widgetBackground(Palette.card)
    }
}

struct CuentasWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MymCuentas", provider: AccountProvider()) { entry in
            CuentasWidgetView(entry: entry)
        }
        .configurationDisplayName("Cuentas")
        .description("Balance total y el de cada cuenta, con el resultado de hoy.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - En vivo

struct EnVivoWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: AccountEntry

    var body: some View {
        let s: AccountSummary = entry.bundle.summary(for: .all)
        let open: [TradeRecord] = entry.bundle.trades.filter { $0.isOpen }
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle().fill(Palette.pos).frame(width: 8, height: 8)
                Text("En vivo").font(.system(size: 12, weight: .bold)).foregroundStyle(Palette.ink2)
                Spacer()
                Text(s.openCount == 1 ? "1 abierta" : "\(s.openCount) abiertas").font(.system(size: 12)).foregroundStyle(Palette.ink2)
            }
            Text(Fmt.opt(s.floating) { Fmt.signedEur2($0) })
                .font(.system(size: family == .systemSmall ? 24 : 30, weight: .bold))
                .foregroundStyle(resultColor(s.floating)).monospacedDigit().minimumScaleFactor(0.7).lineLimit(1)
            Text("ahora mismo").font(.system(size: 12)).foregroundStyle(Palette.ink2)
            if family != .systemSmall {
                Spacer(minLength: 2)
                ForEach(open.prefix(family == .systemLarge ? 7 : 3)) { t in
                    HStack(spacing: 8) {
                        Text(t.par ?? "?").font(.system(size: 13, weight: .bold))
                        Pill(text: t.lado == "venta" ? "Venta" : "Compra", tone: t.lado == "venta" ? .bad : .good)
                        if t.isUnprotected { Pill(text: "Sin stop", tone: .bad) }
                        Spacer()
                        Text(Fmt.opt(t.pnl) { Fmt.signedEur2($0) })
                            .font(.system(size: 13, weight: .bold)).foregroundStyle(resultColor(t.pnl)).monospacedDigit()
                    }
                }
            }
        }
        .widgetBackground(Palette.card)
    }
}

struct EnVivoWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MymEnVivo", provider: AccountProvider()) { entry in
            EnVivoWidgetView(entry: entry)
        }
        .configurationDisplayName("En vivo")
        .description("Lo que ganas o pierdes ahora y las operaciones abiertas.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Avisos

struct AvisosWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: AccountEntry

    var body: some View {
        let s: AccountSummary = entry.bundle.summary(for: .all)
        let urgent: Int = s.alerts.filter { $0.level == .urgent }.count
        if family == .systemMedium {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Avisos").font(.system(size: 12, weight: .bold)).foregroundStyle(Palette.ink2)
                    Text("\(s.alerts.count)")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(urgent > 0 ? Palette.negText : (s.alerts.isEmpty ? Palette.posText : Palette.warnText))
                    Pill(text: urgent > 0 ? "\(urgent) urgente" : (s.alerts.isEmpty ? "Todo en orden" : "Atención"),
                         tone: urgent > 0 ? .bad : (s.alerts.isEmpty ? .good : .warn))
                }
                VStack(alignment: .leading, spacing: 8) {
                    if s.alerts.isEmpty {
                        Text("Sin avisos").font(.system(size: 13)).foregroundStyle(Palette.ink2)
                    }
                    ForEach(s.alerts.prefix(3)) { a in
                        HStack(alignment: .top, spacing: 6) {
                            Circle().fill(a.level == .urgent ? Palette.neg : Palette.warn).frame(width: 8, height: 8).padding(.top, 4)
                            Text(a.title).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink).lineLimit(2)
                        }
                    }
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)
            }
            .widgetBackground(Palette.card)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("Avisos").font(.system(size: 12, weight: .bold)).foregroundStyle(Palette.ink2)
                Text("\(s.alerts.count)")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(urgent > 0 ? Palette.negText : (s.alerts.isEmpty ? Palette.posText : Palette.warnText))
                if urgent > 0 {
                    Pill(text: "\(urgent) urgente", tone: .bad)
                } else {
                    Pill(text: s.alerts.isEmpty ? "Todo en orden" : "Atención", tone: s.alerts.isEmpty ? .good : .warn)
                }
                Spacer(minLength: 2)
                Text(s.alerts.first?.title ?? "Sin avisos")
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink).lineLimit(2)
            }
            .widgetBackground(Palette.card)
        }
    }
}

struct AvisosWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MymAvisos", provider: AccountProvider()) { entry in
            AvisosWidgetView(entry: entry)
        }
        .configurationDisplayName("Avisos")
        .description("Cuántos avisos hay y cuáles son.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Resultados

struct ResultadosWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: AccountEntry

    private static func runningTotal(_ values: [Double]) -> [Double] {
        var acc: Double = 0
        var out: [Double] = []
        for v in values {
            acc += v
            out.append(acc)
        }
        return out
    }

    /// Un cuadrado por día: verde si ganó, rojo si perdió. Sin Canvas, para que lo dibuje el widget.
    private func dayStrip(_ values: [Double]) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<values.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(values[i] >= 0 ? Palette.pos : Palette.neg)
                    .frame(height: 28)
            }
        }
    }

    var body: some View {
        let daily: [Double] = Array(entry.bundle.dailySeries(.all).suffix(30))
        let cumulative: [Double] = Self.runningTotal(daily)
        let total: Double? = cumulative.last
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(family == .systemSmall ? "30 días" : "Resultado · 30 días").font(.system(size: 12, weight: .bold)).foregroundStyle(Palette.ink2)
                Spacer()
            }
            Text(Fmt.opt(total) { Fmt.signedEur2($0) })
                .font(.system(size: family == .systemSmall ? 22 : 26, weight: .bold)).foregroundStyle(resultColor(total)).monospacedDigit().minimumScaleFactor(0.7).lineLimit(1)
            Spacer(minLength: 2)
            Sparkline(values: cumulative, color: Palette.info, lineWidth: 2.4, fill: true)
                .frame(height: family == .systemLarge ? 120 : 48)
            if family == .systemLarge {
                Text("Últimos 14 días").font(.system(size: 12, weight: .bold)).foregroundStyle(Palette.ink2).padding(.top, 6)
                dayStrip(Array(daily.suffix(14)))
            }
        }
        .widgetBackground(Palette.card)
    }
}

struct ResultadosWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MymResultados", provider: AccountProvider()) { entry in
            ResultadosWidgetView(entry: entry)
        }
        .configurationDisplayName("Resultados")
        .description("Resultado acumulado de los últimos 30 días.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#if os(iOS)
// MARK: - Pantalla de bloqueo: riesgo usado

struct RiesgoLockView: View {
    @Environment(\.widgetFamily) private var family
    let entry: AccountEntry

    var body: some View {
        let s: AccountSummary = entry.bundle.summary(for: .all)
        let risk: Double = s.riskUsed ?? 0
        switch family {
        case .accessoryCircular:
            Gauge(value: min(risk, 5), in: 0...5) {
                Text("Riesgo")
            } currentValueLabel: {
                Text(Fmt.comma(risk, 1))
            }
            .gaugeStyle(.accessoryCircular)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text("Mym · hoy").font(.system(size: 12, weight: .semibold))
                Text(Fmt.opt(s.dayChangePct) { Fmt.signedPct($0, 2) }).font(.system(size: 20, weight: .bold))
                Text("\(s.alerts.count) avisos · riesgo \(Fmt.comma(risk, 1)) %").font(.system(size: 12))
            }
        default:
            Text("Mym \(Fmt.opt(s.dayChangePct) { Fmt.signedPct($0, 2) }) · \(s.alerts.count) avisos")
        }
    }
}

struct RiesgoLockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MymRiesgoLock", provider: AccountProvider()) { entry in
            #if compiler(>=5.9)
            if #available(iOS 17.0, *) {
                RiesgoLockView(entry: entry).containerBackground(.clear, for: .widget)
            } else {
                RiesgoLockView(entry: entry)
            }
            #else
            RiesgoLockView(entry: entry)
            #endif
        }
        .configurationDisplayName("Riesgo y resultado")
        .description("Riesgo usado y resultado de hoy en la pantalla de bloqueo.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
#endif
