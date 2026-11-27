#!/usr/bin/env python3
# Panel de cuenta (propuesta B): nivel 1 (vision instantanea), nivel 2 (6 pestanas) y nivel 3 (datos).
import math, os, sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen2
from gen2 import CSS_B, mac2, pill, ch, card, big, spark, donut, mix, IC

OUT = gen2.OUT
MOD = [('Rebote', '#00A3A3'), ('Impulso', '#7A5AF8'), ('Tendencia', '#D444F1'), ('Ruptura', '#C08A00')]
POS, NEG, WARN, INFO, INK, INK2 = '#5FA800', '#F2465E', '#E89B00', '#2E90FA', '#2B2E33', '#6B7078'

EXTRA = r'''
.tbx{overflow-x:auto;border-radius:14px;border:1px solid #EFEFEA}
.tbl{width:100%;border-collapse:collapse;font-size:13px;white-space:nowrap}
.tbl th{position:sticky;top:0;background:#FAFAF8;text-align:left;font-weight:600;color:#6B7078;padding:9px 12px;font-size:12px}
.tbl td{padding:9px 12px;border-top:1px solid #F1F1EC}
.tbl .n{text-align:right;font-variant-numeric:tabular-nums}
.tbl tr:hover td{background:#FAFAF8}
.tbl tr.bad td{background:#FFF4F5}
.tag{display:inline-flex;align-items:center;height:20px;padding:0 7px;border-radius:6px;background:#F2F2EE;color:#4A4E55;font:500 11px ui-monospace,Menlo,monospace}
.ptabs{display:flex;gap:4px;flex-wrap:wrap;background:#E9E9E4;border-radius:13px;padding:4px;align-self:flex-start}
.ptabs button{border:0;background:transparent;height:34px;padding:0 16px;border-radius:10px;font:600 14px -apple-system,BlinkMacSystemFont,'Inter',sans-serif;color:#6B7078;cursor:pointer;transition:all .2s var(--ease)}
.ptabs button:hover{color:#2B2E33}
.ptabs button.on{background:#fff;color:#2B2E33;box-shadow:0 1px 3px rgba(16,17,19,.12)}
.achips{display:flex;gap:6px}
.achips button{height:30px;padding:0 12px;border:0;border-radius:999px;background:#fff;box-shadow:0 0 0 1px #E3E5E8;font:600 13px -apple-system,BlinkMacSystemFont,'Inter',sans-serif;color:#4A4E55;cursor:pointer;transition:all .2s var(--ease)}
.achips button.on{background:#2B2E33;color:#fff;box-shadow:none}
.hstat{display:flex;flex-direction:column;gap:2px;padding:0 18px;border-left:1px solid #EFEFEA}
.hstat:first-child{border-left:0;padding-left:0}
.hstat .l{font-size:12px;font-weight:600;color:#6B7078}
.kgrid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:20px}
.kpi{background:#fff;border-radius:18px;border:1px solid rgba(16,17,19,.05);box-shadow:0 1px 1px rgba(16,17,19,.03),0 4px 14px rgba(16,17,19,.04);padding:18px 20px;display:flex;flex-direction:column;gap:6px;animation:rise .55s var(--ease) both}
.kpi .l{font-size:12px;font-weight:600;color:#6B7078}
.kpi .v{font-size:26px;font-weight:700;letter-spacing:-.02em;font-variant-numeric:tabular-nums}
.kpi .r{font-size:12px;color:#8A8A84}
.kgrid .kpi:nth-child(2){animation-delay:.03s}.kgrid .kpi:nth-child(3){animation-delay:.06s}.kgrid .kpi:nth-child(4){animation-delay:.09s}
.kgrid .kpi:nth-child(5){animation-delay:.12s}.kgrid .kpi:nth-child(6){animation-delay:.15s}.kgrid .kpi:nth-child(7){animation-delay:.18s}.kgrid .kpi:nth-child(8){animation-delay:.21s}
.g2{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}
.g3{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:24px}
.tabpane{display:flex;flex-direction:column;gap:24px;animation:rise .45s var(--ease) both}
.sep2{font-size:12px;font-weight:700;color:#8A8A84;letter-spacing:.04em;text-transform:uppercase;margin-top:4px}
.banner{display:flex;align-items:center;gap:12px;padding:12px 16px;border-radius:14px;background:#FDE4E8;color:#C21A36;font-weight:600;font-size:14px}
.sdot{width:10px;height:10px;border-radius:50%;flex:none}
.rm{display:flex;flex-direction:column;gap:8px}
.rm .it{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;background:#F6F6F3;font-size:13px}
@media (max-width:1240px){.kgrid{grid-template-columns:repeat(2,minmax(0,1fr))}.g3{grid-template-columns:repeat(2,minmax(0,1fr))}}
@media (max-width:900px){.kgrid,.g2,.g3{grid-template-columns:minmax(0,1fr)}.hstat{border-left:0;padding:0}}
'''
CSS = CSS_B + EXTRA


def fmt(v, d=2, sign=False):
    s = ('%.' + str(d) + 'f') % abs(v)
    ent, _, dec = s.partition('.')
    ent = '{:,}'.format(int(ent)).replace(',', '.')
    out = ent + (',' + dec if dec else '')
    if v < 0:
        out = '−' + out
    elif sign and v > 0:
        out = '+' + out
    return out


def svg_open(w, h, label):
    return '<svg viewBox="0 0 %d %d" role="img" aria-label="%s" style="width:100%%;height:auto;display:block">' % (w, h, label)


