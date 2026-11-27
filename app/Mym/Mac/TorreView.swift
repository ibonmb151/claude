#if os(macOS)
import SwiftUI

/// Inicio: un número por área y un enlace a su sitio. Sin listas ni gráficas completas.
///  Dinero → Cuentas · Hoy → Resultados · Órdenes y respuesta → En vivo · Robots → Flota · Avisos → Riesgo
struct TorreView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        let d = store.data
        ScreenScroll {
            ResponsiveRow(breakpoint: 980) {
                link(.cuentas) {
                    KPICard(title: "Dinero total", info: "Suma de todas las cuentas. El detalle, en Cuentas",
                            value: Fmt.eur(d.equity), pill: Fmt.signedPct(d.equityDeltaPct) + " semana", tone: .good,
                            series: d.equitySeries, color: Palette.pos)
                }
                link(.resultados) {
                    KPICard(title: "Hoy", info: "Resultado del día. El detalle, en Resultados",
                            value: Fmt.signedPct(d.dayPct, 2), pill: Fmt.pct(d.dayLimitUsed * 100) + " del límite", tone: .warn,
                            series: d.dayPctSeries, color: Palette.neg)
                }
                link(.envivo) {
                    KPICard(title: "Órdenes", info: "Enviadas hoy y rechazadas. Lo que pasa ahora, en En vivo",
                            value: "\(d.ordersToday)", pill: "\(d.rejectedToday) rechazadas", tone: .neutral,
                            series: d.ordersSeries, color: Palette.info)
                }
                link(.envivo) {
                    KPICard(title: "Respuesta del bróker", info: "Mediana hasta que acepta la orden",
                            value: Fmt.ms(d.latencyMs), pill: "p99 \(d.latencyP99)", tone: .info,
                            series: d.latencySeries, color: Palette.violet)
                }
            }

            ResponsiveRow {
                link(.flota) { FleetDonutCard(cells: d.cells) }
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 2) {
                    Heading("Avisos", info: "Lo que necesita a una persona, de más a menos grave") {
                        Button("Ver todos") { store.module = .riesgo }
                            .buttonStyle(.plain)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Palette.infoText)
                    }
                    ForEach(d.openAlerts.prefix(3)) { alert in
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
                .card(Layout.card)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func link<Content: View>(_ module: Module, @ViewBuilder content: () -> Content) -> some View {
        Button { store.module = module } label: { content() }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
    }
}
#endif
