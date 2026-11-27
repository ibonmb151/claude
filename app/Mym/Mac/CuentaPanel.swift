#if os(macOS)
import SwiftUI

// Panel de cuenta. Solo lo que sirve para decidir algo al momento:
// cabecera, 6 cifras y cuatro pestañas (Ahora, Rendimiento, Módulos, Sistema) más las reglas de la firma.
// El análisis largo (mapas de calor, correlaciones, histogramas) va al Informe semanal, no aquí.

enum CuentaTab: String, CaseIterable, Identifiable {
    case ahora = "Ahora"
    case rendimiento = "Rendimiento"
    case modulos = "Módulos"
    case reglas = "Reglas"
    case sistema = "Sistema"

    var id: String { rawValue }
}

struct CuentasView: View {
    @EnvironmentObject var accounts: AccountStore
    @State private var tab: CuentaTab = .ahora

    var body: some View {
        let bundle: AccountBundle = accounts.bundle
        let summary: AccountSummary = bundle.summary(for: accounts.scope)
        ScreenScroll {
            CuentaHeader(bundle: bundle, summary: summary)
            CuentaKPIs(summary: summary, bundle: bundle)
            Picker("", selection: $tab) {
                ForEach(CuentaTab.allCases) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 560)
            content(bundle, summary)
        }
    }

    @ViewBuilder
    private func content(_ bundle: AccountBundle, _ summary: AccountSummary) -> some View {
        switch tab {
        case .ahora: CuentaAhora(bundle: bundle, summary: summary, scope: accounts.scope)
        case .rendimiento: CuentaRendimiento(bundle: bundle, scope: accounts.scope, summary: summary)
        case .modulos: CuentaModulos(bundle: bundle, scope: accounts.scope)
        case .reglas: ReglasView()
        case .sistema: CuentaSistema(bundle: bundle, summary: summary)
        }
    }
}

// MARK: - Cabecera

private let utcTime: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    f.timeZone = TimeZone(identifier: "UTC")
    return f
}()

struct CuentaHeader: View {
    @EnvironmentObject var accounts: AccountStore
    let bundle: AccountBundle
    let summary: AccountSummary

    private var stateTone: Tone {
        switch summary.state {
        case .active: return .good
        case .demo: return .info
        case .error: return .bad
        }
    }

