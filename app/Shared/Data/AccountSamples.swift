import Foundation

/// Datos de demostración del panel de cuenta. Ficticios. Las cuentas solo existen como «···4152» y «···2511».
extension AccountBundle {
    static let demoA = "demo-4152"
    static let demoB = "demo-2511"

    static var demo: AccountBundle {
        var b = AccountBundle()
        b.source = .demo
        b.accounts = [
            AccountMetrics(cuenta: demoA, balance: 101842.30, equity: 102044.70, marginUsed: 1980, marginFree: 7020, marginLevelPct: 2400,
                           pnlFlotante: 202.40, pnlRealizadoHoy: -790.50, pnlRealizadoTotal: 1842.30, nTradesAbiertos: 3, nTradesCerradosTotal: 305,
                           maxDdHistorico: -1.92, gapConciliacion: 0.0, depositoInicial: 100000, deltaCDep: 1842.30),
            AccountMetrics(cuenta: demoB, balance: 51600.10, equity: 51610.10, marginUsed: 900, marginFree: 3100, marginLevelPct: 3100,
                           pnlFlotante: 10.0, pnlRealizadoHoy: -70.10, pnlRealizadoTotal: 1600.10, nTradesAbiertos: 2, nTradesCerradosTotal: 143,
                           maxDdHistorico: -2.31, gapConciliacion: 1.20, depositoInicial: 50000, deltaCDep: 1600.10)
        ]
        b.modules = [
            ModuleMetrics(modulo: "Rebote", cuenta: demoA, nTrades: 98, wins: 57, losses: 41, wr: 58.2, pnlRealizado: 812.4, costes: 96.2, avgRr: 1.42, maxDd: -1.4,
                          capitalAsignadoPct: 30, capitalEnRiesgoPct: 0.9, sharpe: 1.6, sortino: 2.3, profitFactor: 1.24, avgDuracionMin: 192, decayPct: -2),
            ModuleMetrics(modulo: "Rebote", cuenta: demoB, nTrades: 44, wins: 24, losses: 20, wr: 54.5, pnlRealizado: 300.0, costes: 41.0, avgRr: 1.30, maxDd: -1.1,
                          capitalAsignadoPct: 30, capitalEnRiesgoPct: 0.6, profitFactor: 1.15, avgDuracionMin: 175, decayPct: -9),
            ModuleMetrics(modulo: "Impulso", cuenta: demoA, nTrades: 64, wins: 35, losses: 29, wr: 54.7, pnlRealizado: 1104.0, costes: 41.8, avgRr: 1.55, maxDd: -1.1,
                          capitalAsignadoPct: 25, capitalEnRiesgoPct: 0.5, profitFactor: 1.32, avgDuracionMin: 240, decayPct: 1),
            ModuleMetrics(modulo: "Tendencia", cuenta: demoB, nTrades: 18, wins: 11, losses: 7, wr: 61.1, pnlRealizado: 1420.6, costes: 12.5, avgRr: 1.9, maxDd: -0.9,
                          capitalAsignadoPct: 25, capitalEnRiesgoPct: 0.4, profitFactor: 1.48, avgDuracionMin: 1320, decayPct: 0),
            ModuleMetrics(modulo: "Ruptura", cuenta: demoA, nTrades: 23, wins: 11, losses: 12, wr: 47.8, pnlRealizado: -180.3, costes: 22.1, avgRr: 1.1, maxDd: -2.3,
                          capitalAsignadoPct: 20, capitalEnRiesgoPct: 0.3, profitFactor: 0.94, avgDuracionMin: 130, decayPct: -18)
        ]

        // 30 días: curva realizada y resultado por día, por cuenta.
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        let day: TimeInterval = 86400
        let start = Date(timeIntervalSince1970: 1_761_600_000)
        var daily: [DailyMetrics] = []
        var curve: [CurvePoint] = []
        for (acc, base, scale) in [(demoA, 100000.0, 1.0), (demoB, 50000.0, 0.5)] {
            var eq = base
            var peak = base
            for i in 0..<30 {
                let t = Double(i)
                let pnl = (120 + 380 * sin(t / 3.1) + 160 * sin(t * 1.7)) * scale
                let begin = eq
                eq += pnl
                peak = max(peak, eq)
                let ts = f.string(from: start.addingTimeInterval(Double(i) * day))
                let date = String(ts.prefix(10))
                daily.append(DailyMetrics(fecha: date, cuenta: acc, balanceInicio: begin, balanceFin: eq, pnlRealizado: pnl,
                                          nTradesCerrados: 4 + i % 3, wins: 2 + i % 2, losses: 2, vix: 21.8, regimen: "risk-off"))
                curve.append(CurvePoint(cuenta: acc, ts: ts, equityRealizado: eq, drawdownPct: (eq - peak) / peak * 100))
            }
        }
        b.daily = daily
        b.curve = curve

        b.trades = [
            TradeRecord(label: "rebote-4152-0187", modulo: "Rebote", cuenta: demoA, par: "EURUSD", lado: "compra", entradaPx: 1.17003, sl: 1.16853, tp: 1.17283, volumen: 0.10, riesgoPct: 0.2, pnl: 12.40),
            TradeRecord(label: "impulso-4152-0041", modulo: "Impulso", cuenta: demoA, par: "US500", lado: "venta", entradaPx: 6012.5, sl: 6034.0, tp: 5960.0, volumen: 0.20, riesgoPct: 0.3, pnl: 17.0),
            TradeRecord(label: "ruptura-4152-0008", modulo: "Ruptura", cuenta: demoA, par: "XAUUSD", lado: "venta", entradaPx: 2641.2, sl: 2652.0, tp: 2612.0, volumen: 0.05, riesgoPct: 0.2, pnl: 173.0),
            TradeRecord(label: "tendencia-2511-0012", modulo: "Tendencia", cuenta: demoB, par: "GBPUSD", lado: "compra", entradaPx: 1.3052, sl: 1.3010, tp: 1.3140, volumen: 0.10, riesgoPct: 0.2, pnl: 16.0),
            TradeRecord(label: "rebote-2511-0093", modulo: "Rebote", cuenta: demoB, par: "EURUSD", lado: "compra", entradaPx: 1.1690, sl: nil, tp: 1.1730, volumen: 0.02, riesgoPct: 0.1, pnl: -6.0)
        ]
        b.files = [
            FileStatus(name: "metricas_diarias.json", state: .ok, modified: Date()),
            FileStatus(name: "modulos_metricas.json", state: .ok, modified: Date()),
            FileStatus(name: "cuentas_metricas.json", state: .ok, modified: Date()),
            FileStatus(name: "curva_equity.json", state: .ok, modified: Date()),
            FileStatus(name: "seq_labels.json", state: .ok, modified: Date())
        ]
        return b
    }
}
