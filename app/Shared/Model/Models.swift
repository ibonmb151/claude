import SwiftUI

// MARK: - Módulos de la app

enum Module: String, CaseIterable, Identifiable {
    case torre, ordenes, flota, cuentas, estrategias, ajustes, jev, riesgo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .torre: return "Torre"
        case .ordenes: return "Órdenes"
        case .flota: return "Flota"
        case .cuentas: return "Cuentas"
        case .estrategias: return "Estrategias"
        case .ajustes: return "Ajustes"
        case .jev: return "Asesor"
        case .riesgo: return "Riesgo"
        }
    }

    /// Símbolo de SF Symbols más cercano a los iconos diseñados.
    var symbol: String {
        switch self {
        case .torre: return "square.grid.2x2"
        case .ordenes: return "shippingbox"
        case .flota: return "server.rack"
        case .cuentas: return "creditcard"
        case .estrategias: return "chart.line.uptrend.xyaxis"
        case .ajustes: return "slider.horizontal.3"
        case .jev: return "safari"
        case .riesgo: return "checkmark.shield"
        }
    }

    var color: Color {
        switch self {
        case .torre: return Palette.graphite
        case .ordenes: return Palette.info
        case .flota: return Palette.teal
        case .cuentas: return Palette.gold
        case .estrategias: return Palette.violet
        case .ajustes: return Palette.gray
        case .jev: return Palette.magenta
        case .riesgo: return Palette.neg
        }
    }
}

// MARK: - Estado

enum Health: String {
    case ok, warning, critical, paused

    var label: String {
        switch self {
        case .ok: return "Activa"
        case .warning: return "Aviso"
        case .critical: return "Revisar"
        case .paused: return "Pausada"
        }
    }

    var tone: Tone {
        switch self {
        case .ok: return .good
        case .warning: return .warn
        case .critical: return .bad
        case .paused: return .neutral
        }
    }

    var color: Color {
        switch self {
        case .ok: return Palette.pos
        case .warning: return Palette.warn
        case .critical: return Palette.neg
        case .paused: return Palette.paused
        }
    }
}

// MARK: - Cuentas y células

enum AccountKind: String {
    case funded, real, demo

    var label: String {
        switch self {
        case .funded: return "Fondeo"
        case .real: return "Real"
        case .demo: return "Demo"
        }
    }

    var letter: String {
        switch self {
        case .funded: return "F"
        case .real: return "R"
        case .demo: return "D"
        }
    }

    var color: Color {
        switch self {
        case .funded: return Palette.graphite
        case .real: return Palette.gold
        case .demo: return Palette.gray
        }
    }
}

struct Account: Identifiable {
    let id: String
    let firm: String
    let kind: AccountKind
    let phase: String
    var equity: Double
    var dayPct: Double
    let dayLimitPct: Double
    var drawdownPct: Double
    let drawdownLimitPct: Double
    var targetPct: Double
    let targetGoalPct: Double
    var health: Health
    let cellId: String

    var dayUsed: Double { dayLimitPct > 0 ? min(1, max(0, -dayPct) / dayLimitPct) : 0 }
    var ddUsed: Double { drawdownLimitPct > 0 ? min(1, drawdownPct / drawdownLimitPct) : 0 }
    var targetUsed: Double { targetGoalPct > 0 ? min(1, targetPct / targetGoalPct) : 0 }
}

enum StrategyMode: String {
    case active, shadow, paused

    var label: String {
        switch self {
        case .active: return "Activa"
        case .shadow: return "Sombra"
        case .paused: return "Pausada"
        }
    }

    var tone: Tone {
        switch self {
        case .active: return .good
        case .shadow: return .info
        case .paused: return .neutral
        }
    }
}

struct StrategyWeight: Identifiable {
    var id: String { strategyId }
    let strategyId: String
    var weight: Double
    var mode: StrategyMode
}

struct BotCell: Identifiable {
    let id: String
    let accountId: String
    var health: Health
    let site: String
    let backupSite: String
    let version: String
    var p99: Int
    var rejects24h: Int
    var heartbeat: Double
    var dayPct: Double
    var weights: [StrategyWeight]
    /// Salud técnica 0-100: latido, latencia, rechazos, reloj, datos, conciliación.
    var healthScores: [Double]
    var uptime: [Double]   // 60 días: 1 = sin incidencias, 0.5 = incidencia menor, 0 = parada

    var shortName: String { id.replacingOccurrences(of: "c-", with: "") }
}

// MARK: - Estrategias

struct Param: Identifiable {
    var id: String { key }
    let key: String
    var value: Double
    let previous: Double
    let min: Double
    let max: Double
    let step: Double
    let unit: String
}

struct Strategy: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let color: Color
    let return30d: Double
    let trades: Int
    let hitRate: Double
    let profitFactor: Double
    let maxDrawdown: Double
    var version: Int
    var params: [Param]
    let series: [Double]
    let weeklyRank: [Int]
    let note: String
}

// MARK: - Órdenes

enum Side: String {
    case buy, sell
    var label: String { self == .buy ? "Compra" : "Venta" }
    var arrow: String { self == .buy ? "▲" : "▼" }
}

enum OrderStatus: String {
    case riskOk, sent, accepted, filled, closed, rejected, noStop

