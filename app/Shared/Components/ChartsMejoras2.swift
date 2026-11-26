import SwiftUI

// Gráficas «Mejorado» del lienzo, segunda tanda: flujo, turnos, latencias, retorno y caída,
// antes y después, y cambios. Todo con Canvas y tallas de letra enteras.

// MARK: - Datos de entrada

struct FlowExit {
    let name: String
    let color: Color
    let background: Color
    let foreground: Color
}

enum ShiftKind { case done, todo, pause }

struct ShiftSegment {
    let from: Double
    let to: Double
    let kind: ShiftKind
}

struct ShiftLane: Identifiable {
    var id: String { name }
    let name: String
    let color: Color
    let segments: [ShiftSegment]
}

struct ShiftSession {
    let name: String
    let from: Double
    let to: Double
    let row: Int
    let background: Color
    let foreground: Color
}

struct NewsMark {
    let hour: Double
    let label: String
}

struct LatencyCell: Identifiable {
    var id: String { name }
    let name: String
    let p50: Double
    let p99: Double
}

struct ReturnBubble: Identifiable {
    let id = UUID()
    let strategy: Int
    let cell: String
    let drawdown: Double   // % de caída máxima
    let result: Double     // % de retorno en 30 días
    let trades: Int
}

struct SlopeMeasure: Identifiable {
    var id: String { name }
    let name: String
    let detail: String     // «0,6 → 0,9 %»
    let index: Double      // 100 = igual que antes
    let change: String     // «+50 %»
    let better: Bool?      // nil: neutro
}

struct ChangeEvent: Identifiable {
    var id: String { letter }
    let letter: String
    let day: Int
    let color: Color
}

// MARK: - #13 Flujo de una orden (tubería)

struct FlowChart: View {
    let counts: [Int]          // señales, riesgo ✓, enviadas, ejecutadas
    let exits: [FlowExit]      // por qué se pierde en cada paso
    var height: CGFloat = 290

    private let heads: [String] = ["Señales", "Riesgo ✓", "Enviadas", "Ejecutadas"]

    var body: some View {
        Canvas { ctx, size in
            draw(&ctx, size)
        }
        .frame(height: height)
        .accessibilityLabel("Tubería de órdenes: de \(counts.first ?? 0) señales a \(counts.last ?? 0) ejecutadas")
    }

