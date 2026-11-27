#!/usr/bin/env python3
# Genera los artboards del storyboard que faltan (pantallas actuales de la app).
import math, os

BASE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(BASE, '..', 'root', 'project')
CSS = open(os.path.join(BASE, 'style.css')).read()

INFO = '<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M12 11v5.5M12 7.6h.01"/></svg>'


def rr(x, y, w, h, r):
    return ('M%g %gh%ga%g %g 0 0 1 %g %gv%ga%g %g 0 0 1 -%g %gh-%ga%g %g 0 0 1 -%g -%gv-%ga%g %g 0 0 1 %g -%gz'
            % (x + r, y, w - 2 * r, r, r, r, r, h - 2 * r, r, r, r, r, w - 2 * r, r, r, r, r, h - 2 * r, r, r, r, r))


def ci(cx, cy, r):
    return 'M%g %ga%g %g 0 1 0 %g 0a%g %g 0 1 0 -%g 0z' % (cx - r, cy, r, r, 2 * r, r, r, 2 * r)


ICO = {
    'torre': rr(3.5, 3.5, 7, 7, 2) + rr(13.5, 3.5, 7, 7, 2) + rr(3.5, 13.5, 7, 7, 2) + rr(13.5, 13.5, 7, 7, 2),
    'ordenes': 'M12 3 20 7.3v9.4L12 21l-8-4.3V7.3z M4.3 7.4 12 11.6l7.7-4.2 M12 11.6V21',
    'flota': rr(4, 4, 16, 6.5, 2) + rr(4, 13.5, 16, 6.5, 2) + 'M7.5 7.25h.01 M7.5 16.75h.01 M11 7.25h5 M11 16.75h5',
    'jev': 'M11 3.5c.6 3.6 2.4 5.4 6 6-3.6.6-5.4 2.4-6 6-.6-3.6-2.4-5.4-6-6 3.6-.6 5.4-2.4 6-6z M18.5 14.5c.3 1.7 1.1 2.5 2.8 2.8-1.7.3-2.5 1.1-2.8 2.8-.3-1.7-1.1-2.5-2.8-2.8 1.7-.3 2.5-1.1 2.8-2.8z',
    'avisos': 'M6 16.5V11a6 6 0 0 1 12 0v5.5l1.5 2h-15z M10 20.5a2 2 0 0 0 4 0',
    'mom': 'M6 15l6-6 6 6',
    'rev': 'M3 12h3l2-6 4 12 3-9 2 3h4',
    'tend': 'M7 17 17 7 M9 7h8v8',
    'lock': rr(5, 11, 14, 9, 2.5) + 'M8.5 11V8.5a3.5 3.5 0 0 1 7 0V11',
    'check': 'M5 12.5l4.5 4.5L19 7.5',
    'bang': 'M12 6v7 M12 17.5h.01',
}


def doc(title, w, h, body):
    return ('<!doctype html>\n<html lang="es">\n<head>\n<meta charset="utf-8">\n<title>%s</title>\n<script src="./support.js"></script>\n</head>\n<body>\n<x-dc>\n<helmet>\n'
            '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">\n<style>\n%s\n</style>\n</helmet>\n%s\n</x-dc>\n'
            '<script type="text/x-dc" data-dc-script data-props=\'{"$preview":{"width":%d,"height":%d}}\'>\nclass Component extends DCLogic {\n  renderVals() {\n    return {};\n  }\n}\n</script>\n</body>\n</html>\n'
            % (title, CSS, body, w, h))


def ch(t, info, size=15):
    return '<div class="ch" style="font-size:%dpx">%s<button class="inf" aria-label="%s" title="%s">%s</button></div>' % (size, t, info, info, INFO)


def pill(t, c='sn'):
    return '<span class="pill %s">%s</span>' % (c, t)


def tile(d, color, size=30, r=9):
    s = round(size * .55)
    return '<span class="sq" style="width:%dpx;height:%dpx;border-radius:%dpx;background:%s"><svg viewBox="0 0 24 24" width="%d" height="%d" aria-hidden="true"><path d="%s"/></svg></span>' % (size, size, r, color, s, s, d)


def ring(score, color, size=44):
    C = 2 * math.pi * 19
    p = max(score, 1) / 100
    return ('<svg viewBox="0 0 44 44" width="%d" height="%d" aria-hidden="true"><g transform="rotate(-90 22 22)" fill="none" stroke-linecap="round" stroke-width="6">'
            '<circle cx="22" cy="22" r="19" stroke="#EBEBE6"/><circle cx="22" cy="22" r="19" stroke="%s" stroke-dasharray="%.1f %.1f"/></g></svg>' % (size, size, color, p * C, C))


def mac(active, main, extra=''):
    return ('<div class="win">\n  <div class="tl"><span style="background:#FF5F57"></span><span style="background:#FEBC2E"></span><span style="background:#28C840"></span></div>\n'
            '  <div class="rail"><dc-import name="RielMac" active="%s" hint-size="64px,842px"></dc-import></div>\n'
            '  <main class="main" style="padding-top:22px">%s</main>%s\n</div>' % (active, main, extra))


def tabs(on):
    items = [('torre', 'Hoy', '', '', 'IPhoneHoy.dc.html'), ('ordenes', 'Órdenes', '', '', 'IPhoneOrdenes.dc.html'),
             ('avisos', 'Avisos', '3', '#F2465E', 'IPhoneAvisos.dc.html'), ('jev', 'Jev', '1', '#2E90FA', 'IPhoneJev.dc.html')]
    out = ['<nav class="tabs" aria-label="Secciones">']
    for i, (k, n, b, bc, href) in enumerate(items):
        badge = '<span class="tb" style="background:%s">%s</span>' % (bc, b) if b else ''
        out.append('<a class="%s" href="%s"><svg viewBox="0 0 24 24" width="25" height="25" class="g" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="%s"/></svg>%s%s</a>'
                   % ('tab on' if i == on else 'tab', href, ICO[k], n, badge))
    out.append('</nav>')
    return ''.join(out)


