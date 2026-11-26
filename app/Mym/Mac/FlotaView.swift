#if os(macOS)
import SwiftUI

struct FlotaView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        let d = store.data
        ScreenScroll {
            HStack {
                Heading("Flota", info: "Una célula por cuenta: su motor, su ruta y su estado. Principal y reserva con un cerrojo que decide quién opera", size: 20)
                Button("Relevo manual") { store.requestRelay(store.selectedCellId) }
                    .buttonStyle(MymButtonStyle(kind: .secondary, compact: true))
                Button("Parar todo") { store.requestStopAll() }
                    .buttonStyle(MymButtonStyle(kind: .danger, compact: true))
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 14)], spacing: 14) {
                ForEach(d.cells) { cell in
                    CellCard(cell: cell, snapshot: d,
                             selected: store.selectedCellId == cell.id)
                        .onTapGesture { store.selectedCellId = cell.id }
                }
            }

            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    Heading("Disponibilidad · 60 días", info: "Un día por barra. Ámbar: incidencia menor. Rojo: parada. Gris: pausada")
                    ForEach(d.cells) { cell in
                        HStack(spacing: 12) {
                            Text(cell.id)
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .frame(width: 78, alignment: .leading)
                            HStack(spacing: 2) {
                                ForEach(0..<cell.uptime.count, id: \.self) { i in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(color(for: cell.uptime[i]))
                                        .frame(height: 24)
                                }
                            }
                        }
                    }
                }
                .card(16)
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 10) {
                    Heading("Despliegue v0.9.4", info: "Como una ruta: no pasa a la siguiente parada sin superar la anterior")
                    step("Gemelo", "Repetición de 30 días sin diferencias", state: .done)
                    step("c-dem-01 · demo", "6 de 5 días sin incidencias", state: .done)
                    step("c-lon-04 · fondeo pausado", "Siguiente parada", state: .current)
                    step("c-lon-01 · fondeo", "Después de 3 días en c-lon-04", state: .todo)
                    step("c-lon-02 · fondeo", "", state: .todo)
                    step("c-lon-03 · cuenta real", "Siempre la última", state: .todo)
                }
                .card(16)
                .frame(width: 360)
            }
        }
    }

    private func color(for value: Double) -> Color {
        if value < 0 { return Palette.graphiteSoft }
        if value >= 1 { return Palette.pos }
        if value > 0 { return Palette.warn }
        return Palette.neg
    }

    private enum StepState { case done, current, todo }

    private func step(_ title: String, _ subtitle: String, state: StepState) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(state == .done ? Palette.graphiteDark : Palette.card)
                    .frame(width: 22, height: 22)
                    .overlay(Circle().stroke(state == .todo ? Palette.graphiteSoft : Palette.graphiteDark, lineWidth: 3))
                if state == .done {
                    Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(Color.white)
                }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.ink)
                if !subtitle.isEmpty {
                    Text(subtitle).font(.system(size: 12)).foregroundStyle(Palette.ink2)
                }
            }
            Spacer()
            Pill(text: state == .done ? "Superado" : state == .current ? "Listo" : "Pendiente",
                 tone: state == .done ? .good : state == .current ? .info : .neutral)
        }
    }
}

/// Tarjeta de una célula con anillos de salud.
struct CellCard: View {
    let cell: BotCell
    let snapshot: Snapshot
    var selected: Bool = false
    @EnvironmentObject var store: AppStore

    private func ringColor(_ v: Double) -> Color {
        v >= 90 ? Palette.pos : v >= 70 ? Palette.warn : Palette.neg
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                IconTile(symbol: "server.rack", color: cell.health.color, size: 34, corner: 10)
                VStack(alignment: .leading, spacing: 0) {
                    Text(cell.id).font(.system(size: 15, weight: .semibold, design: .monospaced)).foregroundStyle(Palette.ink)
                    Text(cell.accountId).font(.system(size: 12.5)).foregroundStyle(Palette.ink2)
                }
                Spacer()
                Pill(text: cell.health.label, tone: cell.health.tone)
            }

            HStack(alignment: .center, spacing: 8) {
                metric("Latido", cell.health == .paused ? "—" : Fmt.comma(cell.heartbeat, 1) + " s", cell.healthScores[0])
                metric("Latencia", cell.health == .paused ? "—" : "\(cell.p99) ms", cell.healthScores[1])
                metric("Concil.", cell.healthScores[5] < 70 ? "1 dif." : "ok", cell.healthScores[5])
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Fmt.signedPct(cell.dayPct, 1))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(cell.dayPct < 0 ? Palette.negText : Palette.ink)
                        .monospacedDigit()
                    Text("hoy").font(.system(size: 11.5)).foregroundStyle(Palette.ink2)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            HStack(spacing: 6) {
                ForEach(cell.weights) { w in
                    Pill(text: "\(w.strategyId) · \(w.mode == .active ? Fmt.comma(w.weight, 1) : w.mode.label.lowercased())",
                         tone: w.mode.tone)
                }
            }

            Divider()
            HStack {
                Text("\(cell.site) → LD4").font(.system(size: 12.5, weight: .semibold))
                Text("· \(cell.version)").font(.system(size: 12.5)).foregroundStyle(Palette.ink2)
                Spacer()
                if cell.health == .paused {
                    Button("Reanudar") { store.requestResume(cell.id) }
                        .buttonStyle(MymButtonStyle(kind: .secondary, compact: true))
                } else {
                    Button("Pausar") { store.requestPause(cell.id) }
                        .buttonStyle(MymButtonStyle(kind: .secondary, compact: true))
                }
            }
        }
        .card(16, selected: selected)
    }

    private func metric(_ title: String, _ value: String, _ score: Double) -> some View {
        VStack(spacing: 3) {
            ZStack {
                RingsView(rings: [RingSpec(progress: cell.health == .paused ? 0.01 : score / 100, color: cell.health == .paused ? Palette.graphiteSoft : ringColor(score))],
                          lineWidth: 6, gap: 0)
            }
            .frame(width: 44, height: 44)
            Text(value).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink).monospacedDigit()
            Text(title).font(.system(size: 11)).foregroundStyle(Palette.ink2)
        }
    }
}
#endif