    private func band(_ x0: CGFloat, _ a0: CGFloat, _ a1: CGFloat, _ x1: CGFloat, _ b0: CGFloat, _ b1: CGFloat) -> Path {
        let m: CGFloat = (x0 + x1) / 2
        var p = Path()
        p.move(to: CGPoint(x: x0, y: a0))
        p.addCurve(to: CGPoint(x: x1, y: b0), control1: CGPoint(x: m, y: a0), control2: CGPoint(x: m, y: b0))
        p.addLine(to: CGPoint(x: x1, y: b1))
        p.addCurve(to: CGPoint(x: x0, y: a1), control1: CGPoint(x: m, y: b1), control2: CGPoint(x: m, y: a1))
        p.closeSubpath()
        return p
    }

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize) {
        guard counts.count == 4, exits.count == 3, let total = counts.first, total > 0 else { return }
        let sx: CGFloat = size.width / 600
        let top: CGFloat = 70
        let k: CGFloat = 130 / CGFloat(total)
        let hs: [CGFloat] = counts.map { CGFloat($0) * k }
        let nx: [CGFloat] = [30, 200, 370, 554].map { $0 * sx }

        for i in 0..<3 {
            let xs: CGFloat = nx[i] + 16
            let xe: CGFloat = nx[i + 1]
            let lost: Int = counts[i] - counts[i + 1]
            let eh: CGFloat = max(3, CGFloat(lost) * k)
            let tx: CGFloat = nx[i] + 74 * sx
            let e: FlowExit = exits[i]

            // salida que baja a su destino
            let ribbon: Path = band(xs, top + hs[i + 1], top + hs[i], tx, 236, 236 + eh)
            ctx.fill(ribbon, with: .color(e.color.opacity(0.3)))
            // caudal que sigue
            let main: Path = band(xs, top, top + hs[i + 1], xe, top, top + hs[i + 1])
            ctx.fill(main, with: .color(Palette.info.opacity(0.18)))

            // conversión del paso
            let conv: Double = Double(counts[i + 1]) / Double(counts[i]) * 100
            let mx: CGFloat = (xs + xe) / 2
            let my: CGFloat = top + hs[i + 1] / 2
            let cr = CGRect(x: mx - 26, y: my - 12, width: 52, height: 24)
            ctx.fill(Path(roundedRect: cr, cornerRadius: 12), with: .color(Palette.card))
            ctx.stroke(Path(roundedRect: cr, cornerRadius: 12), with: .color(Palette.infoBg), lineWidth: 1)
            ctx.label(Fmt.comma(conv, 1) + " %", at: CGPoint(x: mx, y: my), size: 12, weight: .bold, color: Palette.infoText)

            // destino de la pérdida
            ctx.fill(Path(roundedRect: CGRect(x: tx, y: 236, width: 10, height: eh), cornerRadius: 3), with: .color(e.color))
            let pw: CGFloat = CGFloat(e.name.count) * 6 + 30
            let pill = CGRect(x: tx + 14, y: 226, width: pw, height: 40)
            ctx.fill(Path(roundedRect: pill, cornerRadius: 12), with: .color(e.background))
            ctx.label(String(lost), at: CGPoint(x: tx + 26, y: 236), size: 15, weight: .bold, color: e.foreground, anchor: .leading)
            ctx.label(e.name, at: CGPoint(x: tx + 26, y: 254), size: 11, color: e.foreground, anchor: .leading)
        }

        for i in 0..<4 {
            let color: Color = i == 3 ? Palette.ink : Palette.info
            ctx.fill(Path(roundedRect: CGRect(x: nx[i], y: top, width: 16, height: hs[i]), cornerRadius: 8), with: .color(color))
            let last: Bool = i == 3
            let hx: CGFloat = last ? size.width - 6 : nx[i]
            let anchor: UnitPoint = last ? .trailing : .leading
            let share: Double = Double(counts[i]) / Double(total) * 100
            ctx.label(heads[i], at: CGPoint(x: hx, y: 20), size: 12, weight: .semibold, anchor: anchor)
            ctx.label(String(counts[i]), at: CGPoint(x: hx, y: 42), size: 18, weight: .bold, color: Palette.ink, anchor: anchor)
            ctx.label(i == 0 ? "100 %" : Fmt.pct(share) + " del total", at: CGPoint(x: hx, y: 58), size: 11, weight: .semibold, anchor: anchor)
        }
    }
}

// MARK: - #14 Turnos del día (carriles horarios)

struct ShiftsChart: View {
    let lanes: [ShiftLane]
    let sessions: [ShiftSession]
    let news: [NewsMark]
    let now: Double            // hora decimal, 10,7 = 10:42
    let nowText: String
    let nextNews: String
    var height: CGFloat = 280

