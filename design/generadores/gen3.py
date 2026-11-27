#!/usr/bin/env python3
# Configuración (propuesta B): panel tipo «ajustes» con cuentas numeradas desplegables,
# bróker o banco, formulario propio de cada proveedor y claves en el Llavero.
import os, sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen2
from gen2 import IC, CSS_B, mac2, setrow, toggle, pill, ch, tile

EXTRA = r'''
.nv{display:flex;align-items:center;gap:10px;width:100%;height:38px;padding:0 12px;border:0;border-radius:10px;background:transparent;color:#4A4E55;font:500 14px -apple-system,BlinkMacSystemFont,'Inter',sans-serif;cursor:pointer;text-align:left;transition:background .2s var(--ease),color .2s var(--ease)}
.nv:hover{background:#EBEBE6}
.nv.on{background:#fff;color:#2B2E33;font-weight:600;box-shadow:0 1px 2px rgba(16,17,19,.06),0 0 0 1px rgba(16,17,19,.05)}
.nv svg{flex:none}
.pane{flex:1;min-width:0;overflow-y:auto;padding:4px 4px 24px;display:flex;flex-direction:column;gap:14px}
.ptitle{font-size:22px;font-weight:700;letter-spacing:-.02em}
.acc{background:#fff;border-radius:18px;border:1px solid rgba(16,17,19,.06);box-shadow:0 1px 1px rgba(16,17,19,.03),0 4px 14px rgba(16,17,19,.04);transition:box-shadow .3s var(--ease)}
.acc.open{box-shadow:0 0 0 2px #3A3D42,0 12px 30px rgba(16,17,19,.10)}
.acch{display:flex;align-items:center;gap:12px;width:100%;padding:14px 16px;border:0;background:transparent;cursor:pointer;text-align:left;font:inherit;color:inherit;border-radius:18px}
.acch:hover{background:#FAFAF8}
.num{width:26px;height:26px;border-radius:8px;background:#2B2E33;color:#fff;font-size:13px;font-weight:700;display:flex;align-items:center;justify-content:center;flex:none}
.mt{width:34px;height:34px;border-radius:10px;background:#EBEBE6;color:#2B2E33;font-size:12px;font-weight:800;letter-spacing:.02em;display:flex;align-items:center;justify-content:center;flex:none}
.an{font-weight:600;font-size:15px}
.chev{transition:transform .3s var(--ease);flex:none;color:#6B7078}
.chev.up{transform:rotate(180deg)}
.accb{border-top:1px solid #EFEFEA;padding:16px 18px 18px;display:flex;flex-direction:column;gap:16px;animation:rise .45s var(--ease) both}
.fl{font-size:13px;font-weight:600;color:#6B7078}
.fld{display:flex;flex-direction:column;gap:6px}
.in{height:40px;border-radius:11px;border:1px solid #DCDCD6;background:#FAFAF8;padding:0 12px;font:15px -apple-system,BlinkMacSystemFont,'Inter',sans-serif;color:#2B2E33;transition:border-color .2s var(--ease),box-shadow .2s var(--ease)}
.in:focus{outline:none;border-color:#2E90FA;box-shadow:0 0 0 4px rgba(46,144,250,.18);background:#fff}
.sg2{display:inline-flex;background:#E9E9E4;border-radius:11px;padding:3px;gap:2px;align-self:flex-start}
.sg2 button{border:0;background:transparent;padding:6px 16px;border-radius:8px;font:600 13px -apple-system,BlinkMacSystemFont,'Inter',sans-serif;color:#6B7078;cursor:pointer;transition:all .2s var(--ease)}
.sg2 button.on{background:#fff;color:#2B2E33;box-shadow:0 1px 3px rgba(16,17,19,.12)}
.pvs{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:8px}
.pv{display:flex;flex-direction:column;align-items:center;gap:6px;padding:12px 6px;border-radius:14px;border:1px solid #E3E5E8;background:#fff;cursor:pointer;font:600 12px -apple-system,BlinkMacSystemFont,'Inter',sans-serif;color:#2B2E33;transition:all .2s var(--ease)}
.pv:hover{border-color:#C9CDD2;transform:translateY(-1px)}
.pv.on{border-color:#2B2E33;box-shadow:0 0 0 1px #2B2E33;background:#FAFAF8}
.sec{display:flex;align-items:center;gap:10px;height:40px;border-radius:11px;border:1px solid #E3E5E8;background:#F6F6F3;padding:0 6px 0 12px}
.dots{flex:1;font-size:18px;letter-spacing:3px;color:#4A4E55}
.kbadge{display:inline-flex;align-items:center;gap:5px;height:24px;padding:0 9px;border-radius:999px;background:#EEF8DC;color:#3F7300;font-size:12px;font-weight:600;white-space:nowrap}
.sbtn{height:28px;padding:0 11px;border:0;border-radius:999px;background:#fff;box-shadow:0 0 0 1px #E3E5E8;font:600 12px -apple-system,BlinkMacSystemFont,'Inter',sans-serif;color:#2B2E33;cursor:pointer;transition:background .2s var(--ease)}
.sbtn:hover{background:#F2F2EE}
.bb{display:inline-flex;align-items:center;justify-content:center;gap:6px;height:36px;padding:0 16px;border:0;border-radius:999px;background:#EBEBE6;color:#2B2E33;font:600 14px -apple-system,BlinkMacSystemFont,'Inter',sans-serif;cursor:pointer;transition:background .2s var(--ease),transform .12s var(--ease)}
.bb:hover{background:#E1E1DB}.bb:active{transform:scale(.96)}
.bb.p{background:#3A3D42;color:#fff}.bb.p:hover{background:#2B2E33}
.bb.l{background:transparent;color:#C21A36;padding:0 8px}.bb.l:hover{background:#FDE4E8}
.ask{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;background:#E3F0FE;color:#1567C9;font-size:13px;font-weight:600;animation:rise .35s var(--ease) both}
.note{display:flex;gap:10px;align-items:flex-start;padding:12px 14px;border-radius:12px;background:#F2F2EE;font-size:13px;color:#4A4E55}
.ok{display:inline-flex;align-items:center;gap:6px;color:#3F7300;font-weight:600;font-size:13px;animation:rise .35s var(--ease) both}
.vault{display:flex;align-items:center;gap:10px}
.vbox{flex:1;background:#fff;border-radius:14px;border:1px solid #E3E5E8;padding:12px;display:flex;align-items:center;gap:10px;font-size:13px;font-weight:600}
'''

