#!/usr/bin/env python3
# Propuesta B · tercera vuelta: cada dato vive en un solo sitio y el dock del iPhone se rehace.
#
#   Inicio     un número por área y enlaces. Sin listas ni gráficas completas.
#   En vivo    lo que pasa AHORA: flotante, trades abiertos, actividad, riesgo y margen.
#   Cuentas    el estado de cada cuenta: saldo, margen, objetivo y conciliación.
#   Resultados todo el rendimiento: periodos, curva, calendario, caída, por cuenta, mejores y peores.
#   Robots     la salud técnica de cada robot.
#   Métodos    cómo rinde y dónde trabaja cada método.
#   Avisos     lo que hay que resolver y cuánto margen queda de cada límite.
#   Análisis   patrones: cuándo se opera, correlación, deslizamiento y pérdida de ventaja.
import os, sys, math, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen2, gen5
from gen2 import (IC, mac2, card, big, pill, ch, spark, gauge, mix, thermo, histogram, besthours, fan, phone2, ptitle, pc, EST, ROBOTS, MET, doc)
from gen5 import page, write, POS, NEG, WARN, INFO, INK, INK2, GR, a_cuentas, a_envivo, a_resultados, LIVE_JS, RES_JS, a_sistema, m_envivo, m_resultados, widgets

# ───── dock del iPhone: cápsula de cristal, solo iconos; la sección activa se expande con su nombre ─────
DOCK = r'''
.scr .tabs{position:absolute;left:50%;transform:translateX(-50%);bottom:22px;width:auto;max-width:calc(100% - 24px);height:64px;padding:8px;gap:4px;border-radius:32px;
  background:rgba(255,255,255,.74);-webkit-backdrop-filter:blur(30px) saturate(1.8);backdrop-filter:blur(30px) saturate(1.8);
  border:1px solid rgba(255,255,255,.75);box-shadow:0 12px 32px rgba(16,17,19,.16),0 1px 0 rgba(255,255,255,.9) inset;display:flex;align-items:center;justify-content:center;z-index:6;animation:dockin .6s var(--ease) .15s both}
.scr .tab{flex:none;position:relative;height:48px;min-width:48px;padding:0 12px;border-radius:24px;flex-direction:row;align-items:center;justify-content:center;gap:0;font-size:13px;font-weight:600;color:#6B7078;
  transition:background .35s var(--ease),color .35s var(--ease),padding .35s var(--ease),gap .35s var(--ease)}
.scr .tab svg{width:24px;height:24px;flex:none}
.scr .tab .lbl{max-width:0;overflow:hidden;white-space:nowrap;opacity:0;transition:max-width .35s var(--ease),opacity .25s var(--ease)}
.scr .tab.on{background:#2B2E33;color:#fff;padding:0 16px;gap:8px;box-shadow:0 6px 14px rgba(43,46,51,.28)}
.scr .tab.on .lbl{max-width:80px;opacity:1}
.scr .tab.on::before{display:none}
.scr .tb{top:6px;right:6px;left:auto;width:10px;min-width:10px;height:10px;padding:0;border-radius:50%;font-size:0;border:2px solid #fff;box-sizing:content-box}
.scr .tab.on .tb{border-color:#2B2E33}
.agenda{display:flex;align-items:center;gap:14px;padding:12px 0;border-top:1px solid #EFEFEA}
.agenda:first-of-type{border-top:0}
.tile{text-decoration:none;color:inherit;cursor:pointer}
.tile .go{font-size:13px;font-weight:600;color:#6B7078;margin-top:auto;transition:color .2s var(--ease),transform .2s var(--ease)}
.tile:hover .go{color:#2B2E33;transform:translateX(4px)}
'''
DOCK += r"""
.achips{display:flex;gap:6px}
.achips button{height:32px;padding:0 14px;border:0;border-radius:999px;background:#fff;box-shadow:0 0 0 1px #E3E5E8;font:600 13px -apple-system,BlinkMacSystemFont,'Inter',sans-serif;color:#4A4E55;cursor:pointer;transition:all .2s var(--ease)}
.achips button.on{background:#2B2E33;color:#fff;box-shadow:none}
.kgrid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:24px}
.kpi{background:#fff;border-radius:18px;border:1px solid rgba(16,17,19,.05);box-shadow:0 1px 1px rgba(16,17,19,.03),0 4px 14px rgba(16,17,19,.04);padding:18px 20px;display:flex;flex-direction:column;gap:6px;animation:rise .55s var(--ease) both}
.kpi .l{font-size:12px;font-weight:600;color:#6B7078}
.sbtn{height:32px;padding:0 14px;border:0;border-radius:999px;background:#fff;box-shadow:0 0 0 1px #E3E5E8;font:600 13px -apple-system,BlinkMacSystemFont,'Inter',sans-serif;color:#2B2E33;cursor:pointer}
@media (max-width:1240px){.kgrid{grid-template-columns:repeat(2,minmax(0,1fr))}}
@media (max-width:900px){.kgrid{grid-template-columns:minmax(0,1fr)}}
"""
gen2.CSS_B += DOCK