def phone(inner, on):
    return ('<div class="stage"><div class="phone"><div class="scr" style="background:#F2F2EE">\n  <div class="island"></div>\n'
            '  <div style="flex:1;padding:58px 16px 0;display:flex;flex-direction:column;gap:12px;overflow:hidden">%s</div>\n  %s\n</div></div></div>' % (inner, tabs(on)))


def phone_title(title, sub=None):
    s = '<div class="t2" style="font-size:13px;font-weight:600">%s</div>' % sub if sub else ''
    return '<div style="padding:0 4px">%s<div class="d" style="font-size:34px;font-weight:700;line-height:1.15">%s</div></div>' % (s, title)


def write(name, title, w, h, body):
    with open(os.path.join(OUT, name), 'w') as f:
        f.write(doc(title, w, h, body))


# ───────────────────────── Mac · Flota ─────────────────────────
def uptime(incidents, paused_last=0):
    bars = []
    for i in range(60):
        if paused_last and i >= 60 - paused_last:
            c = '#C9CDD2'
        else:
            v = incidents.get(i, 1)
            c = '#5FA800' if v >= 1 else ('#E89B00' if v > 0 else '#F2465E')
        bars.append('<span style="flex:1;height:24px;border-radius:2px;background:%s"></span>' % c)
    return '<div style="display:flex;gap:2px;flex:1">%s</div>' % ''.join(bars)


def ring_color(v):
    return '#5FA800' if v >= 90 else ('#E89B00' if v >= 70 else '#F2465E')


CELLS = [
    dict(id='c-lon-01', acc='FND-A-100k', h='ok', sc=(96, 88, 100), v=('0,8 s', '640 ms', 'ok'), day='−0,6 %', neg=True,
         w=[('mom_us500 · 1,0', 'sg'), ('rev_m5 · 1,0', 'sg'), ('tend_d1 · 0,5', 'sg')], foot='Londres → LD4', ver='v0.9.3', btn='Pausar', sel=True,
         up=uptime({41: .5})),
    dict(id='c-lon-02', acc='FND-B-50k', h='warning', sc=(82, 72, 100), v=('1,1 s', '910 ms', 'ok'), day='−1,9 %', neg=True,
         w=[('rev_m5 · 0,5', 'sg'), ('tend_d1 · 0,5', 'sg')], foot='Londres → LD4', ver='v0.9.3', btn='Pausar',
         up=uptime({12: .5, 33: 0, 58: .5, 59: .5})),
    dict(id='c-lon-03', acc='REAL-01', h='critical', sc=(97, 91, 55), v=('0,7 s', '580 ms', '1 dif.'), day='+0,3 %', neg=False,
         w=[('rev_m5 · 0,5', 'sg'), ('tend_d1 · 0,5', 'sg')], foot='Londres → LD4', ver='v0.9.2', btn='Pausar',
         up=uptime({22: .5, 59: 0})),
    dict(id='c-dem-01', acc='DEMO-01', h='ok', sc=(93, 84, 100), v=('0,9 s', '720 ms', 'ok'), day='+0,5 %', neg=False,
         w=[('mom_us500 · sombra', 'sb'), ('rev_m5 · 1,0', 'sg'), ('tend_d1 · 1,0', 'sg')], foot='Bilbao → LD4', ver='v0.9.4 · candidata', btn='Pausar',
         up=uptime({54: .5})),
    dict(id='c-lon-04', acc='FND-A-25k', h='paused', sc=(0, 0, 0), v=('—', '—', 'ok'), day='0,0 %', neg=False,
         w=[('mom_us500 · pausada', 'sn'), ('rev_m5 · pausada', 'sn'), ('tend_d1 · pausada', 'sn')], foot='Londres → LD4', ver='v0.9.3', btn='Reanudar',
         up=uptime({}, 9)),
]
HEALTH = {'ok': ('Activa', 'sg', '#5FA800'), 'warning': ('Aviso', 'so', '#E89B00'), 'critical': ('Revisar', 'sr', '#F2465E'), 'paused': ('Pausada', 'sn', '#B5B5AE')}


def cell_card(c):
    lab, pc, col = HEALTH[c['h']]
    paused = c['h'] == 'paused'
    rings = []
    for (name, score, val) in (('Latido', c['sc'][0], c['v'][0]), ('Latencia', c['sc'][1], c['v'][1]), ('Concil.', c['sc'][2], c['v'][2])):
        rc = '#C9CDD2' if paused else ring_color(score)
        rings.append('<div style="display:flex;flex-direction:column;align-items:center;gap:2px">%s<span class="tn" style="font-size:12px;font-weight:600">%s</span><span class="t2" style="font-size:11px">%s</span></div>'
                     % (ring(score if not paused else 1, rc), val, name))
    dcol = '#C21A36' if c['neg'] else '#2B2E33'
    sh = '0 0 0 2px #6B7078' if c.get('sel') else '0 1px 2px rgba(0,0,0,.05),0 6px 20px rgba(0,0,0,.05)'
    pills = ''.join(pill(t, k) for t, k in c['w'])
    return ('<div class="card" style="padding:16px;display:flex;flex-direction:column;gap:12px;box-shadow:%s">'
            '<div style="display:flex;align-items:center;gap:12px">%s<div style="flex:1;min-width:0"><div class="mono" style="font-weight:600;font-size:15px;line-height:1.25">%s</div><div class="t2" style="font-size:13px">%s</div></div>%s</div>'
            '<div style="display:flex;align-items:center;gap:14px">%s<div style="margin-left:auto;text-align:right"><div class="tn" style="font-size:20px;font-weight:600;color:%s">%s</div><div class="t2" style="font-size:12px">hoy</div></div></div>'
            '<div style="display:flex;gap:6px;flex-wrap:wrap">%s</div>'
            '<div style="border-top:1px solid #EFEFEA;padding-top:10px;display:flex;align-items:center;gap:6px;font-size:13px"><b style="font-weight:600">%s</b><span class="t2">· %s</span>'
            '<a class="btn" href="MacFirmar.dc.html" style="margin-left:auto;height:28px;padding:0 12px;font-size:12.5px;font-weight:600">%s</a></div></div>'
            % (sh, tile(ICO['flota'], col, 34, 10), c['id'], c['acc'], pill(lab, pc), ''.join(rings), dcol, c['day'], pills, c['foot'], c['ver'], c['btn']))