    private var urgent: Int { summary.alerts.filter { $0.level == .urgent }.count }
    private var attention: Int { summary.alerts.filter { $0.level == .attention }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Pill(text: summary.state.label, tone: stateTone)
                chip("Ambas cuentas", .all)
                ForEach(bundle.accounts) { a in
                    chip(maskedAccount(a.cuenta), .one(a.cuenta))
                }
                Spacer()
                Text("Actualizado \(utcTime.string(from: bundle.loadedAt)) UTC · cada 5 min")
                    .font(.system(size: 12)).foregroundStyle(Palette.ink2)
            }
            HStack(alignment: .top, spacing: 0) {
                stat("Balance", Fmt.opt(summary.balance) { Fmt.eur2($0) }, size: 28,
                     sub: dayText, subColor: resultColor(summary.dayChange))
                separator
                stat("Flotante", Fmt.opt(summary.floating) { Fmt.signedEur2($0) }, size: 22,
                     color: resultColor(summary.floating), sub: "sin cerrar", subColor: Palette.ink2)
                separator
                stat("Trades abiertos", "\(summary.openCount)", size: 22, sub: "ahora", subColor: Palette.ink2)
                separator
                alertsStat
                Spacer(minLength: 0)
            }
        }
        .card(16)
    }

    private var dayText: String {
        guard let d = summary.dayChange else { return "n.d. hoy" }
        let pct: String = summary.dayChangePct.map { " · " + Fmt.signedPct($0, 2) } ?? ""
        return Fmt.signedEur2(d) + pct + " hoy"
    }

    private var separator: some View {
        Rectangle().fill(Palette.line).frame(width: 1, height: 52).padding(.horizontal, 22)
    }

    private func stat(_ label: String, _ value: String, size: CGFloat, color: Color = Palette.ink, sub: String, subColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2)
            Text(value).font(.system(size: size, weight: .bold)).foregroundStyle(color).monospacedDigit().lineLimit(1)
            Text(sub).font(.system(size: 12, weight: .semibold)).foregroundStyle(subColor).monospacedDigit().lineLimit(1)
        }
    }

    private var alertsStat: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Alertas").font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2)
            HStack(spacing: 8) {
                Text("\(summary.alerts.count)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(urgent > 0 ? Palette.negText : (attention > 0 ? Palette.warnText : Palette.ink))
                    .monospacedDigit()
                if urgent > 0 { Pill(text: "\(urgent) urgente", tone: .bad) }
                if attention > 0 { Pill(text: "\(attention) atención", tone: .warn) }
            }
            Text(summary.alerts.isEmpty ? "todo en orden" : "abiertas").font(.system(size: 12)).foregroundStyle(Palette.ink2)
        }
    }

    private func chip(_ title: String, _ scope: AccountScope) -> some View {
        let on: Bool = accounts.scope == scope
        return Button {
            accounts.scope = scope
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(on ? Color.white : Palette.ink)
                .padding(.horizontal, 12)
                .frame(height: 28)
                .background(on ? Palette.graphiteDark : Palette.neutralBg, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Seis cifras

struct CuentaKPIs: View {
    let summary: AccountSummary
    let bundle: AccountBundle

    private var last: DailyMetrics? { bundle.daily.last }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                kpi("Resultado de hoy", Fmt.opt(summary.realizedToday) { Fmt.signedEur2($0) }, resultColor(summary.realizedToday), "realizado")
                kpi("Flotante", Fmt.opt(summary.floating) { Fmt.signedEur2($0) }, resultColor(summary.floating), "sin cerrar")
                kpi("Acierto · 30 d", Fmt.opt(summary.winRate) { Fmt.pct($0, 1) }, tone(summary.winRate.map { $0 > 50 }), "de las operaciones cerradas")
                kpi("Profit factor · 30 d", Fmt.opt(summary.profitFactor) { Fmt.comma($0, 2) }, tone(summary.profitFactor.map { $0 > 1.3 }), "media por módulo")
                kpi("Caída máxima", Fmt.opt(summary.maxDrawdown) { Fmt.signedPct($0, 2) }, summary.maxDrawdown == nil ? Palette.ink2 : Palette.negText, "histórica")
                kpi("Riesgo usado", Fmt.opt(summary.riskUsed) { Fmt.pct($0, 1) }, summary.riskUsed.map { $0 < 3 ? Palette.posText : Palette.warnText } ?? Palette.ink2, "de un máximo de 5 %")
            }
            if let d = last {
                Text(context(d)).font(.system(size: 12)).foregroundStyle(Palette.ink2)
            }
        }
    }

    private func context(_ d: DailyMetrics) -> String {
        var parts: [String] = []
        if let v = d.vix { parts.append("VIX \(Fmt.comma(v, 1))") }
        if let r = d.regimen { parts.append("régimen \(r)") }
        if let o = d.oportunidades { parts.append("\(o) oportunidades") }
        return parts.joined(separator: " · ")
    }

    private func tone(_ good: Bool?) -> Color {
        guard let g = good else { return Palette.ink2 }
        return g ? Palette.posText : Palette.ink
    }

    private func kpi(_ title: String, _ value: String, _ color: Color, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2).lineLimit(1)
            Text(value).font(.system(size: 20, weight: .bold)).foregroundStyle(color).monospacedDigit().lineLimit(1).minimumScaleFactor(0.8)
            Text(caption).font(.system(size: 11)).foregroundStyle(Palette.ink2).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(12)
    }
}

// MARK: - Pestaña · Ahora

struct CuentaAhora: View {
    let bundle: AccountBundle
    let summary: AccountSummary
    let scope: AccountScope

