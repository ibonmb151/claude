import WidgetKit
import SwiftUI


// MARK: - Fondo del widget (iOS 17 / macOS 14 usan containerBackground; antes, un fondo normal)

extension View {
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        #if compiler(>=5.9)
        if #available(iOS 17.0, macOS 14.0, *) {
            self.containerBackground(color, for: .widget)
        } else {
            self.padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(color)
        }
        #else
        self.padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(color)
        #endif
    }
}

// MARK: - Datos del widget (ficticios)

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: Snapshot
}

struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: Date(), snapshot: MockData.make())
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let now = Date()
        var entries: [SnapshotEntry] = []
        for step in 0..<4 {
            let date = Calendar.current.date(byAdding: .minute, value: step * 15, to: now) ?? now
            var snap = MockData.make(now: date)
            // Pequeña variación ficticia para que se note que se actualiza.
            snap.latencyMs += step * 7
            snap.ordersToday += step * 3
            entries.append(SnapshotEntry(date: date, snapshot: snap))
        }
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now
        completion(Timeline(entries: entries, policy: .after(next)))
    }
}

// MARK: - Equity

struct EquityWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry

    var body: some View {
        let s = entry.snapshot
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: "chart.bar.xaxis").font(.system(size: 11, weight: .bold)).foregroundStyle(Palette.graphiteDark)
                Text("Equity").font(.system(size: 12, weight: .bold)).foregroundStyle(Palette.ink2)
                Spacer()
                if family == .systemMedium {
                    Pill(text: s.criticalCount > 0 ? "\(s.criticalCount) avisos" : "Todo bien", tone: s.criticalCount > 0 ? .bad : .good)
                }
            }
            Text(Fmt.eur(s.equity))
                .font(.system(size: family == .systemSmall ? 22 : 30, weight: .bold))
                .foregroundStyle(Palette.ink)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Pill(text: Fmt.signedPct(s.equityDeltaPct) + " hoy", tone: .good)
            Spacer(minLength: 2)
            Sparkline(values: s.equitySeries, color: Palette.pos, lineWidth: 2.4, fill: true)
                .frame(height: family == .systemSmall ? 34 : 52)
        }
        .widgetBackground(Palette.card)
    }
}

struct EquityWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MymEquity", provider: SnapshotProvider()) { entry in
            EquityWidgetView(entry: entry)
        }
        .configurationDisplayName("Equity")
        .description("Equity total y su evolución de las últimas dos semanas.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Hoy (anillos)

struct RingsWidgetView: View {
    let entry: SnapshotEntry

    var body: some View {
        let s = entry.snapshot
        VStack(spacing: 6) {
            RingsView(rings: [
                RingSpec(progress: s.dayLimitUsed, color: Palette.warn),
                RingSpec(progress: s.exposurePct / 100, color: Palette.graphiteDark)
            ], lineWidth: 11, gap: 3)
            .overlay(
                Text(Fmt.pct(s.dayLimitUsed * 100))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Palette.ink)
            )
            Text("Hoy · en juego \(Fmt.pct(s.exposurePct))")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Palette.ink2)
        }
        .widgetBackground(Palette.card)
    }
}

struct RingsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MymRings", provider: SnapshotProvider()) { entry in
            RingsWidgetView(entry: entry)
        }
        .configurationDisplayName("Hoy")
        .description("Pérdida del día frente a su límite y exposición.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Robots

struct FleetWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry

    var body: some View {
        let s = entry.snapshot
        let shown = family == .systemMedium ? Array(s.cells.prefix(4)) : s.cells
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "server.rack").font(.system(size: 11, weight: .bold)).foregroundStyle(Palette.teal)
                Text("Robots").font(.system(size: 12, weight: .bold)).foregroundStyle(Palette.ink2)
                Spacer()
                Pill(text: s.openAlerts.isEmpty ? "Todo bien" : "\(s.openAlerts.count) avisos",
                     tone: s.openAlerts.isEmpty ? .good : .warn)
            }
            ForEach(shown) { cell in
                HStack(spacing: 8) {
                    StatusDot(color: cell.health.color)
                    Text(cell.id).font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.ink)
                    Spacer()
                    Text(cell.health.label).font(.system(size: 12)).foregroundStyle(Palette.ink2)
                    Text(Fmt.signedPct(cell.dayPct, 1))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(cell.dayPct < 0 ? Palette.negText : Palette.ink)
                        .monospacedDigit()
                        .frame(width: 58, alignment: .trailing)
                }
            }
            if family != .systemMedium {
                Spacer(minLength: 4)
                HourlyChart(bars: s.hourly, sessions: false)
                    .frame(height: 90)
            }
        }
        .widgetBackground(Palette.card)
    }
}

struct FleetWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MymFleet", provider: SnapshotProvider()) { entry in
            FleetWidgetView(entry: entry)
        }
        .configurationDisplayName("Robots")
        .description("Estado y resultado de hoy de cada robot.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Pantalla de bloqueo (solo iPhone)

#if os(iOS)
struct LockWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry

    var body: some View {
        let s = entry.snapshot
        switch family {
        case .accessoryCircular:
            Gauge(value: s.dayLimitUsed) {
                Text("Día")
            } currentValueLabel: {
                Text("\(Int(s.dayLimitUsed * 100))%")
            }
            .gaugeStyle(.accessoryCircular)
            .widgetBackground(Color.clear)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("Equity \(Fmt.eur(s.equity))").font(.system(size: 13, weight: .bold)).lineLimit(1)
                Text("Hoy \(Fmt.signedPct(s.dayPct, 2)) · \(s.openAlerts.count) avisos").font(.system(size: 12))
                Gauge(value: s.dayLimitUsed) { EmptyView() }
                    .gaugeStyle(.accessoryLinear)
            }
            .widgetBackground(Color.clear)
        default:
            Text("\(Fmt.signedPct(s.dayPct, 2)) · \(s.openAlerts.count) avisos")
                .widgetBackground(Color.clear)
        }
    }
}

struct LockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MymLock", provider: SnapshotProvider()) { entry in
            LockWidgetView(entry: entry)
        }
        .configurationDisplayName("Estado")
        .description("Resultado del día y avisos, en la pantalla de bloqueo.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
#endif

// MARK: - Paquete

@main
struct MymWidgetBundle: WidgetBundle {
    var body: some Widget {
        EquityWidget()
        RingsWidget()
        FleetWidget()
        CuentasWidget()
        EnVivoWidget()
        AvisosWidget()
        ResultadosWidget()
        #if os(iOS)
        LockWidget()
        RiesgoLockWidget()
        #endif
    }
}
