import SwiftUI

// Gráficas «Mejorado» del lienzo, pasadas a SwiftUI con Canvas (texto y trazos nítidos, sin rasterizar).
// Todas las tallas de letra son enteras a propósito: los medios puntos se ven borrosos.

extension GraphicsContext {
    /// Texto con tamaño entero, anclado donde se pida.
    mutating func label(_ s: String, at p: CGPoint, size: CGFloat, weight: Font.Weight = .regular,
               color: Color = Palette.ink2, anchor: UnitPoint = .center, mono: Bool = false) {
        let font: Font = .system(size: size, weight: weight, design: mono ? .monospaced : .default)
        let t = Text(s).font(font).foregroundColor(color)
        draw(t, at: p, anchor: anchor)
    }
}

private func signed(_ v: Double, _ decimals: Int = 1) -> String {
    let sign = v > 0.00001 ? "+" : (v < -0.00001 ? "−" : "")
    return sign + Fmt.comma(abs(v), decimals)
}

private struct LegendDot: View {
    let color: Color
    let text: String
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 9, height: 9)
            Text(text).font(.system(size: 12)).foregroundStyle(Palette.ink2)
        }
    }
}

// MARK: - #06 Contribución semanal (barras apiladas)

struct ContributionChart: View {
    let weeks: [[Double]]      // cada semana: aporte de cada estrategia
    let labels: [String]
    let names: [String]
    let colors: [Color]
    var height: CGFloat = 210

    private var nets: [Double] { weeks.map { $0.reduce(0, +) } }
    private var best: Int { nets.indices.max { nets[$0] < nets[$1] } ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                ForEach(0..<names.count, id: \.self) { i in
                    LegendDot(color: colors[i], text: names[i])
                }
            }
            Canvas { ctx, size in
                draw(&ctx, size)
            }
            .frame(height: height)
            if !weeks.isEmpty {
                bestLine
            }
        }
    }

    private var bestLine: some View {
        let parts: [String] = weeks[best].indices
            .sorted { weeks[best][$0] > weeks[best][$1] }
            .map { names[$0] + " " + signed(weeks[best][$0]) }
        return HStack(spacing: 10) {
            Text(labels[best] + " · " + Fmt.signedPct(nets[best], 1))
                .font(.system(size: 13, weight: .bold))
            Text(parts.joined(separator: " · "))
                .font(.system(size: 12))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Palette.graphiteDark, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize) {
        guard !weeks.isEmpty else { return }
        let left: CGFloat = 38
        let top: CGFloat = 20
        let bottom: CGFloat = 20
        let ups: [Double] = weeks.map { w in w.filter { $0 > 0 }.reduce(0, +) }
        let downs: [Double] = weeks.map { w in -w.filter { $0 < 0 }.reduce(0, +) }
        let maxUp: Double = max(0.5, ups.max() ?? 0)
        let maxDn: Double = max(0.5, downs.max() ?? 0)
        let plotH: CGFloat = size.height - top - bottom
        let unit: CGFloat = plotH / CGFloat(maxUp + maxDn)
        let zeroY: CGFloat = top + CGFloat(maxUp) * unit
        let slot: CGFloat = (size.width - left) / CGFloat(weeks.count)
        let barW: CGFloat = min(30, slot * 0.62)

        // semana destacada
        let hx: CGFloat = left + slot * CGFloat(best)
        let hl = CGRect(x: hx + 2, y: 4, width: slot - 4, height: size.height - 8)
        ctx.fill(Path(roundedRect: hl, cornerRadius: 10), with: .color(Palette.bg.opacity(0.8)))

        // rejilla
        for v in [0.5, -0.5] {
            let y: CGFloat = zeroY - CGFloat(v) * unit
            var line = Path()
            line.move(to: CGPoint(x: left, y: y))
            line.addLine(to: CGPoint(x: size.width, y: y))
            ctx.stroke(line, with: .color(Palette.line), lineWidth: 1)
            ctx.label(v > 0 ? "+0,5" : "−0,5", at: CGPoint(x: left - 6, y: y), size: 11, anchor: .trailing)
        }
        var base = Path()
        base.move(to: CGPoint(x: left, y: zeroY))
        base.addLine(to: CGPoint(x: size.width, y: zeroY))
        ctx.stroke(base, with: .color(Palette.gray), lineWidth: 1.5)
        ctx.label("0", at: CGPoint(x: left - 6, y: zeroY), size: 11, anchor: .trailing)

        for (i, w) in weeks.enumerated() {
            let cx: CGFloat = left + slot * (CGFloat(i) + 0.5)
            var upY: CGFloat = zeroY
            var dnY: CGFloat = zeroY
            for (k, v) in w.enumerated() {
                let h: CGFloat = CGFloat(abs(v)) * unit
                let rect: CGRect
                if v >= 0 {
                    upY -= h
                    rect = CGRect(x: cx - barW / 2, y: upY, width: barW, height: h)
                } else {
                    rect = CGRect(x: cx - barW / 2, y: dnY, width: barW, height: h)
                    dnY += h
                }
                let color: Color = k < colors.count ? colors[k] : Palette.gray
                let p = Path(roundedRect: rect, cornerRadius: 4)
                ctx.fill(p, with: .color(color))
                ctx.stroke(p, with: .color(Palette.card), lineWidth: 1.5)
            }
            let net: Double = nets[i]
            ctx.label(signed(net), at: CGPoint(x: cx, y: upY - 9), size: 12, weight: .bold,
                      color: net >= 0 ? Palette.posText : Palette.negText)
            if i < labels.count {
                ctx.label(labels[i], at: CGPoint(x: cx, y: size.height - 8), size: 11)
            }
        }
    }
}

