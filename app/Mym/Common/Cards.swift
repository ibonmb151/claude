import SwiftUI

// MARK: - Cifra con mini gráfica

struct KPICard: View {
    let title: String
    let info: String
    let value: String
    let pill: String
    var tone: Tone = .neutral
    let series: [Double]
    var color: Color = Palette.graphite
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.ink2)
                InfoButton(text: info)
            }
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(value)
                        .font(.system(size: compact ? 22 : 28, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                        .monospacedDigit()
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Pill(text: pill, tone: tone)
                }
                Spacer(minLength: 6)
                Sparkline(values: series, color: color)
                    .frame(width: compact ? 70 : 96, height: compact ? 28 : 36)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(Layout.cardSmall)
    }
}

// MARK: - Mapa de la red

struct NetworkMap: View {
    private struct Node {
        let name: String
        let symbol: String
        let color: Color
        let x: CGFloat
        let y: CGFloat
        var ring: Bool = false
    }

    private struct Edge {
        let a: Int
        let b: Int
        let label: String
        let color: Color
        var dashed: Bool = false
        var bend: CGFloat = 0.12
    }

    private let nodes: [Node] = [
        Node(name: "Londres", symbol: "server.rack", color: Palette.teal, x: 0.44, y: 0.42, ring: true),
        Node(name: "Bilbao", symbol: "server.rack", color: Palette.paused, x: 0.14, y: 0.76),
        Node(name: "Bróker", symbol: "building.columns", color: Palette.graphite, x: 0.82, y: 0.24),
        Node(name: "Datos", symbol: "waveform.path.ecg", color: Palette.info, x: 0.82, y: 0.68),
        Node(name: "Control", symbol: "lock", color: Palette.gray, x: 0.14, y: 0.22),
        Node(name: "Jev", symbol: "safari", color: Palette.magenta, x: 0.48, y: 0.86)
    ]

    private let edges: [Edge] = [
        Edge(a: 0, b: 2, label: "0,9 ms", color: Palette.info),
        Edge(a: 0, b: 3, label: "1,2 ms", color: Palette.teal),
        Edge(a: 4, b: 0, label: "firmado", color: Palette.gray),
        Edge(a: 5, b: 0, label: "pesos", color: Palette.magenta),
        Edge(a: 1, b: 0, label: "28 ms", color: Palette.paused, dashed: true)
    ]

    var body: some View {
        GeometryReader { g in
            ZStack {
                DotGrid()
                ForEach(0..<edges.count, id: \.self) { i in
                    edgeView(edges[i], size: g.size)
                }
                ForEach(0..<nodes.count, id: \.self) { i in
                    nodeView(nodes[i])
                        .position(x: g.size.width * nodes[i].x, y: g.size.height * nodes[i].y)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func pointOf(_ n: Node, _ size: CGSize) -> CGPoint {
        CGPoint(x: size.width * n.x, y: size.height * n.y)
    }

    private func edgeView(_ e: Edge, size: CGSize) -> some View {
        let a = pointOf(nodes[e.a], size)
        let b = pointOf(nodes[e.b], size)
        let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        let control = CGPoint(x: mid.x + (b.y - a.y) * e.bend, y: mid.y - (b.x - a.x) * e.bend)
        let label = CGPoint(x: (mid.x + control.x) / 2, y: (mid.y + control.y) / 2)
        return ZStack {
            Path { p in
                p.move(to: a)
                p.addQuadCurve(to: b, control: control)
            }
            .stroke(e.color, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, dash: e.dashed ? [6, 5] : []))
            Text(e.label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Palette.ink2)
                .padding(.horizontal, 8)
                .padding(.vertical, 1)
                .background(Capsule().fill(Color.white))
                .overlay(Capsule().stroke(Palette.line, lineWidth: 1))
                .position(label)
        }
    }

    private func nodeView(_ n: Node) -> some View {
        HStack(spacing: 8) {
            IconTile(symbol: n.symbol, color: n.color, size: 30, corner: 9)
            Text(n.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.ink)
        }
        .padding(.leading, 6)
        .padding(.trailing, 13)
        .padding(.vertical, 6)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(n.ring ? n.color : Color.clear, lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 4)
    }
}

struct DotGrid: View {
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0xF7F7F4)))
            var x: CGFloat = 9
            while x < size.width {
                var y: CGFloat = 9
                while y < size.height {
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)), with: .color(Color(hex: 0xD5D5CE)))
                    y += 18
                }
                x += 18
            }
        }
    }
}

