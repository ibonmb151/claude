# Plantilla de «Cuentas» para muchas cuentas: vista compacta (tabla agrupada) y avanzada (tarjetas).

CHEV = '<svg class="chev {{a.chev}}" viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M6 9l6 6 6-6"/></svg>'
TICK = '<svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="#fff" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>'
SEARCH = '<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><circle cx="11" cy="11" r="6.5"/><path d="M16 16l4.5 4.5"/></svg>'

VIEWSEG = '<div class="sg2" role="group" aria-label="Vista de cuentas"><button type="button" class="{{compactCls}}" onClick="{{setCompact}}">Compacta</button><button type="button" class="{{advancedCls}}" onClick="{{setAdvanced}}">Avanzada</button></div>'

CSS = r"""
.fchip{height:32px;padding:0 12px;border:0;border-radius:999px;background:#fff;box-shadow:0 0 0 1px #E3E5E8;font:500 13px -apple-system,BlinkMacSystemFont,'Inter',sans-serif;color:#4A4E55;cursor:pointer;transition:all .2s var(--ease);white-space:nowrap}
.fchip b{font-weight:700;color:#2B2E33;margin-left:2px}
.fchip:hover{background:#F6F6F3}
.fchip.on{background:#2B2E33;color:#fff;box-shadow:none}.fchip.on b{color:#fff}
.bulk{display:flex;align-items:center;gap:8px;padding:10px 12px 10px 16px;border-radius:14px;background:#2B2E33;color:#fff;font-size:14px;animation:rise .3s var(--ease) both}
.bulk .sbtn{box-shadow:none}
.chead{display:flex;align-items:center;gap:12px;padding:0 16px;font-size:12px;font-weight:600;color:#8A8A84}
.grp{background:#fff;border-radius:18px;border:1px solid rgba(16,17,19,.06);box-shadow:0 1px 1px rgba(16,17,19,.03),0 4px 14px rgba(16,17,19,.04);overflow:hidden;flex:none}
.gh{display:flex;align-items:center;gap:10px;padding:10px 16px;font-size:13px;font-weight:700;background:#FAFAF8;border-bottom:1px solid #EFEFEA}
.crow{border-top:1px solid #F1F1EC}
.gh+.crow{border-top:0}
.crow.open{background:#FCFCFA;box-shadow:inset 3px 0 0 #2B2E33}
.crowb{flex:1;min-width:0;display:flex;align-items:center;gap:12px;height:46px;padding:0 16px 0 4px;border:0;background:transparent;cursor:pointer;font:inherit;color:inherit;text-align:left;transition:background .2s var(--ease)}
.crowb:hover{background:#F6F6F3}
.ck{width:22px;height:22px;margin-left:14px;border-radius:7px;border:2px solid #C9CDD2;background:#fff;display:flex;align-items:center;justify-content:center;cursor:pointer;padding:0;flex:none;transition:all .15s var(--ease)}
.ck svg{opacity:0;transition:opacity .15s var(--ease)}
.ck.on{background:#2B2E33;border-color:#2B2E33}.ck.on svg{opacity:1}
.cnum{width:30px;font-size:13px;font-weight:700;color:#6B7078;flex:none}
.mt.sm{width:26px;height:26px;border-radius:8px;font-size:10px}
.cname{flex:1;min-width:0;font-weight:600;font-size:14px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.cprov{width:150px;font-size:13px;flex:none}
.cst{width:110px;flex:none}
.csal{width:100px;text-align:right;font-weight:600;font-size:14px;flex:none}
.clast{width:110px;text-align:right;font-size:12px;flex:none}
.crow .accb{margin:0 16px 14px 50px;border:1px solid #EFEFEA;border-radius:14px;background:#fff}
@media (max-width:1100px){.cprov,.clast{display:none}}
@media (max-width:760px){.csal,.chead{display:none}.crow .accb{margin:0 10px 12px}}
"""


