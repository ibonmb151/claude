import SwiftUI

/// Actividad simulada para el modo demostración de En vivo (Mac e iPhone).
final class LiveFeed: ObservableObject {
    enum Kind { case open, close, reject, warn, stop, signal }

    struct Event: Identifiable {
        let id = UUID()
        let time: String
        let kind: Kind
        let title: String
        let detail: String
    }

    @Published var events: [Event] = []
    @Published var jitter: [String: Double] = [:]      // lo que se ha movido cada trade desde su valor base
    @Published var activity: [Double] = []
    @Published var latency: [Double] = []
    @Published var signals = 142
    @Published var executed = 121
    @Published var rejected = 7
    @Published var lastUpdate = Date()

    private var timer: Timer?
    private let clock: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private let pool: [(Kind, String, String)] = [
        (.open, "Se abrió una compra de GBPJPY", ""),
        (.close, "Cerró EURUSD con +8,60 €", ""),
        (.stop, "US500 ya está protegida en el precio de entrada", ""),
        (.signal, "Posible compra de AUDUSD detectada", ""),
        (.reject, "El bróker rechazó una orden de USDJPY", ""),
        (.close, "Cerró XAUUSD con −9,40 €", ""),
        (.warn, "La hora del bróker va 1,4 s desfasada", "")
    ]

    init() {
        activity = (0..<24).map { Double(2 + Int(5 * abs(sin(Double($0) * 1.3)))) }
        latency = [380, 410, 395, 430, 412, 405, 398, 420, 412]
        events = [
            Event(time: "10:41:58", kind: .open, title: "Se abrió una venta de US500", detail: ""),
            Event(time: "10:41:07", kind: .reject, title: "El bróker rechazó una orden de EURUSD", detail: ""),
            Event(time: "10:30:00", kind: .close, title: "Cerró GBPUSD con +4,10 €", detail: ""),
            Event(time: "10:12:31", kind: .warn, title: "La hora del bróker va 1,4 s desfasada", detail: "")
        ]
    }

    func start(labels: [String]) {
        stop()
        var seeded: [String: Double] = [:]
        for l in labels { seeded[l] = jitter[l] ?? 0 }
        jitter = seeded
        timer = Timer.scheduledTimer(withTimeInterval: 2.3, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        lastUpdate = Date()
        var next: [String: Double] = jitter
        for k in jitter.keys { next[k] = (jitter[k] ?? 0) + Double.random(in: -1.6...1.4) }
        jitter = next
        activity = Array(activity.dropFirst()) + [Double(1 + Int.random(in: 0...6))]
        latency = Array(latency.dropFirst()) + [Double(380 + Int.random(in: 0...90))]
        if Double.random(in: 0...1) < 0.7, let p = pool.randomElement() {
            events.insert(Event(time: clock.string(from: Date()), kind: p.0, title: p.1, detail: p.2), at: 0)
            if events.count > 9 { events.removeLast() }
            if p.0 == .signal { signals += 1 }
            if p.0 == .close { executed += 1 }
            if p.0 == .reject { rejected += 1 }
        }
    }

    func movement(_ label: String) -> Double { jitter[label] ?? 0 }
}