def step(title, sub, state):
    if state == 'done':
        mark = '<span style="width:22px;height:22px;border-radius:50%%;background:#3A3D42;display:flex;align-items:center;justify-content:center;flex:none"><svg viewBox="0 0 24 24" width="12" height="12" class="g" stroke="#fff" stroke-width="3.2"><path d="%s"/></svg></span>' % ICO['check']
        p = pill('Superado', 'sg')
    elif state == 'cur':
        mark = '<span style="width:22px;height:22px;border-radius:50%;background:#fff;border:3px solid #3A3D42;flex:none"></span>'
        p = pill('Listo', 'sb')
    else:
        mark = '<span style="width:22px;height:22px;border-radius:50%;background:#fff;border:3px solid #C9CDD2;flex:none"></span>'
        p = pill('Pendiente', 'sn')
    subh = '<div class="t2" style="font-size:12px">%s</div>' % sub if sub else ''
    return '<div style="display:flex;align-items:flex-start;gap:12px">%s<div style="flex:1;min-width:0"><div style="font-size:13px;font-weight:600">%s</div>%s</div>%s</div>' % (mark, title, subh, p)


def flota():
    head = ('<div style="display:flex;align-items:center;gap:10px">' + ch('Flota', 'Una célula por cuenta: su motor, su ruta y su estado. Principal y reserva con un cerrojo que decide quién opera', 20) +
            '<div style="flex:1"></div><a class="btn" href="MacFirmar.dc.html">Relevo manual</a><a class="btn x" href="MacFirmar.dc.html">Parar todo</a></div>')
    grid = '<section style="display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:14px">%s</section>' % ''.join(cell_card(c) for c in CELLS)
    rows = ''.join('<div style="display:flex;align-items:center;gap:12px"><span class="mono" style="width:78px;font-weight:600;font-size:12px">%s</span>%s</div>' % (c['id'], c['up']) for c in CELLS)
    avail = '<div class="card" style="flex:1;padding:16px;display:flex;flex-direction:column;gap:10px">%s%s</div>' % (ch('Disponibilidad · 60 días', 'Un día por barra. Ámbar: incidencia menor. Rojo: parada. Gris: pausada'), rows)
    steps = ''.join([step('Gemelo', 'Repetición de 30 días sin diferencias', 'done'), step('c-dem-01 · demo', '6 de 5 días sin incidencias', 'done'),
                     step('c-lon-04 · fondeo pausado', 'Siguiente parada', 'cur'), step('c-lon-01 · fondeo', 'Después de 3 días en c-lon-04', 'todo'),
                     step('c-lon-02 · fondeo', '', 'todo'), step('c-lon-03 · cuenta real', 'Siempre la última', 'todo')])
    dep = '<div class="card" style="width:360px;padding:16px;display:flex;flex-direction:column;gap:10px">%s%s</div>' % (ch('Despliegue v0.9.4', 'Como una ruta: no pasa a la siguiente parada sin superar la anterior'), steps)
    return mac('flota', head + grid + '<section style="display:flex;gap:14px;align-items:flex-start">%s%s</section>' % (avail, dep))


# ───────────────────────── Mac · Estrategias ─────────────────────────
def area(vals, w, h, color):
    lo, hi = min(vals + [0]), max(vals)
    sp = (hi - lo) or 1
    pts = [(10 + i * (w - 20) / (len(vals) - 1), h - 14 - (v - lo) / sp * (h - 34)) for i, v in enumerate(vals)]
    line = ' '.join('%.1f,%.1f' % p for p in pts)
    fill = 'M%.1f,%d L%s L%.1f,%d Z' % (pts[0][0], h - 4, ' L'.join('%.1f,%.1f' % p for p in pts), pts[-1][0], h - 4)
    zero = h - 14 - (0 - lo) / sp * (h - 34)
    return ('<svg viewBox="0 0 %d %d" role="img" aria-label="Rendimiento a 30 días de la estrategia: sube de 0 a más 1,8 por ciento" style="width:100%%;height:220px;display:block" preserveAspectRatio="none">'
            '<line x1="0" y1="%.1f" x2="%d" y2="%.1f" stroke="#EBEBE6"/><path d="%s" fill="%s" fill-opacity=".1"/><polyline points="%s" fill="none" stroke="%s" stroke-width="2.4" stroke-linejoin="round"/>'
            '<circle cx="%.1f" cy="%.1f" r="4.5" fill="%s"/></svg>' % (w, h, zero, w, zero, fill, color, line, color, pts[-1][0], pts[-1][1], color))


MOM = [0, .1, .05, .22, .3, .25, .42, .55, .5, .68, .6, .78, .95, .88, 1.0, 1.12, 1.05, 1.2, 1.15, 1.32, 1.28, 1.4, 1.5, 1.45, 1.58, 1.62, 1.55, 1.7, 1.75, 1.8]


