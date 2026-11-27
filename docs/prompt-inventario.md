# Prompt de inventario (para pegar en el chat de cada sistema)

Pégalo tal cual en cada uno de los 6 chats, cambiando solo la primera línea.
Guarda cada respuesta en `docs/inventario/<sistema>.md` (o pásamela) y yo las uno.

```
SISTEMA: <nombre de este sistema>

Voy a hacer un panel (app de Mac y iPhone, solo lectura) que enseña lo que producen mis sistemas
de trading. Necesito un inventario FIEL de lo que este sistema produce y consume. Contesta en
español, con tablas cortas. Reglas:
- No inventes. Marca cada elemento como [HECHO] (existe y funciona), [CÓDIGO] (escrito, sin probar
  en real), [DISEÑO] (solo en un documento) o [SUPUESTO]. Cita la ruta, el fichero o el documento.
- Nada de secretos: ni claves, ni tokens, ni contraseñas. Di DÓNDE viven, no su valor.
- Números de cuenta enmascarados (···1234).

1. IDENTIDAD. Para qué sirve, estado, lenguaje, dónde corre, ruta del repositorio.
2. DATOS QUE PRODUCE. Una fila por fichero, tabla, flujo o endpoint: nombre, dónde está, formato,
   campos con tipo, unidad y escala (por ejemplo «precio ×1e-5», «dinero ×1e-8»), zona horaria,
   cada cuánto se escribe, cuánto se conserva, tamaño por día, si es de solo añadir y si se puede
   leer mientras el sistema corre sin molestarlo.
3. DATOS QUE CONSUME. De dónde le llegan y cada cuánto (bróker, calendario, otros sistemas).
4. EVENTOS Y ESTADOS. Lista de eventos y de máquinas de estados, con sus nombres exactos.
5. MÉTRICAS Y KPIs YA CALCULADOS. Nombre, fórmula, unidad, ventana y umbrales de aviso.
6. AVISOS. Reglas de alerta que existen, con su condición y su gravedad.
7. CÓMO SE LEE DESDE FUERA. API, base de datos, ficheros o métricas; cómo se autentica; si se
   puede dar acceso de SOLO LECTURA; si hay un túnel o una red privada.
8. AUTOMATIZACIÓN. Qué se podría exportar sin tocar el camino de las órdenes: cada minuto, cada
   5 minutos y cada día. Propón el script o el cron y di qué coste tiene.
9. PIEZAS Y APPS. Librerías, servicios, proveedores y versiones que usa, y cuáles son de pago.
10. HUECOS. Datos que un panel necesitaría y hoy no existen o no se guardan.
11. DUDAS Y CONTRADICCIONES con los documentos 01 a 14 del repositorio, si los has visto.
12. BLOQUE FINAL en JSON, con esta forma exacta:
{
  "sistema": "", "estado": "",
  "salidas": [ {"nombre":"", "tipo":"fichero|tabla|metrica|api|evento", "ubicacion":"",
                "formato":"", "campos":[{"n":"","tipo":"","unidad":"","escala":""}],
                "frecuencia":"", "lectura_segura":true, "estado":"HECHO|CODIGO|DISENO|SUPUESTO"} ],
  "entradas": [ {"nombre":"", "origen":"", "frecuencia":""} ],
  "kpis": [ {"nombre":"", "formula":"", "unidad":"", "umbral_aviso":""} ],
  "avisos": [ {"nombre":"", "condicion":"", "gravedad":"critica|aviso"} ],
  "lectura_externa": {"metodo":"", "autenticacion":"", "solo_lectura":true},
  "huecos": [""]
}
```

## Cómo se usan las respuestas
1. Se comparan los 6 bloques JSON con `docs/datos-y-kpis.md` y se rellenan los huecos de la tabla de KPIs.
2. Lo que salga como [HECHO] se conecta primero; lo de [DISEÑO] se queda como «n.d.» en el panel.
3. Con los formatos reales se ajusta el exportador (SQLite → los cinco JSON que lee Mym).
