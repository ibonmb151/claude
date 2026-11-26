// Mym · widget para Scriptable (iPhone, gratis y sin caducidad)
// Tamaños: pequeño, mediano, grande y pantalla de bloqueo (círculo, rectángulo y línea).
// Datos: los mismos ficticios que la app. Cuando haya datos reales, pon una URL en DATA_URL
// que devuelva un JSON con la misma forma que FICTICIOS y el widget la usará.

const DATA_URL = "" // p. ej. "https://tu-servidor/mym/snapshot.json"

// ---------- Datos ficticios (cuadran con la app) ----------
const FICTICIOS = {
  equity: 213214,
  equityDeltaPct: 0.4,
  dayPct: -0.31,
  dayLimitPct: 2.0,
  ordersToday: 128,
  rejectedToday: 7,
  latencyMs: 412,
  equitySeries: [206.0, 207.0, 206.5, 208.0, 207.6, 209.0, 208.4, 210.0, 209.3, 211.0, 210.4, 212.0, 212.6, 213.2],
  dayPctSeries: [0, 0.02, 0.01, 0.04, 0.05, 0.05, 0.03, 0.04, 0.08, 0, -0.12, -0.31],
  cells: [
    { id: "c-lon-01", account: "FND-A-100k", health: "ok", dayPct: -0.6 },
    { id: "c-lon-02", account: "FND-B-50k", health: "warning", dayPct: -1.9 },
    { id: "c-lon-03", account: "REAL-01", health: "critical", dayPct: 0.3 },
    { id: "c-dem-01", account: "DEMO-01", health: "ok", dayPct: 0.5 },
    { id: "c-lon-04", account: "FND-A-25k", health: "paused", dayPct: 0.0 }
  ],
  alerts: [
    { level: "critical", title: "Posición sin stop", time: "09:58" },
    { level: "warning", title: "Pérdida del día al 47 %", time: "10:31" },
    { level: "warning", title: "Reloj del bróker 1,4 s", time: "10:12" }
  ]
}

// ---------- Paleta Grafito (claro y oscuro) ----------
const C = {
  bg: Color.dynamic(new Color("#F4F5F6"), new Color("#1F2124")),
  card: Color.dynamic(new Color("#FFFFFF"), new Color("#2B2E33")),
  ink: Color.dynamic(new Color("#2B2E33"), new Color("#E3E5E8")),
  ink2: Color.dynamic(new Color("#6B7078"), new Color("#9EA3AA")),
  line: Color.dynamic(new Color("#E3E5E8"), new Color("#3A3D42")),
  pos: new Color("#2E9E5B"),
  neg: new Color("#D2463C"),
  warn: new Color("#E0A030"),
  graphite: new Color("#4A4E55"),
  gray: new Color("#C9CDD2")
}
// Colores fijos para dibujar (DrawContext no admite colores dinámicos)
const DARK = Device.isUsingDarkAppearance()
const D = {
  ink: new Color(DARK ? "#E3E5E8" : "#2B2E33"),
  track: new Color(DARK ? "#3A3D42" : "#E3E5E8")
}

// ---------- Formato a la española ----------
function num(v, dec) {
  const s = Math.abs(v).toFixed(dec).split(".")
  const ent = s[0].replace(/\B(?=(\d{3})+(?!\d))/g, ".")
  return (v < 0 ? "−" : "") + ent + (dec > 0 ? "," + s[1] : "")
}
const eur = v => num(v, 0) + " €"
const pct = (v, dec = 2) => (v > 0 ? "+" : "") + num(v, dec) + " %"
const tone = v => (v > 0 ? C.pos : v < 0 ? C.neg : C.ink2)
const healthColor = h => ({ ok: C.pos, warning: C.warn, critical: C.neg, paused: C.gray }[h] || C.gray)

// ---------- Datos ----------
async function loadData() {
  if (DATA_URL) {
    try {
      const r = new Request(DATA_URL)
      r.timeoutInterval = 8
      return await r.loadJSON()
    } catch (e) { /* sin red: usa los ficticios */ }
  }
  return FICTICIOS
}

// ---------- Dibujo ----------
function sparkline(series, w, h, color, fill) {
  const ctx = new DrawContext()
  ctx.size = new Size(w, h)
  ctx.opaque = false
  ctx.respectScreenScale = true
  const lo = Math.min(...series), hi = Math.max(...series)
  const span = hi - lo || 1
  const pts = series.map((v, i) => new Point(
    (i / (series.length - 1)) * (w - 4) + 2,
    h - 3 - ((v - lo) / span) * (h - 6)
  ))
  if (fill) {
    const area = new Path()
    area.move(new Point(pts[0].x, h))
    pts.forEach(p => area.addLine(p))
    area.addLine(new Point(pts[pts.length - 1].x, h))
    area.closeSubpath()
    ctx.addPath(area)
    ctx.setFillColor(new Color(color.hex, 0.14))
    ctx.fillPath()
  }
  const line = new Path()
  line.addLines(pts)
  ctx.addPath(line)
  ctx.setStrokeColor(color)
  ctx.setLineWidth(2.2)
  ctx.strokePath()
  const last = pts[pts.length - 1]
  ctx.setFillColor(color)
  ctx.fillEllipse(new Rect(last.x - 3, last.y - 3, 6, 6))
  return ctx.getImage()
}

