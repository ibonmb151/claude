#if os(iOS)
import SwiftUI

/// Resumen de la cuenta para el iPhone: balance, seis cifras y lo que hay abierto. Solo lectura.
/// El análisis largo (rendimiento por módulo, datos y claves) se hace en el Mac.
struct CuentaPhoneCard: View {
    @EnvironmentObject var accounts: AccountStore

    var body: some View {
        let bundle: AccountBundle = accounts.bundle
        let s: AccountSummary = bundle.summary(for: accounts.scope)
        let open: [TradeRecord] = bundle.trades.filter { $0.isOpen && bundle.inScope($0.cuenta, accounts.scope) }
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                chip("Ambas", .all)
                ForEach(bundle.accounts) { a in
                    chip(maskedAccount(a.cuenta), .one(a.cuenta))
                }
                Spacer()
                Pill(text: s.state.label, tone: s.state == .error ? .bad : (s.state == .demo ? .info : .good))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Balance").font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2)
                Text(Fmt.opt(s.balance) { Fmt.eur2($0) })
                    .font(.system(size: 28, weight: .bold)).monospacedDigit().foregroundStyle(Palette.ink)
                Text(dayText(s))
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(resultColor(s.dayChange)).monospacedDigit()
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                cell("Flotante", Fmt.opt(s.floating) { Fmt.signedEur2($0) }, resultColor(s.floating))
                cell("Trades abiertos", "\(s.openCount)", Palette.ink)
                cell("Acierto · 30 d", Fmt.opt(s.winRate) { Fmt.pct($0, 1) }, (s.winRate ?? 0) > 50 ? Palette.posText : Palette.ink)
                cell("Profit factor", Fmt.opt(s.profitFactor) { Fmt.comma($0, 2) }, (s.profitFactor ?? 0) > 1.3 ? Palette.posText : Palette.ink)
                cell("Caída máxima", Fmt.opt(s.maxDrawdown) { Fmt.signedPct($0, 2) }, s.maxDrawdown == nil ? Palette.ink2 : Palette.negText)
                cell("Riesgo usado", Fmt.opt(s.riskUsed) { Fmt.pct($0, 1) }, (s.riskUsed ?? 0) < 3 ? Palette.posText : Palette.warnText)
            }
            if !open.isEmpty {
                Divider()
                ForEach(open) { t in
                    HStack(spacing: 8) {
                        Text(t.par ?? "?").font(.system(size: 14, weight: .bold, design: .monospaced))
                        Pill(text: t.lado == "venta" ? "Venta" : "Compra", tone: t.lado == "venta" ? .bad : .good)
                        if t.isUnprotected { Pill(text: "Sin stop", tone: .bad) }
                        Spacer()
                        Text(Fmt.opt(t.pnl) { Fmt.signedEur2($0) })
                            .font(.system(size: 14, weight: .bold)).foregroundStyle(resultColor(t.pnl)).monospacedDigit()
                    }
                }
            }
        }
        .card(16)
    }

    private func dayText(_ s: AccountSummary) -> String {
        guard let d = s.dayChange else { return "n.d. hoy" }
        let pct: String = s.dayChangePct.map { " · " + Fmt.signedPct($0, 2) } ?? ""
        return Fmt.signedEur2(d) + pct + " hoy"
    }

    private func chip(_ title: String, _ scope: AccountScope) -> some View {
        let on: Bool = accounts.scope == scope
        return Button {
            accounts.scope = scope
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(on ? Color.white : Palette.ink)
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(on ? Palette.graphiteDark : Palette.neutralBg, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func cell(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2).lineLimit(1)
            Text(value).font(.system(size: 18, weight: .bold)).foregroundStyle(color).monospacedDigit().lineLimit(1).minimumScaleFactor(0.8)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.bg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
#endif
