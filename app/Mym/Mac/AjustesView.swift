#if os(macOS)
import SwiftUI

struct AjustesView: View {
    @EnvironmentObject var store: AppStore
    @State private var active = true
    @State private var notify = true
    @State private var mode = "Producción"
    @State private var values: [String: Double] = [:]
    @State private var sessions: Set<String> = ["Londres", "Nueva York"]

    private var strategy: Strategy {
        store.data.strategies.first { $0.id == store.selectedStrategyId } ?? store.data.strategies[0]
    }

    private var changes: Int {
        strategy.params.filter { abs((values[$0.key] ?? $0.value) - $0.previous) > 0.0001 }.count
    }

    var body: some View {
        let d = store.data
        HStack(alignment: .top, spacing: 14) {
            // Lista de estrategias
            VStack(alignment: .leading, spacing: 6) {
                ForEach(d.strategies) { s in
                    Button {
                        store.selectedStrategyId = s.id
                        values = [:]
                    } label: {
                        HStack(spacing: 10) {
                            IconTile(symbol: s.symbol, color: s.color, size: 26, corner: 7)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(s.id).font(.system(size: 13, weight: .semibold, design: .monospaced))
                                Text(s.name).font(.system(size: 12)).foregroundStyle(Palette.ink2)
                            }
                            Spacer()
                        }
                        .padding(8)
                        .background(s.id == store.selectedStrategyId ? Palette.selection : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Palette.ink)
                }
                Divider().padding(.vertical, 4)
                HStack(spacing: 10) {
                    IconTile(symbol: "lock", color: Palette.gray, size: 26, corner: 7)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Reglas de riesgo").font(.system(size: 13, weight: .semibold))
                        Text("22 comprobaciones · solo lectura").font(.system(size: 12)).foregroundStyle(Palette.ink2)
                    }
                }
                .padding(8)
                Spacer()
            }
            .card(10)
            .frame(width: 250)

            // Formulario
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        IconTile(symbol: strategy.symbol, color: strategy.color, size: 52, corner: 14)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(strategy.name).font(.system(size: 24, weight: .bold)).foregroundStyle(Palette.ink)
                            Text("\(strategy.id) · versión \(strategy.version) vigente · borrador de la \(strategy.version + 1)")
                                .font(.system(size: 13)).foregroundStyle(Palette.ink2)
                        }
                        Spacer()
                        if changes > 0 { Pill(text: "\(changes) cambios sin guardar", tone: .warn) }
                    }

                    group("General") {
                        row("Estrategia activa") { Toggle("", isOn: $active).labelsHidden().toggleStyle(.switch) }
                        row("Modo") {
                            Picker("", selection: $mode) {
                                Text("Producción").tag("Producción")
                                Text("Sombra").tag("Sombra")
                                Text("Demo").tag("Demo")
                            }
                            .labelsHidden()
                            .frame(width: 140)
                        }
                        row("Avisarme si se pausa sola") { Toggle("", isOn: $notify).labelsHidden().toggleStyle(.switch) }
                    }

                    group("Parámetros") {
                        ForEach(strategy.params) { p in
                            let bound = Binding<Double>(
                                get: { values[p.key] ?? p.value },
                                set: { values[p.key] = $0 }
                            )
                            let changed = abs(bound.wrappedValue - p.previous) > 0.0001
                            HStack(spacing: 12) {
                                HStack(spacing: 6) {
                                    if changed { Circle().fill(Palette.warn).frame(width: 7, height: 7) }
                                    Text(p.key).font(.system(size: 13, design: .monospaced)).foregroundStyle(Palette.ink)
                                }
                                .frame(width: 190, alignment: .leading)
                                Slider(value: bound, in: p.min...p.max, step: p.step)
                                Text(Fmt.comma(bound.wrappedValue, p.step < 1 ? 2 : 0) + p.unit)
                                    .font(.system(size: 13, weight: .semibold)).monospacedDigit().lineLimit(1).frame(width: 78, alignment: .trailing)
                                Text(changed ? "antes " + Fmt.comma(p.previous, p.step < 1 ? 2 : 0) : "")
                                    .font(.system(size: 12)).foregroundStyle(Palette.ink2).lineLimit(1).frame(width: 78, alignment: .trailing)
                            }
                            .padding(.vertical, 4)
                        }
                        row("sesiones") {
                            HStack(spacing: 6) {
                                ForEach(["Asia", "Londres", "Nueva York"], id: \.self) { name in
                                    Button(name) {
                                        if sessions.contains(name) { sessions.remove(name) } else { sessions.insert(name) }
                                    }
                                    .buttonStyle(.plain)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(sessions.contains(name) ? Color.white : Palette.ink)
                                    .padding(.horizontal, 12)
                                    .frame(height: 28)
                                    .background(sessions.contains(name) ? Palette.graphiteDark : Palette.neutralBg, in: Capsule())
                                }
                            }
                        }
                    }

                    HStack {
                        Heading("Condiciones", info: "Reglas «si… entonces» para activar o pausar. Se leen como una frase")
                        Button("+ Añadir regla") {}.buttonStyle(MymButtonStyle(kind: .secondary, compact: true))
                    }
                    ConditionBlock(color: Palette.graphite, lines: [
                        ["Si", "volatilidad M5", "es menor que", "percentil 80"],
                        ["y", "noticias de alto impacto", "no hay en", "± 15 min"],
                        ["y", "sesión", "es", "Londres o Nueva York"]
                    ], thenText: ["Entonces", "activar \(strategy.id)"], thenColor: Palette.pos)
                    ConditionBlock(color: Palette.warnText, lines: [
                        ["Si", "resultado de 5 días", "es menor que", "−1,0 %"]
                    ], thenText: ["Entonces", "pausar y avisarme al móvil"], thenColor: Palette.warn)
                    HStack(spacing: 8) {
                        Image(systemName: "lock").foregroundStyle(Palette.ink2)
                        Text("Regla de riesgo · no se edita aquí: si el reloj del bróker se desfasa más de 2 s, no abrir órdenes.")
                            .font(.system(size: 13)).foregroundStyle(Palette.ink2)
                    }
                    .padding(12)
                    .background(Palette.bg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            }

            // Antes y después y camino del cambio
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Heading("Antes y después", info: "v3 frente al borrador v4 en el gemelo, 30 días")
                    beforeAfter("Retorno", "0,9 %", "1,1 %", better: true)
                    beforeAfter("Caída máxima", "−1,4 %", "−1,1 %", better: true)
                    beforeAfter("Operaciones", "142", "131", better: false)
                }
                .card(14)

                VStack(alignment: .leading, spacing: 6) {
                    Heading("Lo que cuesta probar", info: "Cada cambio de parámetros cuenta como un intento")
                    LabeledValue(label: "Intento nº", value: "15")
                    LabeledValue(label: "Sharpe deflactado", value: "0,62 → 0,58", valueColor: Palette.warnText)
                }
                .card(14)

                VStack(alignment: .leading, spacing: 8) {
                    Heading("Camino del cambio", info: "Un cambio no pasa a la siguiente etapa sin superar la anterior")
                    pathStep("Borrador", "Guardado hoy 10:20 · op-03", done: true)
                    pathStep("Gemelo", "Repitiendo 30 días · 62 %", done: false)
                    pathStep("Aprobación", "La firma ap-01", done: false)
                    pathStep("Demo · 5 días", "En c-dem-01", done: false)
                    pathStep("Producción", "Célula a célula", done: false)
                }
                .card(14)

                Button("Solicitar aprobación") { store.requestSubmitConfig(strategy) }
                    .buttonStyle(MymButtonStyle(kind: .primary))
            }
            .frame(width: 290)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
        .onAppear { if values.isEmpty { values = [:] } }
    }

    // MARK: Piezas

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.ink2)
            VStack(spacing: 0) { content() }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Palette.bg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func row<Control: View>(_ title: String, @ViewBuilder control: () -> Control) -> some View {
        HStack {
            Text(title).font(.system(size: 13)).foregroundStyle(Palette.ink)
            Spacer()
            control()
        }
        .padding(.vertical, 7)
    }

    private func beforeAfter(_ name: String, _ before: String, _ after: String, better: Bool) -> some View {
        HStack {
            Text(name).font(.system(size: 13)).foregroundStyle(Palette.ink2)
            Spacer()
            Text(before).font(.system(size: 13)).foregroundStyle(Palette.ink2).monospacedDigit()
            Image(systemName: "arrow.right").font(.system(size: 10)).foregroundStyle(Palette.ink2)
            Text(after).font(.system(size: 13, weight: .bold)).monospacedDigit()
                .foregroundStyle(better ? Palette.posText : Palette.ink)
        }
        .padding(.vertical, 3)
    }

    private func pathStep(_ title: String, _ detail: String, done: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(done ? Palette.graphiteDark : Palette.card)
                .overlay(Circle().stroke(done ? Palette.graphiteDark : Palette.graphiteSoft, lineWidth: 2.5))
                .frame(width: 16, height: 16)
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(.system(size: 13, weight: .semibold))
                Text(detail).font(.system(size: 12)).foregroundStyle(Palette.ink2)
            }
        }
    }
}

/// Condición escrita como bloques, al estilo de Atajos.
struct ConditionBlock: View {
    let color: Color
    let lines: [[String]]
    let thenText: [String]
    let thenColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<lines.count, id: \.self) { i in
                blockRow(lines[i], background: color.opacity(0.16))
                    .padding(.leading, i == 0 ? 0 : 18)
            }
            blockRow(thenText, background: thenColor.opacity(0.18))
        }
        .padding(12)
        .background(Palette.bg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func blockRow(_ parts: [String], background: Color) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<parts.count, id: \.self) { j in
                if j == 0 {
                    Text(parts[j]).font(.system(size: 13, weight: .bold)).foregroundStyle(Palette.ink2).frame(minWidth: 26, alignment: .leading)
                } else {
                    Text(parts[j])
                        .font(.system(size: 13, weight: j % 2 == 1 ? .semibold : .regular))
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(j % 2 == 1 ? Palette.card : Color.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
#endif
