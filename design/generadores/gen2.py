#!/usr/bin/env python3
# Propuesta paralela: lenguaje llano, textos cortos, más pantallas y más gráficas.
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen import doc as doc_base, ch, pill, tile, ring, rr, ci, INFO, OUT, CSS

CSS_B = CSS + '\n:root{--ease:cubic-bezier(.2,.8,.2,1)}\nbody{background:#F3F3F0;font-feature-settings:"tnum" 1,"cv11" 1}\n.win{background:#F3F3F0}\n.card{border-radius:20px;border:1px solid rgba(16,17,19,.05);box-shadow:0 1px 1px rgba(16,17,19,.03),0 6px 18px rgba(16,17,19,.05);transition:box-shadow .3s var(--ease),transform .3s var(--ease)}\n.card:hover{box-shadow:0 1px 2px rgba(16,17,19,.05),0 12px 30px rgba(16,17,19,.09)}\n.pc{border:1px solid rgba(16,17,19,.05);box-shadow:0 1px 1px rgba(16,17,19,.03),0 4px 14px rgba(16,17,19,.04)}\n.ch{font-size:15px;letter-spacing:-.01em}\n.btn{transition:background .2s var(--ease),transform .12s var(--ease),box-shadow .2s var(--ease)}\n.btn:hover{background:#E1E1DB}\n.btn.p:hover{background:#2B2E33}\n.btn.x:hover{background:#A8142C}\n.btn:active,.tab:active,.ri:active{transform:scale(.96)}\na:focus-visible,button:focus-visible{outline:3px solid rgba(46,144,250,.45);outline-offset:2px;border-radius:12px}\n.pill{transition:transform .2s var(--ease)}\n.hov{border-radius:12px;transition:background .2s var(--ease)}\n.hov:hover{background:#F6F6F3}\n.tg>span{transition:all .25s var(--ease)}\n/* riel: etiqueta al pasar y cambio suave */\n.ri{transition:background .2s var(--ease),transform .12s var(--ease)}\n.ri:hover{background:#F2F2EE}\n.ri.stop:hover{background:#FDE4E8}\n.ri.stop:hover path{stroke:#C21A36}\n.ri::after{content:attr(aria-label);position:absolute;left:56px;top:50%;transform:translate(-6px,-50%);opacity:0;pointer-events:none;background:#2B2E33;color:#fff;font-size:12px;font-weight:600;padding:5px 9px;border-radius:8px;white-space:nowrap;transition:opacity .18s var(--ease),transform .18s var(--ease);z-index:9}\n.ri:hover::after{opacity:1;transform:translate(0,-50%)}\n/* en vivo y avisos urgentes */\n.live{display:inline-flex;align-items:center;gap:7px;height:30px;padding:0 12px;border-radius:999px;background:#fff;box-shadow:0 0 0 1px rgba(16,17,19,.06);font-size:13px;font-weight:600;color:#3F7300}\n.live i{width:8px;height:8px;border-radius:50%;background:#5FA800;animation:pulse 2s var(--ease) infinite}\n.pulse{animation:pulse 2s var(--ease) infinite}\n@keyframes pulse{0%{box-shadow:0 0 0 0 rgba(242,70,94,.45)}70%{box-shadow:0 0 0 9px rgba(242,70,94,0)}100%{box-shadow:0 0 0 0 rgba(242,70,94,0)}}\n.live i{animation-name:pulseg}\n@keyframes pulseg{0%{box-shadow:0 0 0 0 rgba(95,168,0,.5)}70%{box-shadow:0 0 0 7px rgba(95,168,0,0)}100%{box-shadow:0 0 0 0 rgba(95,168,0,0)}}\n/* control segmentado */\n.seg{display:flex;background:#E9E9E4;border-radius:11px;padding:3px;gap:2px}\n.seg span{padding:5px 14px;border-radius:8px;font-size:13px;font-weight:600;color:#6B7078;transition:all .2s var(--ease)}\n.seg span.on{background:#fff;color:#2B2E33;box-shadow:0 1px 3px rgba(16,17,19,.12)}\n/* entrada de pantalla: el contenido sube en cascada */\n@keyframes rise{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:none}}\n@keyframes fadein{from{opacity:0}to{opacity:1}}\n.main>*,.scr>div:first-of-type>*{animation:rise .6s var(--ease) both}\n.main>*:nth-child(2),.scr>div:first-of-type>*:nth-child(2){animation-delay:.06s}\n.main>*:nth-child(3),.scr>div:first-of-type>*:nth-child(3){animation-delay:.12s}\n.main>*:nth-child(4),.scr>div:first-of-type>*:nth-child(4){animation-delay:.18s}\n.main>*:nth-child(5),.scr>div:first-of-type>*:nth-child(5){animation-delay:.24s}\n.main>*:nth-child(6),.scr>div:first-of-type>*:nth-child(6){animation-delay:.3s}\nsection>.card{animation:rise .6s var(--ease) both}\nsection>.card:nth-child(2){animation-delay:.08s}\nsection>.card:nth-child(3){animation-delay:.16s}\nsection>.card:nth-child(4){animation-delay:.24s}\nsection>.card:nth-child(5){animation-delay:.32s}\nsection>.card:nth-child(6){animation-delay:.4s}\n/* gráficas que se dibujan */\n.draw{stroke-dasharray:1;animation:draw 1.2s var(--ease) .25s both}\n@keyframes draw{from{stroke-dashoffset:1}to{stroke-dashoffset:0}}\n.fadein{animation:fadein .9s var(--ease) .5s both}\n.grow,.growd{transform-box:fill-box;animation:grow .7s var(--ease) both}\n.grow{transform-origin:50% 100%}\n.growd{transform-origin:50% 0}\n@keyframes grow{from{transform:scaleY(0)}to{transform:scaleY(1)}}\n.pop{transform-box:fill-box;transform-origin:50% 50%;animation:pop .45s var(--ease) both}\n@keyframes pop{from{opacity:0;transform:scale(.6)}to{opacity:1;transform:scale(1)}}\n.fillx{transform-origin:0 50%;animation:fillx .9s var(--ease) .2s both}\n@keyframes fillx{from{transform:scaleX(0)}to{transform:scaleX(1)}}\n.spinin{animation:spinin .9s var(--ease) both}\n@keyframes spinin{from{opacity:0;transform:rotate(-40deg) scale(.85)}to{opacity:1;transform:none}}\n/* pestañas del iPhone */\n.tab{transition:color .2s var(--ease),transform .12s var(--ease)}\n.tab.on::before{content:"";position:absolute;top:0;left:50%;width:26px;height:3px;margin-left:-13px;border-radius:0 0 3px 3px;background:#2B2E33}\n@media (prefers-reduced-motion:reduce){*,*::before,*::after{animation:none!important;transition:none!important}}\n'
CSS_B += '\n/* ── escala tipográfica: siempre px enteros (nada de medios puntos) ── */\nhtml,body{height:100%}\nbody{-webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale;text-rendering:optimizeLegibility;font-size:14px;line-height:1.45}\n.mono{font-size:12px}.btn{font-size:14px;height:34px}.pill{font-size:12px;height:22px;padding:0 9px}.kl{font-size:13px}.ch{font-size:15px;font-weight:600}\n.tab{font-size:11px}.tb{font-size:11px}\n/* ── ventana que se adapta a cualquier tamaño ── */\n.win{width:100%;height:100vh;min-height:640px;border-radius:0;box-shadow:none}\n.main{left:100px;right:0;top:0;bottom:0;padding:24px 28px 28px 12px;overflow-y:auto;overflow-x:hidden}\n.main>section{flex-wrap:wrap}\n.main>section>.card,.main>section>div{min-width:280px}\n/* ── dock lateral: cristal flotante, centrado, activo relleno ── */\n.rail{left:16px;top:16px;bottom:16px;display:flex;align-items:center}\n.dock{width:64px;background:rgba(255,255,255,.8);-webkit-backdrop-filter:blur(24px) saturate(1.6);backdrop-filter:blur(24px) saturate(1.6);border-radius:24px;border:1px solid rgba(16,17,19,.06);box-shadow:0 1px 1px rgba(16,17,19,.04),0 18px 44px rgba(16,17,19,.12);padding:10px 0;display:flex;flex-direction:column;align-items:center;gap:6px}\n.dock .sep{width:28px;height:1px;background:#E6E6E0;margin:2px 0;flex:none}\n.ri{width:44px;height:44px;border-radius:14px}\n.ri.on{background:#2B2E33!important;box-shadow:0 6px 14px rgba(43,46,51,.28)}\n.ri.on path{stroke:#fff}\n.ri::after{top:9px;transform:translateX(-6px)}\n.ri:hover::after{transform:none}\n.dock>a{animation:rise .5s var(--ease) both}\n.dock>a:nth-child(2){animation-delay:.03s}.dock>a:nth-child(3){animation-delay:.06s}.dock>a:nth-child(4){animation-delay:.09s}.dock>a:nth-child(5){animation-delay:.12s}\n.dock>a:nth-child(6){animation-delay:.15s}.dock>a:nth-child(7){animation-delay:.18s}.dock>a:nth-child(8){animation-delay:.21s}.dock>a:nth-child(9){animation-delay:.24s}.dock>a:nth-child(10){animation-delay:.27s}\n.ri.on{animation:popon .5s var(--ease) both}\n@keyframes popon{0%{transform:scale(.7);opacity:0}60%{transform:scale(1.06);opacity:1}100%{transform:scale(1)}}\n/* ── transiciones: título y cifras entran con suavidad, cambio de pantalla con fundido ── */\n.main>div:first-child .d{animation:slidein .55s var(--ease) both}\n@keyframes slidein{from{opacity:0;transform:translateX(-14px)}to{opacity:1;transform:none}}\n.card .d.tn,.pc .d.tn{animation:numin .7s var(--ease) .15s both}\n@keyframes numin{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:none}}\n@view-transition{navigation:auto}\n::view-transition-old(root){animation:vtout .25s var(--ease) both}\n::view-transition-new(root){animation:vtin .35s var(--ease) both}\n@keyframes vtout{to{opacity:0}}\n@keyframes vtin{from{opacity:0}}\n/* ── pantallas más estrechas ── */\n@media (max-width:1240px){\n  .main [style*="repeat(3,minmax(0,1fr))"],.main [style*="repeat(4,minmax(0,1fr))"]{grid-template-columns:repeat(2,minmax(0,1fr))!important}\n  .gal [style*="repeat(4,minmax(0,1fr))"]{grid-template-columns:repeat(2,minmax(0,1fr))!important}\n}\n@media (max-width:900px){\n  .rail{left:12px;right:12px;top:auto;bottom:12px;justify-content:center}\n  .dock{flex-direction:row;width:auto;height:64px;padding:0 10px;border-radius:32px}\n  .dock .sep{width:1px;height:28px;margin:0 2px}\n  .dock .sp{display:none}\n  .ri::after{display:none}\n  .main{left:0;padding:20px 16px 104px}\n  .main [style*="repeat("]{grid-template-columns:minmax(0,1fr)!important}\n  .main [style*="width:360px"],.main [style*="width:420px"]{width:100%!important}\n  .gal [style*="repeat("]{grid-template-columns:minmax(0,1fr)!important}\n  .pvs{grid-template-columns:repeat(3,minmax(0,1fr))}\n  .cfg{flex-direction:column}\n  .cfg>nav{width:100%!important;flex-direction:row!important;overflow-x:auto}\n  .cfg>nav .nv{width:auto;white-space:nowrap}\n}\n/* ── iPhone: dock flotante de cristal ── */\n.scr .tabs{position:absolute;left:14px;right:14px;bottom:18px;height:64px;padding:0 6px;border:1px solid rgba(16,17,19,.06);border-radius:32px;background:rgba(255,255,255,.82);-webkit-backdrop-filter:blur(24px) saturate(1.6);backdrop-filter:blur(24px) saturate(1.6);box-shadow:0 14px 34px rgba(16,17,19,.16);align-items:center;gap:2px;z-index:6;animation:dockin .6s var(--ease) .15s both}\n.scr .tab{height:52px;padding:0;justify-content:center;border-radius:26px;gap:2px;font-size:11px}\n.scr .tab.on{background:#2B2E33;color:#fff;box-shadow:0 6px 14px rgba(43,46,51,.25)}\n.scr .tab.on::before{display:none}\n.scr .tb{top:3px}\n@keyframes dockin{from{opacity:0;transform:translateY(24px)}to{opacity:1;transform:none}}\n@media (prefers-reduced-motion:reduce){*,*::before,*::after{animation:none!important;transition:none!important}}\n'
import re as _re
CSS_B = _re.sub(r'(\d+)\.5px', lambda m: str(int(m.group(1)) + 1) + 'px', CSS_B)