def line_chart(series, w=600, h=220, label='', zero=None, yfmt=None, area=None, ylab=None):
    allv = [v for s in series for v in s[0]] + ([zero] if zero is not None else [])
    lo, hi = min(allv), max(allv)
    sp = (hi - lo) or 1
    L, R, T, B = 44, 10, 12, 24
    def X(i, n): return L + i * (w - L - R) / (n - 1)
    def Y(v): return T + (hi - v) / sp * (h - T - B)
    o = svg_open(w, h, label)
    for k in range(5):
        v = lo + sp * k / 4
        o += '<line x1="%d" y1="%.1f" x2="%d" y2="%.1f" stroke="#F1F1EC"/><text x="%d" y="%.1f" text-anchor="end" font-size="11" fill="#8A8A84">%s</text>' % (L, Y(v), w - R, Y(v), L - 6, Y(v) + 4, (yfmt or (lambda x: fmt(x, 1)))(v))
    if zero is not None:
        o += '<line x1="%d" y1="%.1f" x2="%d" y2="%.1f" stroke="#C9CDD2" stroke-width="1.5"/>' % (L, Y(zero), w - R, Y(zero))
    for vals, color, sw, dash in series:
        n = len(vals)
        pts = ' '.join('%.1f,%.1f' % (X(i, n), Y(v)) for i, v in enumerate(vals))
        if area is not None and color == area[0]:
            base = Y(area[1])
            o += '<path class="fadein" d="M%.1f,%.1f L%s L%.1f,%.1f Z" fill="%s" fill-opacity=".14"/>' % (X(0, n), base, pts.replace(' ', ' L'), X(n - 1, n), base, color)
        o += '<polyline class="draw" pathLength="1" points="%s" fill="none" stroke="%s" stroke-width="%s" %s stroke-linecap="round" stroke-linejoin="round"/>' % (pts, color, sw, ('stroke-dasharray="%s"' % dash) if dash else '')
    if ylab:
        o += '<text x="%d" y="%d" font-size="11" fill="#8A8A84">%s</text><text x="%d" y="%d" text-anchor="end" font-size="11" fill="#8A8A84">%s</text>' % (L, h - 6, ylab[0], w - R, h - 6, ylab[1])
    return o + '</svg>'


def bars_v(vals, w=600, h=200, label='', colors=None, labels=None, fmtv=None):
    mx = max(abs(v) for v in vals) or 1
    has_neg = min(vals) < 0
    L, R, T, B = 10, 10, 18, 22
    zero = T + (h - T - B) / 2 if has_neg else h - B
    sc = ((h - T - B) / 2 if has_neg else (h - T - B)) / mx
    slot = (w - L - R) / len(vals)
    o = svg_open(w, h, label) + '<line x1="%d" y1="%.1f" x2="%d" y2="%.1f" stroke="#C9CDD2"/>' % (L, zero, w - R, zero)
    for i, v in enumerate(vals):
        bh = max(2, abs(v) * sc)
        x = L + i * slot + slot * .18
        c = colors[i] if colors else (POS if v >= 0 else NEG)
        o += '<rect class="%s" style="animation-delay:%.2fs" x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="3" fill="%s"/>' % ('grow' if v >= 0 else 'growd', i * .02, x, zero - bh if v >= 0 else zero, slot * .64, bh, c)
        if fmtv:
            o += '<text x="%.1f" y="%.1f" text-anchor="middle" font-size="11" font-weight="600" fill="#2B2E33">%s</text>' % (x + slot * .32, (zero - bh - 5) if v >= 0 else (zero + bh + 13), fmtv(v))
        if labels and labels[i]:
            o += '<text x="%.1f" y="%d" text-anchor="middle" font-size="11" fill="#8A8A84">%s</text>' % (x + slot * .32, h - 6, labels[i])
    return o + '</svg>'


def bars_h(items, maxv, unit='%', mark=None):
    o = '<div style="display:flex;flex-direction:column;gap:10px">'
    for n, v, c in items:
        o += ('<div style="display:flex;align-items:center;gap:10px;font-size:13px"><span style="width:84px;font-weight:600">%s</span><div style="flex:1;position:relative;height:14px;border-radius:7px;background:#EBEBE6">'
              '<div class="fillx" style="height:14px;border-radius:7px;width:%d%%;background:%s"></div>%s</div><span class="tn" style="width:56px;text-align:right;font-weight:700">%s</span></div>'
              % (n, round(min(v, maxv) / maxv * 100), c, ('<div style="position:absolute;top:-3px;left:%d%%;width:2px;height:20px;background:#2B2E33;opacity:.5"></div>' % round(mark / maxv * 100)) if mark else '', fmt(v, 1) + unit))
    return o + '</div>'


def stacked_area(series, w=600, h=220, label=''):
    n = len(series[0])
    tot = [sum(s[i] for s in series) for i in range(n)]
    mx = max(tot)
    L, R, T, B = 10, 10, 10, 22
    def X(i): return L + i * (w - L - R) / (n - 1)
    def Y(v): return T + (1 - v / mx) * (h - T - B)
    o = svg_open(w, h, label)
    acc = [0] * n
    for k, s in enumerate(series):
        top = [acc[i] + s[i] for i in range(n)]
        up = ' L'.join('%.1f,%.1f' % (X(i), Y(top[i])) for i in range(n))
        dn = ' L'.join('%.1f,%.1f' % (X(i), Y(acc[i])) for i in reversed(range(n)))
        o += '<path class="fadein" style="animation-delay:%.2fs" d="M%s L%s Z" fill="%s" fill-opacity=".85" stroke="#fff" stroke-width="1"/>' % (.1 + k * .12, up, dn, MOD[k][1])
        acc = top
    o += '<text x="%d" y="%d" font-size="11" fill="#8A8A84">hace 30 días</text><text x="%d" y="%d" text-anchor="end" font-size="11" fill="#8A8A84">hoy</text>' % (L, h - 6, w - R, h - 6)
    return o + '</svg>'


def scatter(points, w=600, h=240, label='', xr=(0, 1), yr=(0, 1), xl='', yl='', diag=False, hline=None):
    L, R, T, B = 48, 12, 12, 30
    def X(v): return L + (v - xr[0]) / (xr[1] - xr[0]) * (w - L - R)
    def Y(v): return T + (yr[1] - v) / (yr[1] - yr[0]) * (h - T - B)
    o = svg_open(w, h, label)
    for k in range(5):
        yv = yr[0] + (yr[1] - yr[0]) * k / 4
        xv = xr[0] + (xr[1] - xr[0]) * k / 4
        o += '<line x1="%d" y1="%.1f" x2="%d" y2="%.1f" stroke="#F1F1EC"/><text x="%d" y="%.1f" text-anchor="end" font-size="11" fill="#8A8A84">%s</text>' % (L, Y(yv), w - R, Y(yv), L - 6, Y(yv) + 4, fmt(yv, 1))
        o += '<text x="%.1f" y="%d" text-anchor="middle" font-size="11" fill="#8A8A84">%s</text>' % (X(xv), h - 14, fmt(xv, 1))
    if diag:
        o += '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#8A8A84" stroke-dasharray="5 4"/>' % (X(xr[0]), Y(xr[0]), X(xr[1]), Y(xr[1]))
    if hline is not None:
        o += '<line x1="%d" y1="%.1f" x2="%d" y2="%.1f" stroke="#8A8A84" stroke-dasharray="5 4"/>' % (L, Y(hline), w - R, Y(hline))
    for i, (x, y, r, c, t) in enumerate(points):
        o += '<circle class="pop" style="animation-delay:%.2fs" cx="%.1f" cy="%.1f" r="%.1f" fill="%s" fill-opacity=".3" stroke="%s" stroke-width="2"/>' % (i * .02, X(x), Y(y), r, c, c)
        if t:
            o += '<text x="%.1f" y="%.1f" font-size="11" font-weight="700" fill="%s">%s</text>' % (X(x) + r + 4, Y(y) + 4, c, t)
    o += '<text x="%d" y="%d" text-anchor="end" font-size="11" fill="#6B7078">%s</text><text x="%d" y="%d" font-size="11" fill="#6B7078">%s</text>' % (w - R, h - 2, xl, 4, T + 2, yl)
    return o + '</svg>'


