#!/usr/bin/env python3
# Propuesta B · segunda vuelta: sistema visual, cuentas de trading, En vivo, Resultados y widgets.
import os, sys, math, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen2
from gen2 import (IC, mac2, card, big, pill, ch, tile, spark, gauge, donut, mix, calendar, waterfall, histogram, hourly, besthours,
                  phone2, ptitle, pc, thermo, row_robot, alert_row, EST, ROBOTS, MET)

OUT = gen2.OUT
POS, NEG, WARN, INFO, INK, INK2, GR = '#5FA800', '#F2465E', '#E89B00', '#2E90FA', '#2B2E33', '#6B7078', '#3A3D42'

CSS5 = r'''
/* ───── sistema visual: retícula de 8 px ───── */
:root{--s1:4px;--s2:8px;--s3:12px;--s4:16px;--s5:24px;--s6:32px;--s7:48px}
.ev{display:flex;align-items:center;gap:14px;padding:12px 6px;margin:0 -6px;border-top:1px solid #EFEFEA;border-radius:12px;transition:background .2s var(--ease)}
.ev:hover{background:#F6F6F3}
.ev.new{animation:evin .6s var(--ease) both;background:#F2F8E8}
@keyframes evin{from{opacity:0;transform:translateY(-14px);background:#E4F2CC}to{opacity:1;transform:none}}
.evi{width:34px;height:34px;border-radius:11px;display:flex;align-items:center;justify-content:center;flex:none}
.evt{font-size:12px;font-weight:700;letter-spacing:.02em;text-transform:uppercase}
.tick{animation:tickf .5s var(--ease) both}
@keyframes tickf{from{opacity:.4;transform:translateY(3px)}to{opacity:1;transform:none}}
.seg2{display:inline-flex;background:#E9E9E4;border-radius:12px;padding:3px;gap:2px}
.seg2 button{border:0;background:transparent;height:34px;padding:0 18px;border-radius:9px;font:600 14px -apple-system,BlinkMacSystemFont,'Inter',sans-serif;color:#6B7078;cursor:pointer;transition:all .2s var(--ease)}
.seg2 button.on{background:#fff;color:#2B2E33;box-shadow:0 1px 3px rgba(16,17,19,.12)}
.acct{position:relative;overflow:hidden}
.acct::before{content:"";position:absolute;left:0;top:0;bottom:0;width:4px;background:var(--ac,#3A3D42)}
.acct:hover{transform:translateY(-2px)}
.stat3{display:grid;grid-template-columns:repeat(3,1fr);gap:0;border-top:1px solid #EFEFEA;padding-top:14px}
.stat3>div{display:flex;flex-direction:column;gap:2px;padding-left:14px;border-left:1px solid #EFEFEA}
.stat3>div:first-child{padding-left:0;border-left:0}
.stat3 .l{font-size:12px;font-weight:600;color:#6B7078}
.stat3 .v{font-size:17px;font-weight:700;font-variant-numeric:tabular-nums}
/* widgets */
.wall{background:linear-gradient(160deg,#E9ECF2,#DDE4EE 45%,#EFE9E4);border-radius:26px;padding:28px;display:flex;gap:20px;flex-wrap:wrap;align-items:flex-start}
.wg{background:rgba(255,255,255,.92);border-radius:24px;box-shadow:0 10px 26px rgba(16,17,19,.12),0 0 0 1px rgba(16,17,19,.04);padding:16px;display:flex;flex-direction:column;gap:8px;overflow:hidden;flex:none}
.wg.s{width:158px;height:158px}.wg.m{width:338px;height:158px}.wg.l{width:338px;height:354px}
.wg.dark{background:#2B2E33;color:#fff}
.wl{font-size:12px;font-weight:600;color:#6B7078}.wg.dark .wl{color:#B5B9C0}
.wv{font-size:26px;font-weight:700;letter-spacing:-.02em;font-variant-numeric:tabular-nums;line-height:1.1}
.cap{font-size:13px;font-weight:600;color:#4A4E55;margin-bottom:8px}
.lock{background:linear-gradient(160deg,#7C8BA6,#4A5470);border-radius:26px;padding:28px;display:flex;gap:24px;align-items:center;flex-wrap:wrap;color:#fff}
.lc{background:rgba(255,255,255,.22);backdrop-filter:blur(14px);-webkit-backdrop-filter:blur(14px);border-radius:20px;color:#fff;padding:12px 14px;display:flex;flex-direction:column;gap:2px}
.island{background:#000;border-radius:34px;color:#fff;display:flex;align-items:center;gap:12px;padding:10px 18px}
.spec{background:#fff;border-radius:20px;border:1px solid rgba(16,17,19,.05);padding:24px;display:flex;flex-direction:column;gap:16px}
.gridcols{display:grid;grid-template-columns:repeat(12,1fr);gap:16px;height:90px}
.gridcols i{background:rgba(46,144,250,.12);border-radius:6px}
.ts{display:flex;align-items:baseline;gap:20px;padding:10px 0;border-top:1px solid #EFEFEA}
.ts b{width:56px;color:#6B7078;font-size:12px;font-weight:600;font-family:ui-monospace,Menlo,monospace}
'''
gen2.CSS_B += CSS5


def multiline(series, w=620, h=220):
    L, R, T, B = 44, 12, 12, 24
    allv = [v for _, s in series for v in s]
    lo, hi = min(allv), max(allv)
    sp = (hi - lo) or 1
    n = len(series[0][1])
    X = lambda i: L + i * (w - L - R) / (n - 1)
    Y = lambda v: T + (hi - v) / sp * (h - T - B)
    o = '<svg viewBox="0 0 %d %d" role="img" aria-label="Equity de todas las cuentas con base 100" style="width:100%%;height:auto;display:block">' % (w, h)
    for k in range(5):
        v = lo + sp * k / 4
        o += '<line x1="%d" y1="%.1f" x2="%d" y2="%.1f" stroke="#F1F1EC"/><text x="%d" y="%.1f" text-anchor="end" font-size="11" fill="#8A8A84">%.1f</text>' % (L, Y(v), w - R, Y(v), L - 6, Y(v) + 4, v)
    o += '<line x1="%d" y1="%.1f" x2="%d" y2="%.1f" stroke="#C9CDD2" stroke-dasharray="4 4"/>' % (L, Y(100), w - R, Y(100))
    for i, (c, s) in enumerate(series):
        o += '<polyline class="draw" style="animation-delay:%.2fs" pathLength="1" points="%s" fill="none" stroke="%s" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>' % (.2 + i * .12, ' '.join('%.1f,%.1f' % (X(i2), Y(v)) for i2, v in enumerate(s)), c)
    o += '<text x="%d" y="%d" font-size="11" fill="#8A8A84">hace 30 días</text><text x="%d" y="%d" text-anchor="end" font-size="11" fill="#8A8A84">hoy</text>' % (L, h - 6, w - R, h - 6)
    return o + '</svg>'


