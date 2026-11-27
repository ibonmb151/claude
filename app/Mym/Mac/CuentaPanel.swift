#if os(macOS)
import SwiftUI

// Cuenta: el estado de cada cuenta. Saldo, margen, reglas de la firma, conciliación y datos.
// Lo que pasa ahora (trades abiertos, flotante, riesgo) está en En vivo.
// Todo el rendimiento (resultado, curva, caída) está en Resultados.

struct CuentasView: View {
    @EnvironmentObject var accounts: AccountStore

    var body: some View {
        let bundle: AccountBundle = accounts.bundle
        let scoped: [AccountMetrics] = bundle.accounts.filter { bundle.inScope($0.cuenta, accounts.scope) }
        ScreenScroll {
            CuentaHeader(bundle: bundle, accounts: scoped)
            CuentaEstado(accounts: scoped)
            ReglasView()
            CuentaSistema(bundle: bundle)
        }
    }
}

// MARK: - Cabecera: qué cuenta se mira, balance y equity

private let utcTime: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    f.timeZone = TimeZone(identifier: "UTC")
    return f
}()

struct CuentaHeader: View {
    @EnvironmentObject var accounts: AccountStore
    let bundle: AccountBundle
    let accounts_: [AccountMetrics]

    init(bundle: AccountBundle, accounts: [AccountMetrics]) {
        self.bundle = bundle
        self.accounts_ = accounts
    }

    private func sum(_ f: (AccountMetrics) -> Double?) -> Double? {
        let v: [Double] = accounts_.compactMap(f)
        return v.isEmpty ? nil : v.reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                chip("Ambas cuentas", .all)
                ForEach(bundle.accounts) { a in
                    chip(maskedAccount(a.cuenta), .one(a.cuenta))
                }
                Spacer()
                Text("Actualizado \(utcTime.string(from: bundle.loadedAt)) UTC · cada 5 min")
                    .font(.system(size: 12)).foregroundStyle(Palette.ink2)
            }
            HStack(alignment: .bottom, spacing: 40) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Balance").font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.ink2)
                    Text(Fmt.opt(sum { $0.balance }) { Fmt.eur2($0) })
                        .font(.system(size: 36, weight: .bold)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Equity").font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.ink2)
                    Text(Fmt.opt(sum { $0.equity }) { Fmt.eur2($0) })
                        .font(.system(size: 24, weight: .bold)).foregroundStyle(Palette.ink2).monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
                }
                Spacer()
            }
        }
        .card(Layout.card)
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

// MARK: - Ocho cifras del estado de la cuenta

struct CuentaEstado: View {
    let accounts: [AccountMetrics]

    private func sum(_ f: (AccountMetrics) -> Double?) -> Double? {
        let v: [Double] = accounts.compactMap(f)
        return v.isEmpty ? nil : v.reduce(0, +)
    }

    var body: some View {
        let level: Double? = accounts.count == 1 ? accounts.first?.marginLevelPct : nil
        let drawdown: Double? = accounts.compactMap { $0.maxDdHistorico }.min()
        VStack(spacing: Layout.gap) {
            HStack(spacing: Layout.gap) {
                cell("Margen usado", Fmt.opt(sum { $0.marginUsed }) { Fmt.eur($0) }, Palette.ink)
                cell("Margen libre", Fmt.opt(sum { $0.marginFree }) { Fmt.eur($0) }, Palette.ink)
                cell("Nivel de margen", Fmt.opt(level) { Fmt.pct($0, 0) }, Palette.ink)
                cell("Operaciones cerradas", Fmt.opt(sum { $0.nTradesCerradosTotal.map { Double($0) } }) { Fmt.comma($0, 0) }, Palette.ink)
            }
            HStack(spacing: Layout.gap) {
                cell("Depósito inicial", Fmt.opt(sum { $0.depositoInicial }) { Fmt.eur($0) }, Palette.ink)
                cell("Resultado total", Fmt.opt(sum { $0.pnlRealizadoTotal }) { Fmt.signedEur2($0) }, resultColor(sum { $0.pnlRealizadoTotal }))
                cell("Caída histórica", Fmt.opt(drawdown) { Fmt.signedPct($0, 2) }, drawdown == nil ? Palette.ink2 : Palette.negText)
                cell("Diferencia con el bróker", Fmt.opt(sum { $0.gapConciliacion }) { abs($0) < 0.005 ? "cuadra" : Fmt.signedEur2($0) }, Palette.ink)
            }
        }
    }

    private func cell(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2).lineLimit(1)
            Text(value).font(.system(size: 20, weight: .bold)).foregroundStyle(color).monospacedDigit().lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(Layout.cardSmall)
    }
}

// MARK: - Módulos por cuenta (se ven en Estrategias)

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
        .card(Layout.card)
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

// MARK: - Conciliación y datos

struct CuentaSistema: View {
    let bundle: AccountBundle

    var body: some View {
        ResponsiveRow {
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
            .card(Layout.card)
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
            .card(Layout.card)
            .frame(maxWidth: .infinity)
        }
    }
}
#endif
