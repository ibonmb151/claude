# Prompt del exportador (segunda ronda, para cada chat)

Se usa **después** del inventario. Cada sistema escribe su propio script de exportación, porque es
quien conoce sus datos. Mym solo lee los ficheros que salgan; no se conecta al sistema.

```
SISTEMA: <nombre>

Escribe un script (Python 3, solo librería estándar si puedes) que exporte los datos de ESTE sistema
a ficheros JSON para mi panel. Reglas:
- Solo lectura: no escribe en tu base de datos, no abre posiciones, no cambia nada del sistema.
- Se ejecuta a mano o por cron (cada 5 minutos). Escribe a un fichero temporal y lo renombra al
  final, para que nunca quede un JSON a medias.
- Salida en una carpeta que se pasa por argumento (la llamaremos 06_CONFIG).
- Dinero en la divisa de la cuenta, con decimales normales (no en enteros escalados). Fechas ISO 8601
  en UTC. Porcentajes como número (1,5 significa 1,5 %).
- Números de cuenta: el script escribe el número completo SOLO en el campo `cuenta`; el panel solo
  enseña los cuatro últimos.
- Ningún secreto en la salida, ni en el código, ni en los registros.
- Si un dato no existe en este sistema, NO lo inventes: deja el campo fuera.
- Cada fichero es un array JSON de objetos con estos campos (todos opcionales salvo los marcados):

cuentas_metricas.json   (uno por cuenta)
  cuenta*, balance, equity, margin_used, margin_free, margin_level_pct, pnl_flotante,
  pnl_realizado_hoy, pnl_realizado_total, n_trades_abiertos, n_trades_cerrados_total,
  max_dd_historico, gap_conciliacion, deposito_inicial

modulos_metricas.json   (uno por método y cuenta)
  modulo*, cuenta*, n_trades, wins, losses, wr, pnl_realizado, pnl_flotante, costes, avg_rr,
  max_dd, max_dd_pct, capital_asignado_pct, capital_en_riesgo_pct, sharpe, sortino, profit_factor,
  avg_duracion_min, mejor_trade, peor_trade, ultimo_trade, decay_pct

metricas_diarias.json   (uno por día y cuenta)
  fecha* (AAAA-MM-DD), cuenta, balance_inicio, balance_fin, pnl_realizado, pnl_flotante, costes,
  n_trades_abiertos, n_trades_cerrados, wins, losses, wr, max_dd_intradia, max_dd_desde_pico,
  vix, regimen, oportunidades

curva_equity.json       (un punto cada pocos minutos)
  ts* (ISO UTC), cuenta, equity_realizado, drawdown_pct

seq_labels.json         (una fila por operación, abiertas incluidas)
  label* (identificador único), modulo, cuenta, par, lado ("compra" o "venta"), entrada_px,
  entrada_ts, sl, tp, volumen, riesgo_pct, salida_px, salida_ts (vacío si sigue abierta), pnl,
  comision, swap, duracion_min, resultado, slippage_pips

Entrégame: (1) el script; (2) una prueba con datos de ejemplo inventados que compruebe los campos;
(3) la lista de campos que NO has podido rellenar y por qué; (4) cómo programarlo en cron.
```

Los nombres y los tipos están fijados en `app/Shared/Model/AccountModels.swift`. Si un sistema necesita
más campos, se añaden allí y en este fichero a la vez.