def curve(base, scale, seed):
    out, v = [], 100.0
    for i in range(30):
        v += scale * (0.18 + 0.5 * math.sin(i / 3 + seed) + 0.25 * math.sin(i * 1.7 + seed * 2))
        out.append(round(v, 2))
    return out


ACC = [  # nombre, firma, mono, tint, nº, saldo, equity, flotante, margen libre %, objetivo %, fase, acierto, pf, caida, estado, color
    ('Fondeo A · 100k', 'cT', '#7A5AF8', '4152', '101.842,30 €', '102.044,70 €', 202.40, 78, 22, 'Fase 1', '58,9 %', '1,41', '−1,92 %', 'ok', 0.9),
    ('Fondeo B · 50k', 'M5', '#1567C9', '2511', '51.600,10 €', '51.610,10 €', 10.00, 74, 64, 'Fase 2', '54,2 %', '1,22', '−2,31 %', 'warning', 0.5),
    ('Fondeo A · 25k', 'cT', '#7A5AF8', '8830', '25.090,00 €', '25.090,00 €', 0.0, 100, 5, 'Fase 1', '—', '—', '−0,40 %', 'paused', 0.1),
    ('Cuenta real', 'OA', '#8F5D00', '7712', '12.340,00 €', '12.352,10 €', 12.10, 66, 60, 'Mes', '55,0 %', '1,18', '−3,00 %', 'revisar', 0.3),
    ('Cuenta demo', 'cT', '#7A5AF8', '1120', '22.342,50 €', '22.360,20 €', 17.70, 90, 60, 'Incubación', '57,0 %', '1,25', '−1,20 %', 'ok', 0.6),
]


def acct_card(a, i):
    name, mono, tint, num, bal, eq, flo, free, goal, phase, wr, pf, dd, st, sc = a
    lab, pc_, col = EST[{'ok': 'bien', 'warning': 'atento', 'paused': 'parado', 'revisar': 'revisar'}[st]]
    up = flo >= 0
    s = curve(100, 1.0, i)
    return card(
        '<div style="display:flex;align-items:center;gap:12px"><span class="mt" style="width:40px;height:40px;border-radius:12px;background:%s22;color:%s;font-size:13px">%s</span>' % (tint, tint, mono) +
        '<div style="flex:1;min-width:0"><div style="font-weight:700;font-size:16px">%s</div><div class="t2" style="font-size:13px"><span style="font-family:ui-monospace,Menlo,monospace">···%s</span> · %s</div></div>%s</div>' % (name, num, phase, pill(lab, pc_)) +
        '<div><div class="t2" style="font-size:12px;font-weight:600">Balance</div>' + big(bal, 30) + '</div>' +
        '<div style="display:flex;gap:18px;font-size:13px"><span class="t2">Equity <b class="tn" style="color:#2B2E33">%s</b></span><span class="t2">Flotante <b class="tn" style="color:%s">%s</b></span></div>' % (eq, '#3F7300' if flo > 0 else '#6B7078', ('+' if flo > 0 else '') + ('%.2f' % flo).replace('.', ',') + ' €') +
        spark(s, 320, 54, POS if s[-1] >= 100 else NEG, True, 2.4) +
        '<div style="display:flex;flex-direction:column;gap:6px"><div style="display:flex;justify-content:space-between;font-size:12px" class="t2"><span>Objetivo de la fase</span><b class="tn" style="color:#2B2E33">%d %%</b></div>%s<div style="display:flex;justify-content:space-between;font-size:12px" class="t2"><span>Margen libre</span><b class="tn" style="color:#2B2E33">%d %%</b></div>%s</div>' % (goal, thermo(goal / 100, '', color=GR), free, thermo(free / 100, '', color=INFO)) +
        '<div class="stat3"><div><span class="l">Acierto</span><span class="v">%s</span></div><div><span class="l">PF</span><span class="v">%s</span></div><div><span class="l">Caída</span><span class="v" style="color:#C21A36">%s</span></div></div>' % (wr, pf, dd),
        '--ac:%s;gap:14px' % col).replace('class="card"', 'class="card acct"')


def a_cuentas():
    cards = ''.join(acct_card(a, i) for i, a in enumerate(ACC))
    grid = '<section style="display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:24px">%s</section>' % cards
    recon = ''.join('<div style="display:flex;align-items:center;gap:12px;padding:10px 0;border-top:1px solid #EFEFEA;font-size:14px"><span class="mt" style="width:28px;height:28px;border-radius:8px;font-size:10px">%s</span><span style="flex:1;font-weight:600">%s</span><span class="t2" style="font-family:ui-monospace,Menlo,monospace;font-size:12px">···%s</span>%s</div>' % (a[1], a[0], a[3], pill('Cuadra', 'sg') if i != 1 else pill('Dif. 1,20 €', 'so')) for i, a in enumerate(ACC))
    bottom = '<section style="display:grid;grid-template-columns:1fr 1fr;gap:24px">%s%s</section>' % (
        card(ch('Reparto del capital', 'Cuánto dinero hay en cada cuenta') + '<div style="display:flex;align-items:center;gap:24px">%s<div style="display:flex;flex-direction:column;gap:8px;font-size:14px">%s</div></div>' % (
            donut([(101842, '#3A3D42'), (51600, INFO), (25090, '#B5B5AE'), (12340, WARN), (22342, '#7A5AF8')], 148, 20, '5'),
            ''.join('<div><span style="color:%s">●</span> %s</div>' % (c, a[0]) for c, a in zip(('#3A3D42', INFO, '#B5B5AE', WARN, '#7A5AF8'), ACC)))),
        card(ch('Conciliación', 'Saldo según el bróker frente al del sistema') + recon + '<div class="t2" style="font-size:12px">Resultados y curvas: en Resultados. Trades abiertos: en En vivo.</div>'))
    return mac2('cuentas', 'Cuentas', '', grid + bottom, '<a class="btn p" href="AConfig.dc.html">+ Añadir cuenta</a>')