def doc(title, w, h, body):
    import gen
    old = gen.CSS
    gen.CSS = CSS_B
    try:
        return doc_base(title, w, h, body)
    finally:
        gen.CSS = old


# ───────── iconos ─────────
IC = {
    'inicio': rr(3.5, 3.5, 7, 7, 2) + rr(13.5, 3.5, 7, 7, 2) + rr(3.5, 13.5, 7, 7, 2) + rr(13.5, 13.5, 7, 7, 2),
    'robots': rr(4, 4, 16, 6.5, 2) + rr(4, 13.5, 16, 6.5, 2) + 'M7.5 7.25h.01 M7.5 16.75h.01 M11 7.25h5 M11 16.75h5',
    'cuentas': rr(3.5, 6, 17, 13, 3) + 'M3.5 10h17 M15.5 14.5h2',
    'metodos': 'M4 20h16 M5.5 15.5l4-4 3.5 3 5.5-6 M14.5 8.5h4v4',
    'avisos': 'M6 16.5V11a6 6 0 0 1 12 0v5.5l1.5 2h-15z M10 20.5a2 2 0 0 0 4 0',
    'asesor': ci(12, 12, 9) + 'M15.6 8.4 13.4 13.4 8.4 15.6 10.6 10.6z M12 3v1.6 M12 19.4V21 M3 12h1.6 M19.4 12H21',
    'informe': 'M7 3.5h7l4 4V20a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V4.5a1 1 0 0 1 1-1z M14 3.5V8h4 M9 13h6 M9 16.5h6',
    'ajustes': 'M4 7h8 M16 7h4 M4 12h3 M11 12h9 M4 17h11 M19 17h1' + ci(14, 7, 2) + ci(9, 12, 2) + ci(17, 17, 2),
    'parar': rr(6.5, 6.5, 11, 11, 2.5),
    'check': 'M5 12.5l4.5 4.5L19 7.5',
    'bang': 'M12 6v7 M12 17.5h.01',
    'bell': 'M6 16.5V11a6 6 0 0 1 12 0v5.5l1.5 2h-15z M10 20.5a2 2 0 0 0 4 0',
    'lock': rr(5, 11, 14, 9, 2.5) + 'M8.5 11V8.5a3.5 3.5 0 0 1 7 0V11',
    'phone': rr(7, 3, 10, 18, 2.5) + 'M11 18h2',
    'mac': rr(3, 4.5, 18, 12, 2) + 'M8 20h8 M12 16.5V20',
    'sun': ci(12, 12, 4) + 'M12 3v2 M12 19v2 M3 12h2 M19 12h2 M5.6 5.6 7 7 M17 17l1.4 1.4 M5.6 18.4 7 17 M17 7l1.4-1.4',
}

# ───────── datos llanos (una sola vez) ─────────
ROBOTS = [  # nombre, cuenta, estado, % hoy, serie 14 días
    ('Londres 1', 'Fondeo A · 100k', 'bien', '−0,6 %', [0, .2, .1, .4, .3, .6, .5, .9, .7, 1.1, .9, 1.0, .5, -.6]),
    ('Londres 2', 'Fondeo B · 50k', 'atento', '−1,9 %', [0, .3, .2, .5, .6, .9, .8, 1.2, 1.1, 1.5, 1.3, 1.2, 1.0, -.9]),
    ('Londres 3', 'Cuenta real', 'revisar', '+0,3 %', [0, .1, .2, .1, .3, .2, .4, .3, .5, .4, .6, .5, .6, .9]),
    ('Demo', 'Cuenta demo', 'bien', '+0,5 %', [0, .2, .1, .3, .5, .4, .7, .6, .9, 1.0, 1.2, 1.1, 1.4, 1.9]),
    ('Londres 4', 'Fondeo A · 25k', 'parado', '0,0 %', [0, .1, .2, .1, .3, .3, .3, .3, .3, .3, .3, .3, .3, .3]),
]
EST = {'bien': ('Bien', 'sg', '#5FA800'), 'atento': ('Atento', 'so', '#E89B00'), 'revisar': ('Revisar', 'sr', '#F2465E'), 'parado': ('Parado', 'sn', '#B5B5AE')}
MET = [('Impulso', '#7A5AF8'), ('Rebote', '#00A3A3'), ('Tendencia', '#D444F1')]

# ───────── gráficas SVG ─────────

def spark(vals, w=160, h=40, color='#5FA800', fill=True, sw=2.4, dot=True):
    lo, hi = min(vals), max(vals)
    sp = (hi - lo) or 1
    pts = [(3 + i * (w - 6) / (len(vals) - 1), h - 4 - (v - lo) / sp * (h - 8)) for i, v in enumerate(vals)]
    line = ' '.join('%.1f,%.1f' % p for p in pts)
    out = '<svg viewBox="0 0 %d %d" style="width:100%%;height:%dpx;display:block" aria-hidden="true" preserveAspectRatio="none">' % (w, h, h)
    if fill:
        out += '<path class="fadein" d="M%.1f,%d L%s L%.1f,%d Z" fill="%s" fill-opacity=".1"/>' % (pts[0][0], h, ' L'.join('%.1f,%.1f' % p for p in pts), pts[-1][0], h, color)
    out += '<polyline class="draw" pathLength="1" points="%s" fill="none" stroke="%s" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round"/>' % (line, color, sw)
    if dot:
        out += '<circle class="fadein" style="animation-delay:1.2s" cx="%.1f" cy="%.1f" r="3.5" fill="%s"/>' % (pts[-1][0], pts[-1][1], color)
    return out + '</svg>'


def hourly(w=620, h=250):
    vals = [.02, -.01, .03, .01, 0, -.02, .01, .04, -.08, -.12, -.19]
    hrs = ['8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18']
    mid, sc = h / 2 - 8, 380
    slot = (w - 20) / len(vals)
    o = '<svg viewBox="0 0 %d %d" role="img" aria-label="Resultado de cada hora de hoy" style="width:100%%;height:auto;display:block"><line x1="10" y1="%.1f" x2="%d" y2="%.1f" stroke="#E3E5E8"/>' % (w, h, mid, w - 10, mid)
    acc, pts = 0, []
    for i, v in enumerate(vals):
        x = 10 + slot * i + slot * .2
        bh = max(2, abs(v) * sc)
        y = mid - bh if v >= 0 else mid
        o += '<rect class="%s" style="animation-delay:%.2fs" x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="4" fill="%s"/>' % ('grow' if v >= 0 else 'growd', .1 + i * .05, x, y, slot * .6, bh, '#5FA800' if v >= 0 else '#F2465E')
        acc += v
        pts.append('%.1f,%.1f' % (x + slot * .3, mid - acc * sc))
        o += '<text x="%.1f" y="%d" text-anchor="middle" font-size="11" fill="#6B7078">%s h</text>' % (x + slot * .3, h - 6, hrs[i])
    o += '<polyline class="draw" style="animation-delay:.6s" pathLength="1" points="%s" fill="none" stroke="#3A3D42" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>' % ' '.join(pts)
    return o + '</svg>'