def heat(rows, cols, m, cellw=None, w=600, label='', color=None, fmtc=None):
    L = 92
    cw = cellw or (w - L) / len(cols)
    chh = 30
    h = 22 + len(rows) * (chh + 4)
    o = svg_open(w, h, label)
    for j, c in enumerate(cols):
        o += '<text x="%.1f" y="14" text-anchor="middle" font-size="11" fill="#6B7078">%s</text>' % (L + j * cw + cw / 2, c)
    for i, r in enumerate(rows):
        y = 22 + i * (chh + 4)
        o += '<text x="0" y="%.1f" font-size="12" font-weight="600" fill="#2B2E33">%s</text>' % (y + chh / 2 + 4, r)
        for j in range(len(cols)):
            v = m[i][j]
            fill = color(v)
            o += '<rect class="pop" style="animation-delay:%.2fs" x="%.1f" y="%d" width="%.1f" height="%d" rx="6" fill="%s"/>' % ((i * len(cols) + j) * .006, L + j * cw + 1.5, y, cw - 3, chh, fill)
            if fmtc:
                t = fmtc(v)
                o += '<text x="%.1f" y="%.1f" text-anchor="middle" font-size="11" font-weight="600" fill="%s">%s</text>' % (L + j * cw + cw / 2, y + chh / 2 + 4, '#fff' if abs(v) > .55 else '#2B2E33', t)
    return o + '</svg>'


def gauge_v(frac, text, sub, w=260, h=170, color=POS, ticks=('0', '')):
    cx, cy, r = w / 2, h - 30, 92
    def pt(p):
        a = math.pi * (1 - p)
        return cx + r * math.cos(a), cy - r * math.sin(a)
    x0, y0 = pt(0); x1, y1 = pt(1); xv, yv = pt(max(.01, min(1, frac)))
    o = svg_open(w, h, text + ' ' + sub)
    o += '<path d="M%.1f %.1f A%d %d 0 0 1 %.1f %.1f" fill="none" stroke="#EBEBE6" stroke-width="18" stroke-linecap="round"/>' % (x0, y0, r, r, x1, y1)
    o += '<path class="draw" pathLength="1" d="M%.1f %.1f A%d %d 0 0 1 %.1f %.1f" fill="none" stroke="%s" stroke-width="18" stroke-linecap="round"/>' % (x0, y0, r, r, xv, yv, color)
    o += '<text x="%d" y="%d" text-anchor="middle" font-size="36" font-weight="700" fill="#2B2E33">%s</text>' % (cx, cy - 10, text)
    o += '<text x="%d" y="%d" text-anchor="middle" font-size="12" fill="#6B7078">%s</text>' % (cx, cy + 14, sub)
    o += '<text x="%.1f" y="%d" text-anchor="middle" font-size="11" fill="#8A8A84">%s</text><text x="%.1f" y="%d" text-anchor="middle" font-size="11" fill="#8A8A84">%s</text>' % (x0, cy + 22, ticks[0], x1, cy + 22, ticks[1])
    return o + '</svg>'


def table(heads, rows, num_cols=(), bad_rows=()):
    o = '<div class="tbx"><table class="tbl"><thead><tr>%s</tr></thead><tbody>' % ''.join('<th%s>%s</th>' % (' class="n"' if i in num_cols else '', h) for i, h in enumerate(heads))
    for k, r in enumerate(rows):
        o += '<tr%s>%s</tr>' % (' class="bad"' if k in bad_rows else '', ''.join('<td%s>%s</td>' % (' class="n"' if i in num_cols else '', c) for i, c in enumerate(r)))
    return o + '</tbody></table></div>'


def col(v, d=2, unit=''):
    c = POS if v > 0 else (NEG if v < 0 else INK2)
    tc = '#3F7300' if v > 0 else ('#C21A36' if v < 0 else INK2)
    return '<b style="color:%s">%s%s</b>' % (tc, fmt(v, d, True), unit)


def side(s):
    return pill('Compra', 'sg') if s == 'c' else pill('Venta', 'sr')


def acc(a):
    return '···4152' if a == 1 else '···2511'


def legend(items):
    return '<div style="display:flex;gap:14px;flex-wrap:wrap;font-size:12px;color:#6B7078">%s</div>' % ''.join('<span><span style="display:inline-block;width:10px;height:10px;border-radius:3px;background:%s;margin-right:5px;vertical-align:-1px"></span>%s</span>' % (c, n) for n, c in items)