    private var open: [TradeRecord] {
        bundle.trades.filter { $0.isOpen && bundle.inScope($0.cuenta, scope) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(open.filter { $0.isUnprotected }) { t in
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Palette.neg)
                    Text("Sin stop · \(t.par ?? "?") en \(maskedAccount(t.cuenta ?? "????")) · \(t.label)")
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(Palette.negText)
                    Spacer()
                }
                .padding(12)
                .background(Palette.negBg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            VStack(alignment: .leading, spacing: 8) {
                Heading("Trades abiertos", info: "Solo lo que está abierto ahora. El resultado es flotante: todavía no está realizado")
                if open.isEmpty {
                    Text("No hay trades abiertos").font(.system(size: 13)).foregroundStyle(Palette.ink2).padding(.vertical, 8)
                } else {
                    header
                    ForEach(open) { t in
                        row(t)
                        Divider()
                    }
                }
            }
            .card(16)
            HStack(alignment: .top, spacing: 14) {
                meter("Riesgo usado", info: "Suma del riesgo de las posiciones abiertas. Límite: 5 %",
                      text: Fmt.opt(summary.riskUsed) { Fmt.comma($0, 1) + " de 5 %" },
                      fraction: (summary.riskUsed ?? 0) / 5, color: (summary.riskUsed ?? 0) < 3 ? Palette.pos : Palette.warn, warn: 0.6)
                meter("Margen libre", info: "Margen que queda sin usar",
                      text: Fmt.opt(summary.freeMarginPct) { Fmt.pct($0, 0) },
                      fraction: (summary.freeMarginPct ?? 0) / 100, color: Palette.info, warn: nil)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            col("Par", 84); col("Lado", 74); col("Cuenta", 64)
            col("Entrada", 84, .trailing); col("Stop", 84, .trailing); col("Objetivo", 84, .trailing); col("Flotante", 84, .trailing)
            col("Etiqueta", nil)
        }
        .padding(.top, 2)
    }

    private func col(_ t: String, _ w: CGFloat?, _ a: Alignment = .leading) -> some View {
        let maxW: CGFloat? = (w == nil) ? CGFloat.infinity : nil
        return Text(t).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2)
            .frame(width: w, alignment: a)
            .frame(maxWidth: maxW, alignment: a)
    }

    private func row(_ t: TradeRecord) -> some View {
        HStack(spacing: 8) {
            Text(t.par ?? "?").font(.system(size: 13, weight: .bold, design: .monospaced)).frame(width: 84, alignment: .leading)
            Pill(text: t.lado == "venta" ? "Venta" : "Compra", tone: t.lado == "venta" ? .bad : .good).frame(width: 74, alignment: .leading)
            Text(maskedAccount(t.cuenta ?? "????")).font(.system(size: 12, design: .monospaced)).foregroundStyle(Palette.ink2).frame(width: 64, alignment: .leading)
            Text(Fmt.opt(t.entradaPx) { price($0) }).font(.system(size: 13)).monospacedDigit().frame(width: 84, alignment: .trailing)
            Text(t.isUnprotected ? "sin stop" : Fmt.opt(t.sl) { price($0) })
                .font(.system(size: 13, weight: t.isUnprotected ? .bold : .regular))
                .foregroundStyle(t.isUnprotected ? Palette.negText : Palette.ink).monospacedDigit().frame(width: 84, alignment: .trailing)
            Text(Fmt.opt(t.tp) { price($0) }).font(.system(size: 13)).monospacedDigit().frame(width: 84, alignment: .trailing)
            Text(Fmt.opt(t.pnl) { Fmt.signedEur2($0) }).font(.system(size: 13, weight: .bold)).foregroundStyle(resultColor(t.pnl))
                .monospacedDigit().frame(width: 84, alignment: .trailing)
            Text(t.label).font(.system(size: 12, design: .monospaced)).foregroundStyle(Palette.ink2).lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 3)
    }

    private func price(_ v: Double) -> String {
        v >= 100 ? Fmt.comma(v, 2) : Fmt.comma(v, 5)
    }

    private func meter(_ title: String, info: String, text: String, fraction: Double, color: Color, warn: Double?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Heading(title, info: info) {
                Text(text).font(.system(size: 15, weight: .bold)).monospacedDigit()
            }
            ProgressTrack(fraction: fraction, color: color, warnAt: warn, height: 12)
        }
        .card(16)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Pestaña · Rendimiento

struct CuentaRendimiento: View {
    let bundle: AccountBundle
    let scope: AccountScope
    let summary: AccountSummary

    private var mods: [ModuleMetrics] { bundle.modules.filter { bundle.inScope($0.cuenta, scope) } }

