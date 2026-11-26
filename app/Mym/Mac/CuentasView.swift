#if os(macOS)
import SwiftUI

struct CuentasView: View {
    @EnvironmentObject var store: AppStore

    private var selected: Account {
        store.data.accounts.first { $0.id == store.selectedAccountId } ?? store.data.accounts[0]
    }

    var body: some View {
        let d = store.data
        ScreenScroll {
            Heading("Cuentas", info: "Cada cuenta con las reglas de su firma en tres anillos: objetivo, pérdida del día y drawdown", size: 20)

            HStack(spacing: 14) {
                ForEach(d.accounts) { account in
                    AccountCard(account: account, selected: account.id == store.selectedAccountId)
                        .onTapGesture { store.selectedAccountId = account.id }
                }
            }

            HStack(spacing: 18) {
                legend(Palette.info, "objetivo")
                legend(Palette.warn, "pérdida del día")
                legend(Palette.violet, "drawdown")
            }

            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Heading("\(selected.id) · Proyección",
                            info: "5.000 simulaciones al ritmo de los últimos 60 días: probabilidad de llegar al objetivo antes de romper una regla") {
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("78 %").font(.system(size: 30, weight: .bold)).foregroundStyle(Palette.ink)
                            Text("llega al objetivo").font(.system(size: 12)).foregroundStyle(Palette.ink2)
                        }
                    }
                    FanChart(start: selected.targetPct, target: selected.targetGoalPct, floor: -selected.drawdownLimitPct, days: 30)
                        .frame(height: 280)
                    HStack {
                        Text("hoy").font(.system(size: 11)).foregroundStyle(Palette.ink2)
                        Spacer()
                        Text("+15 d").font(.system(size: 11)).foregroundStyle(Palette.ink2)
                        Spacer()
                        Text("+30 d").font(.system(size: 11)).foregroundStyle(Palette.ink2)
                    }
                }
                .card(16)
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 4) {
                    Heading("Reglas", info: "Las reglas de la firma y cuánto se ha usado de cada una. La raya marca el aviso")
                        .padding(.bottom, 6)
                    ForEach(d.rules) { rule in
                        VStack(spacing: 5) {
                            HStack {
                                Text(rule.name).font(.system(size: 13)).foregroundStyle(Palette.ink)
                                Spacer()
                                Text(rule.text).font(.system(size: 13, weight: .bold)).foregroundStyle(Palette.ink).monospacedDigit()
                            }
                            ProgressTrack(fraction: rule.fraction, color: rule.color, warnAt: rule.warnAt)
                        }
                        .padding(.vertical, 6)
                    }
                    Spacer(minLength: 8)
                    HStack {
                        Spacer()
                        Button("Pausar cuenta") { store.requestPause(selected.cellId) }
                            .buttonStyle(MymButtonStyle(kind: .danger, compact: true))
                    }
                }
                .card(16)
                .frame(width: 340)
            }
        }
    }

    private func legend(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text).font(.system(size: 12)).foregroundStyle(Palette.ink2)
        }
    }
}

struct AccountCard: View {
    let account: Account
    var selected: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    Image(systemName: "shield.fill").font(.system(size: 22)).foregroundStyle(account.kind.color)
                    Text(account.kind.letter).font(.system(size: 10, weight: .heavy)).foregroundStyle(Color.white)
                }
                Text(account.id)
                    .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 2)
                Pill(text: account.health.label, tone: account.health.tone)
            }
            HStack(spacing: 10) {
                RingsView(rings: [
                    RingSpec(progress: account.targetUsed, color: Palette.info),
                    RingSpec(progress: account.dayUsed, color: Palette.warn),
                    RingSpec(progress: account.ddUsed, color: Palette.violet)
                ], lineWidth: 9, gap: 3)
                .frame(width: 84, height: 84)
                VStack(alignment: .leading, spacing: 3) {
                    Text(Fmt.eur(account.equity))
                        .font(.system(size: 16, weight: .bold)).monospacedDigit().minimumScaleFactor(0.7).lineLimit(1)
                    line(Palette.info, Fmt.comma(account.targetPct, 1) + " / " + Fmt.comma(account.targetGoalPct, 0) + " %")
                    line(Palette.warn, Fmt.comma(max(0, -account.dayPct), 1) + " / " + Fmt.comma(account.dayLimitPct, 0) + " %")
                    line(Palette.violet, Fmt.comma(account.drawdownPct, 1) + " / " + Fmt.comma(account.drawdownLimitPct, 0) + " %")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(14, selected: selected)
    }

    private func line(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(text).font(.system(size: 11.5)).foregroundStyle(Palette.ink).monospacedDigit()
        }
    }
}
#endif
