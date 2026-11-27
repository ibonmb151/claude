#if os(macOS)
import SwiftUI

/// Robots: cuántos hay, cómo está cada uno y qué hace. Una tarjeta por robot, con lo justo:
/// su estado en una palabra, lo que ha ganado hoy y, si algo va mal, una frase que lo dice.
struct FlotaView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        let d = store.data
        ScreenScroll {
            HStack {
                Heading("Robots", info: "Cada robot opera una cuenta con uno o varios métodos", size: 22)
                Button("Parar todo") { store.requestStopAll() }
                    .buttonStyle(MymButtonStyle(kind: .secondary, compact: true))
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: Layout.gap)], spacing: Layout.gap) {
                ForEach(d.cells) { cell in
                    CellCard(cell: cell, selected: store.selectedCellId == cell.id)
                        .onTapGesture { store.selectedCellId = cell.id }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Heading("Días sin problemas", info: "Una barra por día, 60 días. Ámbar: aviso. Rojo: parada. Gris: parado")
                ForEach(d.cells) { cell in
                    HStack(spacing: 12) {
                        Text(cell.id)
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 84, alignment: .leading)
                        HStack(spacing: 2) {
                            ForEach(0..<cell.uptime.count, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(color(for: cell.uptime[i]))
                                    .frame(height: 22)
                            }
                        }
                    }
                }
            }
            .card(Layout.card)

            VStack(alignment: .leading, spacing: 10) {
                Heading("Turnos de hoy", info: "Cuándo trabaja cada método. Macizo: hecho. Claro: lo que queda. Rayado: pausa por noticia")
                ShiftsChart(lanes: ChartSamples.shiftLanes, sessions: ChartSamples.shiftSessions, news: ChartSamples.shiftNews,
                            now: 10.7, nowText: "10:42", nextNews: "Próxima noticia en 3 h 48 min")
            }
            .card(Layout.card)

            VStack(alignment: .leading, spacing: 10) {
                Heading("Rapidez del bróker", info: "Un punto por orden. La caja es la mitad central, la raya azul la mediana. En rojo, las que pasan de 1 segundo")
                LatencyChart(cells: ChartSamples.latencyCells)
            }
            .card(Layout.card)

            VStack(alignment: .leading, spacing: 10) {
                Heading("Conexiones", info: "Cómo se comunican los robots, el bróker y el asesor. Continua: activo. Discontinua: en espera")
                NetworkMap()
                    .frame(height: 290)
            }
            .card(Layout.card)
        }
    }

    private func color(for value: Double) -> Color {
        if value < 0 { return Palette.graphiteSoft }
        if value >= 1 { return Palette.pos }
        if value > 0 { return Palette.warn }
        return Palette.neg
    }
}

/// Tarjeta de un robot: nombre y estado, lo de hoy, una frase de salud y con qué métodos trabaja.
struct CellCard: View {
    let cell: BotCell
    var selected: Bool = false
    @EnvironmentObject var store: AppStore

    /// La peor de las seis medidas técnicas, dicha con palabras normales.
    private var problem: (text: String, level: Int) {
        if cell.health == .paused { return ("Está parado y no abre operaciones", 0) }
        let scores: [Double] = cell.healthScores
        let worst: Double = scores.min() ?? 100
        let index: Int = scores.firstIndex(of: worst) ?? 0
        let messages: [String] = [
            "Tarda en responder",
            "Envía las órdenes con lentitud",
            "El bróker rechaza varias órdenes",
            "La hora va algo desfasada",
            "Faltan datos de precio",
            "El saldo no cuadra con el bróker"
        ]
        if worst >= 90 { return ("Funciona con normalidad", 3) }
        return (messages[index], worst >= 70 ? 2 : 1)
    }

    private var healthColor: Color {
        switch problem.level {
        case 3: return Palette.posText
        case 2: return Palette.warnText
        case 1: return Palette.negText
        default: return Palette.ink2
        }
    }

    private var methods: String {
        let active: [String] = cell.weights.filter { $0.mode == .active }.map { $0.strategyId }
        return active.isEmpty ? "Sin métodos activos" : active.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(cell.id).font(.system(size: 17, weight: .bold)).foregroundStyle(Palette.ink)
                Spacer()
                Pill(text: cell.health.label, tone: cell.health.tone)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(cell.health == .paused ? "—" : Fmt.signedPct(cell.dayPct, 1))
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(cell.health == .paused ? Palette.ink2 : (cell.dayPct < 0 ? Palette.negText : Palette.posText))
                    .monospacedDigit()
                Text("hoy").font(.system(size: 14)).foregroundStyle(Palette.ink2)
            }

            HStack(spacing: 8) {
                Circle().fill(problem.level == 3 ? Palette.pos : (problem.level == 2 ? Palette.warn : (problem.level == 1 ? Palette.neg : Palette.paused)))
                    .frame(width: 8, height: 8)
                Text(problem.text).font(.system(size: 14)).foregroundStyle(healthColor)
                    .lineLimit(1)
            }

            Text(methods).font(.system(size: 13)).foregroundStyle(Palette.ink2).lineLimit(1)

            Divider()
            HStack {
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(Layout.card, selected: selected)
    }
}
#endif