# ───────── Pestaña 1 · Trading ─────────
def tab_trading():
    trades = [('EURUSD', 'c', 1, '1,17003', '1,17127', '1,16853', '1,17283', 12.40, 'rebote-4152-0187', 'Rebote'),
              ('US500', 'v', 1, '6.012,5', '6.004,0', '6.034,0', '5.960,0', 17.00, 'impulso-4152-0041', 'Impulso'),
              ('GBPUSD', 'c', 2, '1,30520', '1,30680', '1,30100', '1,31400', 16.00, 'tendencia-2511-0012', 'Tendencia'),
              ('EURUSD', 'c', 2, '1,16900', '1,16840', 'sin SL', '1,17300', -6.00, 'rebote-2511-0093', 'Rebote'),
              ('XAUUSD', 'v', 1, '2.641,20', '2.636,90', '2.652,00', '2.612,00', 173.00, 'ruptura-4152-0008', 'Ruptura')]
    rows = [[t[0], side(t[1]), acc(t[2]), t[3], t[4], ('<b style="color:#C21A36">sin SL</b>' if t[5] == 'sin SL' else t[5]), t[6], col(t[7]), '<span class="tag">%s</span>' % t[8], t[9]] for t in trades]
    ops = [['Ruptura', 'GBPJPY', side('c'), '<b>0,74</b>', '0,25 %', '<span class="tag">ruptura-2511-0009</span>'],
           ['Rebote', 'AUDUSD', side('v'), '<b>0,66</b>', '0,20 %', '<span class="tag">rebote-4152-0188</span>'],
           ['Tendencia', 'USDJPY', side('c'), '<b>0,58</b>', '0,15 %', '<span class="tag">tendencia-4152-0013</span>']]
    banner = '<div class="banner"><span class="sdot pulse" style="background:#F2465E"></span>1 posición sin protección · EURUSD en ···2511 · rebote-2511-0093<span style="flex:1"></span><a class="btn x" href="ACuentaPanel.dc.html" style="height:30px;font-size:13px">Poner stop</a></div>'
    alloc = donut([(30, MOD[0][1]), (25, MOD[1][1]), (25, MOD[2][1]), (20, MOD[3][1])], 132, 18, '4')
    return ('<div class="tabpane">' + banner +
            card(ch('Trades abiertos', 'Solo lo que está abierto ahora: es flotante, aún no realizado') + '<div class="sep2">Flotante</div>' +
                 table(['Par', 'Lado', 'Cuenta', 'Entrada', 'Actual', 'SL', 'TP', 'Flotante', 'Etiqueta', 'Módulo'], rows, num_cols=(3, 4, 5, 6, 7), bad_rows=(3,))) +
            '<div class="g3">' +
            card(ch('Riesgo utilizado', 'Suma del riesgo de las posiciones abiertas. Límite 5 %') + gauge_v(2.4 / 5, '2,4 %', 'de un máximo de 5 %', ticks=('0 %', '5 %'))) +
            card(ch('Margen libre', 'Margen que queda sin usar') + gauge_v(.78, '78 %', 'margen libre', color=INFO, ticks=('0 %', '100 %'))) +
            card(ch('Capital por módulo', 'Cómo se reparte el capital asignado') + '<div style="display:flex;align-items:center;gap:16px">%s<div style="display:flex;flex-direction:column;gap:6px;font-size:13px">%s</div></div>' % (alloc, ''.join('<div><span style="color:%s">●</span> %s · %d %%</div>' % (c, n, p) for (n, c), p in zip(MOD, (30, 25, 25, 20))))) +
            '</div>' +
            card(ch('Oportunidades activas', 'Señales que el sistema vigila y aún no ha abierto') + table(['Módulo', 'Par', 'Lado', 'Confianza', 'Tamaño', 'Etiqueta'], ops, num_cols=(3, 4))) +
            '</div>')


# ───────── Pestaña 2 · Rendimiento ─────────
def series30(f):
    return [f(i) for i in range(30)]


def tab_rendimiento():
    eq = series30(lambda i: 150000 + i * 120 + 900 * math.sin(i / 4) + 300 * math.sin(i * 1.7))
    peak, dd = -1e9, []
    for v in eq:
        peak = max(peak, v); dd.append((v - peak) / peak * 100)
    daily = [eq[i] - eq[i - 1] if i else 140 for i in range(30)]
    cost = []
    c = 0
    for i in range(30):
        c += 38 + 12 * math.sin(i); cost.append(c)
    intr = [0, -.05, -.12, -.08, -.2, -.31, -.27, -.35, -.42, -.38, -.29, -.42]
    met = [['Acierto (WR)', '57,4 %', '<span style="color:#3F7300">bien</span>'], ['Profit factor', '1,38', '<span style="color:#3F7300">bien</span>'], ['Sharpe', '1,62', ''], ['Sortino', '2,31', ''],
           ['Caída máx.', '−2,31 %', ''], ['R:R medio', '1,42', ''], ['Duración media', '3 h 12 min', '']]
    return ('<div class="tabpane"><div class="sep2">Realizado · operaciones cerradas</div>' +
            card(ch('Curva de equity', 'Solo resultado realizado, 30 días') + line_chart([(eq, INFO, 2.6, None)], label='Curva de equity realizada', yfmt=lambda v: fmt(v / 1000, 1) + 'k', area=(INFO, min(eq)), ylab=('hace 30 días', 'hoy'))) +
            '<div class="g2">' +
            card(ch('Caída desde el máximo', 'Área roja: cuánto estás por debajo del pico') + line_chart([(dd, NEG, 2.2, None)], h=200, label='Drawdown', zero=0, area=(NEG, 0), yfmt=lambda v: fmt(v, 1) + ' %')) +
            card(ch('Resultado por día', 'Verde gana, rojo pierde') + bars_v(daily, h=200, label='PnL diario')) +
            card(ch('Costes acumulados', 'Comisiones y swaps') + line_chart([(cost, WARN, 2.4, None)], h=200, label='Costes acumulados', yfmt=lambda v: fmt(v, 0) + ' €')) +
            card(ch('Caída del día', 'Respecto al saldo de las 00:00 UTC') + line_chart([(intr, NEG, 2.4, None)], h=200, label='Drawdown diario', zero=0, area=(NEG, 0), yfmt=lambda v: fmt(v, 2) + ' %', ylab=('00:00', '10:42'))) +
            '</div>' + card(ch('Métricas · 30 días', 'Calculadas solo con operaciones cerradas') + table(['Métrica', 'Valor', ''], met, num_cols=(1,))) + '</div>')