# la etiqueta de cada pestaña va en su propio span para poder expandirla
_src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'gen2.py')).read()


def tabs2(on):
    items = [('inicio', 'Inicio', 'AMInicio.dc.html'), ('envivo', 'En vivo', 'AMEnVivo.dc.html'), ('cuentas', 'Cuentas', 'AMCuenta.dc.html'), ('avisos', 'Avisos', 'AMAvisos.dc.html'), ('resultados', 'Resultados', 'AMResultados.dc.html')]
    o = '<nav class="tabs" aria-label="Secciones">'
    for i, (k, n, href) in enumerate(items):
        b = '<span class="tb" style="background:#2E90FA"></span>' if k == 'avisos' else ''
        o += ('<a class="%s" href="%s" aria-label="%s"><svg viewBox="0 0 24 24" class="g" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="%s"/></svg><span class="lbl">%s</span>%s</a>'
              % ('tab on' if i == on else 'tab', href, n, IC[k], n, b))
    return o + '</nav>'


gen2.tabs2 = tabs2

# dock de Mac: «Informe» pasa a llamarse «Análisis»
_old_rail = gen2.rail2


def rail2(active):
    return _old_rail('informe' if active == 'analisis' else active).replace('aria-label="Informe"', 'aria-label="Análisis"').replace('data-t="Informe"', 'data-t="Análisis"')


gen2.rail2 = rail2

ROB_LINE = '<div style="display:flex;gap:18px;flex-wrap:wrap;font-size:14px;font-weight:600">%s</div>' % ''.join('<span><span style="color:%s">●</span> %s · %d</span>' % (c, n, v) for n, v, c in (('Bien', 2, '#5FA800'), ('Atento', 1, '#E89B00'), ('Revisar', 1, '#F2465E'), ('Parado', 1, '#B5B5AE')))


def tile(href, label, value, sub, extra='', color=INK, go='Ver'):
    return ('<a class="card tile" href="%s" style="padding:20px;gap:10px;text-decoration:none"><span class="t2" style="font-size:13px;font-weight:600">%s</span>' % (href, label) +
            big(value, 32, color) + '<span class="t2" style="font-size:13px">%s</span>' % sub + extra + '<span class="go">%s →</span></a>' % go)