    var body: some View {
        Canvas { ctx, size in
            draw(&ctx, size)
        }
        .frame(height: height)
        .accessibilityLabel("Carriles horarios de hoy con las estrategias y las noticias")
    }

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize) {
        let left: CGFloat = 112
        let plotW: CGFloat = size.width - left - 8
        let unit: CGFloat = plotW / 24
        func x(_ h: Double) -> CGFloat { left + CGFloat(h) * unit }
        func laneY(_ i: Int) -> CGFloat { 96 + CGFloat(i) * 48 }

        // próxima noticia
        let txtWidth: CGFloat = CGFloat(nextNews.count) * 6.6
        let dotX: CGFloat = size.width - 6 - txtWidth - 14
        ctx.fill(Path(ellipseIn: CGRect(x: dotX, y: 6, width: 8, height: 8)), with: .color(Palette.neg))
        ctx.label(nextNews, at: CGPoint(x: size.width - 6, y: 10), size: 12, weight: .semibold, color: Palette.ink, anchor: .trailing)

        // sesiones
        for s in sessions {
            let r = CGRect(x: x(s.from), y: 26 + CGFloat(s.row) * 20, width: x(s.to) - x(s.from), height: 16)
            ctx.fill(Path(roundedRect: r, cornerRadius: 8), with: .color(s.background))
            ctx.label(s.name, at: CGPoint(x: r.minX + 8, y: r.midY), size: 11, weight: .bold, color: s.foreground, anchor: .leading)
        }

        // rejilla horaria
        for h in stride(from: 0, through: 24, by: 3) {
            var g = Path()
            g.move(to: CGPoint(x: x(Double(h)), y: 78))
            g.addLine(to: CGPoint(x: x(Double(h)), y: size.height - 52))
            ctx.stroke(g, with: .color(Palette.line), lineWidth: 1)
            ctx.label(String(format: "%02d", h), at: CGPoint(x: x(Double(h)), y: size.height - 8), size: 11)
        }

        // noticias
        let dash = StrokeStyle(lineWidth: 1, dash: [3, 3])
        for n in news {
            var l = Path()
            l.move(to: CGPoint(x: x(n.hour), y: 78))
            l.addLine(to: CGPoint(x: x(n.hour), y: size.height - 50))
            ctx.stroke(l, with: .color(Palette.neg), style: dash)
        }
        if !news.isEmpty {
            let text: String = news.map { $0.label }.joined(separator: " · ")
            let mid: CGFloat = (x(news.first?.hour ?? 0) + x(news.last?.hour ?? 0)) / 2
            let w: CGFloat = CGFloat(text.count) * 6.3 + 22
            let pill = CGRect(x: mid - w / 2, y: size.height - 48, width: w, height: 20)
            ctx.fill(Path(roundedRect: pill, cornerRadius: 10), with: .color(Palette.negBg))
            ctx.label(text, at: CGPoint(x: mid, y: pill.midY), size: 11, weight: .bold, color: Palette.negText)
        }

        // carriles
        for (i, lane) in lanes.enumerated() {
            let y: CGFloat = laneY(i)
            ctx.fill(Path(roundedRect: CGRect(x: 0, y: y + 2, width: 22, height: 22), cornerRadius: 6), with: .color(lane.color))
            ctx.label(lane.name, at: CGPoint(x: 30, y: y + 13), size: 12, weight: .semibold, color: Palette.ink, anchor: .leading, mono: true)
            for seg in lane.segments {
                let w: CGFloat = max(5, x(seg.to) - x(seg.from))
                let r = CGRect(x: x(seg.from), y: y, width: w, height: 26)
                let p = Path(roundedRect: r, cornerRadius: 8)
                switch seg.kind {
                case .done:
                    ctx.fill(p, with: .color(lane.color))
                case .todo:
                    ctx.fill(p, with: .color(lane.color.opacity(0.4)))
                case .pause:
                    ctx.fill(p, with: .color(Palette.card))
                    var inner = ctx
                    inner.clip(to: p)
                    var hatch = Path()
                    var hx: CGFloat = r.minX - 26
                    while hx < r.maxX + 26 {
                        hatch.move(to: CGPoint(x: hx, y: r.maxY))
                        hatch.addLine(to: CGPoint(x: hx + 26, y: r.minY))
                        hx += 6
                    }
                    inner.stroke(hatch, with: .color(lane.color), lineWidth: 2)
                    ctx.stroke(p, with: .color(lane.color), lineWidth: 1.5)
                }
            }
        }

        // ahora
        var nl = Path()
        nl.move(to: CGPoint(x: x(now), y: 76))
        nl.addLine(to: CGPoint(x: x(now), y: size.height - 52))
        ctx.stroke(nl, with: .color(Palette.ink), lineWidth: 1.5)
        let np = CGRect(x: x(now) - 23, y: 70, width: 46, height: 19)
        ctx.fill(Path(roundedRect: np, cornerRadius: 9.5), with: .color(Palette.ink))
        ctx.label(nowText, at: CGPoint(x: np.midX, y: np.midY), size: 11, weight: .bold, color: Color.white)
    }
}

// MARK: - #15 Latencias (cajas con puntos)

struct LatencyChart: View {
    let cells: [LatencyCell]
    var maxMs: Double = 1300
    var limitMs: Double = 1000
    var height: CGFloat = 250

