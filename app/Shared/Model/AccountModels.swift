import Foundation

// Contrato de datos de las cuentas: los JSON que generan los scripts de 06_CONFIG.
// Los nombres de campo van en snake_case en el fichero y en camelCase aquí (se convierten solos).
// Todo es opcional: si un dato falta, la app muestra «n.d.» y nunca inventa un cero.

struct AccountMetrics: Codable, Identifiable {
    var id: String { cuenta }
    let cuenta: String
    var balance: Double?
    var equity: Double?
    var marginUsed: Double?
    var marginFree: Double?
    var marginLevelPct: Double?
    var pnlFlotante: Double?
    var pnlRealizadoHoy: Double?
    var pnlRealizadoTotal: Double?
    var nTradesAbiertos: Int?
    var nTradesCerradosTotal: Int?
    var maxDdHistorico: Double?
    var gapConciliacion: Double?
    var depositoInicial: Double?
    var deltaCDep: Double?
}

struct ModuleMetrics: Codable, Identifiable {
    var id: String { modulo + "·" + cuenta }
    let modulo: String
    let cuenta: String
    var nTrades: Int?
    var wins: Int?
    var losses: Int?
    var wr: Double?
    var pnlRealizado: Double?
    var pnlFlotante: Double?
    var costes: Double?
    var avgRr: Double?
    var maxDd: Double?
    var maxDdPct: Double?
    var capitalAsignadoPct: Double?
    var capitalEnRiesgoPct: Double?
    var sharpe: Double?
    var sortino: Double?
    var profitFactor: Double?
    var avgDuracionMin: Double?
    var mejorTrade: Double?
    var peorTrade: Double?
    var ultimoTrade: String?
    var decayPct: Double?
}

struct DailyMetrics: Codable, Identifiable {
    var id: String { fecha + "·" + (cuenta ?? "") }
    let fecha: String
    var cuenta: String?
    var balanceInicio: Double?
    var balanceFin: Double?
    var pnlRealizado: Double?
    var pnlFlotante: Double?
    var costes: Double?
    var nTradesAbiertos: Int?
    var nTradesCerrados: Int?
    var wins: Int?
    var losses: Int?
    var wr: Double?
    var maxDdIntradia: Double?
    var maxDdDesdePico: Double?
    var vix: Double?
    var regimen: String?
    var oportunidades: Int?
}

struct CurvePoint: Codable, Identifiable {
    var id: String { (cuenta ?? "") + ts }
    var cuenta: String?
    let ts: String
    var equityRealizado: Double?
    var drawdownPct: Double?
}

struct TradeRecord: Codable, Identifiable {
    var id: String { label }
    let label: String
    var modulo: String?
    var cuenta: String?
    var par: String?
    var lado: String?          // «compra» o «venta»
    var entradaPx: Double?
    var entradaTs: String?
    var sl: Double?
    var tp: Double?
    var volumen: Double?
    var riesgoPct: Double?
    var salidaPx: Double?
    var salidaTs: String?
    var pnl: Double?
    var comision: Double?
    var swap: Double?
    var duracionMin: Double?
    var resultado: String?
    var slippagePips: Double?

    /// Abierta = todavía sin salida. Su resultado es flotante, no realizado.
    var isOpen: Bool { salidaTs == nil }
    /// Sin protección = sin stop (o stop a cero).
    var isUnprotected: Bool { isOpen && (sl == nil || sl == 0) }
}

// MARK: - Alcance, estado de ficheros y resumen

enum AccountScope: Hashable {
    case all
    case one(String)
}

enum FileState {
    case ok
    case missing
    case invalid
}

struct FileStatus: Identifiable {
    var id: String { name }
    let name: String
    var state: FileState
    var modified: Date?
}

enum SystemState {
    case demo, active, error

    var label: String {
        switch self {
        case .demo: return "Demostración"
        case .active: return "Activo"
        case .error: return "Error"
        }
    }
}

struct AccountAlert: Identifiable {
    enum Level { case urgent, attention }
    let id = UUID()
    let level: Level
    let title: String
    let detail: String
}

struct AccountBundle {
    enum Source { case demo, files }

    var accounts: [AccountMetrics] = []
    var modules: [ModuleMetrics] = []
    var daily: [DailyMetrics] = []
    var curve: [CurvePoint] = []
    var trades: [TradeRecord] = []
    var loadedAt: Date = Date()
    var source: Source = .demo
    var files: [FileStatus] = []
}

/// Resumen de lo que se ve arriba del panel, calculado para un alcance (ambas cuentas o una).
struct AccountSummary {
    var balance: Double?
    var dayChange: Double?
    var dayChangePct: Double?
    var floating: Double?
    var openCount: Int
    var realizedToday: Double?
    var winRate: Double?
    var profitFactor: Double?
    var maxDrawdown: Double?
    var riskUsed: Double?
    var freeMarginPct: Double?
    var alerts: [AccountAlert]
    var state: SystemState
}

/// «···4152»: de una cuenta solo se enseñan los cuatro últimos dígitos.
func maskedAccount(_ id: String) -> String {
    "···" + String(id.suffix(4))
}

private func total(_ values: [Double?]) -> Double? {
    let present: [Double] = values.compactMap { $0 }
    return present.isEmpty ? nil : present.reduce(0, +)
}

extension AccountBundle {
    func inScope(_ cuenta: String?, _ scope: AccountScope) -> Bool {
        switch scope {
        case .all: return true
        case .one(let id): return cuenta == id
        }
    }

