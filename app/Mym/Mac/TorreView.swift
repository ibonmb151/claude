#if os(macOS)
import SwiftUI

struct TorreView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        let d = store.data
        ScreenScroll {
            // Cifras
            HStack(spacing: 14) {
                KPICard(title: "Equity", info: "Suma de todas las cuentas",
                        value: Fmt.eur(d.equity), pill: Fmt.signedPct(d.equityDeltaPct) + " hoy", tone: .good,
                        series: d.equitySeries, color: Palette.pos)
                KPICard(title: "Hoy", info: "Resultado del día. Límite global: −2 %",
                        value: Fmt.signedPct(d.dayPct, 2), pill: Fmt.pct(d.dayLimitUsed * 100) + " del límite", tone: .warn,
                        series: d.dayPctSeries, color: Palette.neg)
                KPICard(title: "Órdenes", info: "Órdenes enviadas hoy y rechazadas por el bróker",
                        value: "\(d.ordersToday)", pill: "\(d.rejectedToday) rechazadas", tone: .neutral,
                        series: d.ordersSeries, color: Palette.info)
                KPICard(title: "Latencia", info: "Mediana hasta ACCEPTED. Percentil 99: \(d.latencyP99) ms",
                        value: Fmt.ms(d.latencyMs), pill: "p99 \(d.latencyP99)", tone: .info,
                        series: d.latencySeries, color: Palette.violet)
            }

            // Red y órdenes en tránsito
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Heading("Red", info: "Sedes, bróker, datos y Jev con la latencia de cada tramo. Continua: activo. Discontinua: en espera")
                    NetworkMap()
                        .frame(height: 290)
                }
                .card(16)
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 2) {
                    Heading("En tránsito", info: "Órdenes de los últimos segundos y su parada actual") {
                        Button("Todo") { store.module = .ordenes }
                            .buttonStyle(.plain)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Palette.infoText)
                    }
                    ForEach(d.orders.prefix(4)) { order in
                        Button {
                            store.selectedOrderId = order.id
                            store.module = .ordenes
                        } label: {
                            TransitRow(order: order, strategy: d.strategy(order.strategyId))
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
                .card(16)
                .frame(width: 340)
            }

            // Por hora, flota e incidencias
            HStack(alignment: .top, spacing: 14) {
                HourlyCard(snapshot: d)
                    .frame(maxWidth: .infinity)

                VStack(spacing: 14) {
                    Button { store.module = .flota } label: {
                        FleetDonutCard(cells: d.cells)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 2) {
                        Heading("Incidencias", info: "Lo que necesita a una persona, de más a menos grave")
                        ForEach(d.openAlerts) { alert in
                            Button { store.module = .riesgo } label: {
                                IncidentRow(alert: alert)
                            }
                            .buttonStyle(.plain)
                        }
                        if d.openAlerts.isEmpty {
                            Text("Nada pendiente").font(.system(size: 13)).foregroundStyle(Palette.ink2).padding(.vertical, 8)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card(14)
                }
                .frame(width: 340)
            }
        }
    }
}
#endif
