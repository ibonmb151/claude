#if os(iOS)
import SwiftUI

/// Estado de cada cuenta para el iPhone: saldo y margen libre. Solo lectura.
/// Lo de ahora está en En vivo; el rendimiento, en Resultados; las claves y las cuentas se gestionan en el Mac.
struct CuentaPhoneCard: View {
    @EnvironmentObject var accounts: AccountStore

    var body: some View {
        let bundle: AccountBundle = accounts.bundle
        VStack(alignment: .leading, spacing: 8) {
            Heading("Cuentas", info: "Saldo y margen libre de cada cuenta") {
                Pill(text: bundle.summary(for: .all).state.label, tone: bundle.source == .demo ? .info : .good)
            }
            ForEach(bundle.accounts) { a in
                HStack(spacing: 10) {
                    Text(maskedAccount(a.cuenta)).font(.system(size: 13, design: .monospaced)).foregroundStyle(Palette.ink2)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(Fmt.opt(a.balance) { Fmt.eur2($0) })
                            .font(.system(size: 15, weight: .bold)).monospacedDigit()
                        Text("margen libre " + Fmt.opt(freePct(a)) { Fmt.pct($0, 0) })
                            .font(.system(size: 12)).foregroundStyle(Palette.ink2)
                    }
                }
                .padding(.vertical, 4)
                if a.cuenta != bundle.accounts.last?.cuenta { Divider() }
            }
        }
        .card(Layout.card)
    }

    private func freePct(_ a: AccountMetrics) -> Double? {
        guard let u = a.marginUsed, let f = a.marginFree, u + f > 0 else { return nil }
        return f / (u + f) * 100
    }
}
#endif
