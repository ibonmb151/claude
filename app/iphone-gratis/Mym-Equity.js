// Mym · Equity (pequeño y mediano)
// Necesita la base «Mym-Base» guardada en Scriptable.
const M = importModule("Mym-Base")
const d = await M.loadData()
const family = config.widgetFamily || "medium"

function small() {
  const w = M.newWidget()
  M.title(w, "Equity")
  w.addSpacer(4)
  M.text(w, M.eur(d.equity), Font.boldRoundedSystemFont(22), M.C.ink, 0.6)
  M.text(w, M.pct(d.dayPct) + " hoy", Font.semiboldSystemFont(12), M.tone(d.dayPct))
  w.addSpacer()
  M.image(w, M.sparkline(d.equitySeries, 130, 40, M.D.line, true), 130, 40)
  return w
}

function medium() {
  const w = M.newWidget(16)
  const row = w.addStack()
  const left = row.addStack()
  left.layoutVertically()
  M.title(left, "Equity")
  M.text(left, M.eur(d.equity), Font.boldRoundedSystemFont(26), M.C.ink, 0.6)
  M.text(left, M.pct(d.dayPct) + " hoy", Font.semiboldSystemFont(12), M.tone(d.dayPct))
  left.addSpacer()
  M.text(left, M.pct(d.equityDeltaPct, 1) + " en 14 días", Font.systemFont(11), M.tone(d.equityDeltaPct))
  row.addSpacer(12)
  M.image(row, M.sparkline(d.equitySeries, 160, 110, M.D.line, true), 160, 110)
  return w
}

const widget = family === "small" ? small() : medium()
await M.finish(widget, family === "small" ? "small" : "medium")