# ───────── Pestaña 3 · Por módulo ─────────
def tab_modulos():
    ser = [series30(lambda i, k=k: max(.1, 1 + k * .3 + .6 * math.sin(i / 5 + k))) for k in range(4)]
    wr = [(MOD[0][0], 58.1, MOD[0][1]), (MOD[1][0], 54.7, MOD[1][1]), (MOD[2][0], 61.1, MOD[2][1]), (MOD[3][0], 47.9, MOD[3][1])]
    pts = []
    for k, (n, c) in enumerate(MOD):
        for j in range(7):
            rr = 0.6 + ((k * 7 + j) * 37 % 100) / 60
            w_ = 35 + ((k * 13 + j * 17) % 40)
            pts.append((rr, w_, 5 + j % 3 * 2, c, n if j == 3 else ''))
    ddm = [-1.4, -1.1, -0.9, -2.3]
    rows = [['Rebote', 142, '58,1 %', '1,21', col(812.4), '−96,2', '−1,4 %', pill('Activo', 'sg')], ['Impulso', 64, '54,7 %', '1,32', col(1104.0), '−41,8', '−1,1 %', pill('Activo', 'sg')],
            ['Tendencia', 18, '61,1 %', '1,48', col(1420.6), '−12,5', '−0,9 %', pill('Activo', 'sg')], ['Ruptura', 23, '47,9 %', '0,94', col(-180.3), '−22,1', '−2,3 %', pill('Vigilar', 'so')]]
    return ('<div class="tabpane">' + card(ch('Contribución por módulo', 'Lo que aporta cada módulo al resultado, apilado') + legend(MOD) + stacked_area(ser, label='Contribución por módulo')) +
            '<div class="g3">' +
            card(ch('Acierto por módulo', 'Raya: 50 %') + bars_h([(n, v, c) for n, v, c in wr], 80, mark=50)) +
            card(ch('R:R frente a acierto', 'Cada punto, una semana de un módulo') + scatter(pts, h=230, label='R:R por módulo', xr=(0.5, 2.5), yr=(30, 80), xl='R:R', yl='Acierto %', hline=50)) +
            card(ch('Caída máx. por módulo', '30 días') + bars_v(ddm, h=230, label='Drawdown por módulo', colors=[c for _, c in MOD], labels=[n for n, _ in MOD], fmtv=lambda v: fmt(v, 1) + ' %')) +
            '</div>' + card(ch('Métricas por módulo', '30 días · realizado') + table(['Módulo', 'N.º', 'Acierto', 'PF', 'Resultado', 'Costes', 'Caída máx.', 'Estado'], rows, num_cols=(1, 2, 3, 4, 5, 6))) + '</div>')


# ───────── Pestaña 4 · Análisis ─────────
def tab_analisis():
    days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie']
    hours = [str(h) for h in range(0, 24, 2)]
    m = [[max(0, (math.sin((h - 5) / 3.2) + 1) * (1 + .3 * math.sin(d + h)) * (1 if 3 <= h <= 10 else .35)) for h in range(12)] for d in range(5)]
    mx = max(max(r) for r in m)
    m = [[v / mx for v in r] for r in m]
    names = ['Rebote', 'Impulso', 'Tendencia', 'Ruptura', 'EURUSD', 'GBPUSD']
    cm = [[1, .12, -.08, .31, .62, .40], [.12, 1, .22, .05, .10, .08], [-.08, .22, 1, .18, .02, .35], [.31, .05, .18, 1, .25, .30], [.62, .10, .02, .25, 1, .71], [.40, .08, .35, .30, .71, 1]]
    dur = [6, 14, 22, 31, 26, 18, 11, 7, 4, 2]
    pnl = [2, 5, 14, 22, 30, 20, 11, 6]
    slip = []
    for i in range(36):
        e = .2 + (i * 37 % 100) / 100 * 1.6
        slip.append((e, e + ((i * 53 % 100) - 45) / 160, 4, NEG if ((i * 53 % 100) - 45) / 160 > .25 else INFO, ''))
    wr20 = [52, 54, 55, 57, 58, 57, 59, 60, 58, 57, 56, 55, 55, 54, 53, 54, 52, 51, 52, 51]
    pf20 = [v / 40 for v in [52, 53, 55, 57, 59, 58, 60, 61, 59, 57, 56, 55, 54, 53, 52, 52, 51, 50, 50, 49]]
    return ('<div class="tabpane"><div class="g2">' +
            card(ch('Cuándo se opera', 'Número de trades por hora (UTC) y día') + heat(days, hours, m, label='Frecuencia hora por día', color=lambda v: mix('#F2F2EE', '#2E90FA', v))) +
            card(ch('Correlación', 'Entre módulos y entre pares. Más intenso: se mueven juntos') + heat(names, [n[:4] for n in names], cm, label='Matriz de correlación', color=lambda v: mix('#F2F2EE', '#7A5AF8', v) if v >= 0 else mix('#F2F2EE', '#E89B00', -v), fmtc=lambda v: fmt(v, 2))) +
            card(ch('Duración de los trades', 'En horas') + bars_v(dur, h=200, label='Histograma de duración', colors=[INFO] * 10, labels=['0', '', '1', '', '2', '', '4', '', '8', '12+'], fmtv=lambda v: str(int(v)))) +
            card(ch('Resultado por trade', 'En euros') + bars_v(pnl, h=200, label='Histograma de PnL', colors=[NEG, NEG, NEG, POS, POS, POS, POS, POS], labels=['−60', '−40', '−20', '0', '20', '40', '60', '80'], fmtv=lambda v: str(int(v)))) +
            card(ch('Deslizamiento', 'Precio esperado frente al ejecutado, en pips. Por encima de la raya: peor') + scatter(slip, h=230, label='Slippage', xr=(0, 2), yr=(0, 2.4), xl='esperado', yl='ejecutado', diag=True)) +
            card(ch('Pérdida de ventaja', 'Acierto y PF de los últimos 20 trades, en movimiento') + legend([('Acierto %', INFO), ('PF × 40', WARN)]) + line_chart([(wr20, INFO, 2.4, None), ([v * 40 for v in pf20], WARN, 2.4, '6 4')], h=200, label='Edge decay', yfmt=lambda v: fmt(v, 0))) +
            '</div></div>')