// Anillo de «límite del día usado» (0…1)
function ring(fraction, size, lineW, color) {
  const ctx = new DrawContext()
  ctx.size = new Size(size, size)
  ctx.opaque = false
  ctx.respectScreenScale = true
  const c = size / 2, r = c - lineW
  const arc = (from, to, col) => {
    const steps = Math.max(2, Math.round((to - from) * 90))
    for (let i = 0; i < steps; i++) {
      const a = -Math.PI / 2 + 2 * Math.PI * (from + (to - from) * (i / steps))
      ctx.setFillColor(col)
      ctx.fillEllipse(new Rect(c + r * Math.cos(a) - lineW / 2, c + r * Math.sin(a) - lineW / 2, lineW, lineW))
    }
  }
  arc(0, 1, D.track)
  if (fraction > 0) arc(0, Math.min(1, fraction), color)
  return ctx.getImage()
}

// Barra horizontal fina
function bar(fraction, w, h, color) {
  const ctx = new DrawContext()
  ctx.size = new Size(w, h)
  ctx.opaque = false
  ctx.respectScreenScale = true
  const track = new Path()
  track.addRoundedRect(new Rect(0, 0, w, h), h / 2, h / 2)
  ctx.addPath(track); ctx.setFillColor(D.track); ctx.fillPath()
  const fw = Math.max(h, w * Math.min(1, fraction))
  const fillP = new Path()
  fillP.addRoundedRect(new Rect(0, 0, fw, h), h / 2, h / 2)
  ctx.addPath(fillP); ctx.setFillColor(color); ctx.fillPath()
  return ctx.getImage()
}

// ---------- Piezas ----------
function addText(stack, s, font, color, scale) {
  const t = stack.addText(s)
  t.font = font
  t.textColor = color
  t.lineLimit = 1
  if (scale) t.minimumScaleFactor = scale
  return t
}

function header(w, d) {
  const row = w.addStack()
  row.centerAlignContent()
  addText(row, "Equity", Font.semiboldSystemFont(12), C.ink2)
  row.addSpacer()
  const used = Math.max(0, -d.dayPct) / d.dayLimitPct
  if (d.alerts.some(a => a.level === "critical")) {
    const s = SFSymbol.named("exclamationmark.triangle.fill")
    const im = row.addImage(s.image)
    im.imageSize = new Size(12, 12)
    im.tintColor = C.neg
  } else {
    addText(row, num(used * 100, 0) + " %", Font.semiboldSystemFont(11), C.ink2)
  }
}

function limitRow(stack, d, width) {
  const used = Math.max(0, -d.dayPct) / d.dayLimitPct
  const color = used > 0.75 ? C.neg : used > 0.4 ? C.warn : C.graphite
  const im = stack.addImage(bar(used, width, 6, color))
  im.imageSize = new Size(width, 6)
  stack.addSpacer(3)
  addText(stack, "Límite del día " + num(used * 100, 0) + " %", Font.systemFont(10), C.ink2)
}

// ---------- Tamaños ----------
function small(d) {
  const w = new ListWidget()
  w.backgroundColor = C.card
  w.setPadding(14, 14, 14, 14)
  header(w, d)
  w.addSpacer(4)
  addText(w, eur(d.equity), Font.boldRoundedSystemFont(22), C.ink, 0.6)
  addText(w, pct(d.dayPct) + " hoy", Font.semiboldSystemFont(12), tone(d.dayPct))
  w.addSpacer()
  const sp = w.addImage(sparkline(d.equitySeries, 130, 34, C.graphite, true))
  sp.imageSize = new Size(130, 34)
  w.addSpacer(6)
  limitRow(w, d, 130)
  return w
}

function medium(d) {
  const w = new ListWidget()
  w.backgroundColor = C.card
  w.setPadding(14, 16, 14, 16)
  const row = w.addStack()
  // Izquierda: cifras
  const left = row.addStack()
  left.layoutVertically()
  addText(left, "Equity", Font.semiboldSystemFont(12), C.ink2)
  addText(left, eur(d.equity), Font.boldRoundedSystemFont(24), C.ink, 0.6)
  addText(left, pct(d.dayPct) + " hoy", Font.semiboldSystemFont(12), tone(d.dayPct))
  left.addSpacer()
  addText(left, d.ordersToday + " órdenes · " + d.rejectedToday + " rech.", Font.systemFont(11), C.ink2)
  addText(left, d.latencyMs + " ms", Font.systemFont(11), C.ink2)
  row.addSpacer(12)
  // Derecha: gráfico y límite
  const right = row.addStack()
  right.layoutVertically()
  const sp = right.addImage(sparkline(d.equitySeries, 150, 70, C.graphite, true))
  sp.imageSize = new Size(150, 70)
  right.addSpacer()
  limitRow(right, d, 150)
  return w
}