def gauge(pct, label, w=260, h=170, color='#5FA800', sub=''):
    cx, cy, r = w / 2, h - 30, 92
    def pt(p):
        a = math.pi * (1 - p)
        return cx + r * math.cos(a), cy - r * math.sin(a)
    x0, y0 = pt(0); x1, y1 = pt(1); xv, yv = pt(pct / 100)
    o = '<svg viewBox="0 0 %d %d" role="img" aria-label="%s" style="width:100%%;height:auto;display:block">' % (w, h, label)
    o += '<path d="M%.1f %.1f A%d %d 0 0 1 %.1f %.1f" fill="none" stroke="#EBEBE6" stroke-width="18" stroke-linecap="round"/>' % (x0, y0, r, r, x1, y1)
    o += '<path class="draw" pathLength="1" d="M%.1f %.1f A%d %d 0 0 1 %.1f %.1f" fill="none" stroke="%s" stroke-width="18" stroke-linecap="round"/>' % (x0, y0, r, r, xv, yv, color)
    o += '<text x="%d" y="%d" text-anchor="middle" font-size="40" font-weight="700" fill="#2B2E33">%d %%</text>' % (cx, cy - 8, pct)
    o += '<text x="%d" y="%d" text-anchor="middle" font-size="13" fill="#6B7078">%s</text>' % (cx, cy + 16, sub or label)
    return o + '</svg>'


def mix(a, b, t):
    t = max(0, min(1, t))
    ca = [int(a[i:i + 2], 16) for i in (1, 3, 5)]; cb = [int(b[i:i + 2], 16) for i in (1, 3, 5)]
    return '#%02X%02X%02X' % tuple(round(x + (y - x) * t) for x, y in zip(ca, cb))


DAYS = [  # 5 semanas × 5 días, % del día
    [.1, .3, -.2, .4, .2], [-.1, .2, .5, -.3, .1], [.3, -.4, .2, .6, .1], [.2, .1, -.1, .4, -.2], [.1, .5, .3, -.31, 0]]


def calendar(w=520, cell=62, gap=8, labels=True):
    heads = ['L', 'M', 'X', 'J', 'V']
    left = 74 if labels else 10
    h = 26 + 5 * (cell + gap)
    o = '<svg viewBox="0 0 %d %d" role="img" aria-label="Resultado de cada día de las últimas cinco semanas" style="width:100%%;height:auto;display:block">' % (w, h)
    for j, t in enumerate(heads):
        o += '<text x="%d" y="14" text-anchor="middle" font-size="12" fill="#6B7078">%s</text>' % (left + j * (cell + gap) + cell / 2, t)
    wk = ['27 oct', '3 nov', '10 nov', '17 nov', '24 nov']
    for i, row in enumerate(DAYS):
        y = 26 + i * (cell + gap)
        if labels:
            o += '<text x="0" y="%d" font-size="12" fill="#6B7078">%s</text>' % (y + cell / 2 + 4, wk[i])
        for j, v in enumerate(row):
            c = mix('#EEF0F2', '#5FA800', v / .6) if v >= 0 else mix('#EEF0F2', '#F2465E', -v / .4)
            txt = '#fff' if abs(v) > .35 else '#2B2E33'
            o += '<rect class="pop" style="animation-delay:%.2fs" x="%d" y="%d" width="%d" height="%d" rx="10" fill="%s"/><text x="%d" y="%d" text-anchor="middle" font-size="12" font-weight="600" fill="%s">%s</text>' % (
                .05 + (i * 5 + j) * .03, left + j * (cell + gap), y, cell, cell, c, left + j * (cell + gap) + cell / 2, y + cell / 2 + 4, txt, ('+' if v > 0 else '−' if v < 0 else '') + ('%.1f' % abs(v)).replace('.', ','))
    return o + '</svg>'


def thermo(frac, goal_label, w=240, color='#3A3D42', mark=None):
    o = '<div style="position:relative;height:12px;border-radius:6px;background:#EBEBE6"><div class="fillx" style="height:12px;border-radius:6px;width:%d%%;background:%s"></div>' % (round(frac * 100), color)
    if mark:
        o += '<div style="position:absolute;top:-3px;left:%d%%;width:2px;height:18px;background:#E89B00"></div>' % round(mark * 100)
    return o + '</div>'


def waterfall(w=560, h=260):
    items = [('Fondeo A 100k', 420), ('Fondeo B 50k', 210), ('Fondeo A 25k', 0), ('Real', 64), ('Demo', 159)]
    total = sum(v for _, v in items)
    sc, base = 0.36, 210
    o = '<svg viewBox="0 0 %d %d" role="img" aria-label="Lo que aporta cada cuenta esta semana, total 853 euros" style="width:100%%;height:auto;display:block">' % (w, h)
    slot = (w - 20) / (len(items) + 1)
    run = 0
    for i, (n, v) in enumerate(items):
        x = 10 + i * slot + slot * .15
        y0 = base - run * sc
        y1 = base - (run + v) * sc
        top = min(y0, y1); hh = max(3, abs(y1 - y0))
        o += '<rect class="pop" style="animation-delay:%.2fs" x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="6" fill="%s"/>' % (.1 + i * .12, x, top, slot * .7, hh, '#5FA800' if v > 0 else '#C9CDD2')
        o += '<text x="%.1f" y="%.1f" text-anchor="middle" font-size="12" font-weight="700" fill="#2B2E33">%s</text>' % (x + slot * .35, top - 6, ('+%d €' % v) if v else '0 €')
        o += '<text x="%.1f" y="%d" text-anchor="middle" font-size="11" fill="#6B7078">%s</text>' % (x + slot * .35, h - 8, n)
        run += v
    x = 10 + len(items) * slot + slot * .15
    o += '<rect class="grow" style="animation-delay:.75s" x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="6" fill="#3A3D42"/>' % (x, base - total * sc, slot * .7, total * sc)
    o += '<text x="%.1f" y="%.1f" text-anchor="middle" font-size="12" font-weight="700" fill="#2B2E33">+%d €</text><text x="%.1f" y="%d" text-anchor="middle" font-size="11" fill="#6B7078">Total</text>' % (x + slot * .35, base - total * sc - 6, total, x + slot * .35, h - 8)
    return o + '<line x1="10" y1="%d" x2="%d" y2="%d" stroke="#E3E5E8"/></svg>' % (base, w - 10, base)


def histogram(w=520, h=230):
    bins = [('−30', 2), ('−20', 5), ('−10', 14), ('0', 22), ('10', 30), ('20', 20), ('30', 11), ('40', 6)]
    mx = max(b for _, b in bins)
    slot = (w - 20) / len(bins)
    o = '<svg viewBox="0 0 %d %d" role="img" aria-label="Cuántas operaciones acaban en cada rango de euros" style="width:100%%;height:auto;display:block">' % (w, h)
    for i, (n, c) in enumerate(bins):
        bh = c / mx * 150
        x = 10 + i * slot + 3
        o += '<rect class="grow" style="animation-delay:%.2fs" x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="5" fill="%s"/>' % (.1 + i * .05, x, 176 - bh, slot - 6, bh, '#F2465E' if i < 3 else '#5FA800')
        o += '<text x="%.1f" y="%.1f" text-anchor="middle" font-size="11" font-weight="600" fill="#2B2E33">%d</text>' % (x + (slot - 6) / 2, 170 - bh, c)
        o += '<text x="%.1f" y="196" text-anchor="middle" font-size="11" fill="#6B7078">%s €</text>' % (x + (slot - 6) / 2, n)
    o += '<line x1="10" y1="176" x2="%d" y2="176" stroke="#E3E5E8"/>' % (w - 10)
    return o + '<text x="%d" y="220" text-anchor="middle" font-size="12" fill="#6B7078">Resultado de cada operación</text></svg>' % (w / 2)


def underwater(w=520, h=200):
    dd = [0, 0, -.1, -.3, -.2, 0, 0, -.4, -.9, -1.4, -1.1, -.7, -.3, 0, 0, -.2, -.5, -.3, 0, -.1, -.4, -.31]
    n = len(dd)
    pts = [(14 + i * (w - 28) / (n - 1), 34 + (-v) / 2.0 * 120) for i, v in enumerate(dd)]
    o = '<svg viewBox="0 0 %d %d" role="img" aria-label="Cuánto has bajado desde tu máximo" style="width:100%%;height:auto;display:block">' % (w, h)
    o += '<line x1="10" y1="34" x2="%d" y2="34" stroke="#C9CDD2"/><text x="12" y="24" font-size="11" fill="#6B7078">Máximo</text>' % (w - 10)
    o += '<line x1="10" y1="154" x2="%d" y2="154" stroke="#F2465E" stroke-dasharray="5 4"/><text x="%d" y="148" text-anchor="end" font-size="11" font-weight="700" fill="#C21A36">Límite −2 %%</text>' % (w - 10, w - 12)
    o += '<path class="fadein" d="M%.1f,34 L%s L%.1f,34 Z" fill="#F2465E" fill-opacity=".14"/>' % (pts[0][0], ' L'.join('%.1f,%.1f' % p for p in pts), pts[-1][0])
    o += '<polyline class="draw" pathLength="1" points="%s" fill="none" stroke="#F2465E" stroke-width="2.4" stroke-linejoin="round"/>' % ' '.join('%.1f,%.1f' % p for p in pts)
    o += '<circle cx="%.1f" cy="%.1f" r="4" fill="#F2465E"/>' % pts[-1]
    o += '<text x="12" y="186" font-size="11" fill="#6B7078">hace 30 días</text><text x="%d" y="186" text-anchor="end" font-size="11" fill="#6B7078">hoy</text>' % (w - 12)
    return o + '</svg>'


def streak(rows, w=520, bars=60):
    o = ''
    for name, bad in rows:
        b = ''.join('<span style="flex:1;height:22px;border-radius:2px;background:%s"></span>' % bad.get(i, '#5FA800') for i in range(bars))
        o += '<div style="display:flex;align-items:center;gap:10px"><span style="width:84px;font-size:12px;font-weight:600">%s</span><div style="display:flex;gap:2px;flex:1">%s</div></div>' % (name, b)
    return o