    var body: some View {
        Canvas { ctx, size in
            draw(&ctx, size)
        }
        .frame(height: height)
        .accessibilityLabel("Latencias por célula hasta aceptada")
    }

    /// Muestras de ejemplo, repartidas alrededor de la mediana, con alguna cola larga.
    private func samples(_ c: LatencyCell, _ row: Int) -> [Double] {
        var out: [Double] = []
        for j in 0..<36 {
            let u: Double = Double((j * 73 + row * 31) % 100) / 100
            var m: Double = c.p50 * (0.65 + 0.7 * u)
            if u > 0.9 { m += (u - 0.9) * 13 * (c.p99 - c.p50) }
            out.append(m)
        }
        return out.sorted()
    }

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize) {
        let left: CGFloat = 110
        let plotW: CGFloat = size.width - left - 30
        func x(_ ms: Double) -> CGFloat { left + CGFloat(ms / maxMs) * plotW }

        var lim = Path()
        lim.move(to: CGPoint(x: x(limitMs), y: 24))
        lim.addLine(to: CGPoint(x: x(limitMs), y: size.height - 26))
        ctx.stroke(lim, with: .color(Palette.neg), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
        ctx.label("1 s", at: CGPoint(x: x(limitMs) + 4, y: 12), size: 11, weight: .bold, color: Palette.negText, anchor: .leading)

        for (i, c) in cells.enumerated() {
            let cy: CGFloat = 48 + CGFloat(i) * 48
            let s: [Double] = samples(c, i)
            let q1: Double = s[s.count / 4]
            let q3: Double = s[(s.count * 3) / 4]
            ctx.label(c.name, at: CGPoint(x: 0, y: cy - 8), size: 12, weight: .semibold, color: Palette.ink, anchor: .leading, mono: true)
            ctx.label("p50 \(Int(c.p50)) · p99 \(Int(c.p99))", at: CGPoint(x: 0, y: cy + 8), size: 11, anchor: .leading)

            var whisker = Path()
            whisker.move(to: CGPoint(x: x(s.first ?? 0), y: cy))
            whisker.addLine(to: CGPoint(x: x(s.last ?? 0), y: cy))
            ctx.stroke(whisker, with: .color(Palette.graphiteSoft), lineWidth: 1.5)

            let box = CGRect(x: x(q1), y: cy - 12, width: x(q3) - x(q1), height: 24)
            ctx.fill(Path(roundedRect: box, cornerRadius: 7), with: .color(Palette.infoBg))

            for (j, m) in s.enumerated() {
                let dy: CGFloat = CGFloat((j * 17) % 11 - 5) * 1.7
                let dot = CGRect(x: x(m) - 3, y: cy + dy - 3, width: 6, height: 6)
                ctx.fill(Path(ellipseIn: dot), with: .color((m > limitMs ? Palette.neg : Palette.ink2).opacity(0.75)))
            }

            var med = Path()
            med.move(to: CGPoint(x: x(c.p50), y: cy - 12))
            med.addLine(to: CGPoint(x: x(c.p50), y: cy + 12))
            ctx.stroke(med, with: .color(Palette.infoText), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }

        let ticks: [(Double, String)] = [(0.0, "0"), (400.0, "400 ms"), (800.0, "800 ms"), (1300.0, "1,3 s")]
        for (ms, t) in ticks {
            ctx.label(t, at: CGPoint(x: x(ms), y: size.height - 8), size: 11)
        }
    }
}

// MARK: - #19 Retorno frente a caída (burbujas)

struct ReturnDrawdownChart: View {
    let bubbles: [ReturnBubble]
    let colors: [Color]
    let names: [String]
    var height: CGFloat = 330

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Canvas { ctx, size in
                draw(&ctx, size)
            }
            .frame(height: height)
            HStack(spacing: 14) {
                ForEach(0..<names.count, id: \.self) { i in
                    HStack(spacing: 5) {
                        Circle().fill(colors[i]).frame(width: 9, height: 9)
                        Text(names[i]).font(.system(size: 12)).foregroundStyle(Palette.ink2)
                    }
                }
                Text("tamaño: operaciones").font(.system(size: 12)).foregroundStyle(Palette.ink2)
            }
        }
    }

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize) {
        let left: CGFloat = 56
        let top: CGFloat = 44
        let bottom: CGFloat = 30
        let plotW: CGFloat = size.width - left - 14
        let plotH: CGFloat = size.height - top - bottom
        func px(_ dd: Double) -> CGFloat { left + CGFloat(dd / 2) * plotW }
        func py(_ r: Double) -> CGFloat { top + CGFloat((3 - r) / 4) * plotH }

        // zonas
        var good = Path()
        good.move(to: CGPoint(x: px(0), y: py(0)))
        good.addLine(to: CGPoint(x: px(1.5), y: py(3)))
        good.addLine(to: CGPoint(x: px(0), y: py(3)))
        good.closeSubpath()
        ctx.fill(good, with: .color(Palette.posBg))
        ctx.fill(Path(CGRect(x: px(0), y: py(0), width: plotW, height: py(-1) - py(0))), with: .color(Palette.negBg))

        // rejilla y ejes
        for r in [3.0, 2.0, 1.0, -1.0] {
            var g = Path()
            g.move(to: CGPoint(x: px(0), y: py(r)))
            g.addLine(to: CGPoint(x: px(2), y: py(r)))
            ctx.stroke(g, with: .color(Palette.line), lineWidth: 1)
        }
        for d in [0.5, 1.0, 1.5] {
            var g = Path()
            g.move(to: CGPoint(x: px(d), y: py(3)))
            g.addLine(to: CGPoint(x: px(d), y: py(-1)))
            ctx.stroke(g, with: .color(Palette.line), lineWidth: 1)
        }
        var zero = Path()
        zero.move(to: CGPoint(x: px(0), y: py(0)))
        zero.addLine(to: CGPoint(x: px(2), y: py(0)))
        ctx.stroke(zero, with: .color(Palette.gray), lineWidth: 1.5)

        // rectas de eficiencia 2× y 1×
        let dash = StrokeStyle(lineWidth: 1.5, dash: [6, 4])
        var two = Path()
        two.move(to: CGPoint(x: px(0), y: py(0)))
        two.addLine(to: CGPoint(x: px(1.5), y: py(3)))
        ctx.stroke(two, with: .color(Palette.pos), style: dash)
        var one = Path()
        one.move(to: CGPoint(x: px(0), y: py(0)))
        one.addLine(to: CGPoint(x: px(2), y: py(2)))
        ctx.stroke(one, with: .color(Palette.gray), style: dash)
        let tags: [(String, CGPoint, Color)] = [
            ("2×", CGPoint(x: px(1.5) - 16, y: py(3) + 12), Palette.pos),
            ("1×", CGPoint(x: px(2) - 16, y: py(2) + 12), Palette.gray)
        ]
        for (label, pt, color) in tags {
            let r = CGRect(x: pt.x - 15, y: pt.y - 10, width: 30, height: 20)
            ctx.fill(Path(roundedRect: r, cornerRadius: 10), with: .color(color))
            ctx.label(label, at: pt, size: 11, weight: .bold, color: Color.white)
        }

        // burbujas
        let best: UUID? = bubbles.filter { $0.drawdown > 0 }.max { $0.result / $0.drawdown < $1.result / $1.drawdown }?.id
        for b in bubbles {
            let c: CGPoint = CGPoint(x: px(b.drawdown), y: py(b.result))
            let r: CGFloat = 5 + CGFloat(Double(b.trades).squareRoot()) * 1.5
            let color: Color = b.strategy < colors.count ? colors[b.strategy] : Palette.gray
            let rect = CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)
            let isBest: Bool = b.id == best
            ctx.fill(Path(ellipseIn: rect), with: .color(isBest ? Palette.card : color.opacity(0.28)))
            ctx.stroke(Path(ellipseIn: rect), with: .color(color), lineWidth: 2)
            let toLeft: Bool = c.x > left + plotW * 0.8
            ctx.label(b.cell, at: CGPoint(x: toLeft ? c.x - r - 5 : c.x + r + 5, y: c.y), size: 11, weight: .bold,
                      color: color, anchor: toLeft ? .trailing : .leading)
        }

        // ejes
        ctx.label("Retorno 30 días", at: CGPoint(x: left, y: 14), size: 12, weight: .bold, color: Palette.ink, anchor: .leading)
        let yTicks: [(Double, String)] = [(3.0, "+3 %"), (2.0, "+2 %"), (1.0, "+1 %"), (0.0, "0"), (-1.0, "−1 %")]
        for (r, t) in yTicks {
            ctx.label(t, at: CGPoint(x: left - 8, y: py(r)), size: 11, anchor: .trailing)
        }
        let xTicks: [(Double, String)] = [(0.0, "0"), (0.5, "0,5"), (1.0, "1 %"), (1.5, "1,5")]
        for (d, t) in xTicks {
            ctx.label(t, at: CGPoint(x: px(d), y: size.height - 10), size: 11)
        }
        ctx.label("2 % caída", at: CGPoint(x: px(2), y: size.height - 10), size: 11, anchor: .trailing)
    }
}