def estrategias():
    ranked = [('tend_d1', 'Tendencia D1', '+2,4 %', '#D444F1', ICO['tend'], [0, .3, .2, .6, .9, .8, 1.3, 1.6, 1.5, 2.0, 2.4], False),
              ('mom_us500', 'Momentum US500', '+1,8 %', '#7A5AF8', ICO['mom'], [0, .2, .1, .5, .8, .7, 1.2, 1.4, 1.3, 1.7, 1.8], True),
              ('rev_m5', 'Reversión M5', '+0,9 %', '#00A3A3', ICO['rev'], [0, .1, .05, .2, .35, .3, .5, .6, .55, .8, .9], False)]
    rows = []
    for i, (sid, name, ret, col, d, ser, sel) in enumerate(ranked):
        sp = area(ser, 56, 22, '#5FA800').replace('height:220px', 'height:22px;width:56px').replace('<line', '<line style="display:none"')
        rows.append('<div style="display:flex;align-items:center;gap:11px;padding:7px 8px;border-radius:12px;background:%s"><span class="t2" style="width:14px;font-size:12px">%d</span>%s'
                    '<div style="flex:1;min-width:0"><div class="mono" style="font-weight:600;font-size:13px">%s</div><div class="t2" style="font-size:12px">%s</div></div>%s<span class="tn" style="width:66px;text-align:right;font-weight:700;font-size:13px;color:#3F7300">%s</span></div>'
                    % ('#E3E5E8' if sel else 'transparent', i + 1, tile(d, col, 30, 9), sid, name, sp, ret))
    left1 = '<div class="card" style="padding:14px;display:flex;flex-direction:column;gap:6px">%s%s</div>' % (ch('Estrategias', 'Rendimiento a 30 días, de mejor a peor'), ''.join(rows))
    cols = ['lon-01', 'lon-02', 'lon-03', 'dem-01', 'lon-04']
    W = {'mom_us500': ['1,0', '—', '—', 'som', '‖'], 'rev_m5': ['1,0', '0,5', '0,5', '1,0', '‖'], 'tend_d1': ['0,5', '0,5', '0,5', '1,0', '‖']}
    mh = '<div style="display:flex;gap:4px"><span style="width:76px"></span>%s</div>' % ''.join('<span class="mono" style="flex:1;text-align:center;font-size:10px;color:#5F5F5A">%s</span>' % c for c in cols)
    mrows = []
    for sid, vals in W.items():
        cells = ''
        for v in vals:
            act = v not in ('—', 'som', '‖')
            cells += '<span class="tn" style="flex:1;min-height:24px;display:flex;align-items:center;justify-content:center;border-radius:7px;font-size:11px;font-weight:600;background:%s;color:%s">%s</span>' % ('#EEF8DC' if act else '#EBEBE6', '#3F7300' if act else '#5F5F5A', v)
        mrows.append('<div style="display:flex;gap:4px;align-items:center"><span class="mono" style="width:76px;font-weight:600;font-size:11px">%s</span>%s</div>' % (sid, cells))
    left2 = '<div class="card" style="padding:14px;display:flex;flex-direction:column;gap:6px">%s<div style="display:flex;flex-direction:column;gap:6px">%s%s</div></div>' % (ch('Matriz', 'Qué estrategia corre en qué célula y con qué peso'), mh, ''.join(mrows))
    stats = [('Operaciones', '64'), ('Acierto', '55 %'), ('Factor', '1,32'), ('Caída máx.', '−1,1 %'), ('Sharpe', '1,6'), ('Sharpe defl.', '0,9'), ('Exposición', '0,3 lotes'), ('Días en estado', '11')]
    sg = '<div style="display:grid;grid-template-columns:repeat(4,1fr);gap:0 14px">%s</div>' % ''.join(
        '<div style="padding:10px 0;border-bottom:1px solid #EFEFEA"><div class="t2" style="font-size:12px">%s</div><div class="tn" style="font-size:16px;font-weight:600">%s</div></div>' % s for s in stats)

    def wrow(cid, mode, mc, w):
        return ('<div style="display:flex;align-items:center;gap:10px;padding:3px 0"><span class="mono" style="font-size:13px">%s</span><span style="flex:1"></span>%s<span class="tn" style="width:38px;text-align:right;font-weight:700;font-size:13px">%s</span>'
                '<span style="display:flex;background:#EBEBE6;border-radius:8px;overflow:hidden"><span style="width:28px;height:26px;display:flex;align-items:center;justify-content:center;font-size:14px">−</span><span style="width:1px;background:#D8D8D2;margin:6px 0"></span><span style="width:28px;height:26px;display:flex;align-items:center;justify-content:center;font-size:14px">+</span></span></div>'
                % (cid, pill(mode, mc), w))
    peso = ch('Peso por célula', 'Bajar se aplica con firma. Subir por encima de lo que fijó Jev queda pendiente de aprobación') + wrow('c-lon-01', 'Activa', 'sg', '1,00') + wrow('c-dem-01', 'Sombra', 'sb', '0,00') + wrow('c-lon-04', 'Pausada', 'sn', '0,00')
    params = ch('Parámetros', 'Los vigentes de esta versión. Se cambian en Ajustes') + ''.join(
        '<div style="display:flex;justify-content:space-between"><span class="mono t2" style="font-size:13px">%s</span><span class="tn" style="font-weight:600;font-size:13px">%s</span></div>' % p
        for p in (('ventana', '30'), ('umbral_adx', '22'), ('stop_atr', '2,00')))
    detail = ('<div class="card" style="flex:1;padding:20px;display:flex;flex-direction:column;gap:16px;min-width:0">'
              '<div style="display:flex;align-items:flex-start"><div style="flex:1"><div class="mono t2" style="font-size:12px">mom_us500 · versión 2</div><div class="d" style="font-size:26px;font-weight:700">Momentum US500</div>'
              '<div style="display:flex;align-items:baseline;gap:10px"><span class="d tn" style="font-size:42px;font-weight:600">+1,8 %%</span>%s</div></div><a class="btn p" href="MacAjustes.dc.html" style="height:38px;padding:0 18px;font-size:14px;font-weight:600">Ajustar</a></div>'
              '%s%s<div style="border-top:1px solid #EFEFEA"></div>'
              '<div style="display:flex;gap:24px"><div style="flex:1;display:flex;flex-direction:column;gap:8px">%s</div><div style="flex:1;display:flex;flex-direction:column;gap:8px">%s</div></div></div>'
              % (pill('+0,3 % esta semana', 'sg'), area(MOM, 700, 220, '#5FA800'), sg, peso, params))
    return mac('estrategias', '<section style="display:flex;gap:14px;flex:1;min-height:0"><div style="width:340px;display:flex;flex-direction:column;gap:14px">%s%s</div>%s</section>' % (left1, left2, detail))