def besthours(w=520, h=210):
    vals = [0, 0, 0, 0, 0, 0, 0, 0, .1, .4, .5, .3, .1, -.1, .2, .3, .2, -.2, -.3, 0, 0, 0, 0, 0]
    slot = (w - 20) / 24
    o = '<svg viewBox="0 0 %d %d" role="img" aria-label="Qué horas del día suelen ir mejor" style="width:100%%;height:auto;display:block"><line x1="10" y1="110" x2="%d" y2="110" stroke="#E3E5E8"/>' % (w, h, w - 10)
    for i, v in enumerate(vals):
        x = 10 + i * slot + 2
        bh = abs(v) * 190
        if bh:
            o += '<rect class="%s" style="animation-delay:%.2fs" x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="3" fill="%s" fill-opacity="%s"/>' % ('grow' if v > 0 else 'growd', i * .03, x, 110 - bh if v > 0 else 110, slot - 4, bh, '#5FA800' if v > 0 else '#F2465E', '1' if abs(v) >= .3 and v > 0 else '.55')
    o += '<rect x="%.1f" y="22" width="%.1f" height="150" rx="8" fill="none" stroke="#3A3D42" stroke-dasharray="4 3"/><text x="%.1f" y="16" text-anchor="middle" font-size="12" font-weight="700" fill="#2B2E33">Mejor franja · 9 a 11 h</text>' % (10 + 8.7 * slot, slot * 3.4, 10 + 10.4 * slot)
    for hh in (0, 6, 12, 18, 23):
        o += '<text x="%.1f" y="196" text-anchor="middle" font-size="11" fill="#6B7078">%d h</text>' % (10 + hh * slot + slot / 2, hh)
    return o + '</svg>'


def fan(w=560, h=240):
    def Y(v): return 24 + (8 - v) * 17
    def X(d): return 14 + d * (w - 28) / 30
    up, lo, med = [], [], []
    for d in range(31):
        m = 3.2 + 3.2 * (1 - math.exp(-d / 9)); s = .62 * math.sqrt(d)
        up.append('%.1f,%.1f' % (X(d), Y(m + 1.28 * s))); lo.append('%.1f,%.1f' % (X(d), Y(m - 1.28 * s))); med.append('%.1f,%.1f' % (X(d), Y(m)))
    o = '<svg viewBox="0 0 %d %d" role="img" aria-label="Probabilidad de llegar al objetivo: 78 por ciento" style="width:100%%;height:auto;display:block">' % (w, h)
    o += '<line x1="10" y1="%.1f" x2="%d" y2="%.1f" stroke="#5FA800" stroke-dasharray="6 4"/><text x="%d" y="%.1f" text-anchor="end" font-size="12" font-weight="700" fill="#3F7300">Objetivo +5 %%</text>' % (Y(5), w - 10, Y(5), w - 12, Y(5) - 6)
    o += '<line x1="10" y1="%.1f" x2="%d" y2="%.1f" stroke="#F2465E" stroke-dasharray="6 4"/><text x="%d" y="%.1f" text-anchor="end" font-size="12" font-weight="700" fill="#C21A36">Límite −8 %%</text>' % (Y(-8), w - 10, Y(-8), w - 12, Y(-8) - 6)
    o += '<path class="fadein" d="M%s L%s Z" fill="#4A4E55" fill-opacity=".1"/>' % (' L'.join(up), ' L'.join(reversed(lo)))
    o += '<polyline class="draw" pathLength="1" points="%s" fill="none" stroke="#4A4E55" stroke-width="2.6"/><circle cx="%.1f" cy="%.1f" r="5" fill="#4A4E55" stroke="#fff" stroke-width="2"/>' % (' '.join(med), X(0), Y(3.2))
    o += '<text x="14" y="%d" font-size="11" fill="#6B7078">hoy</text><text x="%d" y="%d" text-anchor="end" font-size="11" fill="#6B7078">dentro de 30 días</text>' % (h - 6, w - 12, h - 6)
    return o + '</svg>'


def stackweeks(w=520, h=230):
    W = [[0.3, 0.2, -0.1], [0.1, -0.2, 0.4], [0.4, 0.1, 0.2], [-0.2, 0.3, 0.3], [0.2, -0.1, 0.5], [0.3, 0.2, -0.2], [0.1, 0.1, 0.4], [0.2, -0.3, 0.3]]
    lab = ['6 oct', '13', '20', '27', '3 nov', '10', '17', '24']
    slot = (w - 40) / 8; zero = 120; sc = 120
    o = '<svg viewBox="0 0 %d %d" role="img" aria-label="Lo que aporta cada método cada semana" style="width:100%%;height:auto;display:block"><line x1="30" y1="%d" x2="%d" y2="%d" stroke="#C9CDD2"/>' % (w, h, zero, w - 10, zero)
    for i, wk in enumerate(W):
        x = 36 + i * slot + slot * .15; up = dn = zero
        for k, v in enumerate(wk):
            hh = abs(v) * sc
            if v >= 0: up -= hh; y = up
            else: y = dn; dn += hh
            o += '<rect class="pop" style="animation-delay:%.2fs" x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="4" fill="%s" stroke="#fff" stroke-width="1.5"/>' % (.08 + i * .06 + k * .03, x, y, slot * .7, hh, MET[k][1])
        net = sum(wk)
        o += '<text x="%.1f" y="%.1f" text-anchor="middle" font-size="12" font-weight="700" fill="%s">%s</text><text x="%.1f" y="%d" text-anchor="middle" font-size="11" fill="#6B7078">%s</text>' % (
            x + slot * .35, up - 7, '#3F7300' if net >= 0 else '#C21A36', ('+' if net >= 0 else '−') + ('%.1f' % abs(net)).replace('.', ','), x + slot * .35, h - 8, lab[i])
    return o + '</svg>'


def donut(parts, size=120, lw=16, center=''):
    C = 2 * math.pi * (size / 2 - lw / 2 - 2)
    r = size / 2 - lw / 2 - 2
    tot = sum(v for v, _ in parts); off = 0
    o = '<svg class="spinin" viewBox="0 0 %d %d" width="%d" height="%d" aria-hidden="true"><g transform="rotate(-90 %d %d)" fill="none" stroke-width="%d">' % (size, size, size, size, size / 2, size / 2, lw)
    for v, c in parts:
        ln = v / tot * C
        o += '<circle cx="%d" cy="%d" r="%.1f" stroke="%s" stroke-dasharray="%.1f %.1f" stroke-dashoffset="%.1f"/>' % (size / 2, size / 2, r, c, max(0, ln - 2), C - ln + 2, -off)
        off += ln
    o += '</g><text x="%d" y="%d" text-anchor="middle" font-size="22" font-weight="700" fill="#2B2E33">%s</text></svg>' % (size / 2, size / 2 + 8, center)
    return o


# ───────── marcos ─────────
def rail2(active):
    items = [('inicio', 'Inicio', '#4A4E55', 'AInicio.dc.html'), ('robots', 'Robots', '#00A3A3', 'ARobots.dc.html'), ('cuentas', 'Cuentas', '#C08A00', 'ACuentas.dc.html'),
             ('metodos', 'Métodos', '#7A5AF8', 'AMetodos.dc.html'), ('avisos', 'Avisos', '#F2465E', 'AAvisos.dc.html'), ('asesor', 'Asesor', '#D444F1', 'AAsesor.dc.html'),
             ('informe', 'Informe', '#2E90FA', 'AInforme.dc.html')]
    out = '<nav class="dock" aria-label="Secciones">'
    badges = {'avisos': ('3', '#2E90FA'), 'asesor': ('1', '#2E90FA')}
    def item(k, n, c, href, on, tile_bg=None, stroke=None):
        b = ''
        if k in badges:
            b = '<span style="position:absolute;top:1px;right:1px;min-width:17px;height:17px;padding:0 4px;border-radius:9px;background:%s;color:#fff;font-size:11px;font-weight:700;display:flex;align-items:center;justify-content:center;border:2px solid #fff">%s</span>' % (badges[k][1], badges[k][0])
        bar = ''
        return ('<a class="ri%s%s" href="%s" data-t="%s" aria-label="%s" style="position:relative;width:44px;height:44px;border-radius:13px;background:%s;display:flex;align-items:center;justify-content:center;flex:none">%s'
                '<svg viewBox="0 0 24 24" width="26" height="26" aria-hidden="true"><path d="%s" fill="%s" stroke="%s" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>%s</a>'
                % (' stop' if k == 'parar' else '', ' on' if on else '', href, n, n, tile_bg or 'transparent', bar, IC[k], 'none' if not tile_bg else '#fff', stroke or (c if on else '#8A8A84'), b))
    for k, n, c, href in items:
        out += item(k, n, c, href, k == active)
    out += '<div class="sep"></div>'
    out += item('ajustes', 'Ajustes', '#8A8A84', 'AConfig.dc.html', active == 'ajustes')
    out += '<div class="sep"></div>'
    out += item('parar', 'Parar todo', '#C9CDD2', 'AInicio.dc.html', False, stroke='#B5B5AE')
    return out + '</nav>'


def mac2(active, title, sub, main, right=''):
    head = ('<div style="display:flex;align-items:center;justify-content:space-between;min-height:40px"><div class="d" style="font-size:30px;font-weight:700;line-height:1.1">%s</div>'
            '<div style="display:flex;gap:10px;align-items:center"><span class="live"><i></i>En vivo</span>%s</div></div>' % (title, right))
    return ('<div class="win">\n  <div class="tl"><span style="background:#FF5F57"></span><span style="background:#FEBC2E"></span><span style="background:#28C840"></span></div>\n'
            '  <div class="rail">%s</div>\n  <main class="main" style="padding-top:26px;gap:14px">%s%s</main>\n</div>' % (rail2(active), head, main))


def card(inner, style=''):
    return '<div class="card" style="padding:16px;display:flex;flex-direction:column;gap:10px;%s">%s</div>' % (style, inner)


def big(v, size=34, color='#2B2E33'):
    return '<span class="d tn" style="font-size:%dpx;font-weight:700;color:%s;line-height:1.1">%s</span>' % (size, color, v)