# ───── Inicio: un número por área, y cada número lleva a su sitio ─────
def a_inicio():
    banner = ('<a href="AAvisos.dc.html" style="display:flex;align-items:center;gap:14px;background:#FDF1D6;border-radius:18px;padding:14px 20px;text-decoration:none"><span style="width:30px;height:30px;border-radius:50%;background:#E89B00;display:flex;align-items:center;justify-content:center">'
              '<svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="#fff" stroke-width="3" stroke-linecap="round"><path d="' + IC['bang'] + '"/></svg></span>'
              '<span style="flex:1;font-weight:600;font-size:15px;color:#8F5D00">Todo bajo control. Un robot pide revisión.</span><span style="font-weight:600;color:#8F5D00">Ver →</span></a>')
    tiles = '<section style="display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:24px">%s%s%s%s</section>' % (
        tile('ACuentas.dc.html', 'Dinero total', '213.214 €', '5 cuentas', spark([206, 207, 206.5, 208, 207.6, 209, 208.4, 210, 209.3, 211, 210.4, 212, 212.6, 213.2], 200, 36, POS, True), go='Cuentas'),
        tile('AResultados.dc.html', 'Resultado de hoy', '−0,31 %', '−661 € · 16 % del margen del día', thermo(.16, '', mark=.75), '#C21A36', 'Resultados'),
        tile('AEnVivo.dc.html', 'Ahora', '+212 €', 'flotante · 5 trades abiertos', spark([20, 50, 30, 90, 60, 140, 120, 190, 212], 200, 36, '#3A3D42', False, 2.4), '#3F7300', 'En vivo'),
        tile('AAvisos.dc.html', 'Avisos', '3', '', '<div style="display:flex;gap:6px">' + pill('1 urgente', 'sr') + pill('2 atención', 'so') + '</div>', '#C21A36', 'Avisos'))
    agenda = card(ch('Lo próximo', 'Lo que viene hoy, para que no te pille de sorpresa') + ''.join(
        '<div class="agenda"><span style="width:44px;font-weight:700;font-size:15px" class="tn">%s</span><span style="flex:1;font-size:14px;font-weight:600">%s</span><span class="t2" style="font-size:13px">%s</span></div>' % x for x in (
            ('14:30', 'Noticia: IPC de EE. UU.', 'en 3 h 48 min'), ('16:30', 'Cierra la sesión de Londres', 'en 5 h 48 min'), ('—', '1 propuesta del asesor pendiente', 'esperando tu respuesta'), ('Vie', 'Informe semanal', 'se genera a las 20:00'))), 'flex:2')
    robots = '<a class="card tile" href="ARobots.dc.html" style="padding:20px;gap:14px;flex:1;text-decoration:none">' + ch('Robots', 'Cuántos hay en cada estado') + big('5', 32) + ROB_LINE + '<span class="go">Robots →</span></a>'
    row2 = '<section style="display:flex;gap:24px">%s%s</section>' % (agenda, robots)
    return mac2('inicio', 'Buenos días', '', banner + tiles + row2, '<span class="seg"><span class="on">Hoy</span><span>Semana</span><span>Mes</span></span>')


def m_inicio():
    t2 = lambda href, l, v, s, c=INK: '<a class="pc" href="%s" style="display:flex;flex-direction:column;gap:4px;text-decoration:none;color:inherit;padding:14px 16px"><span class="t2" style="font-size:12px;font-weight:600">%s</span>%s<span class="t2" style="font-size:12px">%s</span></a>' % (href, l, big(v, 24, c), s)
    body = (ptitle('Buenos días') +
            '<a href="AMAvisos.dc.html" style="display:flex;align-items:center;gap:10px;background:#FDF1D6;border-radius:14px;padding:11px 14px;font-weight:600;font-size:14px;color:#8F5D00;text-decoration:none"><svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="#E89B00" stroke-width="3" stroke-linecap="round"><path d="%s"/></svg><span style="flex:1">Un robot pide revisión</span>→</a>' % IC['bang'] +
            '<div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">%s%s%s%s</div>' % (
                t2('AMCuenta.dc.html', 'Dinero total', '213.214 €', '5 cuentas'), t2('AMResultados.dc.html', 'Hoy', '−0,31 %', '16 % del margen', '#C21A36'),
                t2('AMEnVivo.dc.html', 'Ahora', '+212 €', 'flotante · 5 abiertos', '#3F7300'), t2('AMAvisos.dc.html', 'Avisos', '3', '1 urgente', '#C21A36')) +
            pc(ch('Lo próximo', 'Lo que viene hoy') + ''.join('<div style="display:flex;align-items:center;gap:12px;font-size:14px"><b class="tn" style="width:42px">%s</b><span style="flex:1;font-weight:600">%s</span><span class="t2" style="font-size:12px">%s</span></div>' % x for x in (('14:30', 'Noticia: IPC', 'en 3 h 48'), ('16:30', 'Cierra Londres', 'en 5 h 48'), ('—', 'Propuesta del asesor', 'pendiente')))) +
            pc(ch('Robots', 'Cuántos hay en cada estado') + ROB_LINE))
    return phone2(body, 0)


