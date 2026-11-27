#if os(macOS)
import SwiftUI

/// Órdenes de hoy. A la izquierda, la lista; a la derecha, lo que importa de la elegida:
/// qué ha pasado, cuánto lleva ganado o perdido, y el precio frente a su objetivo y su stop.
struct OrdenesView: View {
    @EnvironmentObject var store: AppStore

    private var order: Order {
        store.data.orders.first { $0.id == store.selectedOrderId } ?? store.data.orders[0]
    }

    var body: some View {
        let d = store.data
        HStack(alignment: .top, spacing: Layout.gap) {
            VStack(alignment: .leading, spacing: 10) {
                Heading("Órdenes de hoy", info: "Cuántas llegan a ejecutarse, en En vivo")
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(d.orders) { o in
                            orderRow(o)
                        }
                    }
                }
            }
            .padding(Layout.cardSmall)
            .frame(width: 340)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)

            ScrollView {
                detail(order, d)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card(Layout.card)
            }
        }
        .padding(.horizontal, Layout.page)
        .padding(.bottom, Layout.page)
    }

    // MARK: Lista

    private func orderRow(_ o: Order) -> some View {
        let selected: Bool = o.id == store.selectedOrderId
        return Button {
            store.selectedOrderId = o.id
        } label: {
            HStack(spacing: 12) {
                Image(systemName: o.side == .buy ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 32, height: 32)
                    .background(Palette.neutralBg, in: Circle())
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(o.side.label) \(o.instrument)").font(.system(size: 14, weight: .semibold))
                    Text(o.time).font(.system(size: 12)).foregroundStyle(Palette.ink2).monospacedDigit()
                }
                Spacer(minLength: 4)
                Pill(text: o.status.label, tone: o.status.tone)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(selected ? Palette.selection : Color.clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Palette.ink)
    }

    // MARK: Detalle

    private func isOpen(_ o: Order) -> Bool {
        o.status == .accepted || o.status == .filled || o.status == .noStop
    }

    /// Qué ha pasado, en una frase.
    private func sentence(_ o: Order) -> String {
        let result: String = o.pnl.map { Fmt.comma(abs($0), 2) + " €" } ?? ""
        switch o.status {
        case .riskOk: return "Revisada. A punto de enviarse al bróker."
        case .sent: return "Enviada al bróker. Esperando su respuesta."
        case .accepted, .filled: return (o.pnl ?? 0) >= 0 ? "Abierta. Ahora mismo va ganando \(result)." : "Abierta. Ahora mismo va perdiendo \(result)."
        case .noStop: return "Abierta, pero sin protección: no tiene stop."
        case .rejected: return "El bróker la rechazó. No se abrió."
        case .closed: return (o.pnl ?? 0) >= 0 ? "Cerrada con una ganancia de \(result)." : "Cerrada con una pérdida de \(result)."
        }
    }

    private func detail(_ o: Order, _ d: Snapshot) -> some View {
        let strategyName: String = d.strategy(o.strategyId)?.id ?? o.strategyId
        let total: Int = d.hops.reduce(0) { $0 + $1.ms }
        return VStack(alignment: .leading, spacing: Layout.gap) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(o.side.label) \(o.instrument)")
                        .font(.system(size: 28, weight: .bold)).foregroundStyle(Palette.ink)
                    Text(sentence(o)).font(.system(size: 15)).foregroundStyle(Palette.ink2)
                }
                Spacer()
                if let pnl = o.pnl {
                    Text(Fmt.eurDecimals(pnl))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(pnl >= 0 ? Palette.posText : Palette.negText)
                        .monospacedDigit()
                }
            }

            steps(o)

            VStack(alignment: .leading, spacing: 8) {
                Heading("Precio", info: "Desde la entrada, con el objetivo arriba y el stop abajo")
                PriceStrip(entry: o.entry, stop: o.stop, target: o.target, last: o.last)
                    .frame(height: 220)
            }

            HStack(alignment: .center) {
                Text("\(o.cellId) · \(strategyName) · \(Fmt.comma(o.lots, 2)) lotes")
                    .font(.system(size: 13)).foregroundStyle(Palette.ink2)
                if o.status == .accepted || o.status == .filled || o.status == .closed {
                    Text("· tardó \(Fmt.comma(Double(total) / 1000, 1)) s en abrirse")
                        .font(.system(size: 13)).foregroundStyle(Palette.ink2)
                }
                Spacer()
                if isOpen(o) {
                    Button("Cerrar posición") { store.requestPause(o.cellId) }
                        .buttonStyle(MymButtonStyle(kind: .primary))
                }
            }
        }
    }

    /// Cuatro pasos, sin tiempos: revisada, enviada, abierta y cerrada.
    private func steps(_ o: Order) -> some View {
        let names: [String] = ["Revisada", "Enviada", "Abierta", "Cerrada"]
        let reached: Int
        switch o.status {
        case .riskOk: reached = 1
        case .sent, .rejected: reached = 2
        case .accepted, .filled, .noStop: reached = 3
        case .closed: reached = 4
        }
        return HStack(spacing: 0) {
            ForEach(0..<names.count, id: \.self) { i in
                HStack(spacing: 0) {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle().fill(i < reached ? Palette.graphiteDark : Palette.card)
                                .frame(width: 24, height: 24)
                                .overlay(Circle().stroke(i < reached ? Palette.graphiteDark : Palette.graphiteSoft, lineWidth: 2.5))
                            if i < reached {
                                Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(Color.white)
                            }
                        }
                        Text(names[i]).font(.system(size: 12, weight: .semibold)).foregroundStyle(i < reached ? Palette.ink : Palette.ink2)
                    }
                    if i < names.count - 1 {
                        Rectangle().fill(i < reached - 1 ? Palette.graphiteDark : Palette.track)
                            .frame(height: 3)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 22)
                    }
                }
            }
        }
    }
}
#endif
