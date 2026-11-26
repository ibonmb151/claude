// Mym · Flota (mediano y grande): estado de las células y avisos
// Necesita la base «Mym-Base» guardada en Scriptable.
const M = importModule("Mym-Base")
const d = await M.loadData()
const family = config.widgetFamily || "large"

function summary(stack) {
  const count = h => d.cells.filter(c => c.health === h).length
  const row = stack.addStack()
  row.centerAlignContent()
  M.title(row, "Flota")
  row.addSpacer()
  ;[["ok", M.C.pos], ["warning", M.C.warn], ["critical", M.C.neg], ["paused", M.C.gray]].forEach(([h, col]) => {
    const n = count(h)
    if (!n) return
    M.dot(row, col, 7)
    row.addSpacer(3)
    M.text(row, String(n), Font.semiboldSystemFont(11), M.C.ink2)
    row.addSpacer(8)
  })
}

function cellRow(stack, c, compact) {
  const r = stack.addStack()
  r.centerAlignContent()
  M.dot(r, M.healthColor(c.health))
  r.addSpacer(8)
  M.text(r, c.id, new Font("Menlo", compact ? 11 : 12), M.C.ink)
  if (!compact) {
    r.addSpacer(6)
    M.text(r, c.account, Font.systemFont(11), M.C.ink2)
  }
  r.addSpacer()
  const paused = c.health === "paused"
  M.text(r, paused ? "pausada" : M.pct(c.dayPct, 1), Font.semiboldSystemFont(11), paused ? M.C.ink2 : M.tone(c.dayPct))
}

function alertRow(stack, a) {
  const s = stack.addStack()
  s.centerAlignContent()
  s.backgroundColor = M.C.bg
  s.cornerRadius = 10
  s.setPadding(7, 10, 7, 10)
  M.symbol(s, a.level === "critical" ? "exclamationmark.triangle.fill" : "bell.fill", 13, a.level === "critical" ? M.C.neg : M.C.warn)
  s.addSpacer(8)
  M.text(s, a.title, Font.semiboldSystemFont(12), M.C.ink, 0.8)
  s.addSpacer()
  M.text(s, a.time, Font.systemFont(11), M.C.ink2)
}

function medium() {
  const w = M.newWidget()
  summary(w)
  w.addSpacer(6)
  const cols = w.addStack()
  const half = Math.ceil(d.cells.length / 2)
  ;[d.cells.slice(0, half), d.cells.slice(half)].forEach((list, i) => {
    const col = cols.addStack()
    col.layoutVertically()
    list.forEach(c => { cellRow(col, c, true); col.addSpacer(5) })
    if (i === 0) cols.addSpacer(14)
  })
  w.addSpacer()
  const crit = d.alerts.find(a => a.level === "critical")
  if (crit) alertRow(w, crit)
  return w
}

function large() {
  const w = M.newWidget(16)
  summary(w)
  w.addSpacer(8)
  d.cells.forEach(c => { cellRow(w, c, false); w.addSpacer(6) })
  w.addSpacer()
  M.title(w, "Avisos")
  w.addSpacer(4)
  d.alerts.slice(0, 3).forEach(a => { alertRow(w, a); w.addSpacer(4) })
  return w
}

const widget = family === "medium" ? medium() : large()
await M.finish(widget, family === "medium" ? "medium" : "large")