# ───────────────────────── Mac · Ajustes ─────────────────────────
def slider(frac, color='#3A3D42'):
    return ('<span style="flex:1;position:relative;height:22px;display:flex;align-items:center"><span style="position:absolute;left:0;right:0;height:4px;border-radius:2px;background:#E3E5E8"></span>'
            '<span style="position:absolute;left:0;width:%.1f%%;height:4px;border-radius:2px;background:%s"></span>'
            '<span style="position:absolute;left:calc(%.1f%% - 9px);width:18px;height:18px;border-radius:50%%;background:#fff;box-shadow:0 1px 3px rgba(0,0,0,.3)"></span></span>' % (frac * 100, color, frac * 100))


def toggle(on=True):
    return '<span style="width:38px;height:22px;border-radius:11px;background:%s;position:relative;flex:none"><span style="position:absolute;top:2px;%s:2px;width:18px;height:18px;border-radius:50%%;background:#fff;box-shadow:0 1px 2px rgba(0,0,0,.25)"></span></span>' % ('#3A3D42' if on else '#D8D8D2', 'right' if on else 'left')


def group(title, rows):
    return '<div><div class="t2" style="font-size:13px;font-weight:600;margin-bottom:4px">%s</div><div style="background:#F2F2EE;border-radius:14px;padding:6px 14px">%s</div></div>' % (title, rows)


def grow(label, ctrl):
    return '<div style="display:flex;align-items:center;justify-content:space-between;padding:7px 0;font-size:13px">%s%s</div>' % (label, ctrl)


def cond_row(parts, bg):
    out = ''
    for j, t in enumerate(parts):
        if j == 0:
            out += '<span class="t2" style="min-width:26px;font-weight:700;font-size:13px">%s</span>' % t
        elif j % 2 == 1:
            out += '<span style="height:28px;padding:0 10px;display:flex;align-items:center;background:#fff;border-radius:8px;font-weight:600;font-size:13px">%s</span>' % t
        else:
            out += '<span style="font-size:13px">%s</span>' % t
    return '<div style="display:flex;align-items:center;gap:8px;padding:6px 10px;border-radius:12px;background:%s">%s</div>' % (bg, out)


def cond_block(color_bg, lines, then, then_bg):
    rows = ''.join('<div style="margin-left:%dpx">%s</div>' % (0 if i == 0 else 18, cond_row(l, color_bg)) for i, l in enumerate(lines))
    return '<div style="background:#F2F2EE;border-radius:14px;padding:12px;display:flex;flex-direction:column;gap:8px">%s%s</div>' % (rows, cond_row(then, then_bg))


def ba(name, a, b, better):
    return ('<div style="display:flex;align-items:center;gap:6px;padding:3px 0;font-size:13px"><span class="t2" style="flex:1">%s</span><span class="t2 tn">%s</span>'
            '<span style="color:#5F5F5A;font-size:11px">→</span><span class="tn" style="font-weight:700;color:%s">%s</span></div>' % (name, a, '#3F7300' if better else '#2B2E33', b))


def pstep(title, detail, done):
    dot = '<span style="width:16px;height:16px;border-radius:50%%;flex:none;background:%s;border:2.5px solid %s;margin-top:2px"></span>' % ('#3A3D42' if done else '#fff', '#3A3D42' if done else '#C9CDD2')
    return '<div style="display:flex;gap:10px;align-items:flex-start">%s<div><div style="font-size:13px;font-weight:600">%s</div><div class="t2" style="font-size:12px">%s</div></div></div>' % (dot, title, detail)


