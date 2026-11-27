import SwiftUI

// Gráficas del panel de cuenta. Canvas, letra de tamaño entero y ejes con valores reales.

extension Fmt {
    /// «n.d.» cuando falta el dato; nunca un cero inventado.
    static func opt(_ v: Double?, _ format: (Double) -> String) -> String {
        guard let v = v else { return "n.d." }
        return format(v)
    }

    static func eur2(_ v: Double) -> String {
        let sign: String = v < 0 ? "−" : ""
        let ent: String = eur(abs(v).rounded(.down))
        let dec: Int = Int(((abs(v) - abs(v).rounded(.down)) * 100).rounded())
        return sign + ent.replacingOccurrences(of: " €", with: "") + "," + String(format: "%02d", dec) + " €"
    }

    static func signedEur2(_ v: Double) -> String {
        (v > 0 ? "+" : "") + eur2(v)
    }
}

/// Color de un número según gane o pierda. Solo el verde y el rojo de la paleta.
func resultColor(_ v: Double?) -> Color {
    guard let v = v, abs(v) > 0.000001 else { return Palette.ink2 }
    return v > 0 ? Palette.posText : Palette.negText
}

// MARK: - Curva con ejes

struct CurveChart: View {
    let values: [Double]
    var color: Color = Palette.info
    var baseline: Double? = nil          // si se da, dibuja la raya y rellena hasta ella
    var yText: (Double) -> String = { Fmt.comma($0, 0) }
    var leftLabel: String = ""
    var rightLabel: String = ""
    var height: CGFloat = 200

    var body: some View {
        Canvas { ctx, size in
            draw(&ctx, size)
        }
        .frame(height: height)
        .accessibilityLabel("Gráfica de \(values.count) puntos")
    }

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize) {
        guard values.count > 1 else { return }
        var lo: Double = values.min() ?? 0
        var hi: Double = values.max() ?? 1
        if let b = baseline { lo = min(lo, b); hi = max(hi, b) }
        let span: Double = max(hi - lo, 0.000001)
        let left: CGFloat = 52
        let right: CGFloat = 10
        let top: CGFloat = 10
        let bottom: CGFloat = 22
        let w: CGFloat = size.width - left - right
        let h: CGFloat = size.height - top - bottom
        func x(_ i: Int) -> CGFloat { left + CGFloat(i) * w / CGFloat(values.count - 1) }
        func y(_ v: Double) -> CGFloat { top + CGFloat((hi - v) / span) * h }

        for k in 0...4 {
            let v: Double = lo + span * Double(k) / 4
            var g = Path()
            g.move(to: CGPoint(x: left, y: y(v)))
            g.addLine(to: CGPoint(x: size.width - right, y: y(v)))
            ctx.stroke(g, with: .color(Palette.line), lineWidth: 1)
            ctx.label(yText(v), at: CGPoint(x: left - 6, y: y(v)), size: 11, anchor: .trailing)
        }
        if let b = baseline {
            var z = Path()
            z.move(to: CGPoint(x: left, y: y(b)))
            z.addLine(to: CGPoint(x: size.width - right, y: y(b)))
            ctx.stroke(z, with: .color(Palette.gray), lineWidth: 1.5)
        }
        let base: CGFloat = baseline.map { y($0) } ?? (top + h)
        var line = Path()
        var area = Path()
        for (i, v) in values.enumerated() {
            let p = CGPoint(x: x(i), y: y(v))
            if i == 0 {
                line.move(to: p)
                area.move(to: CGPoint(x: p.x, y: base))
                area.addLine(to: p)
            } else {
                line.addLine(to: p)
                area.addLine(to: p)
            }
        }
        area.addLine(to: CGPoint(x: x(values.count - 1), y: base))
        area.closeSubpath()
        ctx.fill(area, with: .color(color.opacity(0.12)))
        ctx.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
        if let last = values.last {
            let c = CGRect(x: x(values.count - 1) - 4.5, y: y(last) - 4.5, width: 9, height: 9)
            ctx.fill(Path(ellipseIn: c), with: .color(color))
        }
        if !leftLabel.isEmpty {
            ctx.label(leftLabel, at: CGPoint(x: left, y: size.height - 7), size: 11, anchor: .leading)
        }
        if !rightLabel.isEmpty {
            ctx.label(rightLabel, at: CGPoint(x: size.width - right, y: size.height - 7), size: 11, anchor: .trailing)
        }
    }
}

// MARK: - Resultado por día

struct DailyBarsChart: View {
    let values: [Double]
    var height: CGFloat = 200
    var yText: (Double) -> String = { Fmt.comma($0, 0) }

    var body: some View {
        Canvas { ctx, size in
            draw(&ctx, size)
        }
        .frame(height: height)
        .accessibilityLabel("Resultado de cada uno de los últimos \(values.count) días")
    }

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize) {
        guard !values.isEmpty else { return }
        let mx: Double = max(values.map { abs($0) }.max() ?? 1, 0.000001)
        let left: CGFloat = 52
        let top: CGFloat = 10
        let bottom: CGFloat = 22
        let w: CGFloat = size.width - left - 10
        let mid: CGFloat = top + (size.height - top - bottom) / 2
        let unit: CGFloat = (size.height - top - bottom) / 2 / CGFloat(mx)
        let slot: CGFloat = w / CGFloat(values.count)

        for v in [mx, 0, -mx] {
            var g = Path()
            let yy: CGFloat = mid - CGFloat(v) * unit
            g.move(to: CGPoint(x: left, y: yy))
            g.addLine(to: CGPoint(x: size.width - 10, y: yy))
            ctx.stroke(g, with: .color(v == 0 ? Palette.gray : Palette.line), lineWidth: v == 0 ? 1.5 : 1)
            ctx.label(yText(v), at: CGPoint(x: left - 6, y: yy), size: 11, anchor: .trailing)
        }
        for (i, v) in values.enumerated() {
            let h: CGFloat = max(2, CGFloat(abs(v)) * unit)
            let r = CGRect(x: left + CGFloat(i) * slot + slot * 0.15, y: v >= 0 ? mid - h : mid, width: slot * 0.7, height: h)
            ctx.fill(Path(roundedRect: r, cornerRadius: 2.5), with: .color(v >= 0 ? Palette.pos : Palette.neg))
        }
        ctx.label("hace \(values.count) días", at: CGPoint(x: left, y: size.height - 7), size: 11, anchor: .leading)
        ctx.label("hoy", at: CGPoint(x: size.width - 10, y: size.height - 7), size: 11, anchor: .trailing)
    }
}
