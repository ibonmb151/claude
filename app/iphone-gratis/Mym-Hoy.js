// Mym · Hoy (pequeño y mediano): límite del día, resultado y actividad
// Necesita la base «Mym-Base» guardada en Scriptable.
const M = importModule("Mym-Base")
const d = await M.loadData()
const family = config.widgetFamily || "medium"
const u = M.limitUsed(d)

function ringBlock(stack, size) {
  const z = stack.addStack()
  z.size = new Size(size, size)
  z.backgroundImage = M.ring(u, size, Math.round(size / 9), M.limitColor(u))
  z.centerAlignContent()
  const inner = z.addStack()
  inner.layoutVertically()
  inner.centerAlignContent()
  const a = M.text(inner, M.num(u * 100, 0) + " %", Font.boldRoundedSystemFont(size / 4.5), M.C.ink)
  a.centerAlignText()
  const b = M.text(inner, "límite", Font.systemFont(size / 9), M.C.ink2)
  b.centerAlignText()
}

function small() {
  const w = M.newWidget()
  const top = w.addStack()
  M.title(top, "Hoy")
  top.addSpacer()
  M.text(top, M.pct(d.dayPct), Font.semiboldSystemFont(12), M.tone(d.dayPct))
  w.addSpacer()
  const c = w.addStack()
  c.addSpacer()
  ringBlock(c, 92)
  c.addSpacer()
  w.addSpacer()
  return w
}

function stat(stack, value, label) {
  const s = stack.addStack()
  s.layoutVertically()
  M.text(s, value, Font.boldRoundedSystemFont(16), M.C.ink)
  M.text(s, label, Font.systemFont(10), M.C.ink2)
}

function medium() {
  const w = M.newWidget(16)
  const row = w.addStack()
  ringBlock(row, 104)
  row.addSpacer(16)
  const right = row.addStack()
  right.layoutVertically()
  const head = right.addStack()
  M.title(head, "Hoy")
  head.addSpacer()
  M.text(head, M.pct(d.dayPct), Font.semiboldSystemFont(13), M.tone(d.dayPct))
  right.addSpacer(4)
  M.image(right, M.sparkline(d.dayPctSeries, 170, 40, d.dayPct < 0 ? M.C.neg : M.C.pos, false, true), 170, 40)
  right.addSpacer()
  const stats = right.addStack()
  stat(stats, String(d.ordersToday), "órdenes")
  stats.addSpacer()
  stat(stats, String(d.rejectedToday), "rechazos")
  stats.addSpacer()
  stat(stats, d.latencyMs + " ms", "latencia")
  return w
}

const widget = family === "small" ? small() : medium()
await M.finish(widget, family === "small" ? "small" : "medium")