// MARK: - #21 Antes y después (pendiente)

struct SlopeChart: View {
    let measures: [SlopeMeasure]
    var before: String = "v2"
    var after: String = "v3"
    var height: CGFloat = 290

    var body: some View {
        Canvas { ctx, size in
            draw(&ctx, size)
        }
        .frame(height: height)
        .accessibilityLabel("Cinco medidas entre \(before) y \(after), todas con base 100")
    }

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize) {
        guard !measures.isEmpty else { return }
        let x0: CGFloat = size.width * 0.2
        let x1: CGFloat = size.width * 0.5
        let baseY: CGFloat = 172
        func y(_ idx: Double) -> CGFloat { 260 - CGFloat(idx - 60) * 2.2 }

        for xx in [x0, x1] {
            var v = Path()
            v.move(to: CGPoint(x: xx, y: 30))
            v.addLine(to: CGPoint(x: xx, y: 262))
            ctx.stroke(v, with: .color(Palette.line), lineWidth: 2)
        }
        var base = Path()
        base.move(to: CGPoint(x: x0, y: baseY))
        base.addLine(to: CGPoint(x: x1, y: baseY))
        ctx.stroke(base, with: .color(Palette.graphiteSoft), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        ctx.label(before, at: CGPoint(x: x0, y: size.height - 8), size: 12, weight: .bold, color: Palette.ink)
        ctx.label(after, at: CGPoint(x: x1, y: size.height - 8), size: 12, weight: .bold, color: Palette.ink)
        ctx.label("todo en 100", at: CGPoint(x: x0 - 10, y: baseY), size: 11, anchor: .trailing)

        // evitar que las etiquetas se pisen
        let order: [SlopeMeasure] = measures.sorted { y($0.index) < y($1.index) }
        var lastLabel: CGFloat = -1000
        for m in order {
            let ey: CGFloat = y(m.index)
            let ly: CGFloat = max(ey + 4, lastLabel + 30)
            lastLabel = ly
            let color: Color = m.better == true ? Palette.pos : Palette.gray
            var line = Path()
            line.move(to: CGPoint(x: x0, y: baseY))
            line.addLine(to: CGPoint(x: x1, y: ey))
            ctx.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            ctx.fill(Path(ellipseIn: CGRect(x: x1 - 5.5, y: ey - 5.5, width: 11, height: 11)), with: .color(color))
            var lead = Path()
            lead.move(to: CGPoint(x: x1 + 6, y: ey))
            lead.addLine(to: CGPoint(x: x1 + 16, y: ly))
            ctx.stroke(lead, with: .color(Palette.graphiteSoft), lineWidth: 1)
            ctx.label(m.name + "  " + m.change, at: CGPoint(x: x1 + 20, y: ly), size: 13, weight: .bold,
                      color: Palette.ink, anchor: .leading)
            ctx.label(m.detail, at: CGPoint(x: x1 + 20, y: ly + 15), size: 11, anchor: .leading)
        }
        ctx.fill(Path(ellipseIn: CGRect(x: x0 - 6, y: baseY - 6, width: 12, height: 12)), with: .color(Palette.ink))
    }
}

