import SwiftUI

/// Hoja «Firmar y enviar». La misma en Mac y en iPhone.
struct SignSheet: View {
    @EnvironmentObject var store: AppStore
    let command: PendingCommand
    @State private var seconds = 120
    @State private var working = false
    @State private var failed = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Firmar y enviar")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.ink2)
                Spacer()
                if command.critical { Pill(text: "Acción crítica", tone: .bad) }
            }

            Text(command.title)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Palette.ink)
            Text(command.detail)
                .font(.system(size: 14))
                .foregroundStyle(Palette.ink2)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 0) {
                row("Comando", command.name, mono: true)
                row("Alcance", command.scope)
                row("Quién firma", "op-03 · rol operador")
                row("Algoritmo", "Ed25519 sobre JSON canónico")
                row("Caduca en", String(format: "%d:%02d", seconds / 60, seconds % 60))
            }
            .padding(12)
            .background(Palette.bg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            ProgressTrack(fraction: Double(seconds) / 120, color: seconds < 30 ? Palette.warn : Palette.graphite, height: 6)

            if failed {
                Text("No se pudo confirmar. Inténtalo de nuevo.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.negText)
            }

            HStack(spacing: 10) {
                Button("Cancelar") { store.pending = nil }
                    .buttonStyle(MymButtonStyle(kind: .secondary))
                Spacer()
                Button(working ? "Confirmando…" : "Firmar y enviar") { sign() }
                    .buttonStyle(MymButtonStyle(kind: command.critical ? .danger : .primary))
                    .disabled(working || seconds == 0)
            }
        }
        .padding(24)
        .frame(minWidth: 380, idealWidth: 460)
        .background(Palette.card)
        .onReceive(timer) { _ in
            if seconds > 0 { seconds -= 1 }
        }
    }

    private func row(_ label: String, _ value: String, mono: Bool = false) -> some View {
        HStack {
            Text(label).foregroundStyle(Palette.ink2)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(Palette.ink)
                .font(mono ? .system(size: 13, design: .monospaced) : .system(size: 13))
        }
        .font(.system(size: 13))
        .padding(.vertical, 5)
    }

    private func sign() {
        working = true
        failed = false
        Biometrics.confirm(reason: "Confirma para firmar: \(command.title)") { ok in
            working = false
            if ok {
                store.execute(command)
            } else {
                failed = true
            }
        }
    }
}

// MARK: - Estilo de botón de la app

struct MymButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, danger }
    var kind: Kind = .secondary
    var compact: Bool = false

    private var foreground: Color {
        switch kind {
        case .primary, .danger: return Color.white
        case .secondary: return Palette.ink
        }
    }

    private var background: Color {
        switch kind {
        case .primary: return Palette.graphiteDark
        case .secondary: return Palette.neutralBg
        case .danger: return Palette.stop
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 12.5 : 14, weight: .semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, compact ? 12 : 18)
            .frame(height: compact ? 28 : 38)
            .background(background.opacity(configuration.isPressed ? 0.8 : 1), in: Capsule())
    }
}