# ───────── Pestaña 5 · Sistema ─────────
def tab_sistema():
    mods = [['Rebote', '···4152', pill('Activo', 'sg'), 98, '1,24', '<span style="color:#3F7300">−2 %</span>'], ['Rebote', '···2511', pill('Activo', 'sg'), 44, '1,15', '<span style="color:#8F5D00">−9 %</span>'],
            ['Impulso', '···4152', pill('Activo', 'sg'), 64, '1,32', '<span style="color:#3F7300">+1 %</span>'], ['Tendencia', '···2511', pill('Activo', 'sg'), 18, '1,48', '<span style="color:#3F7300">0 %</span>'],
            ['Ruptura', '···4152', pill('Vigilar', 'so'), 23, '0,94', '<span style="color:#C21A36">−18 %</span>']]
    syst = [('Planificador', 'en marcha · próxima tarea 10:45 UTC', POS), ('MRC', 'en marcha', POS), ('Pipeline diario', 'último paso 25 de 25 · 06:10 UTC', POS), ('Conexión con el bróker', '2 de 2 cuentas conectadas', POS), ('Datos de precio', 'retraso 1,4 s', WARN)]
    files = [['06_CONFIG/metricas_diarias.json', 'hace 4 min', pill('Al día', 'sg')], ['06_CONFIG/modulos_metricas.json', 'hace 4 min', pill('Al día', 'sg')], ['06_CONFIG/cuentas_metricas.json', 'hace 4 min', pill('Al día', 'sg')], ['06_CONFIG/curva_equity.json', 'hace 4 min', pill('Al día', 'sg')], ['seq_labels', 'hace 1 min', pill('Al día', 'sg')], ['orden_ejecutada', 'hace 1 min', pill('Al día', 'sg')]]
    return ('<div class="tabpane"><div class="g2">' +
            card(ch('Sistemas encendidos', 'Lo que tiene que estar en marcha') + ''.join('<div class="hov" style="display:flex;align-items:center;gap:10px;padding:8px 6px;margin:0 -6px;border-top:1px solid #EFEFEA"><span class="sdot" style="background:%s"></span><b style="font-weight:600;font-size:14px;flex:1">%s</b><span class="t2" style="font-size:13px">%s</span></div>' % (c, n, s) for n, s, c in syst)) +
            card(ch('Conciliación', 'Saldo según el bróker frente al del sistema') + '<div style="display:flex;gap:14px">' + ''.join('<div style="flex:1;background:#F6F6F3;border-radius:14px;padding:12px"><div class="t2" style="font-size:12px;font-weight:600">%s</div><div class="tn" style="font-size:22px;font-weight:700">%s</div><div class="t2" style="font-size:12px">%s</div></div>' % x for x in (('···4152', '0,00 €', 'cuadra'), ('···2511', '1,20 €', 'diferencia por swap pendiente'))) + '</div>' + '<div class="t2" style="font-size:12px">Última comprobación 2026-11-27T10:40:00Z</div>') +
            '</div>' +
            card(ch('Estado de módulos', 'Pérdida de ventaja: cambio del PF de los últimos 20 trades frente a la media') + table(['Módulo', 'Cuenta', 'Estado', 'Trades', 'PF', 'Pérdida de ventaja'], mods, num_cols=(3, 4, 5))) +
            '<div class="g2">' +
            card(ch('Salud de los datos', 'Ficheros verificados y lo frescos que están') + table(['Fichero', 'Actualizado', 'Estado'], files)) +
            card(ch('Alertas activas', 'Problemas que siguen abiertos') + gen2.alert_row('u', 'Posición sin protección', 'EURUSD · ···2511 · rebote-2511-0093', '10:31', 'Revisar') + gen2.alert_row('a', 'Ruptura pierde ventaja', 'PF de los últimos 20: 0,94', '09:00', 'Ver') + gen2.alert_row('a', 'Datos de precio con retraso', '1,4 s', '10:12', 'Ver')) +
            '</div></div>')


# ───────── Pestaña 6 · Futuro ─────────
def tab_futuro():
    road = [('Corto plazo', [('Stop obligatorio en todas las órdenes', 'En curso'), ('Avisos de conciliación al móvil', 'Pendiente')]),
            ('Medio plazo', [('Ruptura: revisar o pausar', 'Pendiente'), ('Tercera cuenta en demo', 'Pendiente')]),
            ('Largo plazo', [('Reparto de capital automático', 'Idea'), ('Informe mensual en PDF', 'Idea')])]
    setups = [['Rebote en AUDUSD', 'Rebote', pill('Go', 'sg'), '4 de 4 criterios'], ['Tendencia en oro', 'Tendencia', pill('No-Go', 'sr'), 'Correlación alta con Ruptura'], ['Impulso en NAS100', 'Impulso', pill('Pendiente', 'so'), 'Faltan 12 días de demo']]
    goals = [('Acierto', 57.4, 60, '%'), ('Profit factor', 1.38, 1.5, ''), ('Caída máx.', 2.31, 3, ' %'), ('Sharpe', 1.62, 2, '')]
    gl = ''.join('<div style="display:flex;flex-direction:column;gap:6px"><div style="display:flex;justify-content:space-between;font-size:13px"><b>%s</b><span class="tn">%s de %s%s</span></div><div style="height:12px;border-radius:6px;background:#EBEBE6"><div class="fillx" style="height:12px;border-radius:6px;width:%d%%;background:%s"></div></div></div>' % (n, fmt(v, 2), fmt(t, 2), u, round(min(1, v / t) * 100), POS if v / t >= .9 else WARN) for n, v, t, u in goals)
    return ('<div class="tabpane"><div class="g3">' + ''.join(card(ch(t, 'Hoja de ruta') + '<div class="rm">' + ''.join('<div class="it"><span style="flex:1;font-weight:500">%s</span>%s</div>' % (n, pill(s, 'sb' if s == 'En curso' else 'sn')) for n, s in items) + '</div>') for t, items in road) + '</div>' +
            '<div class="g2">' + card(ch('Setups pendientes', 'Go: listo para activar. No-Go: no cumple') + table(['Setup', 'Módulo', 'Decisión', 'Motivo'], setups)) +
            card(ch('Métricas objetivo', 'Dónde estás frente a dónde quieres estar') + '<div style="display:flex;flex-direction:column;gap:14px">' + gl + '</div>') + '</div></div>')


TABS = [('trading', 'Trading', tab_trading), ('rendimiento', 'Rendimiento', tab_rendimiento), ('modulos', 'Por módulo', tab_modulos),
        ('analisis', 'Análisis', tab_analisis), ('sistema', 'Sistema', tab_sistema), ('futuro', 'Futuro', tab_futuro)]

