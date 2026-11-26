import SwiftUI

// MARK: - Tarjeta

struct CardStyle: ViewModifier {
    var padding: CGFloat = 16
    var selected: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Palette.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(selected ? Palette.graphiteSoft : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func card(_ padding: CGFloat = 16, selected: Bool = false) -> some View {
        modifier(CardStyle(padding: padding, selected: selected))
    }
}

// MARK: - Píldora de estado

struct Pill: View {
    let text: String
    var tone: Tone = .neutral

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(tone.fg)
            .padding(.horizontal, 9)
            .frame(height: 22)
            .background(tone.bg, in: Capsule())
            .lineLimit(1)
            .fixedSize()
    }
}

// MARK: - Botón de información (ⓘ)

struct InfoButton: View {
    let text: String
    @State private var shown = false

    var body: some View {
        Button {
            shown.toggle()
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Palette.ink2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Información")
        .popover(isPresented: $shown) {
            Text(text)
                .font(.callout)
                .foregroundStyle(Palette.ink)
                .padding(12)
                .frame(maxWidth: 260, alignment: .leading)
        }
    }
}

/// Título corto con su ⓘ, y un elemento opcional a la derecha.
struct Heading<Trailing: View>: View {
    let title: String
    let info: String?
    let size: CGFloat
    let trailing: () -> Trailing

    init(_ title: String, info: String? = nil, size: CGFloat = 15, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title
        self.info = info
        self.size = size
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(Palette.ink)
            if let info {
                InfoButton(text: info)
            }
            Spacer(minLength: 8)
            trailing()
        }
    }
}

extension Heading where Trailing == EmptyView {
    init(_ title: String, info: String? = nil, size: CGFloat = 15) {
        self.init(title, info: info, size: size) { EmptyView() }
    }
}

// MARK: - Punto de estado y cuadrado de icono

struct StatusDot: View {
    let color: Color
    var size: CGFloat = 8
    var body: some View {
        Circle().fill(color).frame(width: size, height: size)
    }
}

struct IconTile: View {
    let symbol: String
    let color: Color
    var size: CGFloat = 30
    var corner: CGFloat = 8

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(Color.white)
            .frame(width: size, height: size)
            .background(color, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
}

// MARK: - Fila con etiqueta y valor

struct LabeledValue: View {
    let label: String
    let value: String
    var valueColor: Color = Palette.ink

    var body: some View {
        HStack {
            Text(label).foregroundStyle(Palette.ink2)
            Spacer(minLength: 8)
            Text(value).fontWeight(.semibold).foregroundStyle(valueColor).monospacedDigit()
        }
        .font(.system(size: 13))
        .padding(.vertical, 7)
    }
}

// MARK: - Barra de progreso

struct ProgressTrack: View {
    let fraction: Double
    var color: Color = Palette.graphite
    var warnAt: Double? = nil
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.track)
                Capsule().fill(color)
                    .frame(width: max(height, g.size.width * CGFloat(min(max(fraction, 0), 1))))
                if let warnAt {
                    Rectangle()
                        .fill(Palette.ink.opacity(0.35))
                        .frame(width: 2, height: height + 6)
                        .offset(x: g.size.width * CGFloat(warnAt) - 1)
                }
            }
        }
        .frame(height: height)
    }
}

/// Cuatro paradas de una orden (riesgo, envío, aceptada, ejecutada).
struct StepBar: View {
    let done: Int
    var total: Int = 4
    var doneColor: Color = Palette.graphiteDark

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i < done ? doneColor : Palette.track)
                    .frame(height: 5)
            }
        }
    }
}