# ───── Análisis: patrones. Los totales están en Resultados ─────
def heat_hours(w=560):
    days, hours = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie'], list(range(0, 24, 2))
    L, cw, chh = 44, (w - 44) / 12, 30
    h = 24 + 5 * (chh + 4)
    o = '<svg viewBox="0 0 %d %d" role="img" aria-label="Número de trades por hora y día" style="width:100%%;height:auto;display:block">' % (w, h)
    for j, hr in enumerate(hours):
        o += '<text x="%.1f" y="14" text-anchor="middle" font-size="11" fill="#6B7078">%d</text>' % (L + j * cw + cw / 2, hr)
    for i, d in enumerate(days):
        y = 24 + i * (chh + 4)
        o += '<text x="0" y="%.1f" font-size="12" font-weight="600" fill="#2B2E33">%s</text>' % (y + chh / 2 + 4, d)
        for j, hr in enumerate(hours):
            v = max(0, (math.sin((hr - 5) / 3.2) + 1) * (1 + .3 * math.sin(i + hr)) * (1 if 3 <= hr <= 10 else .35)) / 2.4
            o += '<rect class="pop" style="animation-delay:%.2fs" x="%.1f" y="%d" width="%.1f" height="%d" rx="6" fill="%s"/>' % ((i * 12 + j) * .008, L + j * cw + 1.5, y, cw - 3, chh, mix('#F2F2EE', '#2E90FA', v))
    return o + '</svg>'


def corr(w=520):
    names = ['Rebote', 'Impulso', 'Tendencia', 'Ruptura', 'EURUSD', 'GBPUSD']
    m = [[1, .12, -.08, .31, .62, .40], [.12, 1, .22, .05, .10, .08], [-.08, .22, 1, .18, .02, .35], [.31, .05, .18, 1, .25, .30], [.62, .10, .02, .25, 1, .71], [.40, .08, .35, .30, .71, 1]]
    L, cw, chh = 80, (w - 80) / 6, 32
    h = 26 + 6 * (chh + 3)
    o = '<svg viewBox="0 0 %d %d" role="img" aria-label="Matriz de correlación" style="width:100%%;height:auto;display:block">' % (w, h)
    for j, n in enumerate(names):
        o += '<text x="%.1f" y="16" text-anchor="middle" font-size="11" fill="#6B7078">%s</text>' % (L + j * cw + cw / 2, n[:6])
    for i, n in enumerate(names):
        y = 26 + i * (chh + 3)
        o += '<text x="0" y="%.1f" font-size="12" font-weight="600" fill="#2B2E33">%s</text>' % (y + chh / 2 + 4, n)
        for j in range(6):
            v = m[i][j]
            o += '<rect class="pop" style="animation-delay:%.2fs" x="%.1f" y="%d" width="%.1f" height="%d" rx="6" fill="%s"/><text x="%.1f" y="%.1f" text-anchor="middle" font-size="11" font-weight="600" fill="%s">%s</text>' % (
                (i * 6 + j) * .01, L + j * cw + 1.5, y, cw - 3, chh, mix('#F2F2EE', '#7A5AF8', v) if v >= 0 else mix('#F2F2EE', '#E89B00', -v), L + j * cw + cw / 2, y + chh / 2 + 4, '#fff' if abs(v) > .55 else '#2B2E33', ('%.2f' % v).replace('.', ','))
    return o + '</svg>'


def slippage(w=520, h=250):
    L, R, T, B = 44, 12, 12, 30
    X = lambda v: L + v / 2 * (w - L - R)
    Y = lambda v: T + (2.4 - v) / 2.4 * (h - T - B)
    o = '<svg viewBox="0 0 %d %d" role="img" aria-label="Precio esperado frente al ejecutado" style="width:100%%;height:auto;display:block">' % (w, h)
    for k in range(5):
        o += '<line x1="%d" y1="%.1f" x2="%d" y2="%.1f" stroke="#F1F1EC"/><text x="%d" y="%.1f" text-anchor="end" font-size="11" fill="#8A8A84">%.1f</text>' % (L, Y(k * .6), w - R, Y(k * .6), L - 6, Y(k * .6) + 4, k * .6)
    o += '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#8A8A84" stroke-dasharray="5 4"/>' % (X(0), Y(0), X(2), Y(2))
    for i in range(36):
        e = .2 + (i * 37 % 100) / 100 * 1.6
        d = ((i * 53 % 100) - 45) / 160
        o += '<circle class="pop" style="animation-delay:%.2fs" cx="%.1f" cy="%.1f" r="4" fill="%s" fill-opacity=".5" stroke="%s" stroke-width="1.5"/>' % (i * .015, X(e), Y(max(0, e + d)), NEG if d > .25 else INFO, NEG if d > .25 else INFO)
    return o + '<text x="%d" y="%d" text-anchor="middle" font-size="11" fill="#6B7078">esperado (pips)</text></svg>' % (w / 2, h - 6)


