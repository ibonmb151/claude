import SwiftUI

/// Datos ficticios, deterministas. Las cuentas, firmas y cifras son inventadas.
/// Las estrategias (mom_us500, rev_m5, tend_d1) vienen de los documentos 13 y 14.
enum MockData {

    // MARK: Series deterministas

    /// Serie suave entre `start` y `end` con un poco de ruido determinista.
    static func series(seed: Double, count: Int, start: Double, end: Double, noise: Double) -> [Double] {
        guard count > 1 else { return [start] }
        return (0..<count).map { i in
            let t = Double(i) / Double(count - 1)
            let base = start + (end - start) * t
            let wobble = sin(Double(i) * 0.9 + seed) * noise + sin(Double(i) * 2.3 + seed * 1.7) * noise * 0.5
            return base + wobble * (1 - t * 0.6)
        }
    }

    static func uptime(seed: Int, incidents: [Int: Double], pausedLast: Int = 0) -> [Double] {
        (0..<60).map { i in
            if pausedLast > 0 && i >= 60 - pausedLast { return -1 }
            return incidents[i] ?? 1
        }
    }

    // MARK: Foto

    static func make(now: Date = Date()) -> Snapshot {
        let hourly = [0.02, -0.01, 0.03, 0.01, 0.0, -0.02, 0.01, 0.04, -0.08, -0.12, -0.19]
            .enumerated().map { HourBar(id: $0.offset, value: $0.element) }

        let accounts = makeAccounts()
        let strategies = makeStrategies()
        let cells = makeCells()

        let equity = accounts.reduce(0) { $0 + $1.equity }

        return Snapshot(
            date: now,
            equity: equity,
            equityDeltaPct: 0.4,
            dayPct: -0.31,
            dayLimitPct: 2.0,
            exposurePct: 18,
            exposureLots: 3.2,
            ordersToday: 128,
            rejectedToday: 7,
            latencyMs: 412,
            latencyP99: 640,
            equitySeries: [206.0, 207.0, 206.5, 208.0, 207.6, 209.0, 208.4, 210.0, 209.3, 211.0, 210.4, 212.0, 212.6, 213.2],
            dayPctSeries: [0, 0.02, 0.01, 0.04, 0.05, 0.05, 0.03, 0.04, 0.08, 0, -0.12, -0.31],
            ordersSeries: [2, 6, 9, 15, 22, 30, 41, 58, 79, 96, 113, 128],
            latencySeries: [380, 420, 401, 455, 398, 430, 410, 470, 405, 415, 390, 412],
            hourly: hourly,
            cells: cells,
            accounts: accounts,
            strategies: strategies,
            orders: makeOrders(),
            alerts: makeAlerts(),
            proposals: makeProposals(),
            layers: [
                RiskLayer(name: "Orden", detail: "0,25 de 0,8 %", used: 30, yesterday: 28),
                RiskLayer(name: "Estrategia", detail: "0,4 de 1,0 %", used: 40, yesterday: 35),
                RiskLayer(name: "Célula", detail: "1,9 de 4 %", used: 47, yesterday: 22),
                RiskLayer(name: "Cuenta", detail: "1,2 de 8 %", used: 15, yesterday: 15),
                RiskLayer(name: "Global", detail: "0,3 de 2,0 %", used: 16, yesterday: 9)
            ],
            exposures: [
                ExposureItem(name: "USD", lots: 1.22, pct: 38, isLong: true),
                ExposureItem(name: "GBP", lots: 0.80, pct: 25, isLong: true),
                ExposureItem(name: "EUR", lots: 0.61, pct: 19, isLong: false),
                ExposureItem(name: "US500", lots: 0.38, pct: 12, isLong: true),
                ExposureItem(name: "JPY", lots: 0.19, pct: 6, isLong: false)
            ],
            funnel: Funnel(signals: 142, riskOk: 131, sent: 128, filled: 121),
            hops: [
                Hop(name: "Riesgo", ms: 7, color: Palette.violet),
                Hop(name: "Envío", ms: 12, color: Palette.teal),
                Hop(name: "Bróker", ms: 609, color: Palette.graphiteDark),
                Hop(name: "Ejecución", ms: 62, color: Palette.pos),
                Hop(name: "Stops", ms: 33, color: Palette.warn)
            ],
            rules: [
                RuleUse(name: "Objetivo", text: "3,2 de 5 %", fraction: 0.64, warnAt: 1.0, color: Palette.info),
                RuleUse(name: "Pérdida diaria", text: "1,9 de 4 %", fraction: 0.48, warnAt: 0.75, color: Palette.warn),
                RuleUse(name: "Drawdown", text: "1,2 de 8 %", fraction: 0.15, warnAt: 0.75, color: Palette.violet),
                RuleUse(name: "Días mínimos", text: "12 de 5", fraction: 1.0, warnAt: 1.0, color: Palette.pos),
                RuleUse(name: "Consistencia", text: "31 de 40 %", fraction: 0.78, warnAt: 0.75, color: Palette.warn),
                RuleUse(name: "Tiempo de fase", text: "18 de 60 d", fraction: 0.30, warnAt: 1.0, color: Palette.gray)
            ]
        )
    }

