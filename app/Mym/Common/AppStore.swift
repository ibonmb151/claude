import SwiftUI
import LocalAuthentication

// MARK: - Comandos que se firman

enum CommandAction {
    case stopAll
    case pause(cellId: String)
    case resume(cellId: String)
    case approve(proposalId: String)
    case reject(proposalId: String)
    case relay(cellId: String)
    case submitConfig(strategyId: String)
}

struct PendingCommand: Identifiable {
    let id = UUID()
    let name: String          // p. ej. halt_all
    let title: String         // p. ej. Parar todo
    let detail: String
    let scope: String
    let critical: Bool
    let action: CommandAction
}

// MARK: - Almacén de datos de la app (todo ficticio)

final class AppStore: ObservableObject {
    @Published var data: Snapshot
    @Published var log: [SignedCommand] = []
    @Published var module: Module = .torre
    @Published var showSearch = false
    @Published var pending: PendingCommand?
    @Published var selectedOrderId: String = "#A7F3-21"
    @Published var selectedStrategyId: String = "Rebote"
    @Published var selectedProposalId: String = "p1"
    @Published var selectedAccountId: String = "Fondeo B · 50k"
    @Published var selectedCellId: String = "Londres 2"

    /// Instancia única: la comparten la ventana y el icono de la barra de menús.
    static let shared = AppStore()

    private var timer: Timer?
    private var tickCount = 0

    init() {
        data = MockData.make()
        log = [
            SignedCommand(time: "08:00:03", name: "weights", cell: "Londres 2", key: "jev-01", result: "Aceptado · Rebote a 0,5", accepted: true),
            SignedCommand(time: "07:58:40", name: "resume_confirm", cell: "Londres 1", key: "op-03", result: "Aceptado", accepted: true),
            SignedCommand(time: "07:57:12", name: "resume_request", cell: "Londres 1", key: "op-03", result: "Aceptado", accepted: true),
            SignedCommand(time: "ayer 22:40", name: "resume_request", cell: "Londres 4", key: "mov-02", result: "Rechazado · el móvil no puede reanudar", accepted: false)
        ]
        startLive()
    }

    // MARK: Simulación en vivo (muy ligera)

    private func startLive() {
        timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        tickCount += 1
        let wobble = Int(sin(Double(tickCount) * 1.3) * 18)
        data.latencyMs = max(300, 412 + wobble)
        data.date = Date()
        for i in data.cells.indices where data.cells[i].health != .paused {
            data.cells[i].heartbeat = max(0.5, data.cells[i].heartbeat + sin(Double(tickCount + i)) * 0.05)
        }
    }

    // MARK: Peticiones de comando (abren la hoja de firma)

    func requestStopAll() {
        let active = data.cells.filter { $0.health != .paused }.count
        pending = PendingCommand(
            name: "halt_all", title: "Parar todo",
            detail: "Detiene las órdenes nuevas en todas las células. Las posiciones abiertas conservan su stop.",
            scope: "\(active) células activas", critical: true, action: .stopAll)
    }

    func requestPause(_ cellId: String) {
        pending = PendingCommand(
            name: "pause", title: "Pausar \(cellId)",
            detail: "La célula deja de abrir órdenes. Reanudar son dos comandos desde el Mac.",
            scope: cellId, critical: true, action: .pause(cellId: cellId))
    }

    func requestResume(_ cellId: String) {
        pending = PendingCommand(
            name: "resume_request", title: "Reanudar \(cellId)",
            detail: "Primer paso de dos. Después hay que confirmar en menos de 5 minutos.",
            scope: cellId, critical: false, action: .resume(cellId: cellId))
    }

    func requestApprove(_ p: Proposal) {
        pending = PendingCommand(
            name: "weights", title: "Aprobar y firmar",
            detail: "\(p.title). \(p.effect).",
            scope: p.cellId, critical: false, action: .approve(proposalId: p.id))
    }

