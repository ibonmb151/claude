#if os(macOS)
import SwiftUI

struct JevView: View {
    @EnvironmentObject var store: AppStore

    private var proposal: Proposal {
        store.data.proposals.first { $0.id == store.selectedProposalId } ?? store.data.proposals[0]
    }

    var body: some View {
        let d = store.data
        HStack(alignment: .top, spacing: 14) {
            // Bandeja
            VStack(alignment: .leading, spacing: 4) {
                Heading("Jev", info: "Propuestas del decisor. Fase 2: baja pesos solo; para subir necesita tu firma") {
                    Pill(text: "Fase 2", tone: .neutral)
                }
                .padding(.bottom, 6)
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(d.proposals) { p in
                            row(p)
                        }
                    }
                }
            }
            .padding(14)
            .frame(width: 340)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)

            // Lectura
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        IconTile(symbol: "safari", color: Palette.magenta, size: 42, corner: 21)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Jev propone").font(.system(size: 14, weight: .semibold))
                            Text("\(proposal.time) · parte diario de \(proposal.cellId)")
                                .font(.system(size: 13)).foregroundStyle(Palette.ink2)
                        }
                        Spacer()
                        Pill(text: proposal.status == .pending ? "Caduca 12:00" : proposal.statusText, tone: proposal.status.tone)
                    }

                    Text(proposal.title).font(.system(size: 27, weight: .bold)).foregroundStyle(Palette.ink)
                    Text(proposal.summary).font(.system(size: 15)).foregroundStyle(Palette.ink2)

                    HStack(spacing: 10) {
                        ForEach(proposal.reads) { r in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(r.name).font(.system(size: 12)).foregroundStyle(Palette.ink2)
                                HStack(alignment: .bottom) {
                                    Text(r.value).font(.system(size: 21, weight: .semibold)).monospacedDigit()
                                    Spacer()
                                    Sparkline(values: r.series, color: Palette.magenta, lineWidth: 1.8).frame(width: 54, height: 22)
                                }
                            }
                            .padding(11)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Palette.bg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }

                    HStack(alignment: .top, spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            Heading("Tres respuestas · 2 de 3", info: "Jev pregunta tres veces al modelo y se queda con la mayoría")
                            ForEach(proposal.votes) { v in
                                HStack(alignment: .top, spacing: 10) {
                                    Pill(text: v.label, tone: v.positive ? .good : .neutral).frame(minWidth: 70)
                                    Text(v.reason).font(.system(size: 13)).foregroundStyle(Palette.ink)
                                    Spacer(minLength: 0)
                                }
                                .padding(9)
                                .background(Palette.bg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 8) {
                            Heading("Validador", info: "Reglas fijas que la propuesta debe cumplir antes de llegarte")
                            ForEach(proposal.checks, id: \.self) { c in
                                HStack(spacing: 9) {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.pos)
                                    Text(c).font(.system(size: 13)).foregroundStyle(Palette.ink)
                                }
                            }
                            Text("Historial · 9 de 14").font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2).padding(.top, 6)
                            HStack(spacing: 5) {
                                ForEach(0..<14, id: \.self) { i in
                                    Circle().fill([1, 4, 7, 10, 13].contains(i) ? Palette.neg : Palette.pos).frame(width: 14, height: 14)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Si apruebas").font(.system(size: 13, weight: .bold))
                            Text(proposal.effect).font(.system(size: 13)).foregroundStyle(Palette.ink2)
                        }
                        Spacer()
                        if proposal.status == .pending {
                            Button("Rechazar") { store.requestReject(proposal) }.buttonStyle(MymButtonStyle(kind: .secondary))
                            Button("Más datos") {}.buttonStyle(MymButtonStyle(kind: .secondary))
                            Button("Aprobar y firmar") { store.requestApprove(proposal) }.buttonStyle(MymButtonStyle(kind: .primary))
                        } else {
                            Pill(text: proposal.statusText, tone: proposal.status.tone)
                        }
                    }
                    .padding(14)
                    .background(Palette.bg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
    }

    private func row(_ p: Proposal) -> some View {
        let selected = p.id == store.selectedProposalId
        return Button {
            store.selectedProposalId = p.id
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Circle().fill(p.unread ? Palette.magenta : Color.clear).frame(width: 8, height: 8).padding(.top, 6)
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(p.title).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                        Spacer(minLength: 4)
                        Text(p.time).font(.system(size: 12)).foregroundStyle(Palette.ink2)
                    }
                    Text(p.short).font(.system(size: 12)).foregroundStyle(Palette.ink2).lineLimit(1)
                    Pill(text: p.statusText, tone: p.status.tone).padding(.top, 2)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(selected ? Palette.selection : Color.clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Palette.ink)
    }
}
#endif