    // MARK: Cuentas

    private static func makeAccounts() -> [Account] {
        [
            Account(id: "FND-A-100k", firm: "Firma A", kind: .funded, phase: "Fase 1", equity: 101842,
                    dayPct: -0.6, dayLimitPct: 5, drawdownPct: 1.9, drawdownLimitPct: 10,
                    targetPct: 1.8, targetGoalPct: 8, health: .ok, cellId: "c-lon-01"),
            Account(id: "FND-B-50k", firm: "Firma B", kind: .funded, phase: "Fase 2", equity: 51600,
                    dayPct: -1.9, dayLimitPct: 4, drawdownPct: 1.2, drawdownLimitPct: 8,
                    targetPct: 3.2, targetGoalPct: 5, health: .warning, cellId: "c-lon-02"),
            Account(id: "FND-A-25k", firm: "Firma A", kind: .funded, phase: "Fase 1", equity: 25090,
                    dayPct: 0.0, dayLimitPct: 5, drawdownPct: 0.4, drawdownLimitPct: 10,
                    targetPct: 0.4, targetGoalPct: 8, health: .paused, cellId: "c-lon-04"),
            Account(id: "REAL-01", firm: "Cuenta propia", kind: .real, phase: "Meta del mes", equity: 12340,
                    dayPct: 0.3, dayLimitPct: 2, drawdownPct: 3.0, drawdownLimitPct: 10,
                    targetPct: 0.6, targetGoalPct: 1, health: .critical, cellId: "c-lon-03"),
            Account(id: "DEMO-01", firm: "Bróker cTrader", kind: .demo, phase: "Incubación", equity: 22342,
                    dayPct: 0.5, dayLimitPct: 5, drawdownPct: 1.2, drawdownLimitPct: 10,
                    targetPct: 18, targetGoalPct: 30, health: .ok, cellId: "c-dem-01")
        ]
    }

    // MARK: Células