// MARK: - #08 Exposición (arco con zonas)

struct ExposureGauge: View {
    let pct: Double            // uso actual, 0-100
    let yesterday: Double      // uso de ayer, 0-100
    let lots: Double
    var warnAt: Double = 50
    var dangerAt: Double = 80
    var height: CGFloat = 230

    private var zoneColor: Color {
        pct < warnAt ? Palette.pos : (pct < dangerAt ? Palette.warn : Palette.neg)
    }

    var body: some View {
        Canvas { ctx, size in
            draw(&ctx, size)
        }
        .frame(height: height)
        .accessibilityLabel("Exposición al \(Int(pct)) por ciento del máximo; ayer estaba en el \(Int(yesterday))")
    }

    private func point(_ c: CGPoint, _ r: CGFloat, _ p: Double) -> CGPoint {
        let a: Double = (210 - p * 240) * Double.pi / 180
        return CGPoint(x: c.x + r * CGFloat(cos(a)), y: c.y - r * CGFloat(sin(a)))
    }

    private func arc(_ c: CGPoint, _ r: CGFloat, _ from: Double, _ to: Double) -> Path {
        var path = Path()
        let steps: Int = max(2, Int((to - from) * 90))
        for i in 0...steps {
            let p: Double = from + (to - from) * Double(i) / Double(steps)
            let pt: CGPoint = point(c, r, p)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        return path
    }

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize) {
        let r: CGFloat = min((size.width / 2 - 26) / 1.3, size.height * 0.34)
        let c = CGPoint(x: size.width / 2, y: size.height * 0.5)
        let thin = StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
        let thick = StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round)
        let wa: Double = warnAt / 100
        let da: Double = dangerAt / 100

        // zonas por fuera
        ctx.stroke(arc(c, r * 1.24, 0, wa - 0.01), with: .color(Palette.pos), style: thin)
        ctx.stroke(arc(c, r * 1.24, wa + 0.01, da - 0.01), with: .color(Palette.warn), style: thin)
        ctx.stroke(arc(c, r * 1.24, da + 0.01, 1), with: .color(Palette.neg), style: thin)

        // pista y valor
        ctx.stroke(arc(c, r, 0, 1), with: .color(Palette.track), style: thick)
        let v: Double = min(max(pct / 100, 0.005), 1)
        ctx.stroke(arc(c, r, 0, v), with: .color(zoneColor), style: thick)

        // ayer
        let y: Double = min(max(yesterday / 100, 0), 1)
        var tick = Path()
        tick.move(to: point(c, r * 0.84, y))
        tick.addLine(to: point(c, r * 1.14, y))
        ctx.stroke(tick, with: .color(Palette.gray), style: StrokeStyle(lineWidth: 3, lineCap: .round))