function large(d) {
  const w = new ListWidget()
  w.backgroundColor = C.card
  w.setPadding(16, 16, 16, 16)
  const top = w.addStack()
  const left = top.addStack()
  left.layoutVertically()
  addText(left, "Equity", Font.semiboldSystemFont(12), C.ink2)
  addText(left, eur(d.equity), Font.boldRoundedSystemFont(26), C.ink, 0.6)
  addText(left, pct(d.dayPct) + " hoy", Font.semiboldSystemFont(12), tone(d.dayPct))
  top.addSpacer()
  const used = Math.max(0, -d.dayPct) / d.dayLimitPct
  const rg = top.addImage(ring(used, 54, 7, used > 0.75 ? C.neg : used > 0.4 ? C.warn : C.graphite))
  rg.imageSize = new Size(54, 54)
  w.addSpacer(8)
  const sp = w.addImage(sparkline(d.equitySeries, 300, 60, C.graphite, true))
  sp.imageSize = new Size(300, 60)
  w.addSpacer(10)
  addText(w, "Flota", Font.semiboldSystemFont(12), C.ink2)
  w.addSpacer(4)
  d.cells.slice(0, 5).forEach(c => {
    const r = w.addStack()
    r.centerAlignContent()
    const dot = r.addStack()
    dot.size = new Size(8, 8)
    dot.cornerRadius = 4
    dot.backgroundColor = healthColor(c.health)
    r.addSpacer(8)
    addText(r, c.id, new Font("Menlo", 11), C.ink)
    r.addSpacer(6)
    addText(r, c.account, Font.systemFont(11), C.ink2)
    r.addSpacer()
    addText(r, c.health === "paused" ? "pausada" : pct(c.dayPct, 1), Font.semiboldSystemFont(11), c.health === "paused" ? C.ink2 : tone(c.dayPct))
    w.addSpacer(3)
  })
  w.addSpacer()
  const crit = d.alerts.find(a => a.level === "critical") || d.alerts[0]
  if (crit) {
    const a = w.addStack()
    a.centerAlignContent()
    a.backgroundColor = C.bg
    a.cornerRadius = 10
    a.setPadding(7, 10, 7, 10)
    const s = SFSymbol.named(crit.level === "critical" ? "exclamationmark.triangle.fill" : "bell.fill")
    const im = a.addImage(s.image)
    im.imageSize = new Size(13, 13)
    im.tintColor = crit.level === "critical" ? C.neg : C.warn
    a.addSpacer(8)
    addText(a, crit.title, Font.semiboldSystemFont(12), C.ink, 0.8)
    a.addSpacer()
    addText(a, crit.time, Font.systemFont(11), C.ink2)
  }
  return w
}

// Pantalla de bloqueo
function lockCircular(d) {
  const w = new ListWidget()
  w.addAccessoryWidgetBackground = true
  const used = Math.max(0, -d.dayPct) / d.dayLimitPct
  const z = w.addStack()
  z.layoutVertically()
  z.centerAlignContent()
  const t1 = addText(z, num(used * 100, 0) + "%", Font.boldRoundedSystemFont(14), Color.white())
  t1.centerAlignText()
  const t2 = addText(z, "límite", Font.systemFont(9), Color.white())
  t2.centerAlignText()
  return w
}

function lockRect(d) {
  const w = new ListWidget()
  const crit = d.alerts.filter(a => a.level === "critical").length
  addText(w, "Mym · " + pct(d.dayPct), Font.semiboldSystemFont(13), Color.white())
  addText(w, eur(d.equity), Font.boldRoundedSystemFont(17), Color.white(), 0.7)
  addText(w, crit ? crit + " aviso crítico" : d.alerts.length + " avisos", Font.systemFont(12), Color.white())
  return w
}

function lockInline(d) {
  const w = new ListWidget()
  addText(w, "Mym " + pct(d.dayPct) + " · " + eur(d.equity), Font.systemFont(12), Color.white())
  return w
}

// ---------- Arranque ----------
const data = await loadData()
const family = config.widgetFamily || "large"
const build = {
  small, medium, large,
  accessoryCircular: lockCircular,
  accessoryRectangular: lockRect,
  accessoryInline: lockInline
}[family] || medium
const widget = build(data)
widget.refreshAfterDate = new Date(Date.now() + 15 * 60 * 1000)

if (config.runsInWidget) {
  Script.setWidget(widget)
} else {
  // Al abrirlo desde la app Scriptable, enseña la vista previa
  await widget.presentLarge()
}
Script.complete()
