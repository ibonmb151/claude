// Mym · base común de los widgets (Scriptable)
// Los widgets la cargan con importModule("Mym-Base"). Guárdala en Scriptable con el nombre exacto «Mym-Base».
// Datos: los mismos ficticios que la app. Cuando haya datos reales, pon en DATA_URL una dirección
// que devuelva un JSON con la misma forma que FICTICIOS.

const DATA_URL = ""

const FICTICIOS = {
  equity: 213214,
  equityDeltaPct: 0.4,
  dayPct: -0.31,
  dayLimitPct: 2.0,
  exposurePct: 18,
  ordersToday: 128,
  rejectedToday: 7,
  latencyMs: 412,
  latencyP99: 640,
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
  pos: new Color("#2E9E5B"),
  neg: new Color("#D2463C"),
  warn: new Color("#E0A030"),
  graphite: new Color("#4A4E55"),
  gray: new Color("#C9CDD2"),
  white: Color.white()
}
// DrawContext no admite colores dinámicos: se elige según el modo del sistema
const DARK = Device.isUsingDarkAppearance()
const D = {
  line: new Color(DARK ? "#C9CDD2" : "#4A4E55"),
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
const limitUsed = d => Math.max(0, -d.dayPct) / d.dayLimitPct
const limitColor = u => (u > 0.75 ? C.neg : u > 0.4 ? C.warn : C.graphite)

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
function canvas(w, h) {
  const ctx = new DrawContext()
  ctx.size = new Size(w, h)
  ctx.opaque = false
  ctx.respectScreenScale = true
  return ctx
}

function sparkline(series, w, h, color, fill, zeroLine) {
  const ctx = canvas(w, h)
  const lo = Math.min(...series, zeroLine ? 0 : Infinity)
  const hi = Math.max(...series, zeroLine ? 0 : -Infinity)
  const span = hi - lo || 1
  const y = v => h - 3 - ((v - lo) / span) * (h - 6)
  const pts = series.map((v, i) => new Point((i / (series.length - 1)) * (w - 6) + 3, y(v)))
  if (zeroLine) {
    const z = new Path()
    z.move(new Point(0, y(0)))
    z.addLine(new Point(w, y(0)))
    ctx.addPath(z)
    ctx.setStrokeColor(D.track)
    ctx.setLineWidth(1)
    ctx.strokePath()
  }
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

// Anillo 0…1
function ring(fraction, size, lineW, color) {
  const ctx = canvas(size, size)
  const c = size / 2, r = c - lineW
  const arc = (to, col) => {
    const steps = Math.max(2, Math.round(to * 120))
    ctx.setFillColor(col)
    for (let i = 0; i <= steps; i++) {
      const a = -Math.PI / 2 + 2 * Math.PI * to * (i / steps)
      ctx.fillEllipse(new Rect(c + r * Math.cos(a) - lineW / 2, c + r * Math.sin(a) - lineW / 2, lineW, lineW))
    }
  }
  arc(1, D.track)
  if (fraction > 0) arc(Math.min(1, fraction), color)
  return ctx.getImage()
}

// Barra horizontal 0…1
function bar(fraction, w, h, color) {
  const ctx = canvas(w, h)
  const track = new Path()
  track.addRoundedRect(new Rect(0, 0, w, h), h / 2, h / 2)
  ctx.addPath(track); ctx.setFillColor(D.track); ctx.fillPath()
  const fp = new Path()
  fp.addRoundedRect(new Rect(0, 0, Math.max(h, w * Math.min(1, fraction)), h), h / 2, h / 2)
  ctx.addPath(fp); ctx.setFillColor(color); ctx.fillPath()
  return ctx.getImage()
}

// ---------- Piezas de interfaz ----------
function newWidget(padding) {
  const w = new ListWidget()
  w.backgroundColor = C.card
  const p = padding || 14
  w.setPadding(p, p, p, p)
  return w
}

function text(stack, s, font, color, scale) {
  const t = stack.addText(s)
  t.font = font
  t.textColor = color
  t.lineLimit = 1
  if (scale) t.minimumScaleFactor = scale
  return t
}

function image(stack, img, w, h) {
  const im = stack.addImage(img)
  im.imageSize = new Size(w, h)
  return im
}

function symbol(stack, name, size, color) {
  const im = stack.addImage(SFSymbol.named(name).image)
  im.imageSize = new Size(size, size)
  im.tintColor = color
  return im
}

function title(stack, s) {
  return text(stack, s, Font.semiboldSystemFont(12), C.ink2)
}

function dot(stack, color, size) {
  const s = stack.addStack()
  s.size = new Size(size || 8, size || 8)
  s.cornerRadius = (size || 8) / 2
  s.backgroundColor = color
  return s
}

function limitRow(stack, d, width) {
  const u = limitUsed(d)
  image(stack, bar(u, width, 6, limitColor(u)), width, 6)
  stack.addSpacer(3)
  text(stack, "Límite del día " + num(u * 100, 0) + " %", Font.systemFont(10), C.ink2)
}

// Muestra el widget (o su vista previa al abrirlo en Scriptable) y termina
async function finish(widget, previewSize) {
  widget.refreshAfterDate = new Date(Date.now() + 15 * 60 * 1000)
  if (config.runsInWidget) {
    Script.setWidget(widget)
  } else if (previewSize === "small") {
    await widget.presentSmall()
  } else if (previewSize === "large") {
    await widget.presentLarge()
  } else {
    await widget.presentMedium()
  }
  Script.complete()
}

module.exports = {
  C, D, num, eur, pct, tone, healthColor, limitUsed, limitColor,
  loadData, sparkline, ring, bar,
  newWidget, text, image, symbol, title, dot, limitRow, finish
}