header = '''<div class="card" style="padding:16px 18px;gap:12px">
  <div style="display:flex;align-items:center;gap:14px;flex-wrap:wrap">
    <span style="display:inline-flex;align-items:center;gap:8px;height:30px;padding:0 12px;border-radius:999px;background:#EEF8DC;color:#3F7300;font-weight:700;font-size:13px"><span class="sdot" style="background:{{semColor}}"></span>{{semText}}</span>
    <div class="achips" role="group" aria-label="Cuenta"><sc-for list="{{accs}}" as="c" hint-placeholder-count="3"><button type="button" class="{{c.cls}}" onClick="{{c.pick}}">{{c.n}}</button></sc-for></div>
    <span style="flex:1"></span>
    <span class="t2" style="font-size:12px">Actualizado <b class="tn" style="color:#2B2E33">{{updated}}</b> · cada 5 min</span>
  </div>
  <div style="display:flex;align-items:flex-end;flex-wrap:wrap;gap:12px 0">
    <div class="hstat"><span class="l">Balance</span><span class="d tn" style="font-size:30px;font-weight:700">{{balance}}</span><span class="tn" style="font-size:13px;font-weight:600;color:{{dayColor}}">{{dayChange}} hoy</span></div>
    <div class="hstat"><span class="l">Flotante</span><span class="d tn" style="font-size:24px;font-weight:700;color:{{floatColor}}">{{floating}}</span><span class="t2" style="font-size:12px">sin cerrar</span></div>
    <div class="hstat"><span class="l">Trades abiertos</span><span class="d tn" style="font-size:24px;font-weight:700">{{open}}</span><span class="t2" style="font-size:12px">{{openSub}}</span></div>
    <div class="hstat"><span class="l">Alertas</span><span style="display:flex;align-items:center;gap:8px"><span class="d tn" style="font-size:24px;font-weight:700;color:#C21A36">{{alerts}}</span><span class="pill sr">{{alertsRed}} urgente</span><span class="pill so">{{alertsAmber}} atención</span></span><span class="t2" style="font-size:12px">abiertas</span></div>
  </div>
</div>
<div class="kgrid"><sc-for list="{{kpis}}" as="k" hint-placeholder-count="8"><div class="kpi"><span class="l">{{k.l}}</span><span class="v" style="color:{{k.c}}">{{k.v}}</span><span class="r">{{k.r}}</span></div></sc-for></div>
<div class="ptabs" role="tablist" aria-label="Secciones"><sc-for list="{{tabs}}" as="t" hint-placeholder-count="6"><button type="button" role="tab" aria-selected="{{t.sel}}" class="{{t.cls}}" onClick="{{t.pick}}">{{t.n}}</button></sc-for></div>
'''

panes = ''.join('<sc-if value="{{is_%s}}" hint-placeholder-val="{{ %s }}">%s</sc-if>' % (k, 'true' if k == 'trading' else 'false', fn()) for k, n, fn in TABS)
body = mac2('cuentas', 'Cuentas', '', header + panes)

TABJS = json.dumps([[k, n] for k, n, _ in TABS], ensure_ascii=False)
JS = r'''
class Component extends DCLogic {
  constructor(props) { super(props); this.state = { tab: 'trading', acc: 'ambas' }; }
  renderVals() {
    const S = this.state;
    const TABS = __TABS__;
    const D = {
      ambas: { balance: '153.442,40 €', day: '−648,20 € · −0,42 %', dayNeg: true, floating: '+212,40 €', fneg: false, open: '5', openSub: '3 en ···4152 · 2 en ···2511', alerts: '3', red: '1', amber: '2',
        k: [['PnL realizado hoy', '−860,60 €', 'neg'], ['PnL flotante', '+212,40 €', 'pos'], ['Acierto 30 d', '57,4 %', 'pos'], ['Profit factor 30 d', '1,38', 'pos'], ['Caída máx. 30 d', '−2,31 %', 'neg'], ['Oportunidades', '3', 'info'], ['VIX · régimen', '21,84', 'warn'], ['Riesgo utilizado', '2,4 %', 'pos']] },
      a: { balance: '101.842,30 €', day: '−611,10 € · −0,60 %', dayNeg: true, floating: '+202,40 €', fneg: false, open: '3', openSub: 'en ···4152', alerts: '2', red: '0', amber: '2',
        k: [['PnL realizado hoy', '−790,50 €', 'neg'], ['PnL flotante', '+202,40 €', 'pos'], ['Acierto 30 d', '58,9 %', 'pos'], ['Profit factor 30 d', '1,41', 'pos'], ['Caída máx. 30 d', '−1,92 %', 'neg'], ['Oportunidades', '2', 'info'], ['VIX · régimen', '21,84', 'warn'], ['Riesgo utilizado', '1,6 %', 'pos']] },
      b: { balance: '51.600,10 €', day: '−37,10 € · −0,07 %', dayNeg: true, floating: '+10,00 €', fneg: false, open: '2', openSub: 'en ···2511 · 1 sin SL', alerts: '1', red: '1', amber: '0',
        k: [['PnL realizado hoy', '−70,10 €', 'neg'], ['PnL flotante', '+10,00 €', 'pos'], ['Acierto 30 d', '54,2 %', 'pos'], ['Profit factor 30 d', '1,22', 'warn'], ['Caída máx. 30 d', '−2,31 %', 'neg'], ['Oportunidades', '1', 'info'], ['VIX · régimen', '21,84', 'warn'], ['Riesgo utilizado', 'n.d.', 'nd']] }
    };
    const RULE = ['verde si gana, rojo si pierde', 'abierto, aún no realizado', 'verde si pasa del 50 %', 'verde si pasa de 1,3', 'peor caída del periodo', 'señales vigiladas', 'ámbar: risk-off', 'verde si no llega al 3 %'];
    const COL = { pos: '#3F7300', neg: '#C21A36', info: '#1567C9', warn: '#8F5D00', nd: '#8A8A84' };
    const d = D[S.acc];
    const out = {
      accs: [['ambas', 'Ambas cuentas'], ['a', '···4152'], ['b', '···2511']].map((c) => ({ n: c[1], cls: S.acc === c[0] ? 'on' : '', pick: () => this.setState({ acc: c[0] }) })),
      semText: 'Activo', semColor: '#5FA800', updated: '10:42 UTC',
      balance: d.balance, dayChange: d.day, dayColor: d.dayNeg ? '#C21A36' : '#3F7300',
      floating: d.floating, floatColor: d.fneg ? '#C21A36' : '#3F7300',
      open: d.open, openSub: d.openSub, alerts: d.alerts, alertsRed: d.red, alertsAmber: d.amber,
      kpis: d.k.map((k, i) => ({ l: k[0], v: k[1], c: COL[k[2]], r: k[2] === 'nd' ? 'sin dato' : RULE[i] })),
      tabs: TABS.map((t) => ({ n: t[1], cls: S.tab === t[0] ? 'on' : '', sel: S.tab === t[0] ? 'true' : 'false', pick: () => this.setState({ tab: t[0] }) }))
    };
    TABS.forEach((t) => { out['is_' + t[0]] = S.tab === t[0]; });
    return out;
  }
}
'''.replace('__TABS__', TABJS)