def decay(w=520, h=220):
    wr = [52, 54, 55, 57, 58, 57, 59, 60, 58, 57, 56, 55, 55, 54, 53, 54, 52, 51, 52, 51]
    L, R, T, B = 40, 12, 12, 24
    X = lambda i: L + i * (w - L - R) / 19
    Y = lambda v: T + (62 - v) / 12 * (h - T - B)
    o = '<svg viewBox="0 0 %d %d" role="img" aria-label="Acierto de los últimos 20 trades, en movimiento" style="width:100%%;height:auto;display:block">' % (w, h)
    for v in (50, 54, 58, 62):
        o += '<line x1="%d" y1="%.1f" x2="%d" y2="%.1f" stroke="#F1F1EC"/><text x="%d" y="%.1f" text-anchor="end" font-size="11" fill="#8A8A84">%d %%</text>' % (L, Y(v), w - R, Y(v), L - 6, Y(v) + 4, v)
    o += '<polyline class="draw" pathLength="1" points="%s" fill="none" stroke="%s" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>' % (' '.join('%.1f,%.1f' % (X(i), Y(v)) for i, v in enumerate(wr)), INFO)
    return o + '<text x="%d" y="%d" font-size="11" fill="#8A8A84">hace 20 trades</text><text x="%d" y="%d" text-anchor="end" font-size="11" fill="#8A8A84">último</text></svg>' % (L, h - 6, w - R, h - 6)


def a_analisis():
    intro = '<div class="t2" style="font-size:15px;max-width:760px">Aquí solo hay patrones: cuándo, con qué y a qué coste se opera. Los totales y el rendimiento están en Resultados; lo que pasa ahora, en En vivo.</div>'
    grid = '<section style="display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px">%s%s%s%s%s%s</section>' % (
        card(ch('Cuándo se opera', 'Número de trades por hora (UTC) y día') + heat_hours()),
        card(ch('Qué se mueve junto', 'Más intenso: se mueven a la vez, y el riesgo se acumula') + corr()),
        card(ch('Cómo acaban las operaciones', 'Cuántas acaban en cada rango de euros') + histogram(520, 230)),
        card(ch('Mejores horas', 'Cuándo suelen salir mejor') + besthours(520, 210)),
        card(ch('Precio esperado y ejecutado', 'Por encima de la raya: peor de lo esperado') + slippage()),
        card(ch('Pérdida de ventaja', 'Acierto de los últimos 20 trades, en movimiento') + decay()))
    return mac2('analisis', 'Análisis', '', intro + grid)


def m_analisis():
    body = (ptitle('Análisis') + '<div class="t2" style="font-size:13px;padding:0 4px">Patrones. Los totales están en Resultados.</div>' + pc(ch('Mejores horas', 'Cuándo suelen salir mejor') + besthours(360, 180)) + pc(ch('Cómo acaban las operaciones', 'Rango de euros') + histogram(360, 210)))
    return phone2(body, 4)