def ajustes():
    strs = [('mom_us500', 'Momentum US500', '#7A5AF8', ICO['mom'], False), ('rev_m5', 'Reversión M5', '#00A3A3', ICO['rev'], True), ('tend_d1', 'Tendencia D1', '#D444F1', ICO['tend'], False)]
    items = ''.join('<div style="display:flex;align-items:center;gap:10px;padding:8px;border-radius:10px;background:%s">%s<div><div class="mono" style="font-weight:600;font-size:13px">%s</div><div class="t2" style="font-size:12px">%s</div></div></div>'
                    % ('#E3E5E8' if sel else 'transparent', tile(d, c, 26, 7), i, n) for i, n, c, d, sel in strs)
    left = ('<div class="card" style="width:250px;padding:10px;display:flex;flex-direction:column;gap:6px;flex:none">%s<div style="border-top:1px solid #EFEFEA;margin:4px 0"></div>'
            '<div style="display:flex;align-items:center;gap:10px;padding:8px">%s<div><div style="font-weight:600;font-size:13px">Reglas de riesgo</div><div class="t2" style="font-size:12px">22 comprobaciones · solo lectura</div></div></div></div>'
            % (items, tile(ICO['lock'], '#8A8A84', 26, 7)))

    def prow(key, frac, val, changed, before, unit=''):
        dot = '<span style="width:7px;height:7px;border-radius:50%;background:#E89B00"></span>' if changed else ''
        return ('<div style="display:flex;align-items:center;gap:12px;padding:4px 0"><span style="width:190px;display:flex;align-items:center;gap:6px"><span style="display:contents">%s</span><span class="mono" style="font-size:13px">%s</span></span>%s'
                '<span class="tn" style="width:78px;text-align:right;font-weight:600;font-size:13px">%s</span><span class="t2 tn" style="width:78px;text-align:right;font-size:12px">%s</span></div>' % (dot, key, slider(frac), val, before))
    def chip(n, on):
        bg, fg = ('#3A3D42', '#fff') if on else ('#EBEBE6', '#2B2E33')
        return '<span style="height:28px;padding:0 12px;display:flex;align-items:center;border-radius:14px;font-size:13px;font-weight:500;background:%s;color:%s">%s</span>' % (bg, fg, n)
    chips = ''.join(chip(n, on) for n, on in (('Asia', False), ('Londres', True), ('Nueva York', True)))
    general = group('General', grow('Estrategia activa', toggle(True)) +
                    grow('Modo', '<span style="background:#fff;border-radius:7px;padding:3px 10px;font-size:13px;box-shadow:0 0 0 1px rgba(0,0,0,.1)">Producción ⌄</span>') +
                    grow('Avisarme si se pausa sola', toggle(True)))
    pars = group('Parámetros', prow('ventana', .333, '20', False, '') + prow('umbral_z', .467, '2,20', True, 'antes 2,00') + prow('stop_atr', .333, '1,50', False, '') +
                 prow('riesgo_por_operación', .25, '0,20 %', True, 'antes 0,25') + grow('<span class="mono" style="font-size:13px">sesiones</span>', '<span style="display:flex;gap:6px">%s</span>' % chips))
    b1 = cond_block('rgba(74,78,85,.16)', [['Si', 'volatilidad M5', 'es menor que', 'percentil 80'], ['y', 'noticias de alto impacto', 'no hay en', '± 15 min'], ['y', 'sesión', 'es', 'Londres o Nueva York']], ['Entonces', 'activar rev_m5'], 'rgba(95,168,0,.18)')
    b2 = cond_block('rgba(143,93,0,.16)', [['Si', 'resultado de 5 días', 'es menor que', '−1,0 %']], ['Entonces', 'pausar y avisarme al móvil'], 'rgba(232,155,0,.18)')
    note = '<div style="display:flex;align-items:center;gap:8px;padding:12px;background:#F2F2EE;border-radius:12px;font-size:13px" class="t2"><svg viewBox="0 0 24 24" width="16" height="16" class="g" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="%s"/></svg>Regla de riesgo · no se edita aquí: si el reloj del bróker se desfasa más de 2 s, no abrir órdenes.</div>' % ICO['lock']
    form = ('<div class="card" style="flex:1;min-width:0;padding:20px;display:flex;flex-direction:column;gap:14px;overflow:auto">'
            '<div style="display:flex;align-items:center;gap:14px">%s<div style="flex:1"><div class="d" style="font-size:24px;font-weight:700;line-height:1.2">Reversión M5</div><div class="t2" style="font-size:13px">rev_m5 · versión 3 vigente · borrador de la 4</div></div>%s</div>'
            '%s%s<div style="display:flex;align-items:center;justify-content:space-between">%s<a class="btn" href="MacAjustes.dc.html" style="height:28px;font-size:12.5px;font-weight:600">+ Añadir regla</a></div>%s%s%s</div>'
            % (tile(ICO['rev'], '#00A3A3', 52, 14), pill('2 cambios sin guardar', 'so'), general, pars,
               ch('Condiciones', 'Reglas «si… entonces» para activar o pausar. Se leen como una frase'), b1, b2, note))
    right = ('<div style="width:290px;display:flex;flex-direction:column;gap:14px;flex:none">'
             '<div class="card" style="padding:14px;display:flex;flex-direction:column;gap:6px">%s%s%s%s</div>'
             '<div class="card" style="padding:14px;display:flex;flex-direction:column;gap:6px">%s<div style="display:flex;justify-content:space-between;font-size:13px"><span class="t2">Intento nº</span><b class="tn">15</b></div><div style="display:flex;justify-content:space-between;font-size:13px"><span class="t2">Sharpe deflactado</span><b class="tn" style="color:#8F5D00">0,62 → 0,58</b></div></div>'
             '<div class="card" style="padding:14px;display:flex;flex-direction:column;gap:9px">%s%s%s%s%s%s</div>'
             '<a class="btn p" href="MacFirmar.dc.html" style="height:38px;font-size:14px;font-weight:600">Solicitar aprobación</a></div>'
             % (ch('Antes y después', 'v3 frente al borrador v4 en el gemelo, 30 días'), ba('Retorno', '0,9 %', '1,1 %', True), ba('Caída máxima', '−1,4 %', '−1,1 %', True), ba('Operaciones', '142', '131', False),
                ch('Lo que cuesta probar', 'Cada cambio de parámetros cuenta como un intento'),
                ch('Camino del cambio', 'Un cambio no pasa a la siguiente etapa sin superar la anterior'), pstep('Borrador', 'Guardado hoy 10:20 · op-03', True), pstep('Gemelo', 'Repitiendo 30 días · 62 %', False),
                pstep('Aprobación', 'La firma ap-01', False), pstep('Demo · 5 días', 'En c-dem-01', False), pstep('Producción', 'Célula a célula', False)))
    return mac('ajustes', '<section style="display:flex;gap:14px;flex:1;min-height:0;align-items:flex-start;height:100%%">%s%s%s</section>' % (left, form, right)).replace('flex:1;min-width:0;padding:20px;display:flex;flex-direction:column;gap:14px;overflow:auto', 'flex:1;min-width:0;padding:20px;display:flex;flex-direction:column;gap:14px;overflow:auto;max-height:100%')


