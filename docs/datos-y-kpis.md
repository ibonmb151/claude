# Datos, KPIs y gráficas del sistema

Base: los documentos 12, 13 y 14 de `trading/`. Lo que sigue describe lo **diseñado** en ellos.
Cuál de esas piezas existe ya lo dirán los inventarios (`docs/prompt-inventario.md`).

## 1. Principio
Mym **no calcula** nada de trading: lee lo que el sistema ya produce. Solo lectura, sin llaves para operar
(coincide con NUC-06: nada fuera de la célula puede abrir posiciones).

## 2. De dónde sale cada dato

| Fuente | Qué contiene | Cómo se lee | Frecuencia | Estado |
|---|---|---|---|---|
| **Proyecciones SQLite de cada célula** (`schema.sql`) | `orders`, `order_moves`, `deals`, `positions`, `ledger`, `marks`, `decisions`, `risk_states`, `recon`, `targets`, `data_quality`, `configs` | Lectura SQLite en modo solo lectura (WAL permite leer con la célula en marcha) | `marks`: 1 fila por minuto | Diseño (doc 13) |
| **Métricas Prometheus** (`mym_*`) | Estado en vivo: riesgo, latencias, precios viejos, reloj, cerrojo, conexión | `GET /api/v1/query` de Prometheus por el túnel, o el puerto de métricas de cada célula | Cada 15–60 s | Diseño (doc 14) |
| **Plano de control** | `GET /v1/cells`, `GET /v1/exposure` | HTTPS por el túnel, con una llave de solo lectura | Cada minuto | Diseño (doc 14) |
| **Avisos** (Alertmanager) | Las 14 reglas de `alerts.yml` | `GET /api/v2/alerts` | Al momento | Diseño |
| **Laboratorio** (`lab.sqlite`, gemelo) | Cascada del día, CUSUM de deslizamiento, fichas de mejora | SQLite, copia nocturna | Diario (23:30 UTC) | Diseño |
| **Diario** (`*.seg`, cadena de hashes) | Todo, en bruto | **No** se lee desde el panel: es la verdad y no se toca | — | Diseño |
| **Bróker (cTrader)** | Conciliación | Solo lo usa la célula | — | — |

Unidades de la base (¡obligatorio convertirlas!): precio × 1e-5, volumen en centésimas, dinero × 1e-8 de la divisa de la cuenta,
tiempo en nanosegundos UTC.

## 3. KPIs → fuente → gráfica que ya existe en Mym

| KPI | Fuente exacta | Gráfica de Mym | Pantalla |
|---|---|---|---|
| Saldo y equity | `marks.balance/equity` | `LineAreaChart`, `CurveChart` | Cuentas, Resultados |
| Resultado del día | `mym_daily_pnl_ratio`, `ledger` (kind=pnl) | `DailyBarsChart`, `ProgressTrack` | Inicio, Resultados |
| Caída desde el pico | `marks.equity` frente a su máximo | `LineAreaChart` (zona roja) | Resultados |
| Estado del riesgo (NORMAL/REDUCIR/SOLO_CERRAR/PARADA) | `mym_risk_state`, `risk_states` | `Pill` + `ProgressTrack` con los umbrales −1,25 / −2 / −2,5 % | Robots, En vivo |
| Riesgo abierto (tope 2,5 %) | `mym_open_risk_ratio`, `marks.open_risk` | `ProgressTrack` | En vivo |
| Distancia al suelo de la firma | `mym_floor_distance_ratio` | `FanChart` (reglas de la firma) | Cuentas |
| Embudo señal → orden | `decisions.ok/reasons`, `orders.state` | `FlowChart` | En vivo |
| Vetos por regla (R01–R22) | `decisions.reasons` | `FlowChart` (salidas) o barras | En vivo |
| Latencia de órdenes (objetivo p99 < 1 s) | `mym_order_latency_seconds`, `order_moves` | `LatencyChart`, `Sparkline` | Robots, En vivo |
| Rechazos del bróker | `orders.reject_code`, `mym_orders_total{state="rejected"}` | `Pill` + barras | Robots |
| Salud de un robot (6 medidas) | latido, latencia, rechazos, reloj (`mym_clock_skew_seconds`), datos (`mym_quote_age_seconds`), conciliación (`mym_recon_diffs_total`) | `RadarChart`; frase en la tarjeta | Robots |
| Días sin problemas (60) | `risk_states` + `recon` + huecos de latido | tira de barras | Robots |
| Turnos de cada método | horarios de las estrategias + `targets` | `ShiftsChart` | Robots |
| Conexión y cerrojo | `mym_broker_connected`, `mym_lease_margin_seconds` | `NetworkMap` | Robots |
| Aporte de cada método por semana | `deals` + `positions.strategy` | `ContributionChart` | Métodos |
| Retorno frente a caída por método | `positions` agregadas | `ReturnDrawdownChart` | Métodos |
| Cambios de versión sobre la curva | `configs` (hash, versión) + `marks` | `ChangesChart` | Métodos |
| Deslizamiento (alarma si CUSUM > 6) | `mym_slippage_cusum` | `Sparkline` + umbral | Métodos |
| Ranking de métodos por semana | `positions` | `SlopeChart` | Métodos |
| Resultado por hora | `deals.exec_ts` | `HourlyChart` | Resultados |
| Operaciones abiertas y su recorrido | `positions` + `orders` | `PriceStrip` | Órdenes |
| Diferencias con el bróker | `recon` | lista de avisos | Cuentas |
| Cumplimiento de los 5 objetivos de servicio | doc 14: disponibilidad 99,5 %, stops < 2 s al 100 %, p99 < 1 s, 0 diferencias graves/semana, avisos < 60 s | `RingsView` | Inicio |
| Exposición por firma y por divisa | `GET /v1/exposure` | barras horizontales (nueva) | Cuentas |

**Gráficas que faltan:** la **cascada** del gemelo (de lo que prometía la estrategia a lo que quedó en la cuenta: señal, costes, ejecución, tamaño, fallos, decisiones, suerte) y las barras de exposición. El resto ya está hecho.

## 4. Cómo automatizar la lectura
1. **Exportador** (script en Python, solo lectura) en cada célula o en el plano de control. Cada 1 y 5 minutos lee las proyecciones y escribe los cinco ficheros que Mym ya sabe leer:
   - `curva_equity.json` ← `marks` (cada 5 min)
   - `cuentas_metricas.json` ← última fila de `marks`, `positions` abiertas y `recon`
   - `metricas_diarias.json` ← `ledger` y `deals` agrupados por día
   - `modulos_metricas.json` ← `positions` y `deals` agrupados por estrategia
   - `seq_labels.json` ← `positions` + `deals` (una fila por operación)
2. **Transporte privado:** el túnel WireGuard que ya describe el doc 14 (nada por internet público, ningún servicio de terceros).
3. **Tiempo real después:** cuando haga falta menos de 5 minutos, Mym lee Prometheus y `/v1/cells` por el túnel con una llave de solo lectura guardada en el Llavero.
4. **Sin guardar datos en Mym:** todo se lee, se muestra y se olvida.

## 5. Lo que hoy la app no puede enseñar con estos datos
`vix`, `régimen`, `oportunidades`, `Sharpe`, `Sortino` y `riesgo en R`: no están en `schema.sql`; los calcularía el laboratorio o se quedan en «n.d.».
Falta también saber cuál de los 6 sistemas produce cada pieza: de eso se encarga el inventario.