    private static func makeCells() -> [BotCell] {
        func w(_ id: String, _ weight: Double, _ mode: StrategyMode = .active) -> StrategyWeight {
            StrategyWeight(strategyId: id, weight: weight, mode: mode)
        }
        return [
            BotCell(id: "c-lon-01", accountId: "FND-A-100k", health: .ok, site: "Londres", backupSite: "Bilbao",
                    version: "v0.9.3", p99: 640, rejects24h: 2, heartbeat: 0.8, dayPct: -0.6,
                    weights: [w("mom_us500", 1.0), w("rev_m5", 1.0), w("tend_d1", 0.5)],
                    healthScores: [96, 88, 92, 70, 97, 100],
                    uptime: uptime(seed: 1, incidents: [41: 0.5])),
            BotCell(id: "c-lon-02", accountId: "FND-B-50k", health: .warning, site: "Londres", backupSite: "Bilbao",
                    version: "v0.9.3", p99: 910, rejects24h: 5, heartbeat: 1.1, dayPct: -1.9,
                    weights: [w("rev_m5", 0.5), w("tend_d1", 0.5)],
                    healthScores: [82, 72, 64, 90, 95, 100],
                    uptime: uptime(seed: 2, incidents: [12: 0.5, 33: 0, 58: 0.5, 59: 0.5])),
            BotCell(id: "c-lon-03", accountId: "REAL-01", health: .critical, site: "Londres", backupSite: "Bilbao",
                    version: "v0.9.2", p99: 580, rejects24h: 0, heartbeat: 0.7, dayPct: 0.3,
                    weights: [w("rev_m5", 0.5), w("tend_d1", 0.5)],
                    healthScores: [97, 91, 99, 88, 96, 55],
                    uptime: uptime(seed: 3, incidents: [22: 0.5, 59: 0])),
            BotCell(id: "c-dem-01", accountId: "DEMO-01", health: .ok, site: "Bilbao", backupSite: "Londres",
                    version: "v0.9.4 · candidata", p99: 720, rejects24h: 1, heartbeat: 0.9, dayPct: 0.5,
                    weights: [w("mom_us500", 0, .shadow), w("rev_m5", 1.0), w("tend_d1", 1.0)],
                    healthScores: [93, 84, 95, 92, 98, 100],
                    uptime: uptime(seed: 4, incidents: [54: 0.5])),
            BotCell(id: "c-lon-04", accountId: "FND-A-25k", health: .paused, site: "Londres", backupSite: "Bilbao",
                    version: "v0.9.3", p99: 0, rejects24h: 0, heartbeat: 0, dayPct: 0,
                    weights: [w("mom_us500", 0, .paused), w("rev_m5", 0, .paused), w("tend_d1", 0, .paused)],
                    healthScores: [0, 0, 0, 0, 0, 0],
                    uptime: uptime(seed: 5, incidents: [:], pausedLast: 9))
        ]
    }

    // MARK: Estrategias

    private static func makeStrategies() -> [Strategy] {
        [
            Strategy(id: "mom_us500", name: "Momentum US500", symbol: "chevron.up.2", color: Palette.violet,
                     return30d: 1.8, trades: 64, hitRate: 0.55, profitFactor: 1.32, maxDrawdown: 1.1, version: 2,
                     params: [
                        Param(key: "ventana", value: 30, previous: 30, min: 10, max: 60, step: 1, unit: ""),
                        Param(key: "umbral_adx", value: 22, previous: 22, min: 15, max: 35, step: 1, unit: ""),
                        Param(key: "stop_atr", value: 2.0, previous: 2.0, min: 1.0, max: 3.5, step: 0.1, unit: "")
                     ],
                     series: series(seed: 1.2, count: 30, start: 0, end: 1.8, noise: 0.12),
                     weeklyRank: [1, 1, 1, 2, 3, 1, 2, 2],
                     note: "Impulso en el índice."),
            Strategy(id: "rev_m5", name: "Reversión M5", symbol: "waveform.path", color: Palette.teal,
                     return30d: 0.9, trades: 142, hitRate: 0.57, profitFactor: 1.21, maxDrawdown: 1.4, version: 3,
                     params: [
                        Param(key: "ventana", value: 20, previous: 20, min: 10, max: 40, step: 1, unit: ""),
                        Param(key: "umbral_z", value: 2.2, previous: 2.0, min: 1.5, max: 3.0, step: 0.1, unit: ""),
                        Param(key: "stop_atr", value: 1.5, previous: 1.5, min: 1.0, max: 2.5, step: 0.1, unit: ""),
                        Param(key: "riesgo_por_operación", value: 0.20, previous: 0.25, min: 0.10, max: 0.50, step: 0.05, unit: " %")
                     ],
                     series: series(seed: 0.4, count: 30, start: 0, end: 0.9, noise: 0.10),
                     weeklyRank: [3, 2, 3, 3, 2, 3, 3, 3],
                     note: "Vuelta a la media en cinco minutos."),
            Strategy(id: "tend_d1", name: "Tendencia D1", symbol: "arrow.up.right", color: Palette.magenta,
                     return30d: 2.4, trades: 18, hitRate: 0.61, profitFactor: 1.48, maxDrawdown: 0.9, version: 2,
                     params: [
                        Param(key: "ventana", value: 50, previous: 50, min: 20, max: 100, step: 1, unit: ""),
                        Param(key: "salida_atr", value: 3.0, previous: 3.0, min: 1.5, max: 5.0, step: 0.1, unit: "")
                     ],
                     series: series(seed: 2.1, count: 30, start: 0, end: 2.4, noise: 0.14),
                     weeklyRank: [2, 3, 2, 1, 1, 2, 1, 1],
                     note: "Sigue tendencias diarias.")
        ]
    }