# ───── Cuenta: solo el estado de la cuenta ─────
PANEL_JS = r'''
class Component extends DCLogic {
  constructor(props) { super(props); this.state = { acc: 'ambas' }; }
  renderVals() {
    const D = {
      ambas: { balance: '153.442,40 €', equity: '153.654,80 €', k: [['Balance', '153.442,40 €'], ['Equity', '153.654,80 €'], ['Margen usado', '2.880 €'], ['Margen libre', '10.120 €'], ['Nivel de margen', '2.750 %'], ['Depósito inicial', '150.000 €'], ['Resultado total', '+3.442,40 €'], ['Caída histórica', '−2,31 %']] },
      a: { balance: '101.842,30 €', equity: '102.044,70 €', k: [['Balance', '101.842,30 €'], ['Equity', '102.044,70 €'], ['Margen usado', '1.980 €'], ['Margen libre', '7.020 €'], ['Nivel de margen', '2.400 %'], ['Depósito inicial', '100.000 €'], ['Resultado total', '+1.842,30 €'], ['Caída histórica', '−1,92 %']] },
      b: { balance: '51.600,10 €', equity: '51.610,10 €', k: [['Balance', '51.600,10 €'], ['Equity', '51.610,10 €'], ['Margen usado', '900 €'], ['Margen libre', '3.100 €'], ['Nivel de margen', '3.100 %'], ['Depósito inicial', '50.000 €'], ['Resultado total', '+1.600,10 €'], ['Caída histórica', '−2,31 %']] }
    };
    const d = D[this.state.acc];
    return {
      accs: [['ambas', 'Ambas cuentas'], ['a', '···4152'], ['b', '···2511']].map((c) => ({ n: c[1], cls: this.state.acc === c[0] ? 'on' : '', pick: () => this.setState({ acc: c[0] }) })),
      balance: d.balance, equity: d.equity,
      kpis: d.k.map((k, i) => ({ l: k[0], v: k[1], c: i === 6 ? '#3F7300' : (i === 7 ? '#C21A36' : '#2B2E33') }))
    };
  }
}
'''


def a_panel():
    head = card('<div style="display:flex;align-items:center;gap:14px;flex-wrap:wrap"><div class="achips" role="group" aria-label="Cuenta"><sc-for list="{{accs}}" as="c" hint-placeholder-count="3"><button type="button" class="{{c.cls}}" onClick="{{c.pick}}">{{c.n}}</button></sc-for></div><span style="flex:1"></span>'
                '<span class="t2" style="font-size:12px">Datos de <b style="color:#2B2E33">cuentas_metricas.json</b> · cada 5 min</span></div>'
                '<div style="display:flex;align-items:flex-end;gap:40px;flex-wrap:wrap"><div><div class="t2" style="font-size:13px;font-weight:600">Balance</div><span class="d tn tick" style="font-size:40px;font-weight:700">{{balance}}</span></div>'
                '<div><div class="t2" style="font-size:13px;font-weight:600">Equity</div><span class="d tn" style="font-size:26px;font-weight:700;color:#6B7078">{{equity}}</span></div></div>')
    kg = '<div class="kgrid"><sc-for list="{{kpis}}" as="k" hint-placeholder-count="8"><div class="kpi"><span class="l">{{k.l}}</span><span class="v" style="color:{{k.c}};font-size:22px">{{k.v}}</span></div></sc-for></div>'
    rules = [('#2E90FA', 'Objetivo', '3,2 de 5 %', 64, 1.0), ('#E89B00', 'Pérdida diaria', '1,9 de 4 %', 48, .75), ('#7A5AF8', 'Caída total', '1,2 de 8 %', 15, .75), ('#5FA800', 'Días mínimos', '12 de 5', 100, 1.0), ('#E89B00', 'Constancia', '31 de 40 %', 78, .75), ('#8A8A84', 'Tiempo de fase', '18 de 60 días', 30, 1.0)]
    rl = ''.join('<div style="display:flex;flex-direction:column;gap:6px"><div style="display:flex;justify-content:space-between;font-size:14px"><span style="font-weight:600">%s</span><b class="tn">%s</b></div>%s</div>' % (n, t, thermo(w / 100, '', color=c, mark=m)) for c, n, t, w, m in rules)
    mid = '<section style="display:grid;grid-template-columns:1.4fr 1fr;gap:24px">%s%s</section>' % (
        card('<div style="display:flex;justify-content:space-between;align-items:flex-start">' + ch('Fondeo B · ¿Llego al objetivo?', 'Mil simulaciones al ritmo de los últimos 60 días') + '<div style="text-align:right">' + big('78 %', 32) + '<div class="t2" style="font-size:12px">de llegar</div></div></div>' + fan()),
        card(ch('Reglas de la firma', 'Cuánto llevas usado de cada regla. La raya marca el aviso') + rl))
    low = '<section style="display:grid;grid-template-columns:1fr 1fr;gap:24px">%s%s</section>' % (
        card(ch('Conciliación', 'Saldo según el bróker frente al del sistema') + ''.join('<div style="display:flex;justify-content:space-between;align-items:center;padding:10px 0;border-top:1px solid #EFEFEA;font-size:14px"><span style="font-family:ui-monospace,Menlo,monospace">%s</span>%s</div>' % x for x in (('···4152', pill('Cuadra', 'sg')), ('···2511', pill('Diferencia 1,20 €', 'so'))))),
        card(ch('Ficheros de datos', 'De dónde sale lo que ves') + ''.join('<div style="display:flex;justify-content:space-between;align-items:center;padding:8px 0;border-top:1px solid #EFEFEA"><span style="font-family:ui-monospace,Menlo,monospace;font-size:12px">%s</span>%s</div>' % (n, pill('Al día', 'sg')) for n in ('cuentas_metricas.json', 'modulos_metricas.json', 'metricas_diarias.json', 'curva_equity.json', 'seq_labels.json'))))
    note = '<div class="t2" style="font-size:13px">Trades abiertos y riesgo: en En vivo. Resultados y caídas por periodo: en Resultados.</div>'
    return mac2('cuentas', 'Cuenta', '', head + kg + mid + low + note)


