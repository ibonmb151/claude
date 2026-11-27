import SwiftUI

/// Plan: lo que queremos hacer más adelante. Una lista con orden propio:
/// "Siguiente" es lo que toca ahora, "Parking" lo que se guarda para más tarde y "Hecho" lo terminado.
enum PlanState: String, Codable, CaseIterable, Identifiable {
    case next, parking, done

    var id: String { rawValue }

    var title: String {
        switch self {
        case .next: return "Siguiente"
        case .parking: return "Parking"
        case .done: return "Hecho"
        }
    }

    var tone: Tone {
        switch self {
        case .next: return .info
        case .parking: return .neutral
        case .done: return .good
        }
    }
}

enum PlanKind: String, Codable, CaseIterable, Identifiable {
    case idea, mejora, arreglo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .idea: return "Idea"
        case .mejora: return "Mejora"
        case .arreglo: return "Arreglo"
        }
    }

    var symbol: String {
        switch self {
        case .idea: return "lightbulb"
        case .mejora: return "sparkles"
        case .arreglo: return "wrench.and.screwdriver"
        }
    }
}

struct PlanItem: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var note: String = ""
    var kind: PlanKind = .idea
    var state: PlanState = .parking
}

final class PlanStore: ObservableObject {
    static let shared = PlanStore()

    /// El orden de la lista es el orden de prioridad dentro de cada grupo.
    @Published private(set) var items: [PlanItem] = []
    private let key = "mym.plan"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([PlanItem].self, from: data) {
            items = saved
        } else {
            items = PlanStore.starter
            persist()
        }
    }

    private static var starter: [PlanItem] {
        [
            PlanItem(title: "Conectar una cuenta real de bróker", note: "Empezar por la que tiene API abierta.", kind: .mejora, state: .next),
            PlanItem(title: "Avisos en el Mac cuando algo va mal", note: "Una notificación, sin abrir la app.", kind: .mejora, state: .next),
            PlanItem(title: "Widgets que abran la pantalla correcta", kind: .mejora, state: .parking),
            PlanItem(title: "Actividad en directo en la pantalla de bloqueo", note: "Hace falta cuenta de desarrollador de pago.", kind: .idea, state: .parking),
            PlanItem(title: "Informe semanal en PDF", kind: .idea, state: .parking)
        ]
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func items(_ state: PlanState) -> [PlanItem] {
        items.filter { $0.state == state }
    }

    func count(_ state: PlanState) -> Int {
        items.filter { $0.state == state }.count
    }

    func add(title: String, note: String, kind: PlanKind, state: PlanState) {
        let t: String = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return }
        items.append(PlanItem(title: t, note: note.trimmingCharacters(in: .whitespacesAndNewlines), kind: kind, state: state))
        persist()
    }

    func update(_ id: UUID, _ change: (inout PlanItem) -> Void) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        change(&items[i])
        persist()
    }

    func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
        persist()
    }

    /// Cambia de grupo y lo deja al final del nuevo.
    func move(_ id: UUID, to state: PlanState) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        var item: PlanItem = items.remove(at: i)
        item.state = state
        items.append(item)
        persist()
    }

    /// Sube o baja una posición dentro de su grupo.
    func shift(_ id: UUID, by step: Int) {
        guard let current = items.firstIndex(where: { $0.id == id }) else { return }
        let state: PlanState = items[current].state
        let group: [Int] = items.indices.filter { items[$0].state == state }
        guard let pos = group.firstIndex(of: current) else { return }
        let target: Int = pos + step
        if target < 0 || target >= group.count { return }
        items.swapAt(current, group[target])
        persist()
    }

    /// Arrastrar y soltar dentro de un grupo.
    func reorder(_ state: PlanState, from: IndexSet, to: Int) {
        var group: [PlanItem] = items(state)
        group.move(fromOffsets: from, toOffset: to)
        var merged: [PlanItem] = []
        for s in PlanState.allCases {
            if s == state {
                merged.append(contentsOf: group)
            } else {
                merged.append(contentsOf: items(s))
            }
        }
        items = merged
        persist()
    }

    func canShift(_ id: UUID, by step: Int) -> Bool {
        guard let current = items.firstIndex(where: { $0.id == id }) else { return false }
        let state: PlanState = items[current].state
        let group: [Int] = items.indices.filter { items[$0].state == state }
        guard let pos = group.firstIndex(of: current) else { return false }
        let target: Int = pos + step
        return target >= 0 && target < group.count
    }
}