    var label: String {
        switch self {
        case .riskOk: return "Riesgo ✓"
        case .sent: return "Enviada"
        case .accepted: return "En curso"
        case .filled: return "Ejecutada"
        case .closed: return "Cerrada"
        case .rejected: return "Rechazada"
        case .noStop: return "Sin stop"
        }
    }

    var tone: Tone {
        switch self {
        case .riskOk, .sent, .accepted: return .info
        case .filled: return .good
        case .closed: return .neutral
        case .rejected: return .bad
        case .noStop: return .warn
        }
    }

    /// Paradas completadas de 4: riesgo, envío, aceptada, ejecutada.
    var steps: Int {
        switch self {
        case .riskOk: return 1
        case .sent: return 2
        case .accepted: return 3
        case .filled, .closed: return 4
        case .rejected, .noStop: return 2
        }
    }
}

struct Order: Identifiable {
    let id: String
    let instrument: String
    let side: Side
    let lots: Double
    let strategyId: String
    let cellId: String
    var status: OrderStatus
    let time: String
    let pnl: Double?
    let entry: Double
    let stop: Double
    let target: Double
    let last: Double
}

struct Hop: Identifiable {
    var id: String { name }
    let name: String
    let ms: Int
    let color: Color
}

struct Funnel {
    let signals: Int
    let riskOk: Int
    let sent: Int
    let filled: Int
}

// MARK: - Avisos, Jev y riesgo

enum AlertLevel: String {
    case critical, warning, info

    var label: String {
        switch self {
        case .critical: return "Crítico"
        case .warning: return "Atención"
        case .info: return "Info"
        }
    }

    var tone: Tone {
        switch self {
        case .critical: return .bad
        case .warning: return .warn
        case .info: return .neutral
        }
    }

    var color: Color {
        switch self {
        case .critical: return Palette.stop
        case .warning: return Palette.warn
        case .info: return Palette.gray
        }
    }
}

struct AlertItem: Identifiable {
    let id: String
    let level: AlertLevel
    let title: String
    let subtitle: String
    let time: String
    let action: String?
    var acknowledged: Bool
}

enum ProposalStatus: String {
    case pending, applied, rejected, shadow

    var tone: Tone {
        switch self {
        case .pending: return .warn
        case .applied: return .good
        case .rejected: return .bad
        case .shadow: return .info
        }
    }
}

struct Vote: Identifiable {
    var id: String { reason }
    let label: String
    let reason: String
    let positive: Bool
}

struct Reading: Identifiable {
    var id: String { name }
    let name: String
    let value: String
    let series: [Double]
}

struct Proposal: Identifiable {
    let id: String
    let title: String
    let short: String
    let summary: String
    let cellId: String
    let strategyId: String
    let newWeight: Double
    let time: String
    var status: ProposalStatus
    let statusText: String
    let votes: [Vote]
    let checks: [String]
    let reads: [Reading]
    let effect: String
    var unread: Bool
}

struct RiskLayer: Identifiable {
    var id: String { name }
    let name: String
    let detail: String
    let used: Double        // 0-100
    let yesterday: Double   // 0-100
}

struct ExposureItem: Identifiable {
    var id: String { name }
    let name: String
    let lots: Double
    let pct: Double
    let isLong: Bool
}

struct RuleUse: Identifiable {
    var id: String { name }
    let name: String
    let text: String
    let fraction: Double
    let warnAt: Double
    let color: Color
}

struct SignedCommand: Identifiable {
    let id = UUID()
    let time: String
    let name: String
    let cell: String
    let key: String
    let result: String
    let accepted: Bool
}

// MARK: - Foto completa del sistema

struct HourBar: Identifiable {
    let id: Int
    let value: Double
}

struct Snapshot {
    var date: Date
    var equity: Double
    var equityDeltaPct: Double
    var dayPct: Double
    let dayLimitPct: Double
    var exposurePct: Double
    var exposureLots: Double
    var ordersToday: Int
    var rejectedToday: Int
    var latencyMs: Int
    var latencyP99: Int
    var equitySeries: [Double]
    var dayPctSeries: [Double]
    var ordersSeries: [Double]
    var latencySeries: [Double]
    var hourly: [HourBar]
    var cells: [BotCell]
    var accounts: [Account]
    var strategies: [Strategy]
    var orders: [Order]
    var alerts: [AlertItem]
    var proposals: [Proposal]
    var layers: [RiskLayer]
    var exposures: [ExposureItem]
    var funnel: Funnel
    var hops: [Hop]
    var rules: [RuleUse]

    var dayLimitUsed: Double { min(1, max(0, -dayPct) / dayLimitPct) }
    var openAlerts: [AlertItem] { alerts.filter { !$0.acknowledged && $0.level != .info } }
    var criticalCount: Int { alerts.filter { !$0.acknowledged && $0.level == .critical }.count }
    var pendingProposals: Int { proposals.filter { $0.status == .pending }.count }

    func strategy(_ id: String) -> Strategy? { strategies.first { $0.id == id } }
    func cell(_ id: String) -> BotCell? { cells.first { $0.id == id } }
    func account(_ id: String) -> Account? { accounts.first { $0.id == id } }
}