    func requestReject(_ p: Proposal) {
        pending = PendingCommand(
            name: "reject", title: "Rechazar propuesta",
            detail: p.title, scope: p.cellId, critical: false, action: .reject(proposalId: p.id))
    }

    func requestRelay(_ cellId: String) {
        pending = PendingCommand(
            name: "relay", title: "Relevo manual",
            detail: "Pasa el cerrojo de la sede principal a la reserva. Solo con el motor sin órdenes en vuelo.",
            scope: cellId, critical: true, action: .relay(cellId: cellId))
    }

    func requestSubmitConfig(_ strategy: Strategy) {
        pending = PendingCommand(
            name: "config", title: "Solicitar aprobación",
            detail: "Borrador v\(strategy.version + 1) de \(strategy.id). Pasa por gemelo, aprobación y 5 días en demo.",
            scope: strategy.id, critical: false, action: .submitConfig(strategyId: strategy.id))
    }

    // MARK: Ejecución (simulada)

    func execute(_ cmd: PendingCommand) {
        var result = "Aceptado"
        var scope = cmd.scope
        switch cmd.action {
        case .stopAll:
            for i in data.cells.indices { data.cells[i].health = .paused }
            for i in data.accounts.indices { data.accounts[i].health = .paused }
            result = "Aceptado · todas las células paradas"
            scope = "*"
        case .pause(let id):
            setHealth(cell: id, .paused)
        case .resume(let id):
            setHealth(cell: id, .ok)
            result = "Aceptado · falta resume_confirm"
        case .approve(let pid):
            if let idx = data.proposals.firstIndex(where: { $0.id == pid }) {
                data.proposals[idx].status = .applied
                data.proposals[idx].unread = false
                let prop = data.proposals[idx]
                if let ci = data.cells.firstIndex(where: { $0.id == prop.cellId }),
                   let wi = data.cells[ci].weights.firstIndex(where: { $0.strategyId == prop.strategyId }) {
                    data.cells[ci].weights[wi].weight = prop.newWeight
                }
                result = "Aceptado · \(prop.strategyId) a \(Fmt.comma(prop.newWeight, 1))"
            }
        case .reject(let pid):
            if let idx = data.proposals.firstIndex(where: { $0.id == pid }) {
                data.proposals[idx].status = .rejected
                data.proposals[idx].unread = false
            }
            result = "Registrado · rechazada"
        case .relay:
            result = "Aceptado · cerrojo en Bilbao"
        case .submitConfig:
            result = "Registrado · borrador enviado al gemelo"
        }
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        log.insert(SignedCommand(time: f.string(from: Date()), name: cmd.name, cell: scope, key: "op-03", result: result, accepted: true), at: 0)
        pending = nil
    }

    private func setHealth(cell id: String, _ health: Health) {
        if let i = data.cells.firstIndex(where: { $0.id == id }) {
            data.cells[i].health = health
            if let ai = data.accounts.firstIndex(where: { $0.id == data.cells[i].accountId }) {
                data.accounts[ai].health = health
            }
        }
    }

    func acknowledge(_ alertId: String) {
        if let i = data.alerts.firstIndex(where: { $0.id == alertId }) { data.alerts[i].acknowledged = true }
    }

    func acknowledgeAll() {
        for i in data.alerts.indices { data.alerts[i].acknowledged = true }
    }

    func setWeight(cell: String, strategy: String, delta: Double) {
        guard let ci = data.cells.firstIndex(where: { $0.id == cell }),
              let wi = data.cells[ci].weights.firstIndex(where: { $0.strategyId == strategy }) else { return }
        let w = data.cells[ci].weights[wi].weight + delta
        data.cells[ci].weights[wi].weight = min(1, max(0, (w * 100).rounded() / 100))
    }
}

// MARK: - Autenticación biométrica (Face ID / Touch ID)

enum Biometrics {
    /// Pide Face ID o Touch ID. Si el dispositivo no puede, deja pasar (modo demo).
    static func confirm(reason: String, completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                DispatchQueue.main.async { completion(success) }
            }
        } else {
            completion(true)
        }
    }
}
