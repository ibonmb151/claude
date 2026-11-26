import SwiftUI

/// Datos ficticios de las gráficas nuevas. Cuando haya datos reales, salen de la foto (Snapshot).
enum ChartSamples {
    // #06 · aporte semanal de mom_us500, rev_m5 y tend_d1
    static let strategyNames: [String] = ["mom_us500", "rev_m5", "tend_d1"]
    static let strategyColors: [Color] = [Palette.violet, Palette.teal, Palette.magenta]
    static let weekLabels: [String] = ["6 oct", "13 oct", "20 oct", "27 oct", "3 nov", "10 nov", "17 nov", "24 nov"]
    static let weeklyContribution: [[Double]] = [
        [0.3, 0.2, -0.1], [0.1, -0.2, 0.4], [0.4, 0.1, 0.2], [-0.2, 0.3, 0.3],
        [0.2, -0.1, 0.5], [0.3, 0.2, -0.2], [0.1, 0.1, 0.4], [0.2, -0.3, 0.3]
    ]

    // #08 · exposición de ayer
    static let exposureYesterday: Double = 24
}