def row_robot(n, acc, st, d):
    lab, pc, col = EST[st]
    dc = '#C21A36' if d.startswith('−') else ('#3F7300' if d.startswith('+') else '#6B7078')
    return ('<div class="hov" style="display:flex;align-items:center;gap:12px;padding:9px 6px;margin:0 -6px;border-top:1px solid #EFEFEA"><span style="width:10px;height:10px;border-radius:50%%;background:%s;flex:none"></span>'
            '<div style="flex:1"><div style="font-weight:600;font-size:14px">%s</div><div class="t2" style="font-size:12px">%s</div></div>%s<span class="tn" style="width:64px;text-align:right;font-weight:700;color:%s">%s</span></div>' % (col, n, acc, pill(lab, pc), dc, d))


def alert_row(level, title, sub, time, btn=None):
    c = {'u': '#F2465E', 'a': '#E89B00', 'h': '#2E90FA'}[level]
    ic = IC['bang'] if level != 'h' else IC['check']
    b = '<a class="btn" href="AAvisos.dc.html" style="height:30px;padding:0 14px;font-size:13px;font-weight:600">%s</a>' % btn if btn else ''
    return ('<div class="hov" style="display:flex;align-items:center;gap:12px;padding:10px 6px;margin:0 -6px;border-top:1px solid #EFEFEA"><span class="%s" style="width:28px;height:28px;border-radius:50%%;background:%s;display:flex;align-items:center;justify-content:center;flex:none">'
            '<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="#fff" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="%s"/></svg></span>'
            '<div style="flex:1;min-width:0"><div style="font-weight:600;font-size:14px">%s</div><div class="t2" style="font-size:12px">%s</div></div>%s<span class="t2 tn" style="font-size:12px;width:40px;text-align:right">%s</span></div>' % ('pulse' if level == 'u' else '', c, ic, title, sub, b, time))


def toggle(on=True):
    return '<span class="tg" style="width:42px;height:24px;border-radius:12px;background:%s;position:relative;flex:none;display:inline-block"><span style="position:absolute;top:2px;%s:2px;width:20px;height:20px;border-radius:50%%;background:#fff;box-shadow:0 1px 2px rgba(0,0,0,.25)"></span></span>' % ('#3A3D42' if on else '#D8D8D2', 'right' if on else 'left')


def setrow(label, sub, ctrl):
    return '<div class="hov" style="display:flex;align-items:center;gap:12px;padding:11px 6px;margin:0 -6px;border-top:1px solid #EFEFEA"><div style="flex:1"><div style="font-size:14px;font-weight:500">%s</div>%s</div>%s</div>' % (label, ('<div class="t2" style="font-size:12px">%s</div>' % sub) if sub else '', ctrl)


def lbl(t, c='#6B7078'):
    return '<div style="font-size:13px;font-weight:600;color:%s">%s</div>' % (c, t)


# ───────── pantallas Mac ─────────
def a_inicio():
    banner = ('<div style="display:flex;align-items:center;gap:12px;background:#FDF1D6;border-radius:16px;padding:12px 16px"><span style="width:28px;height:28px;border-radius:50%%;background:#E89B00;display:flex;align-items:center;justify-content:center">'
              '<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="#fff" stroke-width="3" stroke-linecap="round"><path d="%s"/></svg></span>'
              '<div style="flex:1;font-weight:600;font-size:15px;color:#8F5D00">Todo bajo control. Un robot pide revisión.</div><a class="btn" href="AAvisos.dc.html" style="background:#fff;font-weight:600">Ver aviso</a></div>' % IC['bang'])
    kpi = ''.join([
        card('<div class="kl">Dinero total</div>' + big('213.214 €') + spark([206, 207, 206.5, 208, 207.6, 209, 208.4, 210, 209.3, 211, 210.4, 212, 212.6, 213.2], 200, 36), 'flex:1'),
        card('<div class="kl">Hoy</div>' + big('−0,31 %', 34, '#C21A36') + '<div class="t2" style="font-size:13px">Usado un 16 % del margen</div>' + thermo(.16, '', mark=.75), 'flex:1'),
        card('<div class="kl">Esta semana</div>' + big('+0,4 %', 34, '#3F7300') + '<div class="t2" style="font-size:13px">+853 € · mejor día: miércoles</div>' + spark([0, .1, .15, .3, .25, .4], 200, 26), 'flex:1'),
    ])
    mid = ''.join([
        card(ch('Hoy, hora a hora', 'Barras: cada hora. Línea: suma del día') + hourly(), 'flex:2'),
        card(ch('Margen del día', 'Cuánto queda antes del límite') + gauge(16, 'Margen usado', sub='del margen de hoy'), 'flex:1;align-items:stretch'),
    ])
    bot = ''.join([
        card(ch('Robots', 'Estado de cada uno') + ''.join(row_robot(*r[:4]) for r in ROBOTS), 'flex:1'),
        card(ch('Avisos', 'Lo que pide atención') + alert_row('u', 'Operación sin protección', 'Londres 3 · cuenta real', '09:58', 'Revisar') + alert_row('a', 'Fondeo B al 47 % del límite', 'Londres 2', '10:31', 'Entendido') + alert_row('a', 'Hora del bróker desfasada', 'Londres 1', '10:12', 'Entendido'), 'flex:1'),
    ])
    main = banner + '<section style="display:flex;gap:14px">%s</section><section style="display:flex;gap:14px">%s</section><section style="display:flex;gap:14px">%s</section>' % (kpi, mid, bot)
    return mac2('inicio', 'Buenos días', 'jueves 26 nov · 10:42', main, '<span class="seg"><span class="on">Hoy</span><span>Semana</span><span>Mes</span></span>')


def a_robots():
    cards = ''
    for n, acc, st, d, ser in ROBOTS:
        lab, pc, col = EST[st]
        dc = '#C21A36' if d.startswith('−') else ('#3F7300' if d.startswith('+') else '#6B7078')
        sc = '#5FA800' if st in ('bien',) else ('#E89B00' if st == 'atento' else ('#F2465E' if st == 'revisar' else '#B5B5AE'))
        btn = 'Reanudar' if st == 'parado' else 'Pausar'
        cards += card('<div style="display:flex;align-items:center;gap:10px">%s<div style="flex:1"><div style="font-weight:700;font-size:16px">%s</div><div class="t2" style="font-size:12px">%s</div></div>%s</div>' % (tile(IC['robots'], col, 34, 10), n, acc, pill(lab, pc)) +
                      '<div style="display:flex;align-items:flex-end;justify-content:space-between"><div>%s<div class="t2" style="font-size:12px">hoy</div></div><div style="width:150px">%s</div></div>' % (big(d, 28, dc), spark(ser, 150, 38, sc, True, 2.2)) +
                      '<div style="border-top:1px solid #EFEFEA;padding-top:10px;display:flex;justify-content:space-between;align-items:center"><span class="t2" style="font-size:12px">Últimos 14 días</span><a class="btn" href="ARobots.dc.html" style="height:28px;padding:0 12px;font-size:13px;font-weight:600">%s</a></div>' % btn)
    sumcard = card(ch('Resumen', 'Cuántos hay en cada estado') + '<div style="display:flex;align-items:center;gap:16px">%s<div style="display:flex;flex-direction:column;gap:6px;font-size:13px">%s</div></div>' % (
        donut([(2, '#5FA800'), (1, '#E89B00'), (1, '#F2465E'), (1, '#C9CDD2')], 112, 16, '5'),
        ''.join('<div><span style="color:%s">●</span> %s · %d</div>' % (c, t, v) for t, v, c in (('Bien', 2, '#5FA800'), ('Atento', 1, '#E89B00'), ('Revisar', 1, '#F2465E'), ('Parado', 1, '#B5B5AE')))))
    grid = '<section style="display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:14px">%s%s</section>' % (cards, sumcard)
    rows = streak([(r[0], {41: '#E89B00'} if i == 0 else {12: '#E89B00', 33: '#F2465E', 58: '#E89B00', 59: '#E89B00'} if i == 1 else {22: '#E89B00', 59: '#F2465E'} if i == 2 else {54: '#E89B00'} if i == 3 else {k: '#C9CDD2' for k in range(51, 60)}) for i, r in enumerate(ROBOTS)])
    bottom = '<section style="display:flex;gap:14px">%s%s</section>' % (
        card(ch('Días sin problemas', 'Una barra por día, 60 días. Ámbar: aviso. Rojo: paro. Gris: parado') + '<div style="display:flex;flex-direction:column;gap:9px">%s</div>' % rows, 'flex:3'),
        card(ch('Qué hace cada robot', 'Peso de cada método en cada robot') + ''.join(
            '<div style="display:flex;align-items:center;gap:10px;font-size:12px"><span style="width:70px;font-weight:600">%s</span><div style="display:flex;flex:1;height:14px;border-radius:7px;overflow:hidden;gap:2px">%s</div></div>' % (
                n, ''.join('<span style="flex:%s;background:%s"></span>' % (w, MET[k][1]) for k, w in enumerate(ws) if w))
            for n, ws in (('Londres 1', (1, 1, .5)), ('Londres 2', (0, .5, .5)), ('Londres 3', (0, .5, .5)), ('Demo', (.2, 1, 1))))
            + '<div style="display:flex;gap:12px;font-size:12px" class="t2">%s</div>' % ''.join('<span><span style="color:%s">●</span> %s</span>' % (c, n) for n, c in MET), 'flex:2'))
    return mac2('robots', 'Robots', '', grid + bottom)


