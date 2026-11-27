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
        (.open, "Apertura · Compra GBPJPY 0,10", "···2511 · Ruptura"),
        (.close, "Cierre · EURUSD · +8,60 €", "···4152 · Rebote"),
        (.stop, "Stop movido a breakeven · US500", "···4152 · Impulso"),
        (.signal, "Señal nueva · AUDUSD · confianza 0,66", "Rebote"),
        (.reject, "Rechazada por el bróker · USDJPY", "···2511 · Tendencia"),
        (.close, "Cierre · XAUUSD · −9,40 €", "···4152 · Ruptura"),
        (.warn, "Hora del bróker desfasada 1,4 s", "···4152")
    ]

    init() {
        activity = (0..<24).map { Double(2 + Int(5 * abs(sin(Double($0) * 1.3)))) }
        latency = [380, 410, 395, 430, 412, 405, 398, 420, 412]
        events = [
            Event(time: "10:41:58", kind: .open, title: "Apertura · Venta US500 0,20", detail: "···4152 · Impulso"),
            Event(time: "10:41:07", kind: .reject, title: "Rechazada por el bróker · EURUSD", detail: "···2511 · Rebote"),
            Event(time: "10:30:00", kind: .close, title: "Cierre · GBPUSD · +4,10 €", detail: "···2511 · Tendencia"),
            Event(time: "10:12:31", kind: .warn, title: "Hora del bróker desfasada 1,4 s", detail: "···4152")
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
