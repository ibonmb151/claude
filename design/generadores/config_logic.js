class Component extends DCLogic {
  constructor(props) {
    super(props);
    const list = [];
    const add = (name, type, prov, status, perm, saldo, last, extra) => {
      const base = { id: list.length + 1, name: name, type: type, prov: prov, status: status, perm: perm, saldo: saldo, last: last, vals: {}, saved: {}, seg: {}, linked: false, tested: false, testing: false };
      if (prov === 'ctrader') { base.linked = true; base.vals = { 'Número de cuenta': String(4410 + list.length) + ' ' + String(2300 + list.length * 7) }; }
      if (prov === 'mt5') { base.saved = { 'Contraseña': true }; base.vals = { 'Servidor': 'FirmaB-Live', 'Número de cuenta': '50 112 ' + String(300 + list.length) }; base.seg = { 'Tipo de contraseña': perm === 'trade' ? 1 : 0 }; }
      if (prov === 'dxtrade') { base.saved = { 'Contraseña': true }; base.vals = { 'Dirección': 'trade.firma-c.com', 'Usuario': 'fc' + list.length }; }
      if (prov === 'oanda') { base.saved = { 'Clave de acceso': true }; base.vals = { 'Número de cuenta': '001-004-77' + String(10 + list.length) }; base.seg = { 'Entorno': 1 }; }
      if (prov === 'ibkr') { base.saved = { 'Contraseña': true }; base.vals = { 'Usuario': 'ibon' + list.length }; }
      if (type === 'bank') { base.linked = true; }
      list.push(Object.assign(base, extra || {}));
    };
    add('Fondeo A · 100k #1', 'broker', 'ctrader', 'ok', 'trade', '101.842 €', 'hace 2 min');
    add('Fondeo A · 100k #2', 'broker', 'ctrader', 'ok', 'trade', '99.310 €', 'hace 2 min');
    add('Fondeo A · 50k #1', 'broker', 'ctrader', 'ok', 'trade', '50.940 €', 'hace 3 min');
    add('Fondeo A · 50k #2', 'broker', 'ctrader', 'ok', 'trade', '49.870 €', 'hace 3 min');
    add('Fondeo A · 25k #1', 'broker', 'ctrader', 'off', 'view', '25.090 €', 'ayer');
    add('Fondeo A · 25k #2', 'broker', 'ctrader', 'ok', 'trade', '25.410 €', 'hace 4 min');
    add('Fondeo A · 200k #1', 'broker', 'ctrader', 'ok', 'trade', '203.120 €', 'hace 2 min');
    add('Fondeo A · 10k #1', 'broker', 'ctrader', 'ok', 'trade', '10.180 €', 'hace 5 min');
    add('Fondeo B · 50k #1', 'broker', 'mt5', 'warn', 'trade', '51.600 €', 'hace 1 min');
    add('Fondeo B · 50k #2', 'broker', 'mt5', 'ok', 'trade', '50.220 €', 'hace 2 min');
    add('Fondeo B · 50k #3', 'broker', 'mt5', 'ok', 'trade', '49.990 €', 'hace 2 min');
    add('Fondeo B · 50k #4', 'broker', 'mt5', 'ok', 'view', '50.000 €', 'hace 6 min');
    add('Fondeo B · 100k #1', 'broker', 'mt5', 'ok', 'trade', '101.050 €', 'hace 2 min');
    add('Fondeo B · 100k #2', 'broker', 'mt5', 'ok', 'trade', '98.760 €', 'hace 3 min');
    add('Fondeo B · 25k #1', 'broker', 'mt5', 'ok', 'trade', '25.330 €', 'hace 4 min');
    add('Fondeo C · 50k #1', 'broker', 'dxtrade', 'ok', 'trade', '50.410 €', 'hace 2 min');
    add('Fondeo C · 50k #2', 'broker', 'dxtrade', 'ok', 'trade', '50.880 €', 'hace 2 min');
    add('Fondeo C · 50k #3', 'broker', 'dxtrade', 'off', 'view', '49.120 €', 'hace 2 días');
    add('Fondeo C · 100k #1', 'broker', 'dxtrade', 'ok', 'trade', '100.640 €', 'hace 3 min');
    add('Fondeo C · 25k #1', 'broker', 'dxtrade', 'ok', 'trade', '25.060 €', 'hace 5 min');
    add('Cuenta real', 'broker', 'oanda', 'warn', 'trade', '12.340 €', 'hace 1 min');
    add('Cuenta real 2', 'broker', 'oanda', 'ok', 'trade', '8.210 €', 'hace 2 min');
    add('Cuenta real 3', 'broker', 'oanda', 'ok', 'view', '3.450 €', 'hace 9 min');
    add('Inversión a largo plazo', 'broker', 'ibkr', 'ok', 'view', '41.300 €', 'hace 1 h');
    add('Cobertura', 'broker', 'ibkr', 'warn', 'trade', '15.700 €', 'hace 3 h');
    add('Demo 1', 'broker', 'ctrader', 'ok', 'trade', '22.342 €', 'hace 2 min');
    add('Demo 2', 'broker', 'ctrader', 'ok', 'trade', '20.010 €', 'hace 2 min');
    add('Demo 3', 'broker', 'ctrader', 'ok', 'trade', '19.480 €', 'hace 8 min');
    add('Banco principal', 'bank', 'kutxabank', 'ok', 'view', '18.900 €', 'hoy 8:00');
    add('Ahorro', 'bank', 'bbva', 'ok', 'view', '6.200 €', 'hoy 8:00');
    this.state = { section: 'cuentas', view: 'compact', filter: 'todas', q: '', open: 9, asking: null, next: 31, sel: {}, accounts: list };
  }

  upd(id, patch) {
    this.setState({ accounts: this.state.accounts.map((x) => (x.id === id ? Object.assign({}, x, patch) : x)) });
  }

  updMany(ids, patch) {
    this.setState({ accounts: this.state.accounts.map((x) => (ids[x.id] ? Object.assign({}, x, patch) : x)) });
  }

  get(id) {
    return this.state.accounts.find((x) => x.id === id);
  }

  renderVals() {
    const S = this.state;
    const NAV = __NAV__;
    const bank = (n, m) => ({ n: n, m: m, bg: '#E3F0FE', fg: '#1567C9', f: [
      { k: 'link', label: 'Permiso', btn: 'Conectar con ' + n, hint: 'Te lleva a tu banco. Nunca vemos tu contraseña.' },
      { k: 'note', label: 'Qué verá Mym', note: 'Solo saldos y movimientos. El permiso dura 90 días y lo puedes quitar cuando quieras.' }
    ] });
    const PROV = {
      ctrader: { n: 'cTrader', m: 'cT', bg: '#EDE8FE', fg: '#4B35C4', f: [
        { k: 'link', label: 'Acceso', btn: 'Conectar con cTrader', hint: 'Entras con tu usuario de cTrader. Guardamos un permiso, no tu contraseña.' },
        { k: 'text', label: 'Número de cuenta', ph: 'Ej. 4410 2378' }
      ] },
      mt5: { n: 'MetaTrader 5', m: 'M5', bg: '#E3F0FE', fg: '#1567C9', f: [
        { k: 'text', label: 'Servidor', ph: 'Lo da tu firma, ej. FirmaB-Live' },
        { k: 'text', label: 'Número de cuenta', ph: 'Ej. 50 112 340' },
        { k: 'secret', label: 'Contraseña', ph: 'Contraseña de la cuenta' },
        { k: 'seg', label: 'Tipo de contraseña', opts: ['Solo ver', 'Operar'], hint: 'Con la de «solo ver», Mym no puede abrir operaciones.' }
      ] },
      dxtrade: { n: 'DXtrade', m: 'DX', bg: '#E5F4F4', fg: '#00706F', f: [
        { k: 'text', label: 'Dirección', ph: 'Ej. trade.tufirma.com' },
        { k: 'text', label: 'Usuario', ph: 'Tu usuario' },
        { k: 'secret', label: 'Contraseña', ph: 'Tu contraseña' }
      ] },
      ibkr: { n: 'Interactive Brokers', m: 'IB', bg: '#FDE4E8', fg: '#C21A36', f: [
        { k: 'text', label: 'Usuario', ph: 'Tu usuario' },
        { k: 'secret', label: 'Contraseña', ph: 'Tu contraseña' },
        { k: 'note', label: 'Al conectar', note: 'Te pedirá el código de tu móvil la primera vez.' }
      ] },
      oanda: { n: 'OANDA', m: 'OA', bg: '#FDF1D6', fg: '#8F5D00', f: [
        { k: 'secret', label: 'Clave de acceso', ph: 'Pega aquí tu clave', hint: 'Créala en tu área de cliente. Caduca cada 90 días.' },
        { k: 'text', label: 'Número de cuenta', ph: 'Ej. 001-004-7712' },
        { k: 'seg', label: 'Entorno', opts: ['Práctica', 'Real'] }
      ] },
      bbva: bank('BBVA', 'BB'), santander: bank('Santander', 'SA'), caixabank: bank('CaixaBank', 'CB'), kutxabank: bank('Kutxabank', 'KB'), otro: bank('otro banco', '+')
    };
    PROV.otro.n = 'Otro banco';
    const BROKERS = ['ctrader', 'mt5', 'dxtrade', 'ibkr', 'oanda'];
    const BANKS = ['bbva', 'santander', 'caixabank', 'kutxabank', 'otro'];
    const ST = { ok: ['Conectada', 'sg'], warn: ['Revisar', 'so'], off: ['Pausada', 'sn'], new: ['Sin conectar', 'sn'] };
    const TEMPLATES = [
      { n: 'Fondeo A · cTrader', type: 'broker', prov: 'ctrader', vals: {} },
      { n: 'Fondeo B · MetaTrader 5', type: 'broker', prov: 'mt5', vals: { 'Servidor': 'FirmaB-Live' } },
      { n: 'Fondeo C · DXtrade', type: 'broker', prov: 'dxtrade', vals: { 'Dirección': 'trade.firma-c.com' } },
      { n: 'Un banco', type: 'bank', prov: null, vals: {} }
    ];

    const item = (a, idx) => {
      const open = S.open === a.id;
      const p = a.prov ? PROV[a.prov] : null;
      const st = ST[a.status] || ST.new;
      const keys = a.type === 'bank' ? BANKS : BROKERS;
      const providers = keys.map((k) => ({ n: PROV[k].n, m: PROV[k].m, bg: PROV[k].bg, fg: PROV[k].fg, cls: k === a.prov ? 'pv on' : 'pv', pick: () => this.upd(a.id, { prov: k, tested: false, linked: false, saved: {}, vals: {}, seg: {} }) }));
      const fields = p ? p.f.map((f, i) => {
        const key = a.id + ':' + i;
        const saved = !!(a.saved && a.saved[f.label]);
        const segSel = (a.seg && a.seg[f.label] !== undefined) ? a.seg[f.label] : 0;
        return {
          label: f.label,
          isText: f.k === 'text', isNewSecret: f.k === 'secret' && !saved, isSaved: f.k === 'secret' && saved,
          isSeg: f.k === 'seg', isLink: f.k === 'link', isNote: f.k === 'note',
          note: f.note || '', hint: f.hint || '', hasHint: !!f.hint,
          val: (a.vals && a.vals[f.label]) || '', ph: f.ph || '',
          btn: a.linked ? 'Volver a conectar' : f.btn, linked: !!a.linked,
          asking: S.asking === key,
          onChange: (e) => { const v = Object.assign({}, this.get(a.id).vals); v[f.label] = e.target.value; this.upd(a.id, { vals: v }); },
          ask: () => this.setState({ asking: S.asking === key ? null : key }),
          change: () => { const s2 = Object.assign({}, this.get(a.id).saved); delete s2[f.label]; this.upd(a.id, { saved: s2 }); },
          link: () => this.upd(a.id, { linked: true }),
          opts: (f.opts || []).map((o, j) => ({ n: o, cls: j === segSel ? 'on' : '', pick: () => { const s3 = Object.assign({}, this.get(a.id).seg || {}); s3[f.label] = j; this.upd(a.id, { seg: s3 }); } }))
        };
      }) : [];
      const hasSecret = p ? p.f.some((f) => f.k === 'secret') : false;
      const keyText = !p ? 'sin conectar' : a.status === 'warn' && a.prov === 'oanda' ? 'clave caduca en 5 días' : hasSecret ? 'clave en el Llavero' : 'permiso en el Llavero';
      const ckOn = !!S.sel[a.id];
      return {
        num: idx + 1, name: a.name, mono: p ? p.m : '?', bg: p ? p.bg : '#EBEBE6', fg: p ? p.fg : '#2B2E33',
        provName: p ? p.n : '—',
        sub: (a.type === 'bank' ? 'Banco · ' : a.type === 'broker' ? 'Bróker · ' : '') + (p ? p.n : 'Elige con qué conectar'),
        saldo: a.saldo || '—', last: a.last || '—',
        permText: a.perm === 'trade' ? 'Ver y operar' : 'Solo ver', keyText: keyText,
        st: st[0], pc: st[1],
        open: open, expanded: open ? 'true' : 'false', accCls: open ? 'open' : '', chev: open ? 'up' : '',
        ckOn: ckOn ? 'true' : 'false', ckCls: ckOn ? 'on' : '',
        check: () => { const n = Object.assign({}, this.state.sel); if (n[a.id]) delete n[a.id]; else n[a.id] = true; this.setState({ sel: n }); },
        toggle: () => this.setState({ open: open ? null : a.id, asking: null }),
        rename: (e) => this.upd(a.id, { name: e.target.value }),
        isNew: a.status === 'new' && !a.prov,
        templates: TEMPLATES.map((t) => ({ n: t.n, pick: () => this.upd(a.id, { type: t.type, prov: t.prov, vals: Object.assign({}, t.vals), saved: {}, linked: false }) })),
        brokerCls: a.type === 'broker' ? 'on' : '', bankCls: a.type === 'bank' ? 'on' : '',
        setBroker: () => { if (a.type !== 'broker') this.upd(a.id, { type: 'broker', prov: null, linked: false, saved: {}, vals: {}, tested: false }); },
        setBank: () => { if (a.type !== 'bank') this.upd(a.id, { type: 'bank', prov: null, linked: false, saved: {}, vals: {}, tested: false, perm: 'view' }); },
        hasType: !!a.type, provTitle: a.type === 'bank' ? 'Elige tu banco' : 'Elige tu bróker',
        providers: providers, noProv: !p,
        emptyHint: a.type ? 'Elige uno de la lista para ver qué datos hacen falta.' : 'Elige si es un bróker o un banco, o empieza igual que otra cuenta.',
        hasProv: !!p, fields: fields,
        showPerm: !!p && a.type === 'broker',
        viewCls: a.perm === 'view' ? 'on' : '', tradeCls: a.perm === 'trade' ? 'on' : '',
        setView: () => this.upd(a.id, { perm: 'view' }), setTrade: () => this.upd(a.id, { perm: 'trade' }),
        tested: a.tested, testLabel: a.testing ? 'Comprobando…' : 'Probar conexión',
        test: () => { this.upd(a.id, { testing: true, tested: false }); setTimeout(() => this.upd(a.id, { testing: false, tested: true, last: 'ahora' }), 900); },
        save: () => {
          const cur = this.get(a.id);
          const pp = cur.prov ? PROV[cur.prov] : null;
          const s4 = Object.assign({}, cur.saved);
          const v2 = Object.assign({}, cur.vals);
          if (pp) pp.f.forEach((f) => { if (f.k === 'secret') { if (v2[f.label]) s4[f.label] = true; delete v2[f.label]; } });
          this.upd(a.id, { saved: s4, vals: v2, status: pp ? 'ok' : cur.status });
        },
        remove: () => this.setState({ accounts: this.state.accounts.filter((x) => x.id !== a.id), open: null })
      };
    };

    // filtros y búsqueda
    const count = (fn) => S.accounts.filter(fn).length;
    const FIL = [
      ['todas', 'Todas', () => true], ['ok', 'Conectadas', (a) => a.status === 'ok'], ['warn', 'Revisar', (a) => a.status === 'warn'],
      ['off', 'Pausadas', (a) => a.status === 'off'], ['bank', 'Bancos', (a) => a.type === 'bank']
    ];
    const curF = FIL.find((f) => f[0] === S.filter) || FIL[0];
    const q = (S.q || '').toLowerCase();
    const numbered = S.accounts.map((a, i) => ({ a: a, i: i }));
    const visible = numbered.filter((x) => curF[2](x.a) && (!q || x.a.name.toLowerCase().indexOf(q) >= 0 || (x.a.prov && PROV[x.a.prov].n.toLowerCase().indexOf(q) >= 0)));
    const filters = FIL.map((f) => ({ n: f[1], c: count(f[2]), cls: S.filter === f[0] ? 'fchip on' : 'fchip', pick: () => this.setState({ filter: f[0] }) }));

    // grupos por bróker o banco (vista compacta)
    const order = ['ctrader', 'mt5', 'dxtrade', 'oanda', 'ibkr', 'bbva', 'santander', 'caixabank', 'kutxabank', 'otro', 'none'];
    const groupsMap = {};
    visible.forEach((x) => { const k = x.a.prov || 'none'; (groupsMap[k] = groupsMap[k] || []).push(item(x.a, x.i)); });
    const groups = order.filter((k) => groupsMap[k]).map((k) => {
      const p = k === 'none' ? null : PROV[k];
      const isBank = BANKS.indexOf(k) >= 0;
      return { n: p ? (isBank ? 'Banco · ' + p.n : p.n) : 'Sin conectar', m: p ? p.m : '?', bg: p ? p.bg : '#EBEBE6', fg: p ? p.fg : '#2B2E33', c: groupsMap[k].length === 1 ? '1 cuenta' : groupsMap[k].length + ' cuentas', rows: groupsMap[k] };
    });

    const selIds = Object.keys(S.sel);
    const nav = NAV.map((n) => ({ label: n[1], d: n[2], cls: S.section === n[0] ? 'nv on' : 'nv', pick: () => this.setState({ section: n[0] }) }));
    return {
      nav: nav,
      groups: groups,
      flat: visible.map((x) => item(x.a, x.i)),
      filters: filters,
      q: S.q,
      onSearch: (e) => this.setState({ q: e.target.value }),
      noResults: visible.length === 0,
      isCompact: S.view === 'compact', isAdvanced: S.view !== 'compact',
      compactCls: S.view === 'compact' ? 'on' : '', advancedCls: S.view !== 'compact' ? 'on' : '',
      setCompact: () => this.setState({ view: 'compact' }), setAdvanced: () => this.setState({ view: 'advanced' }),
      anySel: selIds.length > 0,
      selCount: selIds.length === 1 ? '1 seleccionada' : selIds.length + ' seleccionadas',
      bulkTest: () => this.updMany(this.state.sel, { tested: true, last: 'ahora' }),
      bulkPause: () => this.updMany(this.state.sel, { status: 'off' }),
      bulkResume: () => this.updMany(this.state.sel, { status: 'ok' }),
      clearSel: () => this.setState({ sel: {} }),
      isGeneral: S.section === 'general', isCuentas: S.section === 'cuentas', isAvisos: S.section === 'avisos',
      isSeguridad: S.section === 'seguridad', isApariencia: S.section === 'apariencia', isDatos: S.section === 'datos', isAcerca: S.section === 'acerca',
      addAccount: () => {
        const id = this.state.next;
        this.setState({
          next: id + 1, open: id, section: 'cuentas', filter: 'todas', q: '',
          accounts: this.state.accounts.concat([{ id: id, name: 'Cuenta nueva', type: null, prov: null, status: 'new', perm: 'view', saldo: '—', last: '—', vals: {}, saved: {}, seg: {}, linked: false, tested: false, testing: false }])
        });
      }
    };
  }
}
