import SwiftUI

// MARK: - Mini gráfica de línea

struct Sparkline: View {
    let values: [Double]
    var color: Color = Palette.graphite
    var lineWidth: CGFloat = 2
    var fill: Bool = false

    var body: some View {
        GeometryReader { g in
            let pts = points(in: g.size)
            ZStack {
                if fill, pts.count > 1 {
                    Path { p in
                        p.move(to: CGPoint(x: pts[0].x, y: g.size.height))
                        for pt in pts { p.addLine(to: pt) }
                        p.addLine(to: CGPoint(x: pts[pts.count - 1].x, y: g.size.height))
                        p.closeSubpath()
                    }
                    .fill(color.opacity(0.10))
                }
                Path { p in
                    for (i, pt) in pts.enumerated() {
                        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            }
        }
    }

    private func points(in size: CGSize) -> [CGPoint] {
        guard values.count > 1, let mn = values.min(), let mx = values.max() else { return [] }
        let range = max(mx - mn, 0.000001)
        let inset = lineWidth
        return values.enumerated().map { i, v in
            let x = size.width * CGFloat(i) / CGFloat(values.count - 1)
            let y = inset + (size.height - 2 * inset) * (1 - CGFloat((v - mn) / range))
            return CGPoint(x: x, y: y)
        }
    }
}

// MARK: - Anillos concéntricos (estilo Actividad)

struct RingSpec: Identifiable {
    let id = UUID()
    let progress: Double
    let color: Color
}

struct RingsView: View {
    let rings: [RingSpec]
    var lineWidth: CGFloat = 10
    var gap: CGFloat = 4

    var body: some View {
        ZStack {
            ForEach(Array(rings.enumerated()), id: \.element.id) { index, ring in
                let inset = CGFloat(index) * (lineWidth + gap) + lineWidth / 2
                Circle()
                    .stroke(ring.color.opacity(0.18), lineWidth: lineWidth)
                    .padding(inset)
                Circle()
                    .trim(from: 0, to: CGFloat(min(max(ring.progress, 0.01), 1)))
                    .stroke(ring.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(inset)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Donut

struct DonutSlice: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
}

struct DonutView: View {
    let slices: [DonutSlice]
    var lineWidth: CGFloat = 16
    var centerText: String = ""

    private var total: Double {
        let sum: Double = slices.reduce(0.0) { $0 + $1.value }
        return max(sum, 0.0001)
    }

    private func startFraction(_ index: Int) -> Double {
        var acc: Double = 0
        for i in 0..<index { acc += slices[i].value }
        return acc / total
    }

    private func sliceView(_ index: Int, _ slice: DonutSlice) -> some View {
        let start: Double = startFraction(index)
        let end: Double = start + slice.value / total
        let from: CGFloat = CGFloat(start + 0.004)
        let to: CGFloat = CGFloat(max(start + 0.004, end - 0.004))
        return Circle()
            .trim(from: from, to: to)
            .stroke(slice.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
            .rotationEffect(.degrees(-90))
            .padding(lineWidth / 2)
    }

    var body: some View {
        ZStack {
            ForEach(0..<slices.count, id: \.self) { index in
                sliceView(index, slices[index])
            }
            if !centerText.isEmpty {
                Text(centerText)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Palette.ink)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Resultado por hora

struct HourlyChart: View {
    let bars: [HourBar]
    var sessions: Bool = true

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let h = g.size.height - 18
            let mid = h / 2
            let slot = w / 24
            let maxV = max(bars.map { abs($0.value) }.max() ?? 0.1, 0.05)
            let scale = (h / 2 - 6) / CGFloat(maxV)
            ZStack(alignment: .topLeading) {
                if sessions {
                    Rectangle().fill(Color(hex: 0xF5F5F2)).frame(width: slot * 8, height: h).offset(x: 0)
                    Rectangle().fill(Color(hex: 0xEEF5FE)).frame(width: slot * 8.5, height: h).offset(x: slot * 8)
                    Rectangle().fill(Color(hex: 0xF3EFFE)).frame(width: slot * 7.5, height: h).offset(x: slot * 14.5)
                }
                Rectangle().fill(Palette.line).frame(width: w, height: 1.5).offset(y: mid)
                ForEach(bars) { bar in
                    let bh: CGFloat = max(2, CGFloat(abs(bar.value)) * scale)
                    let bx: CGFloat = slot * (CGFloat(bar.id) + 8.2)
                    let by: CGFloat = bar.value >= 0 ? mid - bh : mid
                    RoundedRectangle(cornerRadius: 3)
                        .fill(bar.value >= 0 ? Palette.pos : Palette.neg)
                        .frame(width: slot * 0.62, height: bh)
                        .offset(x: bx, y: by)
                }
                Path { p in
                    var acc = 0.0
                    for (i, bar) in bars.enumerated() {
                        acc += bar.value
                        let pt = CGPoint(x: slot * (CGFloat(bar.id) + 8.5), y: mid - CGFloat(acc) * scale)
                        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                    }
                }
                .stroke(Palette.graphiteDark, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                HStack {
                    ForEach([0, 4, 8, 12, 16, 20], id: \.self) { hour in
                        Text(String(format: "%02d", hour))
                            .font(.system(size: 11))
                            .foregroundStyle(Palette.ink2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(width: w)
                .offset(y: h + 3)
            }
        }
    }
}

// MARK: - Línea grande con área, cursor y ejes sencillos

struct LineAreaChart: View {
    let values: [Double]
    var color: Color = Palette.pos
    var unit: String = " %"
    var showLast: Bool = true

    private func lowest() -> Double { min(values.min() ?? 0, 0) }

    private func highest() -> Double { max(values.max() ?? 1, 0.0001) }

    private func yFor(_ v: Double, _ size: CGSize) -> CGFloat {
        let mn: Double = lowest()
        let range: Double = max(highest() - mn, 0.0001)
        let t: Double = (v - mn) / range
        let usable: CGFloat = size.height - 24
        return 8 + usable * CGFloat(1 - t)
    }

    private func points(_ size: CGSize) -> [CGPoint] {
        var out: [CGPoint] = []
        let n: Int = max(values.count - 1, 1)
        for i in 0..<values.count {
            let x: CGFloat = size.width * CGFloat(i) / CGFloat(n)
            out.append(CGPoint(x: x, y: yFor(values[i], size)))
        }
        return out
    }

    var body: some View {
        GeometryReader { g in
            let pts: [CGPoint] = points(g.size)
            let zero: CGFloat = yFor(0, g.size)
            let baseY: CGFloat = g.size.height - 16
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: zero))
                    p.addLine(to: CGPoint(x: g.size.width, y: zero))
                }
                .stroke(Palette.line, lineWidth: 1)
                if pts.count > 1 {
                    Path { p in
                        p.move(to: CGPoint(x: pts[0].x, y: baseY))
                        for pt in pts { p.addLine(to: pt) }
                        p.addLine(to: CGPoint(x: pts[pts.count - 1].x, y: baseY))
                        p.closeSubpath()
                    }
                    .fill(color.opacity(0.10))
                    Path { p in
                        for (i, pt) in pts.enumerated() {
                            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                        }
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
                    if showLast, let last = pts.last {
                        Circle().fill(color).frame(width: 10, height: 10)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                            .position(last)
                    }
                }
            }
        }
    }
}

// MARK: - Cono de proyección (banda de incertidumbre)

struct FanChart: View {
    /// Retorno actual en %, objetivo y límite.
    var start: Double = 3.2
    var target: Double = 5
    var floor: Double = -8
    var days: Int = 30

    private let top = 9.0
    private let bottom = -9.0

    private func xp(_ d: Int, _ size: CGSize) -> CGFloat {
        size.width * CGFloat(d) / CGFloat(days)
    }

    private func yp(_ v: Double, _ size: CGSize) -> CGFloat {
        10 + (size.height - 30) * CGFloat((top - v) / (top - bottom))
    }

    private func median(_ d: Int) -> Double { start + 3.2 * (1 - exp(-Double(d) / 9)) }
    private func spread(_ d: Int) -> Double { 0.62 * sqrt(Double(d)) }

    private func band(_ k: Double, _ size: CGSize) -> Path {
        Path { p in
            for d in 0...days {
                let pt = CGPoint(x: xp(d, size), y: yp(median(d) + k * spread(d), size))
                if d == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            for d in stride(from: days, through: 0, by: -1) {
                p.addLine(to: CGPoint(x: xp(d, size), y: yp(median(d) - k * spread(d), size)))
            }
            p.closeSubpath()
        }
    }

    var body: some View {
        GeometryReader { g in
            ZStack {
                Rectangle().fill(Palette.negBg)
                    .frame(height: 10)
                    .position(x: g.size.width / 2, y: yp(floor, g.size) + 5)
                band(1.28, g.size).fill(Palette.graphiteDark.opacity(0.07))
                band(0.67, g.size).fill(Palette.graphiteDark.opacity(0.13))
                Path { p in
                    p.move(to: CGPoint(x: 0, y: yp(target, g.size)))
                    p.addLine(to: CGPoint(x: g.size.width, y: yp(target, g.size)))
                }
                .stroke(Palette.pos, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                Path { p in
                    for d in 0...days {
                        let pt = CGPoint(x: xp(d, g.size), y: yp(median(d), g.size))
                        if d == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                    }
                }
                .stroke(Palette.graphiteDark, lineWidth: 2.6)
                Circle().fill(Palette.graphiteDark).frame(width: 11, height: 11)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                    .position(x: 0, y: yp(start, g.size))
                Text("Objetivo +5 %")
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.posText)
                    .position(x: g.size.width - 48, y: yp(target, g.size) - 10)
                Text("Límite −8 %")
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.negText)
                    .position(x: g.size.width - 44, y: yp(floor, g.size) - 10)
            }
        }
    }
}

// MARK: - Radar de salud

struct RadarChart: View {
    let labels: [String]
    let values: [Double]      // 0-100
    let reference: [Double]
    var floor: Double = 40

    var body: some View {
        GeometryReader { g in
            let c = CGPoint(x: g.size.width / 2, y: g.size.height / 2)
            let r = min(g.size.width, g.size.height) / 2 - 26
            ZStack {
                ForEach([0.4, 0.7, 1.0], id: \.self) { f in
                    polygon(values: Array(repeating: floor + (100 - floor) * f, count: labels.count), c: c, r: r)
                        .stroke(Palette.track, lineWidth: 1)
                }
                polygon(values: reference, c: c, r: r)
                    .stroke(Palette.gray, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                polygon(values: values, c: c, r: r)
                    .fill(Palette.graphiteDark.opacity(0.10))
                polygon(values: values, c: c, r: r)
                    .stroke(Palette.graphiteDark, style: StrokeStyle(lineWidth: 2.4, lineJoin: .round))
                ForEach(0..<labels.count, id: \.self) { i in
                    let weak = values[i] == (values.min() ?? 0)
                    let p = point(i, 100 + 22, c: c, r: r)
                    VStack(spacing: 0) {
                        Text(labels[i]).font(.system(size: 11)).foregroundStyle(weak ? Palette.negText : Palette.ink)
                        Text("\(Int(values[i]))").font(.system(size: 12, weight: .bold)).foregroundStyle(weak ? Palette.negText : Palette.ink)
                    }
                    .position(p)
                }
            }
        }
    }

    private func point(_ i: Int, _ v: Double, c: CGPoint, r: CGFloat) -> CGPoint {
        let a = -Double.pi / 2 + Double(i) * 2 * Double.pi / Double(labels.count)
        let rad = r * CGFloat(max(0, (v - floor) / (100 - floor)))
        return CGPoint(x: c.x + rad * CGFloat(cos(a)), y: c.y + rad * CGFloat(sin(a)))
    }

    private func polygon(values: [Double], c: CGPoint, r: CGFloat) -> Path {
        Path { p in
            for (i, v) in values.enumerated() {
                let pt = point(i, v, c: c, r: r)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
        }
    }
}

// MARK: - Precio desde la entrada, con objetivo y stop

struct PriceStrip: View {
    let entry: Double
    let stop: Double
    let target: Double
    let last: Double

    private var stopRef: Double { stop == 0 ? entry - (target - entry) : stop }
    private var lo: Double { min(stopRef, target) }
    private var hi: Double { max(stopRef, target) }

    private func yOf(_ v: Double, _ h: CGFloat) -> CGFloat {
        let range = max(hi - lo, 0.0000001)
        return h - 12 - (h - 24) * CGFloat((v - lo) / range)
    }

    private func zone(from a: CGFloat, to b: CGFloat, width: CGFloat, color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: width, height: max(0, abs(b - a)))
            .offset(y: min(a, b))
    }

    private func line(at y: CGFloat, color: Color, label: String, width: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Path { p in
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: width, y: y))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1.4, dash: [5, 4]))
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
                .offset(x: 4, y: y - 17)
        }
    }

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let h = g.size.height
            let pts: [CGPoint] = (0..<14).map { i in
                let t = Double(i) / 13
                let wobble = sin(Double(i) * 1.3) * 0.06
                let v = entry + (last - entry) * t + (hi - lo) * wobble * (1 - t)
                return CGPoint(x: w * CGFloat(t), y: yOf(v, h))
            }
            ZStack(alignment: .topLeading) {
                zone(from: yOf(entry, h), to: yOf(target, h), width: w, color: Palette.posBg.opacity(0.55))
                zone(from: yOf(entry, h), to: yOf(stopRef, h), width: w, color: Palette.negBg.opacity(0.65))
                line(at: yOf(target, h), color: Palette.pos, label: "Objetivo \(Fmt.price(target))", width: w)
                line(at: yOf(entry, h), color: Palette.gray, label: "Entrada \(Fmt.price(entry))", width: w)
                line(at: yOf(stopRef, h), color: Palette.neg, label: stop == 0 ? "Sin stop" : "Stop \(Fmt.price(stop))", width: w)
                Path { p in
                    for (i, pt) in pts.enumerated() {
                        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                    }
                }
                .stroke(Palette.graphiteDark, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
                if let lastPt = pts.last {
                    Circle().fill(Palette.graphiteDark).frame(width: 11, height: 11)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                        .position(lastPt)
                }
            }
        }
    }
}