# ───────────────────────── Mac · Firmar y enviar ─────────────────────────
def firmar():
    ghost = ''.join('<div class="card" style="height:190px;padding:16px;display:flex;flex-direction:column;gap:12px"><div style="height:34px;width:60%;border-radius:10px;background:#EBEBE6"></div><div style="height:44px;border-radius:10px;background:#F2F2EE"></div><div style="height:14px;width:80%;border-radius:7px;background:#F2F2EE"></div></div>' for _ in range(5))
    back = '<section style="display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:14px">%s</section>' % ghost
    rows = ''.join('<div style="display:flex;justify-content:space-between;padding:5px 0;font-size:13px"><span class="t2">%s</span><span style="font-weight:600;%s">%s</span></div>' % (a, 'font-family:ui-monospace,Menlo,monospace' if m else '', b)
                   for a, b, m in (('Comando', 'halt_all', True), ('Alcance', '4 células activas', False), ('Quién firma', 'op-03 · rol operador', False), ('Algoritmo', 'Ed25519 sobre JSON canónico', False), ('Caduca en', '1:42', False)))
    sheet = ('<div style="position:absolute;inset:0;background:rgba(43,46,51,.38);z-index:6"></div>'
             '<div role="dialog" aria-label="Firmar y enviar" style="position:absolute;z-index:7;left:50%;top:50%;transform:translate(-50%,-50%);width:460px;background:#fff;border-radius:16px;padding:24px;box-shadow:0 30px 80px rgba(0,0,0,.35);display:flex;flex-direction:column;gap:16px">'
             '<div style="display:flex;align-items:center;justify-content:space-between"><span class="t2" style="font-size:12px;font-weight:600">Firmar y enviar</span>' + pill('Acción crítica', 'sr') + '</div>'
             '<div class="d" style="font-size:26px;font-weight:700;line-height:1.2">Parar todo</div>'
             '<div class="t2" style="font-size:14px">Detiene las órdenes nuevas en todas las células. Las posiciones abiertas conservan su stop.</div>'
             '<div style="background:#F2F2EE;border-radius:14px;padding:12px">' + rows + '</div>'
             '<div style="height:6px;border-radius:3px;background:#EBEBE6"><div style="height:6px;border-radius:3px;width:85%;background:#4A4E55"></div></div>'
             '<div style="display:flex;align-items:center;justify-content:space-between"><a class="btn" href="MacFlota.dc.html" style="height:38px;padding:0 18px;font-size:14px;font-weight:600">Cancelar</a>'
             '<a class="btn x" href="MacFlota.dc.html" style="height:38px;padding:0 18px;font-size:14px;font-weight:600">Firmar y enviar</a></div></div>')
    return mac('flota', ch('Flota', 'Una célula por cuenta', 20) + back, sheet)


# ───────────────────────── iPhone ─────────────────────────
def iphone_ordenes():
    fun = ''.join('<div style="flex:1;background:#fff;border-radius:14px;padding:10px"><div class="tn" style="font-size:18px;font-weight:700;line-height:1.2">%s</div><div class="t2" style="font-size:11px;font-weight:600">%s</div></div>' % f
                  for f in (('142', 'señales'), ('131', 'riesgo ✓'), ('128', 'enviadas'), ('121', 'ejecutadas')))
    S = {'mom_us500': ('#7A5AF8', ICO['mom']), 'rev_m5': ('#00A3A3', ICO['rev']), 'tend_d1': ('#D444F1', ICO['tend'])}
    orders = [('EURUSD', 'Compra', '0,10', 'rev_m5', '#A7F3-21', 'c-lon-01', 'En curso', 'sb', '10:30:00'), ('US500', 'Venta', '0,20', 'mom_us500', '#A7F3-20', 'c-lon-01', 'Enviada', 'sb', '10:41:58'),
              ('GBPUSD', 'Compra', '0,10', 'tend_d1', '#B210-07', 'c-lon-02', 'Ejecutada', 'sg', '10:30:00'), ('EURUSD', 'Compra', '0,05', 'rev_m5', '#B210-06', 'c-lon-02', 'Rechazada', 'sr', '10:41:07'),
              ('EURUSD', 'Venta', '0,05', 'rev_m5', '#C051-12', 'c-dem-01', 'Riesgo ✓', 'sb', '10:42:11'), ('EURUSD', 'Compra', '0,02', 'rev_m5', '#D400-03', 'c-lon-03', 'Sin stop', 'so', '09:58:20'),
              ('US500', 'Compra', '0,20', 'mom_us500', '#A7F3-19', 'c-lon-01', 'Cerrada', 'sn', '09:15:44'), ('GBPUSD', 'Venta', '0,10', 'tend_d1', '#B210-05', 'c-lon-02', 'Cerrada', 'sn', '08:02:10'),
              ('EURUSD', 'Compra', '0,05', 'rev_m5', '#C051-11', 'c-dem-01', 'Cerrada', 'sn', '07:40:03')]
    rows = ''.join('<div style="display:flex;align-items:center;gap:11px;padding:8px 0;%s">%s<div style="flex:1;min-width:0"><div style="font-size:15px;font-weight:600;line-height:1.25">%s %s %s</div><div class="mono t2" style="font-size:12px">%s · %s</div></div>'
                   '<div style="display:flex;flex-direction:column;align-items:flex-end;gap:3px">%s<span class="t2 tn" style="font-size:12px">%s</span></div></div>'
                   % ('border-top:1px solid #EFEFEA;' if i else '', tile(S[o[3]][1], S[o[3]][0], 32, 10), o[0], o[1], o[2], o[4], o[5], pill(o[6], o[7]), o[8]) for i, o in enumerate(orders))
    return phone(phone_title('Órdenes') + '<div style="display:flex;gap:8px">%s</div><div class="pc" style="padding:2px 16px">%s</div>' % (fun, rows), 1)