    // MARK: Órdenes

    private static func makeOrders() -> [Order] {
        func o(_ id: String, _ ins: String, _ side: Side, _ lots: Double, _ strat: String, _ cell: String,
               _ st: OrderStatus, _ time: String, _ pnl: Double?, _ e: Double, _ s: Double, _ t: Double, _ last: Double) -> Order {
            Order(id: id, instrument: ins, side: side, lots: lots, strategyId: strat, cellId: cell,
                  status: st, time: time, pnl: pnl, entry: e, stop: s, target: t, last: last)
        }
        return [
            o("#A7F3-21", "EURUSD", .buy, 0.10, "rev_m5", "c-lon-01", .accepted, "10:30:00", 12.40, 1.17003, 1.16853, 1.17283, 1.17127),
            o("#A7F3-20", "US500", .sell, 0.20, "mom_us500", "c-lon-01", .sent, "10:41:58", nil, 6012.5, 6034.0, 5960.0, 6012.5),
            o("#B210-07", "GBPUSD", .buy, 0.10, "tend_d1", "c-lon-02", .filled, "10:30:00", 4.10, 1.3052, 1.3010, 1.3140, 1.3068),
            o("#B210-06", "EURUSD", .buy, 0.05, "rev_m5", "c-lon-02", .rejected, "10:41:07", nil, 1.1701, 1.1686, 1.1730, 1.1701),
            o("#C051-12", "EURUSD", .sell, 0.05, "rev_m5", "c-dem-01", .riskOk, "10:42:11", nil, 1.1703, 1.1718, 1.1676, 1.1703),
            o("#D400-03", "EURUSD", .buy, 0.02, "rev_m5", "c-lon-03", .noStop, "09:58:20", -1.20, 1.1690, 0.0, 1.1730, 1.1684),
            o("#A7F3-19", "US500", .buy, 0.20, "mom_us500", "c-lon-01", .closed, "09:15:44", 38.60, 5988.0, 5960.0, 6040.0, 6018.0),
            o("#B210-05", "GBPUSD", .sell, 0.10, "tend_d1", "c-lon-02", .closed, "08:02:10", -9.80, 1.3101, 1.3140, 1.3030, 1.3115),
            o("#C051-11", "EURUSD", .buy, 0.05, "rev_m5", "c-dem-01", .closed, "07:40:03", 6.20, 1.1672, 1.1655, 1.1705, 1.1690)
        ]
    }

    // MARK: Avisos

    private static func makeAlerts() -> [AlertItem] {
        [
            AlertItem(id: "a1", level: .critical, title: "Posición sin stop",
                      subtitle: "c-lon-03 · REAL-01 · manual paso 2 de 4", time: "09:58", action: "Manual", acknowledged: false),
            AlertItem(id: "a2", level: .warning, title: "Pérdida del día al 47 %",
                      subtitle: "FND-B-50k · límite 4 %", time: "10:31", action: "Reconocer", acknowledged: false),
            AlertItem(id: "a3", level: .warning, title: "Reloj del bróker 1,4 s",
                      subtitle: "c-lon-01 · DQ-09", time: "10:12", action: "Reconocer", acknowledged: false),
            AlertItem(id: "a4", level: .info, title: "Jev bajó rev_m5 a 0,5",
                      subtitle: "c-lon-02 · comando firmado", time: "08:00", action: nil, acknowledged: true),
            AlertItem(id: "a5", level: .info, title: "Simulacro de aviso",
                      subtitle: "llegó al móvil en 41 s", time: "ayer", action: nil, acknowledged: true)
        ]
    }