    func summary(for scope: AccountScope) -> AccountSummary {
        let accs: [AccountMetrics] = accounts.filter { inScope($0.cuenta, scope) }
        let mods: [ModuleMetrics] = modules.filter { inScope($0.cuenta, scope) }
        let open: [TradeRecord] = trades.filter { $0.isOpen && inScope($0.cuenta, scope) }

        let balance: Double? = total(accs.map { $0.balance })
        let realized: Double? = total(accs.map { $0.pnlRealizadoHoy })
        var dayPct: Double?
        if let b = balance, let r = realized, b - r != 0 { dayPct = r / (b - r) * 100 }

        // Acierto: victorias entre operaciones, de los módulos. PF: media ponderada por operaciones.
        let wins: Double = mods.compactMap { $0.wins }.reduce(0, +).asDouble
        let losses: Double = mods.compactMap { $0.losses }.reduce(0, +).asDouble
        let winRate: Double? = (wins + losses) > 0 ? wins / (wins + losses) * 100 : nil
        var pfNum: Double = 0
        var pfDen: Double = 0
        for m in mods {
            if let pf = m.profitFactor, let n = m.nTrades, n > 0 {
                pfNum += pf * Double(n)
                pfDen += Double(n)
            }
        }
        let pf: Double? = pfDen > 0 ? pfNum / pfDen : nil

        let dd: Double? = accs.compactMap { $0.maxDdHistorico }.min()

        // Riesgo usado: suma del riesgo de los módulos de cada cuenta; con varias cuentas, la media.
        var perAccount: [Double] = []
        for a in accs {
            let r: [Double] = mods.filter { $0.cuenta == a.cuenta }.compactMap { $0.capitalEnRiesgoPct }
            if !r.isEmpty { perAccount.append(r.reduce(0, +)) }
        }
        let risk: Double? = perAccount.isEmpty ? nil : perAccount.reduce(0, +) / Double(perAccount.count)

        var freePct: Double?
        let used: Double? = total(accs.map { $0.marginUsed })
        let free: Double? = total(accs.map { $0.marginFree })
        if let u = used, let f = free, u + f > 0 { freePct = f / (u + f) * 100 }

        var alerts: [AccountAlert] = []
        for t in open where t.isUnprotected {
            alerts.append(AccountAlert(level: .urgent, title: "Posición sin protección",
                                       detail: [t.par ?? "?", maskedAccount(t.cuenta ?? "????"), t.label].joined(separator: " · ")))
        }
        for m in mods {
            if let d = m.decayPct, d <= -10 {
                alerts.append(AccountAlert(level: .attention, title: "\(m.modulo) pierde ventaja",
                                           detail: "\(maskedAccount(m.cuenta)) · \(Fmt.signedPct(d, 0)) frente a su media"))
            }
        }
        for a in accs {
            if let g = a.gapConciliacion, abs(g) > 0.5 {
                alerts.append(AccountAlert(level: .attention, title: "El saldo no cuadra con el bróker",
                                           detail: "\(maskedAccount(a.cuenta)) · diferencia de \(Fmt.eurDecimals(g))"))
            }
        }
        if let r = risk, r > 3 {
            alerts.append(AccountAlert(level: .attention, title: "Riesgo usado alto", detail: "\(Fmt.comma(r, 1)) % de un máximo de 5 %"))
        }
        let badFiles: [String] = files.filter { $0.state != .ok }.map { $0.name }
        if source == .files && !badFiles.isEmpty {
            alerts.append(AccountAlert(level: .attention, title: "Faltan datos", detail: badFiles.joined(separator: ", ")))
        }

        var state: SystemState = .active
        if source == .demo { state = .demo }
        if source == .files && !badFiles.isEmpty { state = .error }

        return AccountSummary(balance: balance, dayChange: realized, dayChangePct: dayPct, floating: total(accs.map { $0.pnlFlotante }),
                              openCount: open.isEmpty ? (accs.compactMap { $0.nTradesAbiertos }.reduce(0, +)) : open.count,
                              realizedToday: realized, winRate: winRate, profitFactor: pf, maxDrawdown: dd, riskUsed: risk,
                              freeMarginPct: freePct, alerts: alerts, state: state)
    }
}

extension AccountBundle {
    /// Curva de equity realizada. Con «ambas», suma las cuentas punto a punto.
    func equitySeries(_ scope: AccountScope) -> [Double] {
        var perAccount: [[Double]] = []
        for a in accounts where inScope(a.cuenta, scope) {
            perAccount.append(curve.filter { $0.cuenta == a.cuenta }.compactMap { $0.equityRealizado })
        }
        let usable: [[Double]] = perAccount.filter { !$0.isEmpty }
        guard let n = usable.map({ $0.count }).min() else { return [] }
        return (0..<n).map { i in usable.map { $0[i] }.reduce(0, +) }
    }

    /// Caída desde el máximo, en %, calculada sobre una serie de equity.
    static func drawdown(of equity: [Double]) -> [Double] {
        var peak: Double = equity.first ?? 0
        var out: [Double] = []
        for v in equity {
            peak = max(peak, v)
            out.append(peak > 0 ? (v - peak) / peak * 100 : 0)
        }
        return out
    }

    /// Resultado realizado de cada día. Con «ambas», suma las cuentas del mismo día.
    func dailySeries(_ scope: AccountScope) -> [Double] {
        var byDay: [String: Double] = [:]
        for d in daily where inScope(d.cuenta, scope) {
            if let p = d.pnlRealizado { byDay[d.fecha, default: 0] += p }
        }
        return byDay.keys.sorted().map { byDay[$0] ?? 0 }
    }
}

private extension Int {
    var asDouble: Double { Double(self) }
}
