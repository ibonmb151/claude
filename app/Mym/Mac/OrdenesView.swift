#if os(macOS)
import SwiftUI

struct OrdenesView: View {
    @EnvironmentObject var store: AppStore

    private var order: Order {
        store.data.orders.first { $0.id == store.selectedOrderId } ?? store.data.orders[0]
    }

    var body: some View {
        let d = store.data
        HStack(alignment: .top, spacing: 14) {
            // Lista
            VStack(alignment: .leading, spacing: 10) {
                Heading("Órdenes", info: "Las de hoy, de la más reciente a la más antigua. El embudo resume cuántas llegan a ejecutarse")
                HStack(spacing: 6) {
                    funnelCell("\(d.funnel.signals)", "señales")
                    funnelCell("\(d.funnel.riskOk)", "riesgo ✓")
                    funnelCell("\(d.funnel.sent)", "enviadas")
                    funnelCell("\(d.funnel.filled)", "ejecutadas")
                }
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(d.orders) { o in
                            orderRow(o)
                        }
                    }
                }
            }
            .padding(14)
            .frame(width: 330)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)

            // Seguimiento
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header(order)
                    milestones(order)
                    timeBar(d)
                    priceCard(order)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card(20)
            }

            // Detalle
            VStack(alignment: .leading, spacing: 2) {
                Heading("Detalle", info: "Todo lo que el diario sabe de esta orden")
                    .padding(.bottom, 6)
                Group {
                    detailRow("Estrategia", "\(order.strategyId) · v\(d.strategy(order.strategyId)?.version ?? 1)")
                    detailRow("Célula", order.cellId)
                    detailRow("Cuenta", d.cell(order.cellId)?.accountId ?? "—")
                    detailRow("Volumen", Fmt.lots(order.lots))
                    detailRow("Entrada", Fmt.price(order.entry))
                    detailRow("Stop", order.stop == 0 ? "sin stop" : Fmt.price(order.stop))
                    detailRow("Objetivo", Fmt.price(order.target))
                    detailRow("Diario", "f20a…77c9")
                }
                Spacer()
                Button("Ver en el diario") {}
                    .buttonStyle(MymButtonStyle(kind: .secondary))
                Button("Cerrar posición") { store.requestPause(order.cellId) }
                    .buttonStyle(MymButtonStyle(kind: .primary))
                    .padding(.top, 6)
            }
            .padding(18)
            .frame(width: 280)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
    }

    private func funnelCell(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value).font(.system(size: 17, weight: .bold)).monospacedDigit().foregroundStyle(Palette.ink)
            Text(label).font(.system(size: 11, weight: .semibold)).foregroundStyle(Palette.ink2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.bg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func orderRow(_ o: Order) -> some View {
        let selected = o.id == store.selectedOrderId
        let strategy = store.data.strategy(o.strategyId)
        return Button {
            store.selectedOrderId = o.id
        } label: {
            HStack(spacing: 11) {
                IconTile(symbol: strategy?.symbol ?? "arrow.up.right", color: strategy?.color ?? Palette.gray, size: 30)
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 5) {
                        Text(o.instrument).font(.system(size: 14, weight: .semibold))
                        Text("\(o.side.label) \(Fmt.comma(o.lots, 2))").font(.system(size: 13)).foregroundStyle(Palette.ink2)
                    }
                    Text("\(o.id) · \(o.cellId.replacingOccurrences(of: "c-", with: ""))")
                        .font(.system(size: 11, design: .monospaced)).foregroundStyle(Palette.ink2)
                }
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 3) {
                    Pill(text: o.status.label, tone: o.status.tone)
                    Text(o.time).font(.system(size: 11)).foregroundStyle(Palette.ink2).monospacedDigit()
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(selected ? Palette.selection : Color.clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Palette.ink)
    }

    private func header(_ o: Order) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(o.id).font(.system(size: 12, design: .monospaced)).foregroundStyle(Palette.ink2)
                Text("\(o.instrument) · \(o.side.label) \(Fmt.comma(o.lots, 2))")
                    .font(.system(size: 26, weight: .bold)).foregroundStyle(Palette.ink)
                HStack(spacing: 6) {
                    Pill(text: o.status.label, tone: o.status.tone)
                    Pill(text: o.strategyId)
                    Pill(text: o.cellId)
                }
            }
            Spacer()
            if let pnl = o.pnl {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Fmt.eurDecimals(pnl))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(pnl >= 0 ? Palette.posText : Palette.negText)
                        .monospacedDigit()
                    Text(Fmt.price(o.last)).font(.system(size: 12)).foregroundStyle(Palette.ink2).monospacedDigit()
                }
            }
        }
    }

    private func milestones(_ o: Order) -> some View {
        let names = ["Señal", "Riesgo", "Enviada", "Aceptada", "Ejecutada", "Stop", "Cierre"]
        let times = ["\(o.time).012", "+7 ms", "+12 ms", "+609 ms", "+62 ms", "+33 ms", "pendiente"]
        let reached = o.status == .closed ? 7 : min(6, o.status.steps + 2)
        return HStack(alignment: .top, spacing: 0) {
            ForEach(0..<names.count, id: \.self) { i in
                VStack(spacing: 6) {
                    ZStack {
                        Circle().fill(i < reached ? Palette.graphiteDark : Palette.card)
                            .frame(width: 26, height: 26)
                            .overlay(Circle().stroke(Palette.graphiteDark, lineWidth: 3))
                        if i < reached {
                            Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(Color.white)
                        }
                    }
                    Text(names[i]).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink)
                    Text(times[i]).font(.system(size: 11)).foregroundStyle(Palette.ink2).monospacedDigit()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func timeBar(_ d: Snapshot) -> some View {
        let total = d.hops.reduce(0) { $0 + $1.ms }
        return VStack(alignment: .leading, spacing: 8) {
            Heading("Tiempo · \(total) ms", info: "A escala: cuánto tarda cada tramo. El bróker se lleva la mayor parte; nuestro código, 52 ms")
            GeometryReader { g in
                HStack(spacing: 2) {
                    ForEach(d.hops) { hop in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(hop.color)
                            .frame(width: max(4, (g.size.width - 8) * CGFloat(hop.ms) / CGFloat(total)))
                    }
                }
            }
            .frame(height: 30)
            HStack(spacing: 14) {
                ForEach(d.hops) { hop in
                    HStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 3).fill(hop.color).frame(width: 9, height: 9)
                        Text("\(hop.name) \(hop.ms) ms").font(.system(size: 12)).foregroundStyle(Palette.ink2)
                    }
                }
            }
        }
    }

    private func priceCard(_ o: Order) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Heading("Precio", info: "Desde la entrada, con el objetivo arriba y el stop abajo")
            PriceStrip(entry: o.entry, stop: o.stop, target: o.target, last: o.last)
                .frame(height: 190)
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Palette.ink2)
            Spacer()
            Text(value).fontWeight(.semibold).foregroundStyle(Palette.ink).monospacedDigit()
        }
        .font(.system(size: 13))
        .padding(.vertical, 8)
        .overlay(Rectangle().fill(Palette.line).frame(height: 1), alignment: .bottom)
    }
}
#endif