// MARK: - #23 Cambios sobre la curva

struct ChangesChart: View {
    let series: [Double]       // equity de 30 días
    let events: [ChangeEvent]
    let windowFrom: Int        // día del cambio que se destaca
    let windowText: String
    var height: CGFloat = 290

    var body: some View {
        Canvas { ctx, size in
            draw(&ctx, size)
        }
        .frame(height: height)
        .accessibilityLabel("Curva de 30 días con los cambios marcados en su día")
    }

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize) {
        guard series.count > 1, let lo = series.min(), let hi = series.max() else { return }
        let left: CGFloat = 16
        let plotW: CGFloat = size.width - left - 16
        func x(_ i: Int) -> CGFloat { left + CGFloat(i) * plotW / CGFloat(series.count - 1) }
        let span: Double = max(hi - lo, 0.0001)
        func y(_ v: Double) -> CGFloat { 180 - CGFloat((v - lo) / span) * 116 }

        // zona posterior al cambio destacado
        let endIndex: Int = series.count - 1
        let win = CGRect(x: x(windowFrom), y: 24, width: x(endIndex) - x(windowFrom), height: 164)
        ctx.fill(Path(roundedRect: win, cornerRadius: 8), with: .color(Palette.infoBg.opacity(0.7)))
        let pw: CGFloat = CGFloat(windowText.count) * 6.6 + 18
        let pill = CGRect(x: win.midX - pw / 2, y: 30, width: pw, height: 20)
        ctx.fill(Path(roundedRect: pill, cornerRadius: 10), with: .color(Palette.info))
        ctx.label(windowText, at: CGPoint(x: pill.midX, y: pill.midY), size: 11, weight: .bold, color: Color.white)

        // curva
        var area = Path()
        var line = Path()
        for (i, v) in series.enumerated() {
            let pt = CGPoint(x: x(i), y: y(v))
            if i == 0 {
                area.move(to: CGPoint(x: pt.x, y: 188))
                area.addLine(to: pt)
                line.move(to: pt)
            } else {
                area.addLine(to: pt)
                line.addLine(to: pt)
            }
        }
        area.addLine(to: CGPoint(x: x(endIndex), y: 188))
        area.closeSubpath()
        ctx.fill(area, with: .color(Palette.info.opacity(0.07)))
        ctx.stroke(line, with: .color(Palette.info), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))

        // carril de cambios
        var rail = Path()
        rail.move(to: CGPoint(x: left, y: 200))
        rail.addLine(to: CGPoint(x: size.width - 16, y: 200))
        ctx.stroke(rail, with: .color(Palette.line), lineWidth: 1)
        ctx.label("hace 30 d", at: CGPoint(x: left, y: 194), size: 11, anchor: .leading)
        ctx.label("hoy", at: CGPoint(x: size.width - 16, y: 194), size: 11, anchor: .trailing)

        var lastDay: Int = -10
        var row: Int = 0
        for e in events {
            if e.day - lastDay <= 1 { row = 1 - row } else { row = 0 }
            lastDay = e.day
            let ex: CGFloat = x(e.day)
            let ry: CGFloat = 208 + CGFloat(row) * 26
            var stem = Path()
            stem.move(to: CGPoint(x: ex, y: y(series[e.day])))
            stem.addLine(to: CGPoint(x: ex, y: ry))
            ctx.stroke(stem, with: .color(e.color.opacity(0.45)), lineWidth: 1.5)
            let dot = CGRect(x: ex - 4.5, y: y(series[e.day]) - 4.5, width: 9, height: 9)
            ctx.fill(Path(ellipseIn: dot), with: .color(Palette.card))
            ctx.stroke(Path(ellipseIn: dot), with: .color(e.color), lineWidth: 2.5)
            let tag = CGRect(x: ex - 11, y: ry, width: 22, height: 22)
            ctx.fill(Path(roundedRect: tag, cornerRadius: 6), with: .color(e.color))
            ctx.label(e.letter, at: CGPoint(x: tag.midX, y: tag.midY), size: 11, weight: .bold, color: Color.white)
        }
    }
}