def iphone_avisos():
    al = [('#F2465E', '!', 'Posición sin stop', 'c-lon-03 · REAL-01 · manual paso 2 de 4', '09:58', True), ('#E89B00', '!', 'Pérdida del día al 47 %', 'FND-B-50k · límite 4 %', '10:31', True),
          ('#E89B00', '!', 'Reloj del bróker 1,4 s', 'c-lon-01 · DQ-09', '10:12', True), ('#2E90FA', '✓', 'Jev bajó rev_m5 a 0,5', 'c-lon-02 · comando firmado', '08:00', False),
          ('#2E90FA', '✓', 'Simulacro de aviso', 'llegó al móvil en 41 s', 'ayer', False)]
    rows = ''
    for i, (c, ic, t, s, tm, btn) in enumerate(al):
        glyph = ('<svg viewBox="0 0 24 24" width="13" height="13" class="g" stroke="#fff" stroke-width="3"><path d="%s"/></svg>' % (ICO['bang'] if ic == '!' else ICO['check']))
        b = '<a class="btn" href="IPhoneAvisos.dc.html" style="height:28px;padding:0 12px;font-size:13px;font-weight:600;flex:none">Reconocer</a>' if btn else ''
        rows += ('<div style="display:flex;align-items:center;gap:10px;padding:6px 0;%s"><span style="width:26px;height:26px;border-radius:50%%;background:%s;display:flex;align-items:center;justify-content:center;flex:none">%s</span>'
                 '<div style="flex:1;min-width:0"><div style="font-size:13px;font-weight:600">%s</div><div class="t2" style="font-size:12px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">%s</div></div>%s<span class="t2 tn" style="font-size:12px;width:34px;text-align:right">%s</span></div>'
                 % ('border-top:1px solid #EFEFEA;' if i else '', c, glyph, t, s, b, tm))
    cmds = ''.join('<div style="display:flex;justify-content:space-between;align-items:center;padding:3px 0"><span class="mono" style="font-weight:600;font-size:13px">%s</span>%s</div>' % (n, pill(t, k))
                   for n, t, k in (('weights', 'Aceptado', 'sg'), ('resume_confirm', 'Aceptado', 'sg'), ('resume_request', 'Aceptado', 'sg'), ('resume_request', 'Rechazado', 'sr')))
    layers = ''.join('<div style="display:flex;align-items:center;gap:10px;padding:2px 0"><span style="width:62px;font-size:13px;font-weight:700">%s</span><span style="flex:1;height:10px;border-radius:5px;background:#EBEBE6"><span style="display:block;height:10px;border-radius:5px;width:%d%%;background:%s"></span></span><span class="tn" style="width:38px;text-align:right;font-weight:700;font-size:14px">%d %%</span></div>' % (n, u, '#3A3D42' if u < 50 else '#E89B00', u)
                     for n, u in (('Orden', 30), ('Estrategia', 40), ('Célula', 47), ('Cuenta', 15), ('Global', 16)))
    body = (phone_title('Avisos') + '<div class="pc" style="padding:4px 16px">%s</div>' % rows +
            '<div class="pc" style="display:flex;flex-direction:column;gap:6px">%s%s</div>' % (ch('Comandos', 'Lo que se ha firmado desde tus dispositivos'), cmds) +
            '<div class="pc" style="display:flex;flex-direction:column;gap:6px">%s%s</div>' % (ch('Capas', 'Uso de cada capa de límites'), layers))
    return phone(body, 2)


def iphone_jev():
    P = [('Subir tend_d1 a 1,0 · lon-01', 'Tendencia limpia, poca correlación', 'Pendiente', 'so', '10:05', True), ('Bajar rev_m5 a 0,5 · lon-02', 'Pérdida del día al 47 %', 'Aplicada', 'sg', '08:00', False),
         ('Activar mom_us500 · lon-03', 'Volatilidad favorable', 'Rechazada · riesgo', 'sr', 'Ayer', False), ('Bajar tend_d1 a 0,5 · lon-02', 'Cerca de la regla diaria', 'Aplicada · +0,2 %', 'sg', '24 nov', False),
         ('Subir rev_m5 a 1,0 · dem-01', 'Buena racha en demo', 'Rechazada · tiempo', 'sr', '21 nov', False), ('mom_us500 a sombra · dem-01', 'Tres semanas flojas', 'Aplicada · −0,2 %', 'sg', '17 nov', False)]
    rows = ''.join('<div style="display:flex;align-items:flex-start;gap:10px;padding:10px 0;%s"><span style="width:8px;height:8px;border-radius:50%%;margin-top:7px;flex:none;background:%s"></span>'
                   '<div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:2px"><div style="font-size:15px;font-weight:600;line-height:1.3">%s</div><div class="t2" style="font-size:13px">%s</div><div style="margin-top:2px">%s</div></div><span class="t2" style="font-size:12px">%s</span></div>'
                   % ('border-top:1px solid #EFEFEA;' if i else '', '#D444F1' if p[5] else 'transparent', p[0], p[1], pill(p[2], p[3]), p[4]) for i, p in enumerate(P))
    return phone(phone_title('Jev', 'Fase 2 · aprobar se hace en el Mac') + '<div class="pc" style="padding:2px 16px">%s</div>' % rows, 3)


ARTBOARDS = [
    ('MacFlota.dc.html', 'Flota · Mac', 1440, 900, flota),
    ('MacEstrategias.dc.html', 'Estrategias · Mac', 1440, 900, estrategias),
    ('MacAjustes.dc.html', 'Ajustes · Mac', 1440, 900, ajustes),
    ('MacFirmar.dc.html', 'Firmar y enviar · Mac', 1440, 900, firmar),
    ('IPhoneOrdenes.dc.html', 'iPhone · Órdenes', 470, 920, iphone_ordenes),
    ('IPhoneAvisos.dc.html', 'iPhone · Avisos', 470, 920, iphone_avisos),
    ('IPhoneJev.dc.html', 'iPhone · Jev', 470, 920, iphone_jev),
]

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for name, title, w, h, fn in ARTBOARDS:
        write(name, title, w, h, fn())
        print('ok', name)