// MARK: - Fila de orden en tránsito

struct TransitRow: View {
    let order: Order
    let strategy: Strategy?

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                IconTile(symbol: strategy?.symbol ?? "arrow.up.right", color: strategy?.color ?? Palette.gray, size: 22, corner: 6)
                Text(order.instrument).font(.system(size: 14, weight: .bold)).foregroundStyle(Palette.ink)
                Pill(text: order.side.label, tone: order.side == .buy ? .info : .neutral)
                Spacer()
                Text(order.time).font(.system(size: 12)).monospacedDigit().foregroundStyle(Palette.ink2)
            }
            StepBar(done: order.status.steps, doneColor: order.status == .filled ? Palette.pos : Palette.graphiteDark)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Flota en donut

struct FleetDonutCard: View {
    let cells: [BotCell]

    private var slices: [DonutSlice] {
        [
            DonutSlice(label: "Activas", value: Double(cells.filter { $0.health == .ok }.count), color: Palette.pos),
            DonutSlice(label: "Aviso", value: Double(cells.filter { $0.health == .warning }.count), color: Palette.warn),
            DonutSlice(label: "Revisar", value: Double(cells.filter { $0.health == .critical }.count), color: Palette.neg),
            DonutSlice(label: "Pausadas", value: Double(cells.filter { $0.health == .paused }.count), color: Palette.graphiteSoft)
        ].filter { $0.value > 0 }
    }

    var body: some View {
        HStack(spacing: 16) {
            DonutView(slices: slices, lineWidth: 14, centerText: "\(cells.count)")
                .frame(width: 92, height: 92)
            VStack(alignment: .leading, spacing: 6) {
                Heading("Flota", info: "Estado de las cinco células")
                ForEach(slices) { s in
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3).fill(s.color).frame(width: 9, height: 9)
                        Text(s.label).font(.system(size: 13)).foregroundStyle(Palette.ink)
                        Spacer()
                        Text("\(Int(s.value))").font(.system(size: 13)).foregroundStyle(Palette.ink2).monospacedDigit()
                    }
                }
            }
        }
        .card(Layout.cardSmall)
    }
}

// MARK: - Incidencias

struct IncidentRow: View {
    let alert: AlertItem
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(alert.level.color).frame(width: 26, height: 26)
                Image(systemName: alert.acknowledged ? "checkmark" : "exclamationmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(alert.title).font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.ink)
                Text(alert.subtitle).font(.system(size: 12)).foregroundStyle(Palette.ink2).lineLimit(1)
            }
            Spacer(minLength: 6)
            Text(alert.time).font(.system(size: 12)).foregroundStyle(Palette.ink2).monospacedDigit()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Gráfica «Por hora» con cabecera

struct HourlyCard: View {
    let snapshot: Snapshot
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Heading("Por hora", info: "Resultado de cada hora de hoy y su acumulado, con las sesiones de Asia, Londres y Nueva York de fondo") {
                Text(Fmt.signedPct(snapshot.dayPct, 2))
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(snapshot.dayPct < 0 ? Palette.negText : Palette.posText)
                    .monospacedDigit()
            }
            HourlyChart(bars: snapshot.hourly)
                .frame(minHeight: 150)
        }
        .card(Layout.card)
    }
}