def build(INFO_I, LOCK, FINGER, CHECK):
    detail = '''<sc-if value="{{a.open}}" hint-placeholder-val="{{ false }}">
  <div class="accb">
    <label class="fld"><span class="fl">Nombre</span><input class="in" value="{{a.name}}" onChange="{{a.rename}}"></label>
    <sc-if value="{{a.isNew}}" hint-placeholder-val="{{ false }}">
    <div class="fld"><span class="fl">Empezar igual que</span>
      <div style="display:flex;gap:8px;flex-wrap:wrap"><sc-for list="{{a.templates}}" as="t" hint-placeholder-count="4"><button type="button" class="sbtn" style="height:32px;padding:0 14px" onClick="{{t.pick}}">{{t.n}}</button></sc-for></div>
      <span class="t2" style="font-size:12px">Copia el tipo, el proveedor y el servidor. Las claves no se copian nunca.</span>
    </div>
    </sc-if>
    <div class="fld"><span class="fl">Qué vas a conectar</span>
      <div class="sg2" role="group" aria-label="Tipo"><button type="button" class="{{a.brokerCls}}" onClick="{{a.setBroker}}">Bróker</button><button type="button" class="{{a.bankCls}}" onClick="{{a.setBank}}">Banco</button></div>
    </div>
    <sc-if value="{{a.hasType}}" hint-placeholder-val="{{ true }}">
    <div class="fld"><span class="fl">{{a.provTitle}}</span>
      <div class="pvs"><sc-for list="{{a.providers}}" as="p" hint-placeholder-count="5"><button type="button" class="{{p.cls}}" onClick="{{p.pick}}"><span class="mt" style="background:{{p.bg}};color:{{p.fg}}">{{p.m}}</span>{{p.n}}</button></sc-for></div>
    </div>
    </sc-if>
    <sc-if value="{{a.noProv}}" hint-placeholder-val="{{ false }}"><div class="note">''' + INFO_I + '''<span>{{a.emptyHint}}</span></div></sc-if>
    <sc-for list="{{a.fields}}" as="f" hint-placeholder-count="3">
      <div class="fld">
        <span class="fl">{{f.label}}</span>
        <sc-if value="{{f.isText}}" hint-placeholder-val="{{ true }}"><input class="in" aria-label="{{f.label}}" value="{{f.val}}" placeholder="{{f.ph}}" onChange="{{f.onChange}}"></sc-if>
        <sc-if value="{{f.isNewSecret}}" hint-placeholder-val="{{ false }}"><input class="in" type="password" aria-label="{{f.label}}" value="{{f.val}}" placeholder="{{f.ph}}" onChange="{{f.onChange}}"></sc-if>
        <sc-if value="{{f.isSaved}}" hint-placeholder-val="{{ false }}">
          <div class="sec"><span class="dots" aria-label="Clave oculta">••••••••••••</span><span class="kbadge">''' + LOCK + '''En el Llavero</span><button class="sbtn" type="button" onClick="{{f.ask}}">Mostrar</button><button class="sbtn" type="button" onClick="{{f.change}}">Cambiar</button></div>
          <sc-if value="{{f.asking}}" hint-placeholder-val="{{ false }}"><div class="ask">''' + FINGER + '''Toca Touch ID para ver la clave. Se oculta sola en 20 s.</div></sc-if>
        </sc-if>
        <sc-if value="{{f.isSeg}}" hint-placeholder-val="{{ false }}"><div class="sg2"><sc-for list="{{f.opts}}" as="o" hint-placeholder-count="2"><button type="button" class="{{o.cls}}" onClick="{{o.pick}}">{{o.n}}</button></sc-for></div></sc-if>
        <sc-if value="{{f.isLink}}" hint-placeholder-val="{{ false }}">
          <div style="display:flex;align-items:center;gap:12px"><button class="bb" type="button" onClick="{{f.link}}">{{f.btn}}</button><sc-if value="{{f.linked}}" hint-placeholder-val="{{ false }}"><span class="ok">''' + CHECK + '''Conectado · permiso en el Llavero</span></sc-if></div>
        </sc-if>
        <sc-if value="{{f.isNote}}" hint-placeholder-val="{{ false }}"><div class="note">''' + INFO_I + '''<span>{{f.note}}</span></div></sc-if>
        <sc-if value="{{f.hasHint}}" hint-placeholder-val="{{ false }}"><span class="t2" style="font-size:12px">{{f.hint}}</span></sc-if>
      </div>
    </sc-for>
    <sc-if value="{{a.showPerm}}" hint-placeholder-val="{{ true }}">
    <div class="fld"><span class="fl">Qué puede hacer Mym</span><div class="sg2"><button type="button" class="{{a.viewCls}}" onClick="{{a.setView}}">Solo ver</button><button type="button" class="{{a.tradeCls}}" onClick="{{a.setTrade}}">Ver y operar</button></div></div>
    </sc-if>
    <sc-if value="{{a.hasProv}}" hint-placeholder-val="{{ true }}">
    <div style="display:flex;align-items:center;gap:10px;flex-wrap:wrap;border-top:1px solid #EFEFEA;padding-top:14px">
      <button class="bb" type="button" onClick="{{a.test}}">{{a.testLabel}}</button>
      <sc-if value="{{a.tested}}" hint-placeholder-val="{{ false }}"><span class="ok">''' + CHECK + '''Conexión correcta</span></sc-if>
      <span style="flex:1"></span>
      <button class="bb l" type="button" onClick="{{a.remove}}">Quitar cuenta</button>
      <button class="bb p" type="button" onClick="{{a.save}}">Guardar</button>
    </div>
    </sc-if>
  </div>
  </sc-if>'''

    cuentas = ('''<div style="display:flex;align-items:center;justify-content:space-between;gap:12px;flex-wrap:wrap"><div class="ptitle">Cuentas</div><div style="display:flex;align-items:center;gap:10px">''' + VIEWSEG +
               '''<button class="bb p" type="button" onClick="{{addAccount}}">+ Añadir cuenta</button></div></div>
<div style="display:flex;align-items:center;gap:10px;flex-wrap:wrap">
  <label style="flex:1;min-width:220px;position:relative;display:flex"><span style="position:absolute;left:12px;top:11px;color:#8A8A84">''' + SEARCH + '''</span><input class="in" style="flex:1;padding-left:38px" aria-label="Buscar cuenta" placeholder="Buscar cuenta, bróker o banco" value="{{q}}" onChange="{{onSearch}}"></label>
  <div style="display:flex;gap:6px;flex-wrap:wrap"><sc-for list="{{filters}}" as="fi" hint-placeholder-count="5"><button type="button" class="{{fi.cls}}" onClick="{{fi.pick}}">{{fi.n}} <b>{{fi.c}}</b></button></sc-for></div>
</div>
<sc-if value="{{anySel}}" hint-placeholder-val="{{ false }}">
<div class="bulk"><b>{{selCount}}</b><span style="flex:1"></span><button class="sbtn" type="button" onClick="{{bulkTest}}">Probar conexión</button><button class="sbtn" type="button" onClick="{{bulkPause}}">Pausar</button><button class="sbtn" type="button" onClick="{{bulkResume}}">Reanudar</button><button class="sbtn" type="button" onClick="{{clearSel}}">Quitar selección</button></div>
</sc-if>
<sc-if value="{{noResults}}" hint-placeholder-val="{{ false }}"><div class="note">''' + INFO_I + '''<span>Ninguna cuenta coincide.</span></div></sc-if>
<sc-if value="{{isCompact}}" hint-placeholder-val="{{ true }}">
  <div class="chead"><span style="width:36px"></span><span class="cnum">N.º</span><span style="width:26px"></span><span class="cname">Cuenta</span><span class="cprov">Con</span><span class="cst">Estado</span><span class="csal">Saldo</span><span class="clast">Comprobada</span><span style="width:18px"></span></div>
  <sc-for list="{{groups}}" as="g" hint-placeholder-count="4">
  <div class="grp">
    <div class="gh"><span class="mt sm" style="background:{{g.bg}};color:{{g.fg}}">{{g.m}}</span>{{g.n}}<span class="t2" style="font-weight:500">{{g.c}}</span></div>
    <sc-for list="{{g.rows}}" as="a" hint-placeholder-count="5">
    <div class="crow {{a.accCls}}">
      <div style="display:flex;align-items:center">
        <button type="button" class="ck {{a.ckCls}}" onClick="{{a.check}}" aria-label="Seleccionar {{a.name}}" aria-pressed="{{a.ckOn}}">''' + TICK + '''</button>
        <button type="button" class="crowb" onClick="{{a.toggle}}" aria-expanded="{{a.expanded}}">
          <span class="cnum">{{a.num}}</span><span class="mt sm" style="background:{{a.bg}};color:{{a.fg}}">{{a.mono}}</span>
          <span class="cname">{{a.name}}</span><span class="cprov t2">{{a.provName}}</span>
          <span class="cst"><span class="pill {{a.pc}}">{{a.st}}</span></span>
          <span class="csal tn">{{a.saldo}}</span><span class="clast t2">{{a.last}}</span>''' + CHEV + '''
        </button>
      </div>
      ''' + detail + '''
    </div>
    </sc-for>
  </div>
  </sc-for>
</sc-if>
<sc-if value="{{isAdvanced}}" hint-placeholder-val="{{ false }}">
<sc-for list="{{flat}}" as="a" hint-placeholder-count="6">
<div class="acc {{a.accCls}}" style="flex:none">
  <button class="acch" type="button" onClick="{{a.toggle}}" aria-expanded="{{a.expanded}}">
    <span class="num">{{a.num}}</span><span class="mt" style="background:{{a.bg}};color:{{a.fg}}">{{a.mono}}</span>
    <span style="flex:1;min-width:0;display:flex;flex-direction:column"><span class="an">{{a.name}}</span><span class="t2" style="font-size:13px">{{a.sub}}</span></span>
    <span style="display:flex;flex-direction:column;align-items:flex-end;margin-right:6px"><span class="tn" style="font-weight:700">{{a.saldo}}</span><span class="t2" style="font-size:12px">{{a.permText}} · {{a.keyText}}</span></span>
    <span class="pill {{a.pc}}">{{a.st}}</span>''' + CHEV + '''
  </button>
  ''' + detail + '''
</div>
</sc-for>
</sc-if>
<div class="note">''' + LOCK.replace('currentColor', '#3F7300') + '''<span>Las claves y permisos van cifrados al Llavero de este Mac. Mym nunca las muestra sin Touch ID y no las envía a nadie.</span></div>''')
    return cuentas