# ───────── En vivo (se mueve solo) ─────────
LIVE_JS = r'''
class Component extends DCLogic {
  constructor(props) {
    super(props);
    const T = [
      { id: 't1', par: 'EURUSD', side: 'Compra', acc: '···4152', mod: 'Rebote', pnl: 12.4, sl: true },
      { id: 't2', par: 'US500', side: 'Venta', acc: '···4152', mod: 'Impulso', pnl: 17.0, sl: true },
      { id: 't3', par: 'GBPUSD', side: 'Compra', acc: '···2511', mod: 'Tendencia', pnl: 16.0, sl: true },
      { id: 't4', par: 'XAUUSD', side: 'Venta', acc: '···4152', mod: 'Ruptura', pnl: 173.0, sl: true },
      { id: 't5', par: 'EURUSD', side: 'Compra', acc: '···2511', mod: 'Rebote', pnl: -6.0, sl: false }
    ];
    const ev = [
      { t: '10:41:58', k: 'open', title: 'Apertura · Venta US500 0,20', sub: '···4152 · Impulso' },
      { t: '10:41:07', k: 'reject', title: 'Rechazada por el bróker · EURUSD', sub: '···2511 · Rebote' },
      { t: '10:30:00', k: 'close', title: 'Cierre · GBPUSD · +4,10 €', sub: '···2511 · Tendencia' },
      { t: '10:12:31', k: 'warn', title: 'Hora del bróker desfasada 1,4 s', sub: '···4152' }
    ];
    const bars = []; for (let i = 0; i < 24; i++) bars.push(2 + Math.round(5 * Math.abs(Math.sin(i * 1.3))));
    const line = []; for (let i = 0; i < 40; i++) line.push(-50 + i * 4 + 30 * Math.sin(i / 3));
    this.state = { T: T, ev: ev, bars: bars, line: line, lat: [380, 410, 395, 430, 412, 405, 398, 420, 412], fresh: false, n: 4, signals: 142, done: 121, rej: 7, clock: 10 * 3600 + 42 * 60 };
  }
  componentDidMount() { this.timer = setInterval(() => this.tick(), 2300); }
  componentWillUnmount() { clearInterval(this.timer); }
  tick() {
    const S = this.state, r = Math.random;
    const T = S.T.map((t) => Object.assign({}, t, { pnl: +(t.pnl + (r() - 0.46) * 3.2).toFixed(2) }));
    const clock = S.clock + 2;
    const hh = String(Math.floor(clock / 3600)).padStart(2, '0'), mm = String(Math.floor(clock % 3600 / 60)).padStart(2, '0'), ss = String(clock % 60).padStart(2, '0');
    const POOL = [
      ['open', 'Apertura · Compra GBPJPY 0,10', '···2511 · Ruptura'], ['close', 'Cierre · EURUSD · +8,60 €', '···4152 · Rebote'], ['sl', 'Stop movido a breakeven · US500', '···4152 · Impulso'],
      ['signal', 'Señal nueva · AUDUSD · confianza 0,66', 'Rebote'], ['reject', 'Rechazada por el bróker · USDJPY', '···2511 · Tendencia'], ['sync', 'Saldo conciliado', '···2511 · cuadra'], ['close', 'Cierre · XAUUSD · −9,40 €', '···4152 · Ruptura']
    ];
    let ev = S.ev, signals = S.signals, done = S.done, rej = S.rej, fresh = false;
    if (r() < 0.7) {
      const p = POOL[Math.floor(r() * POOL.length)];
      ev = [{ t: hh + ':' + mm + ':' + ss, k: p[0], title: p[1], sub: p[2] }].concat(S.ev).slice(0, 9);
      fresh = true; signals += p[0] === 'signal' ? 1 : 0; done += p[0] === 'close' ? 1 : 0; rej += p[0] === 'reject' ? 1 : 0;
    }
    const bars = S.bars.slice(1).concat([1 + Math.round(r() * 7)]);
    const line = S.line.slice(1).concat([S.line[S.line.length - 1] + (r() - 0.42) * 14]);
    const lat = S.lat.slice(1).concat([Math.round(380 + r() * 90)]);
    this.setState({ T: T, ev: ev, bars: bars, line: line, lat: lat, fresh: fresh, signals: signals, done: done, rej: rej, clock: clock });
  }
  renderVals() {
    const S = this.state;
    const eur = (v, s) => (s && v > 0 ? '+' : v < 0 ? '−' : '') + Math.abs(v).toFixed(2).replace('.', ',') + ' €';
    const COL = { open: ['#E3F0FE', '#1567C9', 'M12 5v14 M5 12h14', 'Apertura'], close: ['#EEF8DC', '#3F7300', 'M5 12.5l4.5 4.5L19 7.5', 'Cierre'], reject: ['#FDE4E8', '#C21A36', 'M6 6l12 12 M18 6 6 18', 'Rechazo'], warn: ['#FDF1D6', '#8F5D00', 'M12 6v7 M12 17.5h.01', 'Aviso'], sl: ['#EDE8FE', '#4B35C4', 'M5 12h14 M13 6l6 6-6 6', 'Stop'], signal: ['#E5F4F4', '#00706F', 'M3 12h4l2.5-6 4 12 2.5-6H21', 'Señal'], sync: ['#EBEBE6', '#4A4E55', 'M20 12a8 8 0 1 1-2.3-5.7 M20 4v5h-5', 'Conciliación'] };
    const total = S.T.reduce((a, t) => a + t.pnl, 0);
    const hh = String(Math.floor(S.clock / 3600)).padStart(2, '0'), mm = String(Math.floor(S.clock % 3600 / 60)).padStart(2, '0'), ss = String(S.clock % 60).padStart(2, '0');
    const mxb = Math.max.apply(null, S.bars);
    const bars = S.bars.map((v, i) => ({ x: 10 + i * 22, y: 100 - v / mxb * 86, h: v / mxb * 86 }));
    const lo = Math.min.apply(null, S.line), hi = Math.max.apply(null, S.line), sp = (hi - lo) || 1;
    const pts = S.line.map((v, i) => (10 + i * (600 / (S.line.length - 1))).toFixed(1) + ',' + (110 - (v - lo) / sp * 96).toFixed(1)).join(' ');
    const lmx = Math.max.apply(null, S.lat), lmn = Math.min.apply(null, S.lat);
    const lpts = S.lat.map((v, i) => (4 + i * (180 / (S.lat.length - 1))).toFixed(1) + ',' + (34 - (v - lmn) / ((lmx - lmn) || 1) * 28).toFixed(1)).join(' ');
    return {
      clock: hh + ':' + mm + ':' + ss,
      total: eur(total, true), totalColor: total >= 0 ? '#3F7300' : '#C21A36',
      latency: S.lat[S.lat.length - 1] + ' ms', lpts: lpts,
      trades: S.T.map((t) => ({ par: t.par, side: t.side, sideCls: t.side === 'Venta' ? 'pill sr' : 'pill sg', acc: t.acc, mod: t.mod, pnl: eur(t.pnl, true), pc: t.pnl >= 0 ? '#3F7300' : '#C21A36', nosl: !t.sl, rowCls: t.sl ? 'ev' : 'ev', slText: t.sl ? '' : 'sin stop' })),
      events: S.ev.map((e, i) => ({ t: e.t, title: e.title, sub: e.sub, cls: i === 0 && S.fresh ? 'ev new' : 'ev', bg: COL[e.k][0], fg: COL[e.k][1], d: COL[e.k][2], kind: COL[e.k][3] })),
      signals: String(S.signals), done: String(S.done), rej: String(S.rej),
      bars: bars, pts: pts
    };
  }
}
'''


