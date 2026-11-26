import SwiftUI

// MARK: - Capas de límites

struct LayersCard: View {
    let layers: [RiskLayer]

    private func color(_ used: Double) -> Color {
        used < 50 ? Palette.graphiteDark : used < 80 ? Palette.warn : Palette.neg
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Heading("Capas", info: "Uso de cada capa de límites. Color de la barra: zona. Raya naranja: aviso. Marca gris: ayer. Flecha: cambio")
            ForEach(layers) { layer in
                let delta = Int(layer.used - layer.yesterday)
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(layer.name).font(.system(size: 13, weight: .bold))
                        Text(layer.detail).font(.system(size: 11)).foregroundStyle(Palette.ink2)
                    }
                    .frame(width: 100, alignment: .leading)
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Palette.track)
                            Capsule().fill(color(layer.used))
                                .frame(width: max(8, g.size.width * CGFloat(layer.used) / 100))
                            Rectangle().fill(Palette.warn).frame(width: 2.5, height: 18)
                                .offset(x: g.size.width * 0.75)
                            Triangle().fill(Palette.gray).frame(width: 9, height: 7)
                                .offset(x: g.size.width * CGFloat(layer.yesterday) / 100 - 4.5, y: -11)
                        }
                    }
                    .frame(height: 14)
                    Text(Fmt.pct(layer.used)).font(.system(size: 14, weight: .bold)).monospacedDigit().lineLimit(1).frame(width: 50, alignment: .trailing)
                    Text(delta == 0 ? "=" : (delta > 0 ? "▲ \(delta)" : "▼ \(abs(delta))"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(delta > 10 ? Palette.warnText : Palette.ink2)
                        .frame(width: 40, alignment: .leading)
                }
                .padding(.vertical, 3)
            }
        }
        .card(16)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

// MARK: - Exposición por divisa

struct ExposureCard: View {
    let exposures: [ExposureItem]
    let totalLots: Double
    let pct: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Heading("Exposición", info: "Arco: uso actual frente al máximo, con las zonas por fuera; la raya gris es ayer. Áreas: el peso de cada divisa o índice. Azul: largo. Grafito: corto") {
                Text("\(Fmt.comma(totalLots, 1)) lotes")
                    .font(.system(size: 13)).foregroundStyle(Palette.ink2)
            }
            HStack(alignment: .center, spacing: 14) {
                ExposureGauge(pct: pct, yesterday: ChartSamples.exposureYesterday, lots: totalLots)
                    .frame(minWidth: 210, maxWidth: 260)
                CurrencyTreemap(items: exposures)
                    .frame(maxWidth: .infinity)
            }
        }
        .card(16)
    }
}
