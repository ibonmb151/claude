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
                    Text(Fmt.pct(layer.used)).font(.system(size: 14, weight: .bold)).monospacedDigit().frame(width: 44, alignment: .trailing)
                    Text(delta == 0 ? "=" : (delta > 0 ? "▲ \(delta)" : "▼ \(abs(delta))"))
                        .font(.system(size: 11.5, weight: .bold))
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
            Heading("Por divisa", info: "Largo a la derecha del eje, corto a la izquierda. El ancho es el peso de cada divisa o índice") {
                Text("\(Fmt.comma(totalLots, 1)) lotes · \(Fmt.pct(pct)) del máximo")
                    .font(.system(size: 12.5)).foregroundStyle(Palette.ink2)
            }
            HStack(spacing: 6) {
                Text("◀ corto").font(.system(size: 11.5, weight: .semibold)).foregroundStyle(Palette.ink2)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text("largo ▶").font(.system(size: 11.5, weight: .semibold)).foregroundStyle(Palette.infoText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, 56)
            ForEach(exposures) { e in
                HStack(spacing: 8) {
                    Text(e.name).font(.system(size: 13, weight: .bold)).frame(width: 48, alignment: .leading)
                    GeometryReader { g in
                        let half = g.size.width / 2
                        let w = half * CGFloat(e.pct) / 40
                        ZStack {
                            Rectangle().fill(Palette.line).frame(width: 1.5)
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(e.isLong ? Palette.graphiteDark : Palette.graphiteSoft)
                                .frame(width: w, height: 24)
                                .offset(x: e.isLong ? w / 2 : -w / 2)
                        }
                    }
                    .frame(height: 24)
                    Text("\(e.isLong ? "▲" : "▼") \(Fmt.comma(e.lots, 2))")
                        .font(.system(size: 12.5, weight: .semibold)).monospacedDigit().frame(width: 60, alignment: .trailing)
                }
            }
        }
        .card(16)
    }
}