    var body: some View {
        let equity: [Double] = bundle.equitySeries(scope)
        let dd: [Double] = AccountBundle.drawdown(of: equity)
        let daily: [Double] = Array(bundle.dailySeries(scope).suffix(30))
        VStack(alignment: .leading, spacing: 14) {
            Text("Realizado: solo operaciones cerradas").font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2)
            VStack(alignment: .leading, spacing: 8) {
                Heading("Curva de equity", info: "Resultado realizado de los últimos 30 días. No incluye lo flotante")
                if equity.count > 1 {
                    CurveChart(values: equity, color: Palette.info, yText: { Fmt.comma($0 / 1000, 1) + "k" },
                               leftLabel: "hace 30 días", rightLabel: "hoy", height: 220)
                } else {
                    empty
                }
            }
            .card(16)
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Heading("Caída desde el máximo", info: "Cuánto estás por debajo del mejor punto de la curva")
                    if dd.count > 1 {
                        CurveChart(values: dd, color: Palette.neg, baseline: 0, yText: { Fmt.comma($0, 1) + " %" }, height: 190)
                    } else { empty }
                }
                .card(16)
                .frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 8) {
                    Heading("Resultado por día", info: "Verde gana, rojo pierde")
                    if !daily.isEmpty {
                        DailyBarsChart(values: daily, yText: { Fmt.comma($0, 0) }, height: 190)
                    } else { empty }
                }
                .card(16)
                .frame(maxWidth: .infinity)
            }
            VStack(alignment: .leading, spacing: 4) {
                Heading("Resumen · 30 días", info: "Calculado solo con operaciones cerradas")
                LabeledValue(label: "Acierto", value: Fmt.opt(summary.winRate) { Fmt.pct($0, 1) })
                LabeledValue(label: "Profit factor", value: Fmt.opt(summary.profitFactor) { Fmt.comma($0, 2) })
                LabeledValue(label: "Caída máxima", value: Fmt.opt(summary.maxDrawdown) { Fmt.signedPct($0, 2) })
                LabeledValue(label: "R:R medio", value: Fmt.opt(weighted { $0.avgRr }) { Fmt.comma($0, 2) })
                LabeledValue(label: "Duración media", value: Fmt.opt(weighted { $0.avgDuracionMin }) { duration($0) })
                LabeledValue(label: "Costes", value: Fmt.opt(sum { $0.costes }) { Fmt.eur2(-$0) })
            }
            .card(16)
        }
    }

    private var empty: some View {
        Text("n.d.").font(.system(size: 13)).foregroundStyle(Palette.ink2).frame(maxWidth: .infinity, minHeight: 80)
    }

    private func weighted(_ f: (ModuleMetrics) -> Double?) -> Double? {
        var num: Double = 0
        var den: Double = 0
        for m in mods {
            if let v = f(m), let n = m.nTrades, n > 0 {
                num += v * Double(n)
                den += Double(n)
            }
        }
        return den > 0 ? num / den : nil
    }

    private func sum(_ f: (ModuleMetrics) -> Double?) -> Double? {
        let v: [Double] = mods.compactMap(f)
        return v.isEmpty ? nil : v.reduce(0, +)
    }

    private func duration(_ minutes: Double) -> String {
        let h: Int = Int(minutes) / 60
        let m: Int = Int(minutes) % 60
        return h > 0 ? "\(h) h \(m) min" : "\(m) min"
    }
}

// MARK: - Pestaña · Módulos

struct CuentaModulos: View {
    let bundle: AccountBundle
    let scope: AccountScope

