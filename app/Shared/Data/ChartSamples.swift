import SwiftUI
import Foundation

/// Datos ficticios de las gráficas nuevas. Cuando haya datos reales, salen de la foto (Snapshot).
enum ChartSamples {
    // #06 · aporte semanal de Impulso, Rebote y Tendencia
    static let strategyNames: [String] = ["Impulso", "Rebote", "Tendencia"]
    static let strategyColors: [Color] = [Palette.violet, Palette.teal, Palette.magenta]
    static let weekLabels: [String] = ["6 oct", "13 oct", "20 oct", "27 oct", "3 nov", "10 nov", "17 nov", "24 nov"]
    static let weeklyContribution: [[Double]] = [
        [0.3, 0.2, -0.1], [0.1, -0.2, 0.4], [0.4, 0.1, 0.2], [-0.2, 0.3, 0.3],
        [0.2, -0.1, 0.5], [0.3, 0.2, -0.2], [0.1, 0.1, 0.4], [0.2, -0.3, 0.3]
    ]

    // #08 · exposición de ayer
    static let exposureYesterday: Double = 24
}

// MARK: - Segunda tanda

extension ChartSamples {
    // #13 · por qué se pierde una orden en cada paso
    static let flowExits: [FlowExit] = [
        FlowExit(name: "frenadas por riesgo", color: Palette.violet, background: Color(hex: 0xEDE8FE), foreground: Color(hex: 0x4B35C4)),
        FlowExit(name: "canceladas", color: Palette.gray, background: Palette.neutralBg, foreground: Palette.ink2),
        FlowExit(name: "rechazadas", color: Palette.neg, background: Palette.negBg, foreground: Palette.negText)
    ]

    // #14 · turnos de hoy
    static let shiftLanes: [ShiftLane] = [
        ShiftLane(name: "Rebote", color: Palette.teal, segments: [
            ShiftSegment(from: 8, to: 10.7, kind: .done),
            ShiftSegment(from: 10.7, to: 14.33, kind: .todo),
            ShiftSegment(from: 14.33, to: 14.67, kind: .pause),
            ShiftSegment(from: 14.67, to: 17, kind: .todo)
        ]),
        ShiftLane(name: "Impulso", color: Palette.violet, segments: [
            ShiftSegment(from: 15.5, to: 22, kind: .todo)
        ]),
        ShiftLane(name: "Tendencia", color: Palette.magenta, segments: [
            ShiftSegment(from: 22.85, to: 23.15, kind: .todo)
        ])
    ]
    static let shiftSessions: [ShiftSession] = [
        ShiftSession(name: "Asia", from: 0, to: 8, row: 0, background: Palette.neutralBg, foreground: Palette.graphiteDark),
        ShiftSession(name: "Londres", from: 8, to: 16.5, row: 0, background: Palette.infoBg, foreground: Palette.infoText),
        ShiftSession(name: "Nueva York", from: 14.5, to: 22, row: 1, background: Color(hex: 0xEDE8FE), foreground: Color(hex: 0x4B35C4))
    ]
    static let shiftNews: [NewsMark] = [NewsMark(hour: 14.5, label: "IPC 14:30"), NewsMark(hour: 16, label: "ISM 16:00")]

    // #15 · latencia hasta ACCEPTED por célula
    static let latencyCells: [LatencyCell] = [
        LatencyCell(name: "Londres 1", p50: 400, p99: 640),
        LatencyCell(name: "Londres 2", p50: 520, p99: 910),
        LatencyCell(name: "Londres 3", p50: 360, p99: 580),
        LatencyCell(name: "Demo", p50: 430, p99: 720)
    ]

    // #19 · retorno frente a caída (estrategia 0 = Impulso, 1 = Rebote, 2 = Tendencia)
    static let returnBubbles: [ReturnBubble] = [
        ReturnBubble(strategy: 0, cell: "Londres 1", drawdown: 0.9, result: 1.8, trades: 40),
        ReturnBubble(strategy: 0, cell: "Demo", drawdown: 1.1, result: 0.6, trades: 22),
        ReturnBubble(strategy: 1, cell: "Londres 1", drawdown: 1.0, result: 1.1, trades: 60),
        ReturnBubble(strategy: 1, cell: "Londres 2", drawdown: 1.6, result: -0.6, trades: 48),
        ReturnBubble(strategy: 1, cell: "Londres 3", drawdown: 0.7, result: 0.4, trades: 30),
        ReturnBubble(strategy: 1, cell: "Demo", drawdown: 1.2, result: 1.3, trades: 55),
        ReturnBubble(strategy: 2, cell: "Londres 1", drawdown: 0.5, result: 1.4, trades: 8),
        ReturnBubble(strategy: 2, cell: "Londres 2", drawdown: 0.8, result: 0.2, trades: 6),
        ReturnBubble(strategy: 2, cell: "Londres 3", drawdown: 0.4, result: 0.9, trades: 5),
        ReturnBubble(strategy: 2, cell: "Demo", drawdown: 0.6, result: 2.4, trades: 9)
    ]

    // #21 · Rebote de v2 a v3, todo con base 100
    static let slopeMeasures: [SlopeMeasure] = [
        SlopeMeasure(name: "Retorno", detail: "0,6 → 0,9 %", index: 150, change: "+50 %", better: true),
        SlopeMeasure(name: "Acierto", detail: "54 → 57 %", index: 105.6, change: "+5,6 %", better: true),
        SlopeMeasure(name: "Factor", detail: "1,14 → 1,21", index: 106.1, change: "+6,1 %", better: true),
        SlopeMeasure(name: "Operaciones", detail: "160 → 142", index: 88.75, change: "−11 %", better: nil),
        SlopeMeasure(name: "Caída máx.", detail: "1,9 → 1,4 %", index: 73.7, change: "−26 %", better: true)
    ]

    // #23 · equity de 30 días y los cambios sobre ella
    static let changeSeries: [Double] = (0..<30).map { (i: Int) -> Double in
        let t = Double(i)
        return 100 + t * 0.07 + 0.5 * sin(t / 3) + 0.2 * sin(t * 1.3)
    }
    static let changeEvents: [ChangeEvent] = [
        ChangeEvent(letter: "A", day: 20, color: Palette.info),
        ChangeEvent(letter: "B", day: 21, color: Palette.warn),
        ChangeEvent(letter: "C", day: 23, color: Palette.gray),
        ChangeEvent(letter: "D", day: 27, color: Palette.teal),
        ChangeEvent(letter: "E", day: 28, color: Palette.violet),
        ChangeEvent(letter: "F", day: 29, color: Palette.info)
    ]

    static let changeLegend: [(String, Color)] = [
        ("peso", Palette.info), ("parámetros", Palette.violet), ("condición", Palette.teal),
        ("despliegue", Palette.gray), ("pausa", Palette.warn)
    ]
}