def a_cuentas():
    accs = [('Fondeo A · 100k', '101.842 €', .22, 'Bien', 'sg', .12, .19), ('Fondeo B · 50k', '51.600 €', .64, 'Atento', 'so', .48, .15), ('Fondeo A · 25k', '25.090 €', .05, 'Parada', 'sn', 0, .04),
            ('Cuenta real', '12.340 €', .60, 'Revisar', 'sr', 0, .30), ('Cuenta demo', '22.342 €', .60, 'Bien', 'sg', 0, .12)]
    cards = ''
    for n, eq, goal, st, pc, dayu, ddu in accs:
        cards += card('<div style="display:flex;justify-content:space-between;align-items:center"><span style="font-weight:700;font-size:15px">%s</span>%s</div>' % (n, pill(st, pc)) + big(eq, 24) +
                      '<div class="t2" style="font-size:12px">Objetivo</div>' + thermo(goal, '', color='#3A3D42') + '<div class="t2" style="font-size:12px">Margen de hoy</div>' + thermo(dayu, '', color='#E89B00' if dayu > .4 else '#5FA800', mark=.75) +
                      '<div class="t2" style="font-size:12px">Margen total</div>' + thermo(ddu, '', color='#5FA800', mark=.75), 'flex:1;gap:7px')
    rules = ''.join('<div style="display:flex;align-items:center;gap:10px;padding:8px 0;border-top:1px solid #EFEFEA;font-size:13px"><span style="width:10px;height:10px;border-radius:50%%;background:%s"></span><span style="flex:1;font-weight:500">%s</span><span class="tn" style="font-weight:700">%s</span></div>' % r
                    for r in (('#5FA800', 'Objetivo', '3,2 de 5 %'), ('#E89B00', 'Pérdida diaria', '1,9 de 4 %'), ('#5FA800', 'Caída total', '1,2 de 8 %'), ('#5FA800', 'Días mínimos', '12 de 5'), ('#E89B00', 'Constancia', '31 de 40 %'), ('#5FA800', 'Tiempo', '18 de 60 d')))
    bottom = '<section style="display:flex;gap:14px;flex:1">%s%s</section>' % (
        card('<div style="display:flex;justify-content:space-between;align-items:flex-start">%s<div style="text-align:right">%s<div class="t2" style="font-size:12px">de llegar al objetivo</div></div></div>' % (ch('Fondeo B · ¿Llego?', 'Mil simulaciones al ritmo de los últimos 60 días'), big('78 %', 32)) + fan(), 'flex:2'),
        card(ch('Reglas · Fondeo B', 'Verde: bien. Ámbar: atención') + rules, 'flex:1'))
    return mac2('cuentas', 'Cuentas', '5 cuentas · 213.214 € en total', '<section style="display:flex;gap:14px">%s</section>' % cards + bottom)


def a_metodos():
    ms = [('Tendencia', '#D444F1', '+2,4 %', [0, .3, .2, .6, .9, .8, 1.3, 1.6, 1.5, 2.0, 2.4], 'Sigue subidas largas'), ('Impulso', '#7A5AF8', '+1,8 %', [0, .2, .1, .5, .8, .7, 1.2, 1.4, 1.3, 1.7, 1.8], 'Aprovecha arranques'), ('Rebote', '#00A3A3', '+0,9 %', [0, .1, .05, .2, .35, .3, .5, .6, .55, .8, .9], 'Compra caídas rápidas')]
    left = ''.join(card('<div style="display:flex;align-items:center;gap:10px"><span style="width:12px;height:12px;border-radius:4px;background:%s"></span><div style="flex:1"><div style="font-weight:700;font-size:16px">%s</div><div class="t2" style="font-size:12px">%s</div></div>%s</div>' % (c, n, d, big(r, 26, '#3F7300')) + spark(s, 300, 56, c, True, 2.4), 'gap:6px') for n, c, r, s, d in ms)
    heat = ''
    cols = ['Londres 1', 'Londres 2', 'Londres 3', 'Demo']
    W = {'Impulso': ['1,0', '—', '—', 'sombra'], 'Rebote': ['1,0', '0,5', '0,5', '1,0'], 'Tendencia': ['0,5', '0,5', '0,5', '1,0']}
    heat = '<div style="display:flex;gap:6px;padding-left:92px">%s</div>' % ''.join('<span style="flex:1;text-align:center;font-size:12px;color:#6B7078">%s</span>' % c for c in cols)
    for n, vs in W.items():
        cells = ''
        for v in vs:
            ok = v[0].isdigit()
            cells += '<span style="flex:1;height:38px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-weight:600;background:%s;color:%s">%s</span>' % ('#EEF8DC' if ok else '#EBEBE6', '#3F7300' if ok else '#6B7078', v)
        heat += '<div style="display:flex;gap:6px;align-items:center"><span style="width:86px;font-weight:600;font-size:13px">%s</span>%s</div>' % (n, cells)
    right = card(ch('Aporte por semana', 'Lo que suma o resta cada método') + '<div style="display:flex;gap:14px;font-size:12px" class="t2">%s</div>' % ''.join('<span><span style="color:%s">●</span> %s</span>' % (c, n) for n, c in MET) + stackweeks(), 'flex:1')
    right2 = card(ch('Dónde trabaja', 'Peso de cada método en cada robot') + '<div style="display:flex;flex-direction:column;gap:6px">%s</div>' % heat, 'flex:0 0 auto')
    return mac2('metodos', 'Métodos', '3 métodos · últimos 30 días', '<section style="display:flex;gap:14px;flex:1;min-height:0"><div style="width:360px;display:flex;flex-direction:column;gap:14px">%s</div><div style="flex:1;display:flex;flex-direction:column;gap:14px">%s%s</div></section>' % (left, right, right2))


def a_avisos():
    lst = (lbl('Urgente', '#C21A36') + alert_row('u', 'Operación sin protección', 'Londres 3 · cuenta real · paso 2 de 4', '09:58', 'Revisar') +
           '<div style="height:10px"></div>' + lbl('Atención', '#8F5D00') + alert_row('a', 'Fondeo B al 47 % del límite diario', 'Londres 2 · el límite es 4 %', '10:31', 'Entendido') + alert_row('a', 'Hora del bróker desfasada 1,4 s', 'Londres 1', '10:12', 'Entendido') +
           '<div style="height:10px"></div>' + lbl('Hecho') + alert_row('h', 'El asesor bajó Rebote a 0,5', 'Londres 2 · firmado', '08:00') + alert_row('h', 'Prueba de aviso', 'Llegó al móvil en 41 s', 'ayer'))
    bars = ''.join('<div style="display:flex;align-items:center;gap:10px;font-size:13px"><span style="width:70px;font-weight:600">%s</span><div style="flex:1;position:relative;height:12px;border-radius:6px;background:#EBEBE6"><div style="height:12px;border-radius:6px;width:%d%%;background:%s"></div><div style="position:absolute;top:-3px;left:75%%;width:2px;height:18px;background:#E89B00"></div></div><span class="tn" style="width:42px;text-align:right;font-weight:700">%d %%</span></div>' % (n, u, '#3A3D42' if u < 50 else '#E89B00', u)
                   for n, u in (('Orden', 30), ('Método', 40), ('Robot', 47), ('Cuenta', 15), ('Total', 16)))
    right = ('<div style="width:420px;display:flex;flex-direction:column;gap:14px">%s%s</div>' % (
        card(ch('Margen que queda', 'Barra: lo usado. Raya naranja: aviso') + bars + '<div class="t2" style="font-size:12px">Robot sube de 22 % a 47 % desde ayer</div>'),
        card(ch('Exposición', 'Cuánto dinero está en juego ahora') + gauge(18, 'Exposición al 18 %', sub='3,2 de 17,8 lotes', color='#5FA800') + '<div style="text-align:center">' + pill('6 puntos menos que ayer', 'sg') + '</div>')))
    return mac2('avisos', 'Avisos', '1 urgente · 2 de atención', '<section style="display:flex;gap:14px;flex:1;min-height:0">%s%s</section>' % (card(lst, 'flex:1;overflow:hidden'), right), '<a class="btn" href="AAvisos.dc.html">Marcar todo como visto</a>')


def a_asesor():
    P = [('Subir Tendencia · Londres 1', 'Pendiente', 'so', '10:05', True, True), ('Bajar Rebote · Londres 2', 'Hecho', 'sg', '08:00', False, False), ('Activar Impulso · Londres 3', 'No · riesgo', 'sr', 'ayer', False, False),
         ('Bajar Tendencia · Londres 2', 'Hecho', 'sg', '24 nov', False, False), ('Subir Rebote · Demo', 'No · pronto', 'sr', '21 nov', False, False)]
    lst = ''.join('<div class="hov" style="display:flex;align-items:center;gap:10px;padding:11px 12px;border-radius:14px;background:%s"><span style="width:8px;height:8px;border-radius:50%%;background:%s"></span><div style="flex:1;font-weight:600;font-size:14px">%s</div>%s<span class="t2" style="font-size:12px;width:42px;text-align:right">%s</span></div>' % ('#E3E5E8' if sel else 'transparent', '#D444F1' if un else 'transparent', t, pill(s, c), tm) for t, s, c, tm, un, sel in P)
    det = card('<div style="display:flex;align-items:center;gap:10px">' + tile(IC['asesor'], '#D444F1', 36, 11) + '<div class="t2" style="font-size:13px;font-weight:600">El asesor propone · 10:05</div></div><div class="d" style="font-size:28px;font-weight:700;line-height:1.15">Subir Tendencia en Londres 1</div>'
               '<div style="font-size:15px;color:#4A4E55">Va bien, sube con calma y apenas se parece a los otros métodos.</div>'
               '<div style="display:flex;gap:14px;align-items:stretch"><div style="flex:1;background:#F2F2EE;border-radius:14px;padding:14px">%s<div style="display:flex;align-items:center;gap:12px;margin-top:6px">%s<span class="t2">→</span>%s</div></div>'
               '<div style="flex:1;background:#F2F2EE;border-radius:14px;padding:14px">%s<div style="display:flex;align-items:center;gap:12px;margin-top:6px">%s<span class="t2">→</span>%s</div></div></div>' % (
                   lbl('Peso'), big('0,5', 30, '#6B7078'), big('1,0', 30), lbl('Dinero en juego'), big('18 %', 30, '#6B7078'), big('21 %', 30)) +
               ch('Tres opiniones', 'El asesor pregunta tres veces y se queda con la mayoría') +
               '<div style="display:flex;gap:10px">%s</div>' % ''.join('<div style="flex:1;border:1px solid #EFEFEA;border-radius:14px;padding:12px"><div style="display:flex;align-items:center;gap:8px;margin-bottom:4px">%s</div><div class="t2" style="font-size:13px">%s</div></div>' % (pill(v, c), t) for v, c, t in (('Subir', 'sg', 'Tendencia limpia.'), ('Subir', 'sg', 'Poco parecida a Rebote.'), ('Mantener', 'sn', 'Solo 4 operaciones este mes.'))) +
               ch('Si lo aceptas', 'Simulación de los últimos 30 días') + '<svg viewBox="0 0 560 120" style="width:100%;height:auto;display:block" role="img" aria-label="Simulación con y sin el cambio"><polyline points="10,90 80,84 150,88 220,70 290,74 360,56 430,60 500,40 550,34" fill="none" stroke="#C9CDD2" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/><polyline points="10,90 80,82 150,84 220,62 290,64 360,42 430,44 500,22 550,12" fill="none" stroke="#5FA800" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round"/><text x="548" y="30" text-anchor="end" font-size="12" font-weight="700" fill="#3F7300">Con el cambio</text><text x="548" y="52" text-anchor="end" font-size="12" fill="#6B7078">Sin el cambio</text></svg>' +
               '<div style="display:flex;gap:10px;margin-top:auto"><a class="btn p" href="AAsesor.dc.html" style="height:42px;padding:0 24px;font-size:15px;font-weight:600">Aceptar</a><a class="btn" href="AAsesor.dc.html" style="height:42px;padding:0 24px;font-size:15px;font-weight:600">Rechazar</a></div>', 'flex:1;padding:22px;gap:12px')
    return mac2('asesor', 'Asesor', 'Jev · 1 propuesta nueva', '<section style="display:flex;gap:14px;flex:1;min-height:0"><div style="width:420px">%s</div>%s</section>' % (card(ch('Propuestas', 'De la más nueva a la más antigua') + lst, 'gap:4px'), det))


