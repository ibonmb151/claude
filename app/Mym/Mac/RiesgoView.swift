#if os(macOS)
import SwiftUI

struct RiesgoView: View {
    @EnvironmentObject var store: AppStore

    private var cell: BotCell {
        store.data.cells.first { $0.id == store.selectedCellId } ?? store.data.cells[0]
    }

    var body: some View {
        let d = store.data
        ScreenScroll {
            HStack {
                Heading("Riesgo", info: "Límites en capas, salud de las células, exposición y lo que ha pasado hoy", size: 20)
                Button("Reconocer todos") { store.acknowledgeAll() }
                    .buttonStyle(MymButtonStyle(kind: .secondary, compact: true))
            }

            ResponsiveRow {
                LayersCard(layers: d.layers).frame(maxWidth: .infinity)
                healthCard(d).frame(maxWidth: .infinity)
            }

            ResponsiveRow {
                ExposureCard(exposures: d.exposures, totalLots: d.exposureLots, pct: d.exposurePct).frame(maxWidth: .infinity)
                alertsCard(d).frame(maxWidth: .infinity)
            }

            commandsCard()
        }
    }

    private func healthCard(_ d: Snapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Heading("Salud · \(cell.id)", info: "Seis medidas técnicas de la célula; la escala empieza en 40. Línea discontinua: célula de referencia. Rojo: el punto más débil") {
                HStack(spacing: 4) {
                    ForEach(d.cells.filter { $0.health != .paused }) { c in
                        Button(c.shortName) { store.selectedCellId = c.id }
                            .buttonStyle(.plain)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(c.id == store.selectedCellId ? Color.white : Palette.ink2)
                            .padding(.horizontal, 9)
                            .frame(height: 22)
                            .background(c.id == store.selectedCellId ? Palette.graphiteDark : Palette.neutralBg, in: Capsule())
                    }
                }
            }
            HStack(alignment: .center, spacing: 8) {
                RadarChart(labels: ["Latido", "Latencia", "Rechazos", "Reloj", "Datos", "Conciliación"],
                           values: cell.healthScores.map { max($0, 40) },
                           reference: [96, 88, 92, 70, 97, 100])
                    .frame(height: 260)
                VStack(spacing: 4) {
                    ZStack {
                        RingsView(rings: [RingSpec(progress: avg / 100, color: Palette.pos)], lineWidth: 9, gap: 0)
                        Text("\(Int(avg))").font(.system(size: 22, weight: .bold)).foregroundStyle(Palette.ink)
                    }
                    .frame(width: 84, height: 84)
                    Text("salud media").font(.system(size: 12)).foregroundStyle(Palette.ink2)
                    Text("Más débil").font(.system(size: 12, weight: .bold)).foregroundStyle(Palette.negText).padding(.top, 8)
                    Text(weakest).font(.system(size: 12)).foregroundStyle(Palette.ink)
                }
                .frame(width: 110)
            }
        }
        .card(Layout.card)
    }

    private var avg: Double {
        guard !cell.healthScores.isEmpty else { return 0 }
        return cell.healthScores.reduce(0, +) / Double(cell.healthScores.count)
    }

    private var weakest: String {
        let names = ["Latido", "Latencia", "Rechazos", "Reloj", "Datos", "Conciliación"]
        guard let m = cell.healthScores.min(), let i = cell.healthScores.firstIndex(of: m) else { return "—" }
        return "\(names[i]) · \(Int(m))"
    }

    private func alertsCard(_ d: Snapshot) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Heading("Avisos", info: "Lo que ha pasado hoy, de más reciente a más antiguo, con su manual si lo tiene") {
                Pill(text: "\(d.openAlerts.count) abiertos", tone: d.openAlerts.isEmpty ? .good : .bad)
            }
            ForEach(d.alerts) { a in
                HStack(spacing: 10) {
                    IncidentRow(alert: a)
                    if let action = a.action, !a.acknowledged {
                        Button(action) { store.acknowledge(a.id) }
                            .buttonStyle(MymButtonStyle(kind: .secondary, compact: true))
                    }
                }
                Divider()
            }
        }
        .card(Layout.card)
    }

    private func commandsCard() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Heading("Comandos firmados", info: "Ed25519 · caducidad de 2 minutos · número de un solo uso")
            ForEach(store.log) { c in
                HStack(spacing: 12) {
                    Text(c.time).font(.system(size: 12, design: .monospaced)).foregroundStyle(Palette.ink2).frame(width: 82, alignment: .leading)
                    Text(c.name).font(.system(size: 13, weight: .semibold, design: .monospaced)).frame(width: 130, alignment: .leading)
                    Text(c.cell).font(.system(size: 12, design: .monospaced)).frame(width: 90, alignment: .leading)
                    Text(c.key).font(.system(size: 12, design: .monospaced)).foregroundStyle(Palette.ink2).frame(width: 64, alignment: .leading)
                    Pill(text: c.accepted ? "Aceptado" : "Rechazado", tone: c.accepted ? .good : .bad)
                    Text(c.result).font(.system(size: 12)).foregroundStyle(Palette.ink2).lineLimit(1)
                    Spacer()
                }
                .padding(.vertical, 4)
                Divider()
            }
        }
        .card(Layout.card)
    }
}
#endif