import config_parts as _cp
CSS = CSS_B + EXTRA + _cp.CSS

LOCK = '<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="%s"/></svg>' % IC['lock']
INFO_I = '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="#6B7078" stroke-width="2" stroke-linecap="round" aria-hidden="true" style="flex:none;margin-top:1px"><circle cx="12" cy="12" r="9"/><path d="M12 11v5.5M12 7.6h.01"/></svg>'
FINGER = '<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true"><path d="M7 11a5 5 0 0 1 10 0v2 M9.5 11.5a2.5 2.5 0 0 1 5 0V14c0 2-.6 3.8-1.6 5.2 M12 11.5V14c0 2.4-.8 4.5-2.2 6 M7 13.5c0 1.6-.3 3-1 4.2 M17 15.5c-.2 1.3-.6 2.5-1.2 3.6 M5 8.5A8 8 0 0 1 19 8.5"/></svg>'
CHECK = '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>'


def sel(label, val):
    return '<span class="t2" style="display:inline-flex;align-items:center;gap:6px;font-weight:500">%s<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M7 10l5 5 5-5"/></svg></span>' % val


def box(title, inner):
    return '<div class="card" style="padding:6px 18px 8px;gap:0"><div class="ch" style="padding:12px 0 6px">%s</div>%s</div>' % (title, inner)


