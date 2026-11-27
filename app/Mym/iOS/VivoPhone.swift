#if os(iOS)
import SwiftUI

/// En vivo en el iPhone: flotante, trades abiertos, actividad y respuesta del bróker.
struct EnVivoPhoneView: View {
    @EnvironmentObject var accounts: AccountStore
    @StateObject private var feed = LiveFeed()

    private var demo: Bool { accounts.bundle.source == .demo }
    private var open: [TradeRecord] {
        accounts.bundle.trades.filter { $0.isOpen && accounts.bundle.inScope($0.cuenta, accounts.scope) }
    }

    private func current(_ t: TradeRecord) -> Double? {
        guard let base = t.pnl else { return nil }
        return demo ? base + feed.movement(t.label) : base
    }

    var body: some View {
        let values: [Double] = open.compactMap { current($0) }
        let floating: Double? = values.isEmpty ? nil : values.reduce(0, +)
        PhoneScreen(title: "En vivo") {
            VStack(alignment: .leading, spacing: 4) {
                Text("Flotante ahora").font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2)
                Text(Fmt.opt(floating) { Fmt.signedEur2($0) })
                    .font(.system(size: 36, weight: .bold)).foregroundStyle(resultColor(floating)).monospacedDigit()
                Text("\(open.count) trades abiertos").font(.system(size: 13)).foregroundStyle(Palette.ink2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(Layout.card)

            VStack(alignment: .leading, spacing: 6) {
                Heading("Trades abiertos", info: "Resultado flotante de cada uno")
                ForEach(open) { t in
                    HStack(spacing: 8) {
                        Text(t.par ?? "?").font(.system(size: 13, weight: .bold, design: .monospaced))
                        Pill(text: t.lado == "venta" ? "Venta" : "Compra", tone: t.lado == "venta" ? .bad : .good)
                        if t.isUnprotected { Pill(text: "Sin stop", tone: .bad) }
                        Spacer()
                        Text(Fmt.opt(current(t)) { Fmt.signedEur2($0) })
                            .font(.system(size: 14, weight: .bold)).foregroundStyle(resultColor(current(t))).monospacedDigit()
                    }
                    .padding(.vertical, 3)
                }
            }
            .card(Layout.card)

            VStack(alignment: .leading, spacing: 4) {
                Heading("Actividad", info: "Lo más nuevo, arriba")
                ForEach(feed.events.prefix(5)) { e in
                    HStack(spacing: 10) {
                        Text(e.title).font(.system(size: 14, weight: .semibold)).lineLimit(2)
                        Spacer()
                        Text(e.time).font(.system(size: 12)).foregroundStyle(Palette.ink2).monospacedDigit()
                    }
                    .padding(.vertical, 5)
                    Divider()
                }
            }
            .card(Layout.card)

            NavigationLink {
                OrdenesPhoneView()
            } label: {
                HStack {
                    Text("Todas las órdenes de hoy").font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.ink2)
                }
                .foregroundStyle(Palette.ink)
                .card(Layout.cardSmall)
            }
            .buttonStyle(.plain)
        }
        .onAppear { if demo { feed.start(labels: open.map { $0.label }) } }
        .onDisappear { feed.stop() }
    }
}

/// Resultados en el iPhone: cuánto se ha ganado o perdido y cómo.
struct ResultadosPhoneView: View {
    private enum Period: String, CaseIterable, Identifiable {
        case semana = "Semana"
        case mes = "Mes"

        var id: String { rawValue }
        var days: Int { self == .semana ? 7 : 30 }
    }

    @EnvironmentObject var accounts: AccountStore
    @State private var period: Period = .mes

    var body: some View {
        let bundle: AccountBundle = accounts.bundle
        let daily: [Double] = Array(bundle.dailySeries(accounts.scope).suffix(period.days))
        let total: Double? = daily.isEmpty ? nil : daily.reduce(0, +)
        let summary: AccountSummary = bundle.summary(for: accounts.scope)
        PhoneScreen(title: "Resultados") {
            Picker("", selection: $period) {
                ForEach(Period.allCases) { p in Text(p.rawValue).tag(p) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            VStack(alignment: .leading, spacing: 4) {
                Text(period == .semana ? "Esta semana" : "Últimos 30 días").font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2)
                Text(Fmt.opt(total) { Fmt.signedEur2($0) })
                    .font(.system(size: 36, weight: .bold)).foregroundStyle(resultColor(total)).monospacedDigit().minimumScaleFactor(0.7).lineLimit(1)
                Text("Realizado. No incluye lo flotante.").font(.system(size: 12)).foregroundStyle(Palette.ink2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(Layout.card)

            HStack(spacing: 12) {
                cell("Acierto", Fmt.opt(summary.winRate) { Fmt.pct($0, 1) })
                cell("Profit factor", Fmt.opt(summary.profitFactor) { Fmt.comma($0, 2) })
            }

            VStack(alignment: .leading, spacing: 8) {
                Heading("Resultado por día", info: "Verde gana, rojo pierde")
                if daily.isEmpty {
                    Text("n.d.").font(.system(size: 13)).foregroundStyle(Palette.ink2)
                } else {
                    DailyBarsChart(values: daily, height: 190, yText: { Fmt.comma($0, 0) })
                }
            }
            .card(Layout.card)
        }
    }

    private func cell(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2)
            Text(value).font(.system(size: 22, weight: .bold)).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(Layout.cardSmall)
    }
}
#endif
