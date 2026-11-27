#if os(macOS)
import SwiftUI

/// Métodos: cómo rinde cada método y en qué robots trabaja.
/// Arriba, una tarjeta por método. Debajo, solo lo del elegido: su curva, cuatro cifras y dónde trabaja.
struct EstrategiasView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var accounts: AccountStore

    private var selected: Strategy {
        store.data.strategies.first { $0.id == store.selectedStrategyId } ?? store.data.strategies[0]
    }

    var body: some View {
        let d = store.data
        ScreenScroll {
            Heading("Métodos", info: "Cada método es una forma de operar. Un robot puede usar varios", size: 22)

            ResponsiveRow(breakpoint: 980) {
                ForEach(d.strategies.sorted { $0.return30d > $1.return30d }) { s in
                    methodCard(s)
                }
            }

            detailCard(selected, d)

            ResponsiveRow(breakpoint: 1080) {
                VStack(alignment: .leading, spacing: 8) {
                    Heading("Qué aporta cada método", info: "Lo que suma o resta cada uno cada semana. El número es el neto de la semana")
                    ContributionChart(weeks: ChartSamples.weeklyContribution, labels: ChartSamples.weekLabels,
                                      names: ChartSamples.strategyNames, colors: ChartSamples.strategyColors, height: 200)
                }
                .card(Layout.card)
                .frame(maxWidth: .infinity)

                CuentaModulos(bundle: accounts.bundle, scope: accounts.scope)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: Tarjeta de un método

    private func methodCard(_ s: Strategy) -> some View {
        let on: Bool = s.id == store.selectedStrategyId
        return Button {
            store.selectedStrategyId = s.id
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    IconTile(symbol: s.symbol, color: s.color, size: 32)
                    Text(s.id).font(.system(size: 17, weight: .bold)).foregroundStyle(Palette.ink)
                    Spacer()
                }
                Text(s.name).font(.system(size: 13)).foregroundStyle(Palette.ink2)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(Fmt.signedPct(s.return30d, 1))
                        .font(.system(size: 30, weight: .bold)).foregroundStyle(Palette.posText).monospacedDigit()
                    Text("este mes").font(.system(size: 13)).foregroundStyle(Palette.ink2)
                }
                Sparkline(values: s.series, color: Palette.pos, lineWidth: 2, fill: true)
                    .frame(height: 40)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(Layout.card, selected: on)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    // MARK: Detalle del elegido

    private func detailCard(_ s: Strategy, _ d: Snapshot) -> some View {
        VStack(alignment: .leading, spacing: Layout.gap) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(s.id).font(.system(size: 24, weight: .bold)).foregroundStyle(Palette.ink)
                    Text("En los últimos 30 días ha ganado \(Fmt.comma(s.return30d, 1)) %. Acierta \(Int(s.hitRate * 100)) de cada 100 operaciones.")
                        .font(.system(size: 15)).foregroundStyle(Palette.ink2)
                }
                Spacer()
                Button("Ajustar") { store.module = .ajustes }
                    .buttonStyle(MymButtonStyle(kind: .secondary))
            }

            LineAreaChart(values: s.series, color: Palette.pos)
                .frame(height: 200)

            HStack(spacing: Layout.gap) {
                stat("Operaciones", "\(s.trades)")
                stat("Aciertos", Fmt.pct(s.hitRate * 100))
                stat("Gana por cada 1 € que pierde", Fmt.comma(s.profitFactor, 2) + " €")
                stat("Peor caída", "−" + Fmt.comma(s.maxDrawdown, 1) + " %")
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Heading("Dónde trabaja", info: "Más peso, más dinero en juego. Bajarlo se aplica al momento; subirlo lo decide el asesor")
                ForEach(d.cells.filter { cell in cell.weights.contains { $0.strategyId == s.id } }) { cell in
                    weightRow(cell, s)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(Layout.card)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2).lineLimit(2)
            Text(value).font(.system(size: 22, weight: .bold)).foregroundStyle(Palette.ink).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func weightRow(_ cell: BotCell, _ s: Strategy) -> some View {
        let w = cell.weights.first { $0.strategyId == s.id }
        return HStack(spacing: 12) {
            Text(cell.id).font(.system(size: 14, weight: .semibold))
            Spacer()
            Pill(text: (w?.mode ?? .paused).label, tone: (w?.mode ?? .paused).tone)
            Text(Fmt.comma(w?.weight ?? 0, 2)).font(.system(size: 14, weight: .bold)).monospacedDigit().frame(width: 44, alignment: .trailing)
            HStack(spacing: 0) {
                Button { store.setWeight(cell: cell.id, strategy: s.id, delta: -0.25) } label: {
                    Image(systemName: "minus").frame(width: 30, height: 28)
                }
                Divider().frame(height: 14)
                Button { store.setWeight(cell: cell.id, strategy: s.id, delta: 0.25) } label: {
                    Image(systemName: "plus").frame(width: 30, height: 28)
                }
            }
            .buttonStyle(.plain)
            .background(Palette.neutralBg, in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(.vertical, 4)
    }
}
#endif