def a_envivo():
    head = ''  # la cabecera ya la pone mac2
    feed = card('<div style="display:flex;align-items:center;justify-content:space-between">' + ch('Actividad', 'Lo que está pasando ahora, lo más nuevo arriba') + '<span class="pill sg"><span class="sdot" style="width:8px;height:8px;border-radius:50%;background:#5FA800;animation:pulseg 2s infinite"></span>{{clock}} UTC</span></div>'
                '<sc-for list="{{events}}" as="e" hint-placeholder-count="6"><div class="{{e.cls}}"><span class="evi" style="background:{{e.bg}}"><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="{{e.fg}}" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="{{e.d}}"/></svg></span>'
                '<div style="flex:1;min-width:0"><div style="font-weight:600;font-size:14px">{{e.title}}</div><div class="t2" style="font-size:12px">{{e.sub}}</div></div><div style="text-align:right"><div class="evt" style="color:{{e.fg}}">{{e.kind}}</div><div class="t2 tn" style="font-size:12px">{{e.t}}</div></div></div></sc-for>', 'flex:1.25;min-height:0;overflow:hidden')
    hero = card('<div class="t2" style="font-size:12px;font-weight:600">Flotante ahora</div><span class="d tn tick" style="font-size:44px;font-weight:700;color:{{totalColor}};line-height:1.05">{{total}}</span><div class="t2" style="font-size:13px">5 trades abiertos · se actualiza cada pocos segundos</div>'
                '<svg viewBox="0 0 620 120" role="img" aria-label="Flotante de la última hora" style="width:100%;height:auto;display:block"><polyline points="{{pts}}" fill="none" stroke="#3A3D42" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/></svg>')
    trades = card(ch('Trades abiertos', 'Resultado flotante de cada uno, en directo') +
                  '<sc-for list="{{trades}}" as="t" hint-placeholder-count="5"><div class="ev" style="gap:12px"><span style="width:84px;font-weight:700;font-family:ui-monospace,Menlo,monospace;font-size:13px">{{t.par}}</span><span class="{{t.sideCls}}">{{t.side}}</span><span class="t2" style="font-size:12px;width:62px;font-family:ui-monospace,Menlo,monospace">{{t.acc}}</span><span class="t2" style="font-size:13px;flex:1">{{t.mod}}</span>'
                  '<sc-if value="{{t.nosl}}" hint-placeholder-val="{{ false }}"><span class="pill sr">sin stop</span></sc-if><span class="tn tick" style="width:84px;text-align:right;font-weight:700;color:{{t.pc}}">{{t.pnl}}</span></div></sc-for>')
    kp = lambda l, v, c='#2B2E33': '<div style="flex:1;display:flex;flex-direction:column;gap:2px"><span class="t2" style="font-size:12px;font-weight:600">%s</span><span class="d tn" style="font-size:26px;font-weight:700;color:%s">%s</span></div>' % (l, c, v)
    counters = card(ch('Hoy', 'Cuántas señales llegan y cuántas acaban en operación') + '<div style="display:flex;gap:16px">' + kp('Señales', '{{signals}}') + kp('Ejecutadas', '{{done}}', '#3F7300') + kp('Rechazadas', '{{rej}}', '#C21A36') + '</div>')
    activity = card(ch('Actividad por minuto', 'Eventos de los últimos 24 minutos') + '<svg viewBox="0 0 540 110" role="img" aria-label="Actividad por minuto" style="width:100%;height:auto;display:block"><line x1="6" y1="100" x2="534" y2="100" stroke="#E3E5E8"/><sc-for list="{{bars}}" as="b" hint-placeholder-count="24"><rect x="{{b.x}}" y="{{b.y}}" width="16" height="{{b.h}}" rx="4" fill="#2E90FA"/></sc-for></svg>')
    lat = card(ch('Respuesta del bróker', 'Tiempo hasta que acepta la orden') + '<div style="display:flex;align-items:flex-end;gap:16px"><span class="d tn tick" style="font-size:30px;font-weight:700">{{latency}}</span><svg viewBox="0 0 190 40" style="width:190px;height:40px" aria-hidden="true"><polyline points="{{lpts}}" fill="none" stroke="#2E90FA" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg></div><div class="t2" style="font-size:12px">Normal: menos de 700 ms</div>')
    meters = card(ch('Riesgo y margen', 'Lo que queda antes de los límites') + '<div style="display:flex;flex-direction:column;gap:12px"><div><div style="display:flex;justify-content:space-between;font-size:13px"><span>Riesgo usado</span><b class="tn">2,4 de 5 %</b></div><div style="height:6px"></div>' + thermo(.48, '', color=POS, mark=.6) + '</div><div><div style="display:flex;justify-content:space-between;font-size:13px"><span>Margen libre</span><b class="tn">78 %</b></div><div style="height:6px"></div>' + thermo(.78, '', color=INFO) + '</div></div>')
    main = '<section style="display:flex;gap:24px;flex:1;min-height:0">%s<div style="flex:1;display:flex;flex-direction:column;gap:24px;min-width:0">%s%s</div></section><section style="display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:24px">%s%s%s%s</section>' % (feed, hero, trades, counters, meters, activity, lat)
    return main


# ───────── Resultados (con periodo) ─────────
RES_JS = r'''
class Component extends DCLogic {
  constructor(props) { super(props); this.state = { p: 'mes' }; }
  renderVals() {
    const P = this.state.p;
    const D = {
      hoy: { title: 'Hoy', total: -860.6, pct: -0.56, vals: [20, -10, 30, 10, 0, -20, 10, 40, -80, -120, -190], lab: ['8', '', '10', '', '12', '', '14', '', '16', '', '18'], wr: '50,0 %', pf: '0,82', best: '+40,00 €', worst: '−190,00 €', ops: '12', unit: 'hora' },
      semana: { title: 'Esta semana', total: 853.0, pct: 0.4, vals: [140, 310, -120, 420, -97], lab: ['L', 'M', 'X', 'J', 'V'], wr: '56,0 %', pf: '1,31', best: '+420,00 €', worst: '−120,00 €', ops: '58', unit: 'día' },
      mes: { title: 'Este mes', total: 3412.0, pct: 1.6, vals: [120, 380, -90, 210, 440, -160, 300, 90, 250, -40, 380, 120, 220, -130, 310, 180, 90, 420, -70, 260, 150, 340, -110, 200, 120, 280, -60, 160, 230, 90], lab: [], wr: '57,4 %', pf: '1,38', best: '+440,00 €', worst: '−160,00 €', ops: '241', unit: 'día' },
      año: { title: 'Este año', total: 18240.0, pct: 9.1, vals: [820, 1240, 1610, -380, 1900, 2210, 1450, 1730, 2480, 1620, 2100, 1360], lab: ['E', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'], wr: '56,1 %', pf: '1,33', best: '+2.480 €', worst: '−380 €', ops: '2.314', unit: 'mes' }
    };
    const d = D[P];
    const mx = Math.max.apply(null, d.vals.map(Math.abs)), n = d.vals.length, W = 620, H = 220, mid = 120;
    const slot = (W - 20) / n;
    const bars = d.vals.map((v, i) => { const h = Math.max(2, Math.abs(v) / mx * 96); return { x: (10 + i * slot + slot * .15).toFixed(1), y: (v >= 0 ? mid - h : mid).toFixed(1), w: (slot * .7).toFixed(1), h: h.toFixed(1), c: v >= 0 ? '#5FA800' : '#F2465E', l: d.lab[i] || '', lx: (10 + i * slot + slot * .5).toFixed(1) }; });
    let acc = 0; const cum = d.vals.map((v) => (acc += v));
    const lo = Math.min.apply(null, cum.concat([0])), hi = Math.max.apply(null, cum.concat([0])), sp = (hi - lo) || 1;
    const pts = cum.map((v, i) => (10 + i * slot + slot * .5).toFixed(1) + ',' + (200 - (v - lo) / sp * 150).toFixed(1)).join(' ');
    const fmt = (v) => (v > 0 ? '+' : v < 0 ? '−' : '') + Math.abs(v).toFixed(0).replace(/\B(?=(\d{3})+(?!\d))/g, '.') + ' €';
    const seg = ['hoy', 'semana', 'mes', 'año'].map((k) => ({ n: k.charAt(0).toUpperCase() + k.slice(1), cls: P === k ? 'on' : '', pick: () => this.setState({ p: k }) }));
    return {
      seg: seg, title: d.title, total: fmt(d.total), totalColor: d.total >= 0 ? '#3F7300' : '#C21A36', pct: (d.pct > 0 ? '+' : '−') + Math.abs(d.pct).toFixed(2).replace('.', ',') + ' %',
      wr: d.wr, pf: d.pf, best: d.best, worst: d.worst, ops: d.ops, unit: d.unit, bars: bars, pts: pts
    };
  }
}
'''


