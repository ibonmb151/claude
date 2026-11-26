// Mym · pantalla de bloqueo (círculo, rectángulo y línea)
// Necesita la base «Mym-Base» guardada en Scriptable.
const M = importModule("Mym-Base")
const d = await M.loadData()
const family = config.widgetFamily || "accessoryRectangular"
const u = M.limitUsed(d)
const white = M.C.white
const critical = d.alerts.filter(a => a.level === "critical").length

function circular() {
  const w = new ListWidget()
  w.addAccessoryWidgetBackground = true
  const z = w.addStack()
  z.layoutVertically()
  z.centerAlignContent()
  M.text(z, M.num(u * 100, 0) + "%", Font.boldRoundedSystemFont(15), white).centerAlignText()
  M.text(z, "límite", Font.systemFont(9), white).centerAlignText()
  return w
}

function rectangular() {
  const w = new ListWidget()
  const top = w.addStack()
  top.centerAlignContent()
  M.text(top, "Mym", Font.semiboldSystemFont(12), white)
  top.addSpacer(6)
  M.text(top, M.pct(d.dayPct), Font.semiboldSystemFont(12), white)
  if (critical) {
    top.addSpacer(4)
    M.symbol(top, "exclamationmark.triangle.fill", 11, white)
  }
  M.text(w, M.eur(d.equity), Font.boldRoundedSystemFont(18), white, 0.7)
  M.text(w, critical ? critical + " aviso crítico" : d.alerts.length + " avisos", Font.systemFont(11), white)
  return w
}

function inline() {
  const w = new ListWidget()
  M.text(w, "Mym " + M.pct(d.dayPct) + (critical ? " · ⚠︎ " + critical : ""), Font.systemFont(12), white)
  return w
}

const build = { accessoryCircular: circular, accessoryInline: inline }[family] || rectangular
const widget = build()
widget.refreshAfterDate = new Date(Date.now() + 15 * 60 * 1000)
if (config.runsInAccessoryWidget || config.runsInWidget) {
  Script.setWidget(widget)
} else {
  // En la app no hay vista previa de pantalla de bloqueo: se enseña en grande como texto
  await widget.presentSmall()
}
Script.complete()