def a_ajustes():
    segs = '<span style="display:flex;background:#EBEBE6;border-radius:10px;padding:3px;gap:2px">%s</span>' % ''.join('<span style="padding:5px 14px;border-radius:8px;font-size:13px;font-weight:600;background:%s;color:%s">%s</span>' % (('#fff', '#2B2E33', t) if on else ('transparent', '#6B7078', t)) for t, on in (('Claro', True), ('Oscuro', False), ('Auto', False)))
    size = ('<div style="display:flex;align-items:center;gap:12px"><span style="font-size:13px">Aa</span><span style="width:200px;position:relative;height:22px;display:flex;align-items:center"><span style="position:absolute;left:0;right:0;height:4px;border-radius:2px;background:#E3E5E8"></span><span style="position:absolute;left:0;width:50%;height:4px;border-radius:2px;background:#3A3D42"></span><span style="position:absolute;left:calc(50% - 10px);width:20px;height:20px;border-radius:50%;background:#fff;box-shadow:0 1px 4px rgba(0,0,0,.3)"></span></span><span style="font-size:20px;font-weight:600">Aa</span></div>')
    dev = lambda ic, n, s, ok: '<div style="display:flex;align-items:center;gap:12px;padding:11px 0;border-top:1px solid #EFEFEA">%s<div style="flex:1"><div style="font-size:14px;font-weight:500">%s</div><div class="t2" style="font-size:12px">%s</div></div>%s</div>' % (tile(IC[ic], '#4A4E55', 34, 10), n, s, pill('Conectado', 'sg') if ok else pill('Sin conexión', 'sn'))
    c1 = card(ch('Avisos', 'Cómo quieres que te avisemos') + setrow('Avisos en el móvil', 'Solo urgentes y de atención', toggle(True)) + setrow('Avisos en el Mac', '', toggle(True)) + setrow('Sonido', 'Solo los urgentes', toggle(False)) + setrow('Resumen diario', 'A las 20:00', toggle(True)), 'gap:0')
    c2 = card(ch('Seguridad', 'Qué hace falta para parar o cambiar algo') + setrow('Confirmar con Face ID', 'Para parar, pausar y aceptar cambios', toggle(True)) + setrow('Tiempo para confirmar', '2 minutos', '<span class="t2">2 min ⌄</span>') + setrow('Bloquear al cerrar', '', toggle(True)), 'gap:0')
    c3 = card(ch('Dispositivos', 'Dónde puedes ver y parar') + dev('mac', 'Mac', 'Este equipo · puede todo', True) + dev('phone', 'iPhone', 'Puede ver y parar', True) + dev('mac', 'Mac de la oficina', 'Visto hace 3 días', False), 'gap:0')
    c4 = card(ch('Apariencia', 'Cómo se ve la app') + setrow('Tema', '', segs) + setrow('Tamaño de letra', 'Para leer mejor', size) + setrow('Números grandes', 'En el inicio', toggle(True)), 'gap:0')
    c5 = card(ch('Datos', 'De dónde salen los números') + setrow('Conexión', 'Actualizado hace 2 s', pill('En vivo', 'sg')) + setrow('Modo demostración', 'Usa datos de ejemplo', toggle(True)) + setrow('Exportar informes', 'PDF y hoja de cálculo', '<a class="btn" href="AInforme.dc.html" style="font-weight:600">Exportar</a>'), 'gap:0')
    c6 = card(ch('Acerca de', '') + setrow('Versión', '1.0', '<span class="t2">Al día</span>') + setrow('Ayuda', 'Guía corta de 2 minutos', '<a class="btn" href="AAjustes.dc.html" style="font-weight:600">Abrir</a>'), 'gap:0')
    return mac2('ajustes', 'Ajustes', 'Todo en un sitio', '<section style="display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:14px;align-content:start">%s%s%s%s%s%s</section>' % (c1, c2, c3, c4, c5, c6))


def a_informe():
    kp = lambda a, b, c='#2B2E33': '<div style="flex:1;border-left:1px solid #EFEFEA;padding-left:16px"><div class="t2" style="font-size:13px">%s</div>%s</div>' % (a, big(b, 26, c))
    hero = card('<div style="display:flex;align-items:center;gap:30px"><div><div class="t2" style="font-size:14px;font-weight:600">Semana del 17 al 24 de noviembre</div>%s<div class="t2" style="font-size:14px">+0,4 %% · bastante estable</div></div>%s%s%s%s</div>' % (
        big('+853 €', 46, '#3F7300'), kp('Mejor día', 'Miércoles', '#2B2E33'), kp('Peor día', 'Jueves −0,3 %', '#C21A36'), kp('Acierto', '57 %'), kp('Operaciones', '142')))
    cal = card(ch('Día a día', 'Resultado de cada día, 5 semanas') + calendar(), 'flex:1')
    wat = card(ch('Qué cuenta aportó', 'Lo que suma cada cuenta esta semana') + waterfall(), 'flex:1')
    his = card(ch('Cómo acaban las operaciones', 'Cuántas acaban en cada rango') + histogram(), 'flex:1')
    return mac2('informe', 'Informe', 'Resumen para leer en un minuto', hero + '<section style="display:flex;gap:14px">%s%s</section><section style="display:flex;gap:14px">%s%s</section>' % (cal, wat, his, card(ch('Mejores horas', 'Cuándo suelen salir mejor las operaciones') + besthours(), 'flex:1')), '<a class="btn p" href="AInforme.dc.html">Compartir</a>')


# ───────── iPhone ─────────
def tabs2(on):
    items = [('inicio', 'Inicio', 'AMInicio.dc.html'), ('cuentas', 'Cuentas', 'AMCuenta.dc.html'), ('avisos', 'Avisos', 'AMAvisos.dc.html'), ('asesor', 'Asesor', 'AMAsesor.dc.html'), ('informe', 'Informe', 'AMInforme.dc.html')]
    o = '<nav class="tabs" aria-label="Secciones">'
    for i, (k, n, href) in enumerate(items):
        b = '<span class="tb" style="background:#2E90FA">3</span>' if k == 'avisos' else ('<span class="tb" style="background:#2E90FA">1</span>' if k == 'asesor' else '')
        o += '<a class="%s" href="%s"><svg viewBox="0 0 24 24" width="25" height="25" class="g" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="%s"/></svg>%s%s</a>' % ('tab on' if i == on else 'tab', href, IC[k], n, b)
    return o + '</nav>'


def phone2(inner, on):
    return ('<div class="stage"><div class="phone"><div class="scr" style="background:#F2F2EE">\n  <div class="island"></div>\n'
            '  <div style="flex:1;padding:58px 16px 100px;display:flex;flex-direction:column;gap:12px;overflow:hidden">%s</div>\n  %s\n</div></div></div>' % (inner, tabs2(on)))


def ptitle(t, s=None):
    return '<div style="padding:0 4px"><div class="d" style="font-size:34px;font-weight:700;line-height:1.15">%s</div></div>' % t


def pc(inner, style=''):
    return '<div class="pc" style="display:flex;flex-direction:column;gap:8px;%s">%s</div>' % (style, inner)


def m_inicio():
    ban = '<div style="display:flex;align-items:center;gap:10px;background:#FDF1D6;border-radius:14px;padding:11px 14px;font-weight:600;font-size:14px;color:#8F5D00"><svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="#E89B00" stroke-width="3" stroke-linecap="round"><path d="%s"/></svg>Un robot pide revisión</div>' % IC['bang']
    body = (ptitle('Inicio', 'jue 26 nov · 10:42') + ban +
            pc('<div class="kl">Dinero total</div><div style="display:flex;justify-content:space-between;align-items:flex-end">%s%s</div>%s' % (big('213.214 €', 31), pill('+0,4 % semana', 'sg'), spark([206, 207, 206.5, 208, 207.6, 209, 208.4, 210, 209.3, 211, 210.4, 212, 212.6, 213.2], 320, 44))) +
            '<div style="display:flex;gap:12px"><div class="pc" style="flex:1;display:flex;flex-direction:column;gap:6px"><div class="kl">Hoy</div>%s%s</div><div class="pc" style="flex:1;padding:6px 8px">%s</div></div>' % (big('−0,31 %', 24, '#C21A36'), thermo(.16, '', mark=.75), gauge(16, 'Margen usado', 200, 124, sub='del margen')) +
            '<div class="pc" style="padding:2px 16px">%s</div>' % ''.join(row_robot(*r[:4]) for r in ROBOTS[:4]).replace('border-top:1px solid #EFEFEA', 'border-top:1px solid #EFEFEA', 1) +
            '<a class="btn" href="AMInicio.dc.html" style="align-self:center;height:36px;padding:0 16px;font-size:14px;font-weight:600;color:#6B7078;background:transparent;box-shadow:0 0 0 1px #DCDCD6"><svg viewBox="0 0 24 24" width="14" height="14" aria-hidden="true"><rect x="6.5" y="6.5" width="11" height="11" rx="2.5" fill="none" stroke="#8A8A84" stroke-width="2"/></svg>Parar todo</a>')
    return phone2(body, 0)