    private var mods: [ModuleMetrics] { bundle.modules.filter { bundle.inScope($0.cuenta, scope) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Heading("Módulos", info: "Cómo va cada módulo en cada cuenta. «Vigilar» = pierde ventaja: su rendimiento reciente está al menos un 10 % por debajo de su media")
            HStack(spacing: 8) {
                head("Módulo", nil); head("Cuenta", 70); head("Trades", 60, .trailing); head("Acierto", 70, .trailing)
                head("PF", 56, .trailing); head("Resultado", 92, .trailing); head("Caída", 70, .trailing); head("Estado", 84)
            }
            ForEach(mods) { m in
                HStack(spacing: 8) {
                    Text(m.modulo).font(.system(size: 14, weight: .semibold)).frame(maxWidth: .infinity, alignment: .leading)
                    Text(maskedAccount(m.cuenta)).font(.system(size: 12, design: .monospaced)).foregroundStyle(Palette.ink2).frame(width: 70, alignment: .leading)
                    Text(Fmt.opt(m.nTrades.map { Double($0) }) { Fmt.comma($0, 0) }).monospacedDigit().frame(width: 60, alignment: .trailing)
                    Text(Fmt.opt(m.wr) { Fmt.pct($0, 1) }).monospacedDigit().frame(width: 70, alignment: .trailing)
                    Text(Fmt.opt(m.profitFactor) { Fmt.comma($0, 2) }).monospacedDigit().frame(width: 56, alignment: .trailing)
                    Text(Fmt.opt(m.pnlRealizado) { Fmt.signedEur2($0) }).font(.system(size: 13, weight: .bold)).foregroundStyle(resultColor(m.pnlRealizado))
                        .monospacedDigit().frame(width: 92, alignment: .trailing)
                    Text(Fmt.opt(m.maxDd) { Fmt.signedPct($0, 1) }).foregroundStyle(Palette.negText).monospacedDigit().frame(width: 70, alignment: .trailing)
                    state(m).frame(width: 84, alignment: .leading)
                }
                .font(.system(size: 13))
                .padding(.vertical, 4)
                Divider()
            }
            if mods.isEmpty {
                Text("n.d.").font(.system(size: 13)).foregroundStyle(Palette.ink2).padding(.vertical, 8)
            }
        }
        .card(16)
    }

    private func head(_ t: String, _ w: CGFloat?, _ a: Alignment = .leading) -> some View {
        let maxW: CGFloat? = (w == nil) ? CGFloat.infinity : nil
        return Text(t).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2)
            .frame(width: w, alignment: a)
            .frame(maxWidth: maxW, alignment: a)
    }

    @ViewBuilder
    private func state(_ m: ModuleMetrics) -> some View {
        if let d = m.decayPct {
            if d <= -10 { Pill(text: "Vigilar", tone: .warn) } else { Pill(text: "Activo", tone: .good) }
        } else {
            Pill(text: "n.d.", tone: .neutral)
        }
    }
}

// MARK: - Pestaña · Sistema

struct CuentaSistema: View {
    let bundle: AccountBundle
    let summary: AccountSummary

    private var headline: String {
        switch summary.state {
        case .error: return "Hay un problema con los datos"
        case .demo: return "Mostrando datos de demostración"
        case .active: return summary.alerts.isEmpty ? "Todo en orden" : "\(summary.alerts.count) cosas por revisar"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                StatusDot(color: summary.state == .error ? Palette.neg : (summary.alerts.isEmpty ? Palette.pos : Palette.warn), size: 12)
                Text(headline).font(.system(size: 17, weight: .semibold))
                Spacer()
            }
            .card(16)
            if !summary.alerts.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Heading("Alertas", info: "Problemas que siguen abiertos")
                    ForEach(summary.alerts) { a in
                        HStack(spacing: 10) {
                            StatusDot(color: a.level == .urgent ? Palette.neg : Palette.warn, size: 10)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(a.title).font(.system(size: 14, weight: .semibold))
                                Text(a.detail).font(.system(size: 12)).foregroundStyle(Palette.ink2)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        Divider()
                    }
                }
                .card(16)
            }
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Heading("Conciliación", info: "Saldo según el bróker frente al del sistema")
                    ForEach(bundle.accounts) { a in
                        HStack {
                            Text(maskedAccount(a.cuenta)).font(.system(size: 13, design: .monospaced))
                            Spacer()
                            Text(Fmt.opt(a.gapConciliacion) { abs($0) < 0.005 ? "cuadra" : Fmt.signedEur2($0) })
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle((a.gapConciliacion ?? 0) == 0 ? Palette.posText : Palette.warnText)
                        }
                        .padding(.vertical, 3)
                    }
                }
                .card(16)
                .frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 6) {
                    Heading("Datos", info: "Ficheros de los que sale todo lo que ves")
                    ForEach(bundle.files) { f in
                        HStack {
                            Text(f.name).font(.system(size: 12, design: .monospaced))
                            Spacer()
                            Pill(text: f.state == .ok ? "Al día" : (f.state == .missing ? "Falta" : "No se lee"),
                                 tone: f.state == .ok ? .good : .bad)
                        }
                        .padding(.vertical, 2)
                    }
                    if bundle.files.isEmpty {
                        Text("Sin ficheros").font(.system(size: 13)).foregroundStyle(Palette.ink2)
                    }
                }
                .card(16)
                .frame(maxWidth: .infinity)
            }
        }
    }
}
#endif