def a_resultados():
    kp = lambda l, v, c='#2B2E33': '<div class="card" style="padding:18px 20px;gap:6px"><span class="t2" style="font-size:12px;font-weight:600">%s</span><span class="d tn" style="font-size:26px;font-weight:700;color:%s">%s</span></div>' % (l, c, v)
    hero = card('<div style="display:flex;align-items:center;gap:20px;flex-wrap:wrap"><div><div class="t2" style="font-size:14px;font-weight:600">{{title}}</div><span class="d tn tick" style="font-size:52px;font-weight:700;color:{{totalColor}};line-height:1.05">{{total}}</span><div class="t2" style="font-size:14px">{{pct}} sobre el capital total</div></div><span style="flex:1"></span>'
                '<div class="seg2" role="group" aria-label="Periodo"><sc-for list="{{seg}}" as="s" hint-placeholder-count="4"><button type="button" class="{{s.cls}}" onClick="{{s.pick}}">{{s.n}}</button></sc-for></div></div>')
    kpis = '<section style="display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:24px">%s%s%s%s%s</section>' % (kp('Acierto', '{{wr}}'), kp('Profit factor', '{{pf}}'), kp('Operaciones', '{{ops}}'), kp('Mejor {{unit}}', '{{best}}', '#3F7300'), kp('Peor {{unit}}', '{{worst}}', '#C21A36'))
    chart = card(ch('Resultado por periodo', 'Barras: cada hora, día o mes. Línea: lo acumulado') + '<svg viewBox="0 0 620 240" role="img" aria-label="Resultado por periodo y acumulado" style="width:100%;height:auto;display:block"><line x1="10" y1="120" x2="610" y2="120" stroke="#C9CDD2"/><sc-for list="{{bars}}" as="b" hint-placeholder-count="12"><g><rect x="{{b.x}}" y="{{b.y}}" width="{{b.w}}" height="{{b.h}}" rx="4" fill="{{b.c}}" fill-opacity=".9"/><text x="{{b.lx}}" y="236" text-anchor="middle" font-size="11" fill="#8A8A84">{{b.l}}</text></g></sc-for><polyline points="{{pts}}" fill="none" stroke="#3A3D42" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round" transform="translate(0,-30)"/></svg>', 'flex:1.4')
    cal = card(ch('Calendario', 'Resultado de cada día') + calendar(480, 52, 8))
    best = [('+440 €', 'EURUSD · Rebote · ···4152', '12 nov'), ('+312 €', 'XAUUSD · Ruptura · ···4152', '19 nov'), ('+260 €', 'GBPUSD · Tendencia · ···2511', '5 nov')]
    worst = [('−160 €', 'US500 · Impulso · ···4152', '8 nov'), ('−131 €', 'USDJPY · Rebote · ···2511', '14 nov'), ('−97 €', 'EURUSD · Rebote · ···2511', '26 nov')]
    rows = lambda items, c: ''.join('<div class="ev" style="gap:12px"><b class="tn" style="width:74px;color:%s;font-size:15px">%s</b><div style="flex:1"><div style="font-size:13px;font-weight:600">%s</div></div><span class="t2" style="font-size:12px">%s</span></div>' % (c, a, b, d) for a, b, d in items)
    pnl = [('···4152', 420), ('···2511', 210), ('···8830', 0), ('···7712', 64), ('···1120', 159)]
    mx = max(abs(v) for _, v in pnl)
    cuentas = ''.join('<div style="display:flex;align-items:center;gap:12px;font-size:13px"><span style="width:70px;font-family:ui-monospace,Menlo,monospace" class="t2">%s</span><div style="flex:1;height:14px;border-radius:7px;background:#EBEBE6"><div class="fillx" style="height:14px;border-radius:7px;width:%d%%;background:%s"></div></div><b class="tn" style="width:78px;text-align:right">%s</b></div>' % (n, max(2, abs(v) / mx * 100), POS, ('+%d €' % v) if v else '0 €') for n, v in pnl)
    row2 = '<section style="display:grid;grid-template-columns:1fr 1fr;gap:24px">%s%s</section>' % (
        card(ch('Caída desde el máximo', 'Cuánto estás por debajo del mejor punto') + gen2.underwater(560, 200)),
        card(ch('Por cuenta', 'Resultado de la semana en cada cuenta') + '<div style="display:flex;flex-direction:column;gap:14px">%s</div>' % cuentas + '<div class="t2" style="font-size:12px">Cómo rinde cada método: en Métodos.</div>'))
    ops = row2 + '<section style="display:grid;grid-template-columns:1fr 1fr;gap:24px">%s%s</section>' % (card(ch('Mejores operaciones', 'Las tres mejores del periodo') + rows(best, '#3F7300')), card(ch('Peores operaciones', 'Las tres peores del periodo') + rows(worst, '#C21A36')))
    return mac2('resultados', 'Resultados', '', hero + kpis + '<section style="display:grid;grid-template-columns:1.4fr 1fr;gap:24px">%s%s</section>' % (chart, cal) + ops)