def m_avisos():
    body = (ptitle('Avisos', '1 urgente') + '<div class="pc" style="padding:4px 16px">%s%s%s%s</div>' % (
        alert_row('u', 'Operación sin protección', 'Londres 3', '09:58', 'Revisar').replace('border-top:1px solid #EFEFEA;', ''), alert_row('a', 'Fondeo B al 47 % del límite', 'Londres 2', '10:31', 'Visto'), alert_row('a', 'Hora del bróker desfasada', 'Londres 1', '10:12', 'Visto'), alert_row('h', 'El asesor bajó Rebote', 'Londres 2', '08:00')) +
            pc(ch('Margen que queda', 'Barra: lo usado') + ''.join('<div style="display:flex;align-items:center;gap:10px;font-size:13px"><span style="width:62px;font-weight:600">%s</span><div style="flex:1;height:10px;border-radius:5px;background:#EBEBE6"><div style="height:10px;border-radius:5px;width:%d%%;background:%s"></div></div><span class="tn" style="width:38px;text-align:right;font-weight:700">%d %%</span></div>' % (n, u, '#3A3D42' if u < 50 else '#E89B00', u) for n, u in (('Orden', 30), ('Método', 40), ('Robot', 47), ('Cuenta', 15), ('Total', 16)))) +
            pc(ch('Exposición', 'Dinero en juego') + gauge(18, 'Exposición', 260, 150, sub='3,2 de 17,8 lotes')))
    return phone2(body, 2)


def m_asesor():
    P = [('Subir Tendencia · Londres 1', 'Va bien y sube con calma', 'Pendiente', 'so', '10:05', True), ('Bajar Rebote · Londres 2', 'Cerca del límite diario', 'Hecho', 'sg', '08:00', False), ('Activar Impulso · Londres 3', 'Mercado favorable', 'No · riesgo', 'sr', 'ayer', False), ('Bajar Tendencia · Londres 2', 'Proteger el límite', 'Hecho', 'sg', '24 nov', False), ('Subir Rebote · Demo', 'Buena racha', 'No · pronto', 'sr', '21 nov', False)]
    rows = ''.join('<div style="display:flex;align-items:flex-start;gap:10px;padding:10px 0;%s"><span style="width:8px;height:8px;border-radius:50%%;margin-top:7px;background:%s;flex:none"></span><div style="flex:1"><div style="font-size:15px;font-weight:600">%s</div><div class="t2" style="font-size:13px">%s</div><div style="margin-top:3px">%s</div></div><span class="t2" style="font-size:12px">%s</span></div>' % ('border-top:1px solid #EFEFEA;' if i else '', '#D444F1' if un else 'transparent', t, s, pill(st, c), tm) for i, (t, s, st, c, tm, un) in enumerate(P))
    body = ptitle('Asesor', 'Aceptar se hace en el Mac') + '<div class="pc" style="padding:2px 16px">%s</div>' % rows
    return phone2(body, 3)


def m_cuenta():
    rules = ''.join('<div style="display:flex;align-items:center;gap:10px;padding:7px 0;font-size:14px"><span style="width:10px;height:10px;border-radius:50%%;background:%s"></span><span style="flex:1">%s</span><b class="tn">%s</b></div>' % r for r in (('#5FA800', 'Objetivo', '3,2 de 5 %'), ('#E89B00', 'Pérdida diaria', '1,9 de 4 %'), ('#5FA800', 'Caída total', '1,2 de 8 %'), ('#5FA800', 'Días mínimos', '12 de 5')))
    body = (ptitle('Fondeo B · 50k', 'Londres 2') +
            pc('<div style="display:flex;justify-content:space-between;align-items:center">%s%s</div><div class="t2" style="font-size:13px">Objetivo</div>%s<div class="t2" style="font-size:13px">Margen de hoy</div>%s' % (big('51.600 €', 30), pill('Atento', 'so'), thermo(.64, ''), thermo(.48, '', color='#E89B00', mark=.75))) +
            pc('<div style="display:flex;justify-content:space-between;align-items:flex-start">%s<div style="text-align:right">%s<div class="t2" style="font-size:11px">llega al objetivo</div></div></div>%s' % (ch('¿Llego?', 'Mil simulaciones'), big('78 %', 26), fan(360, 170))) +
            '<div class="pc" style="padding:6px 16px">%s</div>' % rules)
    return phone2(body, 1)


def m_informe():
    body = (ptitle('Informe', '17 – 24 nov') +
            pc('%s<div class="t2" style="font-size:13px">+0,4 %% · bastante estable</div>' % big('+853 €', 40, '#3F7300')) +
            pc(ch('Día a día', 'Resultado de cada día') + calendar(360, 46, 6, False)) +
            pc(ch('Qué cuenta aportó', 'Suma de la semana') + waterfall(360, 200)))
    return phone2(body, 4)


# ───────── galería de gráficas nuevas ─────────
def galeria():
    def g(t, s, inner, w='1'):
        return '<div class="card" style="padding:18px;display:flex;flex-direction:column;gap:8px;min-width:0"><div style="display:flex;align-items:baseline;gap:8px"><b style="font-size:16px">%s</b><span class="t2" style="font-size:13px">%s</span></div>%s</div>' % (t, s, inner)
    th = '<div style="display:flex;flex-direction:column;gap:14px;padding-top:6px"><div><div style="display:flex;justify-content:space-between;font-size:13px"><b>Objetivo</b><span class="tn">3,2 de 5 %</span></div><div style="height:6px"></div>' + thermo(.64, '') + '</div><div><div style="display:flex;justify-content:space-between;font-size:13px"><b>Margen de hoy</b><span class="tn">48 % usado</span></div><div style="height:6px"></div>' + thermo(.48, '', color='#E89B00', mark=.75) + '</div><div><div style="display:flex;justify-content:space-between;font-size:13px"><b>Caída total</b><span class="tn">15 % usado</span></div><div style="height:6px"></div>' + thermo(.15, '', color='#5FA800', mark=.75) + '</div></div>'
    st = '<div style="display:flex;flex-direction:column;gap:9px;padding-top:6px">' + streak([('Londres 1', {41: '#E89B00'}), ('Londres 2', {12: '#E89B00', 33: '#F2465E'}), ('Londres 3', {22: '#E89B00', 59: '#F2465E'}), ('Demo', {54: '#E89B00'})], bars=45) + '</div>'
    items = [
        g('Calendario', 'Cada día, un color', calendar(440, 52, 8)),
        g('Barras de meta', 'Cuánto falta y cuánto queda', th),
        g('Medidor', 'El dinero en juego ahora', gauge(18, 'Exposición al 18 %', sub='3,2 de 17,8 lotes')),
        g('Cascada', 'Qué suma cada cuenta', waterfall(440, 240)),
        g('Reparto de resultados', 'Cuántas ganan y cuántas pierden', histogram(440, 220)),
        g('Desde el máximo', 'Cuánto has bajado', underwater(440, 200)),
        g('Días sin problemas', 'Una barra por día', st),
        g('Mejores horas', 'Cuándo sale mejor', besthours(440, 210)),
    ]
    body = ('<div class="gal" style="min-height:1100px;background:#F3F3F0;padding:34px 40px 40px;display:flex;flex-direction:column;gap:20px"><div><h1 class="d" style="margin:0;font-size:34px;font-weight:700">Gráficas nuevas</h1><div class="t2" style="font-size:15px">Ocho ideas sencillas, sin jerga. Dime cuáles quedan.</div></div>'
            '<div style="display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:18px">%s</div></div>' % ''.join(items))
    return body


ARTBOARDS = [
    ('AInicio.dc.html', 'Inicio · propuesta', 1440, 900, a_inicio),
    ('ARobots.dc.html', 'Robots · propuesta', 1440, 900, a_robots),
    ('ACuentas.dc.html', 'Cuentas · propuesta', 1440, 900, a_cuentas),
    ('AMetodos.dc.html', 'Métodos · propuesta', 1440, 900, a_metodos),
    ('AAvisos.dc.html', 'Avisos · propuesta', 1440, 900, a_avisos),
    ('AAsesor.dc.html', 'Asesor · propuesta', 1440, 900, a_asesor),
    ('AAjustes.dc.html', 'Ajustes · propuesta', 1440, 900, a_ajustes),
    ('AInforme.dc.html', 'Informe · propuesta', 1440, 900, a_informe),
    ('AMInicio.dc.html', 'iPhone Inicio · propuesta', 470, 920, m_inicio),
    ('AMCuenta.dc.html', 'iPhone Cuenta · propuesta', 470, 920, m_cuenta),
    ('AMAvisos.dc.html', 'iPhone Avisos · propuesta', 470, 920, m_avisos),
    ('AMAsesor.dc.html', 'iPhone Asesor · propuesta', 470, 920, m_asesor),
    ('AMInforme.dc.html', 'iPhone Informe · propuesta', 470, 920, m_informe),
    ('AGraficas.dc.html', 'Gráficas nuevas · propuesta', 1440, 1100, galeria),
]

if __name__ == '__main__':
    for name, title, w, h, fn in ARTBOARDS:
        with open(os.path.join(OUT, name), 'w') as f:
            f.write(doc(title, w, h, fn()))
        print('ok', name)
