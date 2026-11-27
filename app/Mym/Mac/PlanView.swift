#if os(macOS)
import SwiftUI

/// Plan: lo que queremos hacer más adelante. Tres listas (Siguiente, Parking y Hecho)
/// que se pueden ordenar, mover de una a otra, editar y borrar.
struct PlanView: View {
    @EnvironmentObject var plan: PlanStore
    @State private var title = ""
    @State private var note = ""
    @State private var kind: PlanKind = .idea
    @State private var state: PlanState = .parking

    var body: some View {
        ScreenScroll {
            Heading("Plan", info: "Lo que queremos hacer más adelante. Ordénalo, muévelo o bórralo", size: 22)

            addCard

            ResponsiveRow(breakpoint: 1100) {
                ForEach(PlanState.allCases) { s in
                    column(s)
                }
            }
        }
    }

    // MARK: Añadir

    private var addCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                TextField("¿Qué quieres hacer?", text: $title, onCommit: add)
                    .textFieldStyle(.roundedBorder)
                Picker("", selection: $kind) {
                    ForEach(PlanKind.allCases) { k in Text(k.title).tag(k) }
                }
                .labelsHidden()
                .frame(width: 110)
                Picker("", selection: $state) {
                    ForEach(PlanState.allCases) { s in Text(s.title).tag(s) }
                }
                .labelsHidden()
                .frame(width: 120)
                Button("Añadir", action: add)
                    .buttonStyle(MymButtonStyle(kind: .primary, compact: true))
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            TextField("Nota (opcional)", text: $note, onCommit: add)
                .textFieldStyle(.roundedBorder)
        }
        .card(Layout.card)
    }

    private func add() {
        plan.add(title: title, note: note, kind: kind, state: state)
        title = ""
        note = ""
    }

    // MARK: Una lista

    private func column(_ s: PlanState) -> some View {
        let list: [PlanItem] = plan.items(s)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(s.title).font(.system(size: 17, weight: .bold)).foregroundStyle(Palette.ink)
                Pill(text: "\(list.count)", tone: s.tone)
                Spacer()
            }
            if list.isEmpty {
                Text(s == .done ? "Aún no hay nada terminado." : "Nada por aquí.")
                    .font(.system(size: 13)).foregroundStyle(Palette.ink2)
                    .padding(.vertical, 12)
            }
            ForEach(Array(list.enumerated()), id: \.element.id) { index, item in
                row(item, number: index + 1)
                if index < list.count - 1 { Divider() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .card(Layout.card)
    }

    private func row(_ item: PlanItem, number: Int) -> some View {
        let titleBinding = Binding<String>(get: { item.title }, set: { v in plan.update(item.id) { $0.title = v } })
        let noteBinding = Binding<String>(get: { item.note }, set: { v in plan.update(item.id) { $0.note = v } })
        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: item.kind.symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Palette.ink)
                .frame(width: 28, height: 28)
                .background(Palette.neutralBg, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                TextField("Título", text: titleBinding)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .semibold))
                    .strikethrough(item.state == .done)
                    .foregroundColor(item.state == .done ? Palette.ink2 : Palette.ink)
                TextField("Añadir nota", text: noteBinding)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(Palette.ink2)
            }
            Spacer(minLength: 4)
            HStack(spacing: 2) {
                iconButton("chevron.up", "Subir", plan.canShift(item.id, by: -1)) { withAnimation(.easeOut(duration: 0.2)) { plan.shift(item.id, by: -1) } }
                iconButton("chevron.down", "Bajar", plan.canShift(item.id, by: 1)) { withAnimation(.easeOut(duration: 0.2)) { plan.shift(item.id, by: 1) } }
                Menu {
                    ForEach(PlanState.allCases.filter { $0 != item.state }) { s in
                        Button("Pasar a \(s.title)") { withAnimation(.easeOut(duration: 0.2)) { plan.move(item.id, to: s) } }
                    }
                    Divider()
                    Button("Borrar") { withAnimation(.easeOut(duration: 0.2)) { plan.remove(item.id) } }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 28, height: 28)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
            }
        }
        .padding(.vertical, 6)
    }

    private func iconButton(_ symbol: String, _ label: String, _ enabled: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .frame(width: 28, height: 28)
                .foregroundStyle(enabled ? Palette.ink : Palette.graphiteSoft)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .help(label)
    }
}
#endif