html = ('<!doctype html>\n<html lang="es">\n<head>\n<meta charset="utf-8">\n<title>Panel de cuenta</title>\n<script src="./support.js"></script>\n</head>\n<body>\n<x-dc>\n<helmet>\n'
        '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">\n<style>\n' + CSS + '\n</style>\n</helmet>\n' + body +
        '\n</x-dc>\n<script type="text/x-dc" data-dc-script data-props=\'{"$preview":{"width":1440,"height":1300}}\'>' + JS + '</script>\n</body>\n</html>\n')
open(os.path.join(OUT, 'ACuentaPanel.dc.html'), 'w').write(html)
print('ok ACuentaPanel', len(html))


# ───────── Nivel 3 · datos por trade, día, módulo y cuenta ─────────
FILES = [
    ('Por trade', 'seq_labels + orden_ejecutada', 'Una fila por operación, abierta o cerrada.',
     'label modulo cuenta par lado entrada_px entrada_ts sl tp volumen riesgo_pct sesion regimen confianza salida_px salida_ts pnl comision swap duracion_min resultado slippage_px slippage_pips'),
    ('Por día', '06_CONFIG/metricas_diarias.json', 'Una entrada por día y cuenta. Paso 23 del pipeline.',
     'fecha balance_inicio balance_fin pnl_realizado pnl_flotante costes n_trades_abiertos n_trades_cerrados wins losses wr max_dd_intradia max_dd_desde_pico vix regimen oportunidades'),
    ('Por módulo', '06_CONFIG/modulos_metricas.json', 'Una entrada por módulo y cuenta. Paso 24 del pipeline.',
     'modulo cuenta n_trades wins losses wr pnl_realizado pnl_flotante costes avg_rr max_dd max_dd_pct capital_asignado_pct capital_en_riesgo_pct sharpe sortino profit_factor avg_duracion_min mejor_trade peor_trade ultimo_trade decay_pct'),
    ('Por cuenta', '06_CONFIG/cuentas_metricas.json', 'Una entrada por cuenta. Paso 25 del pipeline.',
     'cuenta balance equity margin_used margin_free margin_level_pct pnl_flotante pnl_realizado_hoy pnl_realizado_total n_trades_abiertos n_trades_cerrados_total max_dd_historico gap_conciliacion deposito_inicial delta_c_dep'),
    ('Curva', '06_CONFIG/curva_equity.json', 'Puntos de la curva de equity realizada, por cuenta.',
     'cuenta ts equity_realizado drawdown_pct'),
]
FLOAT = {'pnl_flotante', 'n_trades_abiertos', 'equity', 'margin_used', 'margin_free', 'margin_level_pct'}
TS = {'entrada_ts', 'salida_ts', 'fecha', 'ultimo_trade', 'ts'}


def chip(f):
    if f in FLOAT:
        return '<span class="tag" style="background:#E3F0FE;color:#1567C9">%s</span>' % f
    if f in TS:
        return '<span class="tag" style="background:#FDF1D6;color:#8F5D00">%s</span>' % f
    return '<span class="tag">%s</span>' % f


cards = ''.join(card('<div style="display:flex;align-items:baseline;gap:10px;flex-wrap:wrap"><b style="font-size:17px">%s</b><span class="tag" style="background:#2B2E33;color:#fff">%s</span></div><div class="t2" style="font-size:13px">%s</div><div style="display:flex;flex-wrap:wrap;gap:6px">%s</div>' % (t, f, d, ''.join(chip(x) for x in fields.split()))) for t, f, d, fields in FILES)
rules = [('Solo nuestras 2 cuentas', '···4152 y ···2511. Nunca datos del EA.'), ('Realizado y flotante, separados', 'Azul: flotante. El resto, realizado.'), ('Cada dato con su fuente', 'Etiqueta módulo-cuenta-secuencia, p. ej. rebote-4152-0187.'),
         ('Hora en UTC, ISO 8601', 'Ámbar: campos de fecha y hora, p. ej. 2026-11-27T10:42:00Z.'), ('Sin credenciales', 'Ningún fichero guarda claves; van al Llavero.'), ('Números exactos', 'Si falta, «n.d.». Nunca un cero inventado.'),
         ('Se refresca cada 5 min', 'Los datos críticos se ven sin depender de JavaScript.'), ('Estilo de los ficheros', 'Español sin tildes y sin emojis.')]
rcard = card(ch('Principios', 'Se aplican a todos los ficheros y pantallas') + '<div class="g2">' + ''.join('<div style="background:#F6F6F3;border-radius:12px;padding:12px"><b style="font-size:14px">%s</b><div class="t2" style="font-size:13px">%s</div></div>' % r for r in rules) + '</div>')
pipe = card(ch('En el pipeline diario', 'Pasos nuevos de pipeline_diario.py') + ''.join('<div class="hov" style="display:flex;align-items:center;gap:12px;padding:9px 6px;margin:0 -6px;border-top:1px solid #EFEFEA"><span class="num">%s</span><span class="tag">%s</span><span class="t2" style="font-size:13px">→ %s</span></div>' % x for x in (('23', 'metricas_diarias.py', 'metricas_diarias.json'), ('24', 'modulos_metricas.py', 'modulos_metricas.json'), ('25', 'cuentas_metricas.py', 'cuentas_metricas.json'), ('·', 'curva_equity.py', 'curva_equity.json'))))
lst = '<section class="g2" style="align-items:start">' + cards + '</section><section class="g2" style="align-items:start">' + rcard + pipe + '</section>'
body2 = mac2('cuentas', 'Datos por cuenta', '', lst)
extra_css = '.num{width:26px;height:26px;border-radius:8px;background:#2B2E33;color:#fff;font-size:13px;font-weight:700;display:flex;align-items:center;justify-content:center;flex:none}'
html2 = ('<!doctype html>\n<html lang="es">\n<head>\n<meta charset="utf-8">\n<title>Datos por cuenta</title>\n<script src="./support.js"></script>\n</head>\n<body>\n<x-dc>\n<helmet>\n'
         '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">\n<style>\n' + CSS + extra_css + '\n</style>\n</helmet>\n' + body2 +
         '\n</x-dc>\n<script type="text/x-dc" data-dc-script data-props=\'{"$preview":{"width":1440,"height":1100}}\'>\nclass Component extends DCLogic {\n  renderVals() {\n    return {};\n  }\n}\n</script>\n</body>\n</html>\n')
open(os.path.join(OUT, 'ADatosCuenta.dc.html'), 'w').write(html2)
print('ok ADatosCuenta')
