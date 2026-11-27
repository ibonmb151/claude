#if os(macOS)
import SwiftUI

struct EstrategiasView: View {
    @EnvironmentObject var store: AppStore

    private var selected: Strategy {
        store.data.strategies.first { $0.id == store.selectedStrategyId } ?? store.data.strategies[0]
    }

    var body: some View {
        let d = store.data
        HStack(alignment: .top, spacing: 14) {
            // Listas y ranking
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Heading("Estrategias", info: "Rendimiento a 30 días, de mejor a peor")
                        ForEach(d.strategies.sorted { $0.return30d > $1.return30d }) { s in
                            strategyRow(s)
                        }
                    }
                    .card(Layout.cardSmall)

                    VStack(alignment: .leading, spacing: 6) {
                        Heading("Matriz", info: "Qué estrategia corre en qué célula y con qué peso")
                        matrix(d)
                    }
                    .card(Layout.cardSmall)

                    VStack(alignment: .leading, spacing: 6) {
                        Heading("Contribución", info: "Lo que aporta cada estrategia cada semana. El número es el neto. La semana resaltada es la mejor")
                        ContributionChart(weeks: ChartSamples.weeklyContribution, labels: ChartSamples.weekLabels,
                                          names: ChartSamples.strategyNames, colors: ChartSamples.strategyColors, height: 190)
                    }
                    .card(Layout.cardSmall)
                }
            }
            .frame(width: 340)

            // Detalle
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(selected.id) · versión \(selected.version)")
                                .font(.system(size: 12, design: .monospaced)).foregroundStyle(Palette.ink2)
                            Text(selected.name).font(.system(size: 26, weight: .bold)).foregroundStyle(Palette.ink)
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text(Fmt.signedPct(selected.return30d, 1))
                                    .font(.system(size: 42, weight: .semibold)).monospacedDigit().foregroundStyle(Palette.ink)
                                Pill(text: "+0,3 % esta semana", tone: .good)
                            }
                        }
                        Spacer()
                        Button("Ajustar") { store.module = .ajustes }
                            .buttonStyle(MymButtonStyle(kind: .primary))
                    }

                    LineAreaChart(values: selected.series, color: Palette.pos)
                        .frame(height: 220)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 0) {
                        stat("Operaciones", "\(selected.trades)")
                        stat("Acierto", Fmt.pct(selected.hitRate * 100))
                        stat("Factor", Fmt.comma(selected.profitFactor, 2))
                        stat("Caída máx.", "−" + Fmt.comma(selected.maxDrawdown, 1) + " %")
                        stat("Sharpe", "1,6")
                        stat("Sharpe defl.", "0,9")
                        stat("Exposición", "0,3 lotes")
                        stat("Días en estado", "11")
                    }

                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Heading("Retorno y caída", info: "Cada burbuja es una estrategia en una célula; el tamaño, sus operaciones. Las rectas marcan cuánto retorno saca por cada punto de caída: 1× y 2×. Por encima de 2×, zona verde; por debajo de cero, zona roja")
                        ReturnDrawdownChart(bubbles: ChartSamples.returnBubbles, colors: ChartSamples.strategyColors, names: ChartSamples.strategyNames)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Heading("Cambios", info: "La curva de 30 días con cada cambio clavado en su día. La zona azul es lo que pasó después del cambio C")
                        ChangesChart(series: ChartSamples.changeSeries, events: ChartSamples.changeEvents, windowFrom: 23, windowText: "C · +0,5 % en 6 días")
                        HStack(spacing: 14) {
                            ForEach(0..<ChartSamples.changeLegend.count, id: \.self) { i in
                                HStack(spacing: 5) {
                                    RoundedRectangle(cornerRadius: 3).fill(ChartSamples.changeLegend[i].1).frame(width: 10, height: 10)
                                    Text(ChartSamples.changeLegend[i].0).font(.system(size: 12)).foregroundStyle(Palette.ink2)
                                }
                            }
                        }
                    }
                    Divider()
                    HStack(alignment: .top, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Heading("Peso por célula", info: "Bajar se aplica con firma. Subir por encima de lo que fijó Jev queda pendiente de aprobación")
                            ForEach(d.cells.filter { cell in cell.weights.contains { $0.strategyId == selected.id } }) { cell in
                                weightRow(cell)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 8) {
                            Heading("Parámetros", info: "Los vigentes de esta versión. Se cambian en Ajustes")
                            ForEach(selected.params) { p in
                                HStack {
                                    Text(p.key).font(.system(size: 13, design: .monospaced)).foregroundStyle(Palette.ink2)
                                    Spacer()
                                    Text(Fmt.comma(p.value, p.step < 1 ? 2 : 0) + p.unit)
                                        .font(.system(size: 13, weight: .semibold)).monospacedDigit()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
    }

    private func strategyRow(_ s: Strategy) -> some View {
        let sel = s.id == store.selectedStrategyId
        let ranked = store.data.strategies.sorted { $0.return30d > $1.return30d }
        let rank = (ranked.firstIndex { $0.id == s.id } ?? 0) + 1
        return Button {
            store.selectedStrategyId = s.id
        } label: {
            HStack(spacing: 11) {
                Text("\(rank)")
                    .font(.system(size: 12)).foregroundStyle(Palette.ink2).frame(width: 14)
                IconTile(symbol: s.symbol, color: s.color, size: 30)
                VStack(alignment: .leading, spacing: 0) {
                    Text(s.id).font(.system(size: 13, weight: .semibold, design: .monospaced))
                    Text(s.name).font(.system(size: 12)).foregroundStyle(Palette.ink2)
                }
                Spacer()
                Sparkline(values: s.series, color: Palette.pos, lineWidth: 1.8).frame(width: 56, height: 22)
                Text(Fmt.signedPct(s.return30d, 1))
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(Palette.posText).monospacedDigit()
                    .lineLimit(1)
                    .frame(width: 66, alignment: .trailing)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(sel ? Palette.selection : Color.clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Palette.ink)
    }

    private func matrix(_ d: Snapshot) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Text("").frame(width: 76)
                ForEach(d.cells) { c in
                    Text(c.shortName).font(.system(size: 10, design: .monospaced)).foregroundStyle(Palette.ink2)
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(d.strategies) { s in
                HStack(spacing: 4) {
                    Text(s.id).font(.system(size: 11, weight: .semibold, design: .monospaced)).frame(width: 76, alignment: .leading)
                    ForEach(d.cells) { c in
                        let w = c.weights.first { $0.strategyId == s.id }
                        Text(w == nil ? "—" : (w!.mode == .active ? Fmt.comma(w!.weight, 1) : (w!.mode == .shadow ? "som" : "‖")))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(w == nil ? Palette.ink2 : (w!.mode == .active ? Palette.posText : Palette.ink2))
                            .frame(maxWidth: .infinity, minHeight: 24)
                            .background((w?.mode == .active ? Palette.posBg : Palette.neutralBg), in: RoundedRectangle(cornerRadius: 7))
                    }
                }
            }
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label).font(.system(size: 12)).foregroundStyle(Palette.ink2)
            Text(value).font(.system(size: 16, weight: .semibold)).foregroundStyle(Palette.ink).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .overlay(Rectangle().fill(Palette.line).frame(height: 1), alignment: .bottom)
    }

    private func weightRow(_ cell: BotCell) -> some View {
        let w = cell.weights.first { $0.strategyId == selected.id }
        return HStack(spacing: 10) {
            Text(cell.id).font(.system(size: 13, design: .monospaced))
            Spacer()
            Pill(text: (w?.mode ?? .paused).label, tone: (w?.mode ?? .paused).tone)
            Text(Fmt.comma(w?.weight ?? 0, 2)).font(.system(size: 13, weight: .bold)).monospacedDigit().frame(width: 38, alignment: .trailing)
            HStack(spacing: 0) {
                Button { store.setWeight(cell: cell.id, strategy: selected.id, delta: -0.25) } label: {
                    Image(systemName: "minus").frame(width: 28, height: 26)
                }
                Divider().frame(height: 14)
                Button { store.setWeight(cell: cell.id, strategy: selected.id, delta: 0.25) } label: {
                    Image(systemName: "plus").frame(width: 28, height: 26)
                }
            }
            .buttonStyle(.plain)
            .background(Palette.neutralBg, in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(.vertical, 3)
    }
}
#endif