# ───────── Sistema visual ─────────
def a_sistema():
    cols = '<div class="gridcols">' + '<i></i>' * 12 + '</div>'
    spaces = ''.join('<div style="display:flex;align-items:center;gap:14px;font-size:13px"><span style="width:48px;font-family:ui-monospace,Menlo,monospace" class="t2">%d px</span><span style="height:14px;width:%dpx;background:#2E90FA;border-radius:4px"></span><span class="t2">%s</span></div>' % (v, v, t) for v, t in ((4, 'icono y texto'), (8, 'entre elementos pequeños'), (12, 'dentro de una fila'), (16, 'entre filas de una tarjeta'), (24, 'entre tarjetas'), (32, 'margen de la pantalla'), (48, 'entre secciones')))
    types = [(40, '700', 'Cifra principal'), (30, '700', 'Título de pantalla'), (24, '700', 'Cifra de tarjeta'), (20, '600', 'Título de sección'), (17, '600', 'Subtítulo'), (15, '600', 'Encabezado de tarjeta'), (14, '400', 'Texto'), (13, '400', 'Texto secundario'), (12, '600', 'Etiqueta y pie')]
    tp = ''.join('<div class="ts"><b>%d / %d</b><span style="font-size:%dpx;font-weight:%s;line-height:1.2">%s</span></div>' % (s, round(s * 1.35), s, w, t) for s, w, t in types)
    radii = '<div style="display:flex;gap:20px;align-items:flex-end">%s</div>' % ''.join('<div style="display:flex;flex-direction:column;gap:6px;align-items:center;font-size:12px" class="t2"><span style="width:72px;height:72px;background:#E3E5E8;border-radius:%dpx"></span>%d px</div>' % (r, r) for r in (8, 12, 16, 20, 24))
    dock_items = ''.join('<span style="width:48px;height:48px;border-radius:16px;background:%s;display:flex;align-items:center;justify-content:center"><svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="%s" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="%s"/></svg></span>' % ('#2B2E33' if i == 1 else 'transparent', '#fff' if i == 1 else '#8A8A84', IC[k]) for i, k in enumerate(('inicio', 'envivo', 'cuentas', 'resultados')))
    dock = ('<div style="display:flex;gap:40px;align-items:flex-start"><div style="display:flex;flex-direction:column;gap:8px;background:#fff;border-radius:24px;padding:12px 0;width:72px;align-items:center;box-shadow:0 18px 44px rgba(16,17,19,.12);border:1px solid rgba(16,17,19,.06)">' + dock_items +
            '</div><div style="display:flex;flex-direction:column;gap:10px;font-size:13px" class="t2"><b style="color:#2B2E33;font-size:15px">Dock</b><span>Ancho 72 · icono 24 · botón 48 · hueco 8</span><span>Cristal con desenfoque, borde de 1 px</span><span>Activo: relleno grafito, icono blanco</span><span>Etiqueta al pasar el ratón</span><span>En ventana estrecha pasa abajo, en horizontal</span><span>iPhone: cápsula de 68 px, flotante, a 16 px del borde</span></div></div>')
    body = ('<div style="min-height:1000px;background:#F3F3F0;padding:40px 48px 48px;display:flex;flex-direction:column;gap:24px"><div><h1 class="d" style="margin:0;font-size:34px;font-weight:700">Retícula, aire y tipografía</h1><div class="t2" style="font-size:15px">Todo se mide de 8 en 8 y la letra va en tamaños enteros.</div></div>'
            '<div style="display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px">'
            '<div class="spec">' + ch('Retícula de 12 columnas', 'Márgenes de 32 px y huecos de 16 px') + cols + '<div class="t2" style="font-size:13px">Márgenes 32 · hueco 16 · tarjetas en 3, 4 o 6 columnas</div></div>'
            '<div class="spec">' + ch('Aire', 'Escala de espacios') + spaces + '</div>'
            '<div class="spec">' + ch('Tipografía', 'Tamaño / interlineado') + tp + '</div>'
            '<div class="spec" style="gap:24px">' + ch('Esquinas', 'Más grande el elemento, más redondeo') + radii + ch('Dock', 'Barra de secciones') + dock + '</div></div></div>')
    return body


# ───────── iPhone: En vivo y Resultados ─────────
def m_envivo():
    ev = [('open', 'Apertura · Venta US500 0,20', '···4152 · Impulso', '10:41:58'), ('reject', 'Rechazada · EURUSD', '···2511 · Rebote', '10:41:07'), ('close', 'Cierre · GBPUSD · +4,10 €', '···2511 · Tendencia', '10:30:00'), ('warn', 'Hora del bróker desfasada', '···4152', '10:12:31')]
    COL = {'open': ('#E3F0FE', '#1567C9', 'M12 5v14 M5 12h14'), 'close': ('#EEF8DC', '#3F7300', 'M5 12.5l4.5 4.5L19 7.5'), 'reject': ('#FDE4E8', '#C21A36', 'M6 6l12 12 M18 6 6 18'), 'warn': ('#FDF1D6', '#8F5D00', 'M12 6v7 M12 17.5h.01')}
    rows = ''.join('<div class="ev" style="gap:12px;padding:10px 0;margin:0"><span class="evi" style="background:%s;width:32px;height:32px"><svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="%s" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="%s"/></svg></span><div style="flex:1;min-width:0"><div style="font-weight:600;font-size:14px">%s</div><div class="t2" style="font-size:12px">%s</div></div><span class="t2 tn" style="font-size:12px">%s</span></div>' % (COL[k][0], COL[k][1], COL[k][2], t, s, h) for k, t, s, h in ev)
    body = (ptitle('En vivo') +
            pc('<div class="t2" style="font-size:12px;font-weight:600">Flotante ahora</div><span class="d tn" style="font-size:38px;font-weight:700;color:#3F7300;line-height:1.05">+212,40 €</span><div class="t2" style="font-size:13px">5 trades abiertos</div>' + spark([20, 50, 30, 90, 60, 140, 120, 190, 170, 212], 320, 48, '#3A3D42', True, 2.6)) +
            pc(ch('Trades abiertos', 'Resultado flotante de cada uno') + ''.join('<div style="display:flex;align-items:center;gap:8px;font-size:14px"><b style="width:70px;font-family:ui-monospace,Menlo,monospace;font-size:13px">%s</b><span class="pill %s">%s</span><span style="flex:1"></span>%s<b class="tn" style="color:%s">%s</b></div>' % x for x in (('EURUSD', 'sg', 'Compra', '', '#3F7300', '+12,40 €'), ('US500', 'sr', 'Venta', '', '#3F7300', '+17,00 €'), ('EURUSD', 'sg', 'Compra', '<span class="pill sr">sin stop</span>', '#C21A36', '−6,00 €')))) +
            '<div class="pc" style="padding:6px 16px">%s</div>' % rows +
            pc(ch('Respuesta del bróker', 'Tiempo hasta aceptar la orden') + '<div style="display:flex;align-items:flex-end;gap:12px"><span class="d tn" style="font-size:26px;font-weight:700">412 ms</span><div style="flex:1">%s</div></div>' % spark([380, 410, 395, 430, 412, 405, 398, 420, 412], 160, 36, '#2E90FA', False, 2.4)))
    return phone2(body, 1)


def m_resultados():
    body = (ptitle('Resultados') + '<div style="display:flex;justify-content:center"><div class="seg2"><button class="" type="button">Hoy</button><button class="" type="button">Semana</button><button class="on" type="button">Mes</button><button class="" type="button">Año</button></div></div>' +
            pc('<div class="t2" style="font-size:12px;font-weight:600">Este mes</div><span class="d tn" style="font-size:38px;font-weight:700;color:#3F7300;line-height:1.05">+3.412 €</span><div class="t2" style="font-size:13px">+1,60 % sobre el capital total</div>') +
            pc(ch('Día a día', 'Resultado de cada día') + calendar(360, 46, 6, False)) +
            '<div style="display:flex;gap:12px"><div class="pc" style="flex:1"><div class="t2" style="font-size:12px;font-weight:600">Acierto</div><b class="tn" style="font-size:22px">57,4 %</b></div><div class="pc" style="flex:1"><div class="t2" style="font-size:12px;font-weight:600">Profit factor</div><b class="tn" style="font-size:22px">1,38</b></div></div>')
    return phone2(body, 4)


