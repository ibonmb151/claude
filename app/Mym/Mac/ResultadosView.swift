#if os(macOS)
import SwiftUI

// Resultados: cuánto se ha ganado o perdido y cómo. Con los ficheros de hoy solo hay resultado por día,
// así que los periodos son Semana y Mes. «Hoy» por horas y «Año» necesitan ficheros por hora y por mes.

struct ResultadosView: View {
    enum Period: String, CaseIterable, Identifiable {
        case semana = "Semana"
        case mes = "Mes"

        var id: String { rawValue }
        var days: Int { self == .semana ? 7 : 30 }
    }

    @EnvironmentObject var accounts: AccountStore
    @State private var period: Period = .mes

    private var bundle: AccountBundle { accounts.bundle }

    var body: some View {
        let daily: [Double] = Array(bundle.dailySeries(accounts.scope).suffix(period.days))
        let total: Double? = daily.isEmpty ? nil : daily.reduce(0, +)
        let equity: [Double] = Array(bundle.equitySeries(accounts.scope).suffix(period.days + 1))
        let summary: AccountSummary = bundle.summary(for: accounts.scope)
        ScreenScroll {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(period == .semana ? "Esta semana" : "Últimos 30 días")
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(Palette.ink2)
                    Text(Fmt.opt(total) { Fmt.signedEur2($0) })
                        .font(.system(size: 44, weight: .bold)).foregroundStyle(resultColor(total)).monospacedDigit()
                    Text("Resultado realizado. No incluye lo flotante.").font(.system(size: 13)).foregroundStyle(Palette.ink2)
                }
                Spacer()
                Picker("", selection: $period) {
                    ForEach(Period.allCases) { p in Text(p.rawValue).tag(p) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 200)
            }
            .card(Layout.card)

            ResponsiveRow(breakpoint: 980) {
                stat("Acierto", Fmt.opt(summary.winRate) { Fmt.pct($0, 1) })
                stat("Profit factor", Fmt.opt(summary.profitFactor) { Fmt.comma($0, 2) })
                stat("Mejor día", Fmt.opt(daily.max()) { Fmt.signedEur2($0) }, Palette.posText)
                stat("Peor día", Fmt.opt(daily.min()) { Fmt.signedEur2($0) }, Palette.negText)
                stat("Días con ganancia", daily.isEmpty ? "n.d." : "\(daily.filter { $0 > 0 }.count) de \(daily.count)")
            }

            ResponsiveRow(breakpoint: 1080) {
                VStack(alignment: .leading, spacing: 8) {
                    Heading("Resultado por día", info: "Verde gana, rojo pierde")
                    if daily.isEmpty {
                        Text("n.d.").font(.system(size: 13)).foregroundStyle(Palette.ink2).frame(maxWidth: .infinity, minHeight: 80)
                    } else {
                        DailyBarsChart(values: daily, height: 220, yText: { Fmt.comma($0, 0) })
                    }
                }
                .card(Layout.card)
                .frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 8) {
                    Heading("Curva de equity", info: "Resultado realizado acumulado")
                    if equity.count > 1 {
                        CurveChart(values: equity, color: Palette.info, yText: { Fmt.comma($0 / 1000, 1) + "k" },
                                   leftLabel: "", rightLabel: "hoy", height: 220)
                    } else {
                        Text("n.d.").font(.system(size: 13)).foregroundStyle(Palette.ink2).frame(maxWidth: .infinity, minHeight: 80)
                    }
                }
                .card(Layout.card)
                .frame(maxWidth: .infinity)
            }

            ResponsiveRow(breakpoint: 1080) {
                modulesCard.frame(maxWidth: .infinity)
                accountsCard.frame(maxWidth: .infinity)
            }
        }
    }

    private func stat(_ title: String, _ value: String, _ color: Color = Palette.ink) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2)
            Text(value).font(.system(size: 22, weight: .bold)).foregroundStyle(color).monospacedDigit().lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(Layout.cardSmall)
    }

    private var modulesCard: some View {
        let mods: [ModuleMetrics] = bundle.modules.filter { bundle.inScope($0.cuenta, accounts.scope) }
        let mx: Double = max(mods.compactMap { $0.pnlRealizado }.map { abs($0) }.max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 10) {
            Heading("Por módulo", info: "Cuánto ha aportado cada módulo")
            if mods.isEmpty {
                Text("n.d.").font(.system(size: 13)).foregroundStyle(Palette.ink2)
            }
            ForEach(mods) { m in
                HStack(spacing: 10) {
                    Text(m.modulo).font(.system(size: 13, weight: .semibold)).frame(width: 84, alignment: .leading)
                    ProgressTrack(fraction: abs(m.pnlRealizado ?? 0) / mx, color: (m.pnlRealizado ?? 0) >= 0 ? Palette.pos : Palette.neg, height: 12)
                    Text(Fmt.opt(m.pnlRealizado) { Fmt.signedEur2($0) })
                        .font(.system(size: 13, weight: .bold)).foregroundStyle(resultColor(m.pnlRealizado)).monospacedDigit()
                        .frame(width: 96, alignment: .trailing)
                }
            }
        }
        .card(Layout.card)
    }

    private var accountsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Heading("Por cuenta", info: "Resultado realizado de hoy en cada cuenta")
            ForEach(bundle.accounts) { a in
                HStack {
                    Text(maskedAccount(a.cuenta)).font(.system(size: 13, design: .monospaced))
                    Spacer()
                    Text(Fmt.opt(a.pnlRealizadoHoy) { Fmt.signedEur2($0) })
                        .font(.system(size: 14, weight: .bold)).foregroundStyle(resultColor(a.pnlRealizadoHoy)).monospacedDigit()
                }
                .padding(.vertical, 3)
                Divider()
            }
        }
        .card(Layout.card)
    }
}
#endif