def m_cuenta():
    body = (ptitle('Cuenta') + '<div style="display:flex;gap:6px"><button class="sbtn" type="button" style="background:#2B2E33;color:#fff;box-shadow:none">Ambas</button><button class="sbtn" type="button">···4152</button><button class="sbtn" type="button">···2511</button></div>' +
            pc('<div class="t2" style="font-size:12px;font-weight:600">Balance</div>' + big('153.442,40 €', 30) + '<div class="t2" style="font-size:13px">Equity 153.654,80 €</div>') +
            '<div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">%s</div>' % ''.join('<div class="pc" style="padding:12px 14px;gap:2px;display:flex;flex-direction:column"><span class="t2" style="font-size:12px;font-weight:600">%s</span><b class="tn" style="font-size:17px;color:%s">%s</b></div>' % x for x in (('Margen libre', INK, '10.120 €'), ('Nivel de margen', INK, '2.750 %'), ('Resultado total', '#3F7300', '+3.442 €'), ('Caída histórica', '#C21A36', '−2,31 %'))) +
            pc(ch('Reglas de la firma', 'La raya marca el aviso') + ''.join('<div style="display:flex;flex-direction:column;gap:5px"><div style="display:flex;justify-content:space-between;font-size:13px"><span style="font-weight:600">%s</span><b class="tn">%s</b></div>%s</div>' % (n, t, thermo(w / 100, '', color=c, mark=m)) for c, n, t, w, m in (('#2E90FA', 'Objetivo', '3,2 de 5 %', 64, 1.0), ('#E89B00', 'Pérdida diaria', '1,9 de 4 %', 48, .75), ('#7A5AF8', 'Caída total', '1,2 de 8 %', 15, .75)))))
    return phone2(body, 2)


# ───── ensamblado ─────
ARTBOARD_FNS = {'AInicio.dc.html': a_inicio, 'ACuentas.dc.html': a_cuentas, 'AInforme.dc.html': a_analisis, 'AMInicio.dc.html': m_inicio, 'AMCuenta.dc.html': m_cuenta, 'AMInforme.dc.html': m_analisis}
TITLES = {'AInforme.dc.html': 'Análisis · propuesta', 'AMInforme.dc.html': 'iPhone Análisis · propuesta'}

if __name__ == '__main__':
    for name, title, w_, h_, fn in gen2.ARTBOARDS:
        fn = ARTBOARD_FNS.get(name, fn)
        write(name, gen2.doc(TITLES.get(name, title), w_, h_, fn()))
    write('AEnVivo.dc.html', page('En vivo', 1440, 900, mac2('envivo', 'En vivo', '', a_envivo()), LIVE_JS))
    write('AResultados.dc.html', page('Resultados', 1440, 900, a_resultados(), RES_JS))
    write('ASistema.dc.html', page('Sistema visual', 1440, 1000, a_sistema()))
    write('AMEnVivo.dc.html', page('iPhone En vivo', 470, 920, m_envivo()))
    write('AMResultados.dc.html', page('iPhone Resultados', 470, 920, m_resultados()))
    write('AWidgets.dc.html', page('Widgets', 1440, 1500, widgets()))
    write('ACuentaPanel.dc.html', page('Cuenta', 1440, 1100, a_panel(), PANEL_JS))