    // MARK: Jev

    private static func makeProposals() -> [Proposal] {
        func spark(_ v: [Double]) -> [Double] { v }
        let reads = [
            Reading(name: "Volatilidad D1", value: "p35", series: spark([60, 55, 52, 48, 44, 40, 38, 35])),
            Reading(name: "Tendencia 20 d", value: "+1,8", series: spark([0.4, 0.7, 0.9, 1.1, 1.3, 1.5, 1.6, 1.8])),
            Reading(name: "Correlación", value: "−0,12", series: spark([0.1, 0.05, 0, -0.02, -0.06, -0.1, -0.11, -0.12])),
            Reading(name: "Días en peso", value: "11", series: spark([4, 5, 6, 7, 8, 9, 10, 11]))
        ]
        let votes = [
            Vote(label: "Subir", reason: "Tendencia limpia y volatilidad baja.", positive: true),
            Vote(label: "Subir", reason: "Poca correlación con rev_m5.", positive: true),
            Vote(label: "Mantener", reason: "Solo 4 operaciones en el mes.", positive: false)
        ]
        let checks = ["Lecturas presentes en el parte", "11 de 7 días en el estado", "2 de 3 cambios esta semana", "No la paró el riesgo"]
        func p(_ id: String, _ title: String, _ short: String, _ summary: String, _ cell: String, _ strat: String,
               _ w: Double, _ time: String, _ st: ProposalStatus, _ stText: String, _ unread: Bool) -> Proposal {
            Proposal(id: id, title: title, short: short, summary: summary, cellId: cell, strategyId: strat, newWeight: w,
                     time: time, status: st, statusText: stText, votes: votes, checks: checks, reads: reads,
                     effect: "Riesgo por operación de 0,12 % a 0,25 % · exposición del 18 % al 21 %", unread: unread)
        }
        return [
            p("p1", "Subir tend_d1 a 1,0 · lon-01", "Tendencia limpia, poca correlación",
              "Tendencia limpia, volatilidad baja y casi sin relación con la otra estrategia de la célula. Lleva 11 días en el peso actual.",
              "c-lon-01", "tend_d1", 1.0, "10:05", .pending, "Pendiente", true),
            p("p2", "Bajar rev_m5 a 0,5 · lon-02", "Pérdida del día al 47 %",
              "La cuenta se acerca a su regla diaria. Se baja el peso para frenar la exposición.",
              "c-lon-02", "rev_m5", 0.5, "08:00", .applied, "Aplicada", false),
            p("p3", "Activar mom_us500 · lon-03", "Volatilidad favorable",
              "Condiciones favorables en US500, pero la célula está parada por el riesgo.",
              "c-lon-03", "mom_us500", 0.5, "Ayer", .rejected, "Rechazada · riesgo", false),
            p("p4", "Bajar tend_d1 a 0,5 · lon-02", "Cerca de la regla diaria",
              "Menos peso para proteger la regla de pérdida diaria.",
              "c-lon-02", "tend_d1", 0.5, "24 nov", .applied, "Aplicada · +0,2 %", false),
            p("p5", "Subir rev_m5 a 1,0 · dem-01", "Buena racha en demo",
              "Buena racha en demo, pero no se cumple el tiempo mínimo en el estado.",
              "c-dem-01", "rev_m5", 1.0, "21 nov", .rejected, "Rechazada · tiempo", false),
            p("p6", "mom_us500 a sombra · dem-01", "Tres semanas flojas",
              "Tres semanas por debajo de su media: pasa a sombra, se registra pero no opera.",
              "c-dem-01", "mom_us500", 0, "17 nov", .applied, "Aplicada · −0,2 %", false)
        ]
    }
}