static_general = ('<div class="ptitle">General</div>' + box('Idioma y región',
                  setrow('Idioma', '', sel('', 'Español')) + setrow('Moneda', '', sel('', 'Euro (€)')) + setrow('Zona horaria', '', sel('', 'Madrid')) + setrow('Formato de números', '1.234,56', sel('', 'España'))) +
                  box('Al arrancar', setrow('Abrir Mym al iniciar sesión', '', toggle(True)) + setrow('Mostrar en la barra de menús', '', toggle(True)) + setrow('Empezar en', '', sel('', 'Inicio'))))
static_avisos = ('<div class="ptitle">Avisos</div>' + box('Dónde', setrow('En el móvil', 'Urgentes y de atención', toggle(True)) + setrow('En el Mac', '', toggle(True)) + setrow('Por correo', 'Solo el resumen diario', toggle(False))) +
                 box('Cuándo', setrow('Pérdida del día', 'Al llegar al 50 % del límite', sel('', '50 %')) + setrow('Robot parado', '', toggle(True)) + setrow('Clave a punto de caducar', '7 días antes', toggle(True)) + setrow('No molestar', 'De 23:00 a 7:00, salvo urgentes', toggle(True))))
keys = [('Cuenta 2 · Fondeo B', 'Contraseña', 'Guardada el 12 nov', 'sg', 'En el Llavero', 'Borrar'),
        ('Cuenta 3 · Cuenta real', 'Clave de acceso', 'Caduca en 5 días', 'so', 'Renovar pronto', 'Renovar'),
        ('Cuenta 5 · Fondeo A 25k', 'Contraseña', 'Guardada el 3 oct', 'sg', 'En el Llavero', 'Borrar'),
        ('Cuentas 1 y 4 · cTrader', 'Permiso de acceso', 'Se renueva solo', 'sg', 'En el Llavero', 'Quitar'),
        ('Cuenta 6 · Kutxabank', 'Permiso de lectura', 'Quedan 62 días', 'sg', 'En el Llavero', 'Quitar')]
keyrows = ''.join(setrow('<b style="font-weight:600">%s</b> · %s' % (a, b), c, '%s<span class="sbtn" style="display:inline-flex;align-items:center">%s</span>' % (pill(e, d), f)) for a, b, c, d, e, f in keys)
flow = ('<div class="vault">' + ''.join('<div class="vbox">%s%s</div>' % (tile(ic, col, 30, 9), t) + ('<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#C9CDD2" stroke-width="2" aria-hidden="true"><path d="M5 12h14 M13 6l6 6-6 6"/></svg>' if i < 2 else '')
                                    for i, (ic, col, t) in enumerate(((IC['asesor'], '#4A4E55', 'Mym pide la clave'), (IC['lock'], '#3A3D42', 'Llavero cifrado'), (IC['mac'], '#5FA800', 'Solo en este Mac')))) + '</div>')
static_seg = ('<div class="ptitle">Seguridad y claves</div><div class="card" style="padding:16px 18px;gap:12px"><div style="font-size:15px;color:#4A4E55">Tus claves se guardan cifradas en el Llavero de este Mac. No salen del equipo y no se ven sin Touch ID.</div>%s</div>' % flow +
              box('Claves guardadas', keyrows) +
              box('Protección', setrow('Pedir Touch ID para ver o cambiar una clave', '', toggle(True)) + setrow('Bloquear Mym tras 5 minutos sin uso', '', toggle(True)) + setrow('Avisarme 7 días antes de que caduque una clave', '', toggle(True))) +
              '<div><button class="bb l" type="button">Borrar todas las claves</button></div>')