        // punto del valor
        let dot: CGPoint = point(c, r, v)
        let dotRect = CGRect(x: dot.x - 6, y: dot.y - 6, width: 12, height: 12)
        ctx.fill(Path(ellipseIn: dotRect), with: .color(Palette.card))
        ctx.stroke(Path(ellipseIn: dotRect), with: .color(zoneColor), lineWidth: 3)

        // marcas
        let marks: [(Double, String)] = [(0.0, "0"), (0.5, "50"), (0.8, "80"), (1.0, "100")]
        for (p, t) in marks {
            ctx.label(t, at: point(c, r * 1.46, p), size: 11)
        }

        // centro
        ctx.label(Fmt.pct(pct), at: CGPoint(x: c.x, y: c.y - 4), size: 38, weight: .bold, color: Palette.ink)
        ctx.label(Fmt.comma(lots, 1) + " lotes", at: CGPoint(x: c.x, y: c.y + 26), size: 13)
        let delta: Int = Int((pct - yesterday).rounded())
        let text: String = (delta == 0 ? "= ayer" : (delta > 0 ? "+\(delta)" : "−\(abs(delta))") + " pts vs ayer")
        let good: Bool = delta <= 0
        let pill = CGRect(x: c.x - 56, y: c.y + 44, width: 112, height: 24)
        ctx.fill(Path(roundedRect: pill, cornerRadius: 12), with: .color(good ? Palette.posBg : Palette.warnBg))
        ctx.label(text, at: CGPoint(x: c.x, y: c.y + 56), size: 12, weight: .semibold,
                  color: good ? Palette.posText : Palette.warnText)
    }
}

// MARK: - #10 Mapa de exposición por divisa (áreas proporcionales)

struct CurrencyTreemap: View {
    let items: [ExposureItem]
    var height: CGFloat = 220

    var body: some View {
        Canvas { ctx, size in
            draw(&ctx, size)
        }
        .frame(height: height)
        .accessibilityLabel("Mapa de exposición por divisa")
    }

    /// Reparto recursivo: el primero ocupa su parte y el resto se reparte en lo que queda, alternando eje.
    private func layout(_ weights: [Double], in rect: CGRect, vertical: Bool) -> [CGRect] {
        guard let first = weights.first else { return [] }
        if weights.count == 1 { return [rect] }
        let total: Double = weights.reduce(0, +)
        let f: CGFloat = CGFloat(first / max(total, 0.0001))
        var a = rect
        var b = rect
        if vertical {
            a.size.width = rect.width * f
            b.origin.x = rect.minX + a.width
            b.size.width = rect.width - a.width
        } else {
            a.size.height = rect.height * f
            b.origin.y = rect.minY + a.height
            b.size.height = rect.height - a.height
        }
        return [a] + layout(Array(weights.dropFirst()), in: b, vertical: !vertical)
    }

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize) {
        let sorted: [ExposureItem] = items.sorted { $0.pct > $1.pct }
        let rects: [CGRect] = layout(sorted.map { $0.pct }, in: CGRect(origin: .zero, size: size), vertical: true)
        var longRank = 0
        for (i, item) in sorted.enumerated() where i < rects.count {
            let r: CGRect = rects[i].insetBy(dx: 2, dy: 2)
            let color: Color
            if item.isLong {
                let a: Double = max(0.62, 1 - Double(longRank) * 0.16)
                color = Palette.info.opacity(a)
                longRank += 1
            } else {
                color = item.pct > 10 ? Palette.graphiteDark : Palette.graphite
            }
            ctx.fill(Path(roundedRect: r, cornerRadius: 12), with: .color(color))
            let big: Bool = r.height > 70 && r.width > 120
            let title: String = item.name + (r.width > 90 ? "  " + Fmt.pct(item.pct) : "")
            ctx.label(title, at: CGPoint(x: r.minX + 12, y: r.minY + 10), size: big ? 20 : 14, weight: .bold,
                      color: Color.white, anchor: .topLeading)
            if r.height > 44 {
                let sub: String = (item.isLong ? "▲ largo · " : "▼ corto · ") + Fmt.comma(item.lots, 2) + (r.width > 150 ? " lotes" : "")
                ctx.label(sub, at: CGPoint(x: r.minX + 12, y: r.minY + (big ? 38 : 30)), size: 12,
                          color: Color.white.opacity(0.9), anchor: .topLeading)
            }
        }
    }
}