# ───────── Widgets ─────────
def w(cls, inner, dark=False):
    return '<div class="wg %s%s">%s</div>' % (cls, ' dark' if dark else '', inner)


def lab(t):
    return '<span class="wl">%s</span>' % t


def widgets():
    s_bal = w('s', lab('Balance') + '<span class="wv">153.442 €</span><span style="font-size:13px;font-weight:700;color:#C21A36">−0,42 % hoy</span>' + spark([206, 207, 206.5, 208, 207.6, 209, 208.4, 210, 209.3, 211, 210.4, 212], 130, 32, '#5FA800', True, 2.4))
    s_gauge = w('s', lab('Margen del día') + gauge(16, 'Margen usado', 150, 100, sub='usado').replace('width:100%;height:auto', 'width:100%;height:auto'))
    s_alert = w('s', lab('Alertas') + '<span class="wv" style="color:#C21A36;font-size:40px">1</span><span class="pill sr" style="align-self:flex-start">Sin stop</span><span class="t2" style="font-size:12px">+ 2 de atención</span>')
    s_live = w('s', '<span class="wl" style="display:flex;align-items:center;gap:6px"><span style="width:8px;height:8px;border-radius:50%;background:#5FA800;animation:pulseg 2s infinite"></span>En vivo</span><span class="wv" style="color:#3F7300">+212 €</span><span class="t2" style="font-size:12px">flotante · 5 abiertos</span>' + spark([20, 50, 30, 90, 60, 140, 120, 190, 212], 130, 28, '#3A3D42', False, 2.2))
    s_stop = w('s', lab('Parar todo') + '<div style="flex:1;display:flex;align-items:center;justify-content:center"><span style="width:64px;height:64px;border-radius:32px;background:#EBEBE6;display:flex;align-items:center;justify-content:center"><svg viewBox="0 0 24 24" width="30" height="30"><rect x="6.5" y="6.5" width="11" height="11" rx="2.5" fill="none" stroke="#8A8A84" stroke-width="2"/></svg></span></div><span class="t2" style="font-size:12px;text-align:center">Pide Face ID</span>', False)
    m_acc = w('m', lab('Cuentas') + ''.join('<div style="display:flex;align-items:center;gap:10px"><span class="mt" style="width:28px;height:28px;border-radius:8px;font-size:10px">%s</span><div style="flex:1"><div style="font-size:13px;font-weight:600;line-height:1.2">%s</div></div><b class="tn" style="font-size:14px">%s</b><b class="tn" style="font-size:13px;width:60px;text-align:right;color:%s">%s</b></div>' % x for x in (('cT', 'Fondeo A · 100k', '101.842 €', '#C21A36', '−0,6 %'), ('M5', 'Fondeo B · 50k', '51.600 €', '#C21A36', '−1,9 %'), ('OA', 'Cuenta real', '12.340 €', '#3F7300', '+0,3 %'))))
    m_trades = w('m', lab('Trades abiertos') + ''.join('<div style="display:flex;align-items:center;gap:10px;font-size:13px"><b style="width:70px;font-family:ui-monospace,Menlo,monospace">%s</b><span class="pill %s" style="height:20px">%s</span><span style="flex:1"></span><b class="tn" style="color:%s">%s</b></div>' % x for x in (('EURUSD', 'sg', 'Compra', '#3F7300', '+12,40 €'), ('US500', 'sr', 'Venta', '#3F7300', '+17,00 €'), ('EURUSD', 'sg', 'Compra', '#C21A36', '−6,00 € · sin stop'))))
    m_curve = w('m', '<div style="display:flex;justify-content:space-between"><div>' + lab('Equity · 7 días') + '<div class="wv" style="font-size:24px">+0,4 %</div></div><span class="pill sg">+853 €</span></div>' + spark([100, 100.3, 99.8, 100.4, 100.1, 100.6, 100.4], 300, 54, '#2E90FA', True, 2.6))
    m_robots = w('m', lab('Robots') + '<div style="display:flex;gap:10px;flex-wrap:wrap">%s</div>' % ''.join('<div style="display:flex;align-items:center;gap:6px;background:#F2F2EE;border-radius:12px;padding:6px 10px;font-size:12px;font-weight:600"><span style="width:8px;height:8px;border-radius:50%%;background:%s"></span>%s</div>' % (EST[r[2]][2], r[0]) for r in ROBOTS))
    l_panel = w('l', '<div style="display:flex;justify-content:space-between;align-items:flex-start"><div>' + lab('Mym · Hoy') + '<div class="wv" style="font-size:30px">153.442 €</div><div style="font-size:13px;font-weight:700;color:#C21A36">−648 € · −0,42 %</div></div><span class="pill sg">Activo</span></div>'
              + spark([206, 207, 206.5, 208, 207.6, 209, 208.4, 210, 209.3, 211, 210.4, 212], 300, 56, '#5FA800', True, 2.4)
              + '<div style="display:grid;grid-template-columns:1fr 1fr;gap:8px">%s</div>' % ''.join('<div style="background:#F2F2EE;border-radius:12px;padding:8px 10px"><div class="wl">%s</div><div style="font-size:16px;font-weight:700;color:%s" class="tn">%s</div></div>' % x for x in (('Flotante', '#3F7300', '+212 €'), ('Abiertos', '#2B2E33', '5'), ('Acierto 30 d', '#3F7300', '57,4 %'), ('Riesgo usado', '#3F7300', '2,4 %')))
              + '<span class="wl">Avisos</span><div style="display:flex;align-items:center;gap:8px;font-size:13px;font-weight:600"><span style="width:8px;height:8px;border-radius:50%;background:#F2465E"></span>Posición sin stop · ···2511</div>')
    l_cal = w('l', lab('Mes · resultado por día') + calendar(300, 36, 6, False))
    gal = lambda t, items: '<div><div class="cap">%s</div><div class="wall">%s</div></div>' % (t, items)
    lock = ('<div class="lock"><div class="lc" style="width:84px;height:84px;border-radius:42px;align-items:center;justify-content:center"><svg viewBox="0 0 44 44" width="64" height="64"><g transform="rotate(-90 22 22)" fill="none" stroke-width="5" stroke-linecap="round"><circle cx="22" cy="22" r="18" stroke="rgba(255,255,255,.3)"/><circle cx="22" cy="22" r="18" stroke="#fff" stroke-dasharray="54 113"/></g></svg></div>'
            '<div class="lc" style="width:168px"><span style="font-size:12px;font-weight:600;opacity:.8">Mym · hoy</span><span style="font-size:22px;font-weight:700">−0,42 %</span><span style="font-size:12px;opacity:.85">1 aviso urgente</span></div>'
            '<div class="lc" style="flex-direction:row;gap:8px;align-items:center;padding:8px 16px"><b>Mym −0,42 %</b><span style="opacity:.8">· 1 aviso</span></div></div>')
    isla = ('<div style="display:flex;gap:24px;flex-wrap:wrap;align-items:center;background:#E9ECF2;border-radius:26px;padding:28px"><div class="island" style="width:300px"><span style="width:10px;height:10px;border-radius:50%%;background:#5FA800;animation:pulseg 2s infinite"></span><b style="font-size:14px">EURUSD · Compra</b><span style="flex:1"></span><b class="tn" style="color:#8EE04A;font-size:15px">+12,40 €</b></div>'
            '<div class="island" style="width:372px;border-radius:30px;flex-direction:column;align-items:stretch;gap:8px;padding:16px 20px"><div style="display:flex;justify-content:space-between;font-size:13px;opacity:.8"><span>Mym · en vivo</span><span>5 abiertos</span></div><div style="display:flex;align-items:flex-end;justify-content:space-between"><b class="tn" style="font-size:32px;color:#8EE04A">+212,40 €</b><span style="width:150px">%s</span></div><div style="font-size:12px;opacity:.8">1 sin stop · ···2511</div></div></div>' % spark([20, 50, 30, 90, 60, 140, 120, 190, 212], 150, 36, '#8EE04A', False, 2.4).replace('style="width:100%;', 'style="width:150px;'))
    mac = ('<div class="wall" style="background:linear-gradient(160deg,#DFE7F2,#CDD8E8 55%,#E8E2DA)">' + w('m', lab('Mym · En vivo') + '<div class="wv" style="color:#3F7300">+212,40 €</div>' + spark([20, 50, 30, 90, 60, 140, 120, 190, 212], 300, 48, '#3A3D42', True, 2.4)) +
           w('l', lab('Cuentas') + ''.join('<div style="display:flex;align-items:center;gap:10px"><span class="mt" style="width:28px;height:28px;border-radius:8px;font-size:10px">%s</span><div style="flex:1;font-size:13px;font-weight:600">%s</div><b class="tn" style="font-size:14px">%s</b></div>' % x for x in (('cT', 'Fondeo A · 100k', '101.842 €'), ('M5', 'Fondeo B · 50k', '51.600 €'), ('cT', 'Fondeo A · 25k', '25.090 €'), ('OA', 'Cuenta real', '12.340 €'), ('cT', 'Cuenta demo', '22.342 €'))) + '<div style="margin-top:auto">' + lab('Reparto') + '</div>' + gauge(18, 'Exposición', 200, 110, sub='del máximo')) + '</div>')
    watch = ('<div class="wall" style="background:#1F2124;gap:28px"><div style="width:176px;height:208px;background:#000;border-radius:44px;padding:18px;color:#fff;display:flex;flex-direction:column;gap:2px;border:3px solid #3A3D42"><span style="font-size:12px;opacity:.7">Mym · hoy</span><b class="tn" style="font-size:34px;color:#FF7A8A">−0,42 %</b><span style="font-size:12px;opacity:.8">153.442 €</span><span style="flex:1"></span><span style="font-size:12px;opacity:.9">1 aviso urgente</span></div>'
             '<div style="width:96px;height:96px;background:#000;border-radius:48px;color:#fff;display:flex;align-items:center;justify-content:center;border:3px solid #3A3D42"><svg viewBox="0 0 44 44" width="80" height="80"><g transform="rotate(-90 22 22)" fill="none" stroke-width="5" stroke-linecap="round"><circle cx="22" cy="22" r="17" stroke="#3A3D42"/><circle cx="22" cy="22" r="17" stroke="#5FA800" stroke-dasharray="26 107"/></g><text x="22" y="26" text-anchor="middle" font-size="11" font-weight="700" fill="#fff" transform="rotate(0)">2,4 %</text></svg></div></div>')
    notes = '<div class="spec" style="gap:10px"><b style="font-size:15px">Qué se puede y qué no</b><span class="t2" style="font-size:13px">Los widgets se refrescan unas pocas veces por hora: sirven para ver, no para operar. Lo que va en tiempo real es la Isla dinámica y la Actividad en vivo, que reciben avisos del servidor. Parar todo desde un widget necesita iOS 17 y confirmar con Face ID dentro de la app.</span></div>'
    body = ('<div style="min-height:1500px;background:#F3F3F0;padding:40px 48px 48px;display:flex;flex-direction:column;gap:32px"><div><h1 class="d" style="margin:0;font-size:34px;font-weight:700">Widgets</h1><div class="t2" style="font-size:15px">Pantalla de inicio, pantalla de bloqueo, Isla dinámica, Mac y reloj.</div></div>'
            + gal('Pantalla de inicio · pequeños', s_bal + s_gauge + s_alert + s_live + s_stop) + gal('Pantalla de inicio · medianos y grandes', m_acc + m_trades + m_curve + m_robots + l_panel + l_cal)
            + gal('Pantalla de bloqueo', lock) + gal('Isla dinámica y Actividad en vivo', isla) + gal('Mac · escritorio y Centro de notificaciones', mac) + gal('Apple Watch', watch) + notes + '</div>')
    return body