static_apariencia = ('<div class="ptitle">Apariencia</div>' + box('Lista de cuentas', setrow('Vista', 'Compacta para muchas cuentas. Avanzada con más detalle.', _cp.VIEWSEG) + setrow('Agrupar por', '', sel('', 'Bróker o banco'))) + box('Tema', setrow('Aspecto', '', '<span class="seg"><span class="on">Claro</span><span>Oscuro</span><span>Auto</span></span>') + setrow('Movimiento', 'Animaciones al cambiar de pantalla', toggle(True))) +
                     box('Lectura', setrow('Tamaño de letra', 'Para leer mejor', '<span style="display:flex;align-items:center;gap:10px"><span style="font-size:12px">Aa</span><span style="width:160px;height:4px;border-radius:2px;background:linear-gradient(90deg,#3A3D42 50%,#E3E5E8 50%)"></span><span style="font-size:19px;font-weight:600">Aa</span></span>') + setrow('Números grandes en el inicio', '', toggle(True))))
static_datos = ('<div class="ptitle">Datos</div>' + box('Origen', setrow('Conexión', 'Actualizado hace 2 s', pill('En vivo', 'sg')) + setrow('Modo demostración', 'Usa datos de ejemplo', toggle(True))) +
                box('Exportar', setrow('Informe semanal', 'PDF', '<span class="sbtn" style="display:inline-flex;align-items:center">Exportar</span>') + setrow('Todas las operaciones', 'Hoja de cálculo', '<span class="sbtn" style="display:inline-flex;align-items:center">Exportar</span>')))
static_acerca = ('<div class="ptitle">Acerca de</div>' + box('Mym', setrow('Versión', '1.0 · al día', '') + setrow('Guía rápida', 'Dos minutos', '<span class="sbtn" style="display:inline-flex;align-items:center">Abrir</span>')))

import config_parts
cuentas = config_parts.build(INFO_I, LOCK, FINGER, CHECK)

nav = '''<nav aria-label="Configuración" style="width:230px;flex:none;display:flex;flex-direction:column;gap:2px">
<sc-for list="{{nav}}" as="n" hint-placeholder-count="7"><button type="button" class="{{n.cls}}" onClick="{{n.pick}}"><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="{{n.d}}"/></svg>{{n.label}}</button></sc-for>
</nav>'''

pane = '<div class="pane">' + ''.join('<sc-if value="{{is%s}}" hint-placeholder-val="{{ %s }}">%s</sc-if>' % (k, 'true' if k == 'Cuentas' else 'false', v) for k, v in (
    ('General', static_general), ('Cuentas', cuentas), ('Avisos', static_avisos), ('Seguridad', static_seg), ('Apariencia', static_apariencia), ('Datos', static_datos), ('Acerca', static_acerca))) + '</div>'

main = '<section class="cfg" style="display:flex;gap:22px;flex:1;min-height:0">' + nav + pane + '</section>'
body = mac2('ajustes', 'Configuración', 'Cuentas, claves y preferencias', main)

NAVJS = json.dumps([['general', 'General', IC['ajustes']], ['cuentas', 'Cuentas', IC['cuentas']], ['avisos', 'Avisos', IC['avisos']], ['seguridad', 'Seguridad y claves', IC['lock']],
                    ['apariencia', 'Apariencia', IC['sun']], ['datos', 'Datos', IC['informe']], ['acerca', 'Acerca de', 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18z M12 11v5.5 M12 7.6h.01']], ensure_ascii=False)

JS = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'config_logic.js')).read().replace('__NAV__', NAVJS)

html = ('<!doctype html>\n<html lang="es">\n<head>\n<meta charset="utf-8">\n<title>Configuración</title>\n<script src="./support.js"></script>\n</head>\n<body>\n<x-dc>\n<helmet>\n'
        '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">\n<style>\n' + CSS + '\n</style>\n</helmet>\n' + body +
        '\n</x-dc>\n<script type="text/x-dc" data-dc-script data-props=\'{"$preview":{"width":1440,"height":900}}\'>' + JS + '</script>\n</body>\n</html>\n')
open(os.path.join(gen2.OUT, 'AConfig.dc.html'), 'w').write(html)
print('ok AConfig.dc.html', len(html))