# ───────── ensamblado ─────────
def page(title, w_, h_, body, js=None):
    if js is None:
        js = 'class Component extends DCLogic {\n  renderVals() {\n    return {};\n  }\n}\n'
    css = gen2.CSS_B
    return ('<!doctype html>\n<html lang="es">\n<head>\n<meta charset="utf-8">\n<title>%s</title>\n<script src="./support.js"></script>\n</head>\n<body>\n<x-dc>\n<helmet>\n'
            '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">\n<style>\n' % title + css + '\n</style>\n</helmet>\n' + body +
            '\n</x-dc>\n<script type="text/x-dc" data-dc-script data-props=\'{"$preview":{"width":%d,"height":%d}}\'>\n%s</script>\n</body>\n</html>\n' % (w_, h_, js))


def write(name, html):
    with open(os.path.join(OUT, name), 'w') as f:
        f.write(html)
    print('ok', name)


if __name__ == '__main__':
    for name, title, w_, h_, fn in gen2.ARTBOARDS:
        if name == 'ACuentas.dc.html':
            fn = a_cuentas
        write(name, gen2.doc(title, w_, h_, fn()))
    write('AEnVivo.dc.html', page('En vivo', 1440, 900, mac2('envivo', 'En vivo', '', a_envivo()), LIVE_JS))
    write('AResultados.dc.html', page('Resultados', 1440, 900, a_resultados(), RES_JS))
    write('ASistema.dc.html', page('Sistema visual', 1440, 1000, a_sistema()))
    write('AMEnVivo.dc.html', page('iPhone En vivo', 470, 920, m_envivo()))
    write('AMResultados.dc.html', page('iPhone Resultados', 470, 920, m_resultados()))
    write('AWidgets.dc.html', page('Widgets', 1440, 1500, widgets()))
