# Conexiones reales: cTrader y bancos

Plan para pasar de datos de ejemplo a datos reales sin guardar nada que no haga falta.
Estado: la autorización de cTrader (guía, Client ID, Secret, permiso en el Llavero) ya está en Configuración > Cuentas. Falta la conexión en directo, la renovación automática del permiso y todo lo de los bancos.

## Reglas de privacidad (valen para todo)

1. **Solo se guardan claves.** Tokens y secretos van al Llavero (`WhenUnlockedThisDeviceOnly`), nunca a un fichero, a `UserDefaults` ni al repositorio.
2. **Los datos viven en memoria.** Saldos, operaciones y precios se piden, se enseñan y se olvidan al cerrar la app.
3. **Mym habla directamente con el bróker o el banco.** Ningún servidor intermedio propio, ninguna analítica, ningún registro de red.
4. **Lo que sí se guarda en el disco:** nombres de cuentas y qué proveedor usan (sin números completos) y el plan. Nada más, salvo lo opcional de abajo.
5. **Opcional y desactivado por defecto:** un resumen diario (fecha, saldo y resultado por cuenta) en una base local cifrada, con la clave en el Llavero. Sirve para dibujar curvas largas si el bróker no devuelve tanto historial.
6. **Números de cuenta siempre enmascarados** (`···4152`) en pantalla, avisos y registros.
7. **Los widgets no ven las claves.** Un widget es un proceso aparte; compartir Llavero con él exige firma de desarrollador (App Group). Hasta entonces, los widgets seguirán con datos de ejemplo.

## cTrader (Open API de Spotware)

**Cómo funciona**
- Hay que registrar una aplicación en el portal de Open API y obtener `client id` y `client secret`.
- Autorización OAuth 2.0: abres una página de cTrader, aceptas, vuelve un código y se cambia por `access token` y `refresh token`.
- El `access token` caduca a los ~30 días. El `refresh token` se debe tratar como **de un solo uso**: en cada renovación se guarda el nuevo y se descarta el viejo.
- Datos en tiempo real por una conexión continua (mensajes Protocol Buffers, por TCP o WebSocket). Se autentica primero la aplicación y luego cada cuenta con su token.

**Qué se guarda en el Llavero**
| Dato | Clave |
|---|---|
| Client secret de la app | `ctrader.clientSecret` |
| Access token | `ctrader.<cuenta>.access` |
| Refresh token (el más reciente) | `ctrader.<cuenta>.refresh` |

**Piezas a programar**
1. `CTraderAuth`: abrir el navegador, recibir el código (esquema de URL propio o `ASWebAuthenticationSession`), canjearlo, renovar antes de caducar y guardar el nuevo refresh token.
2. `CTraderClient`: conexión continua con reconexión automática, latido, y mensajes para saldo, posiciones abiertas, órdenes, historial de operaciones y eventos de ejecución.
3. Un traductor que convierta eso a los tipos que la app ya usa (`AccountMetrics`, `TradeRecord`), así **ninguna pantalla cambia**.
4. Paquete SwiftProtobuf para los mensajes (se añade por Swift Package Manager desde `project.yml`).

**Qué hay que verificar antes de programar**
- Endpoints y puertos actuales (demo y real) en la documentación oficial.
- Que una cuenta de bróker puede autorizarse para una aplicación propia sin pasar por revisión del bróker.
- Límites de peticiones por segundo.

**Orden recomendado:** primero cuenta **demo**, solo lectura. El permiso para operar queda fuera hasta que lo de ver funcione bien semanas.

## Bancos

**Trade Republic**
- Tiene interfaz PSD2 oficial, pero es para proveedores con licencia (certificado eIDAS). Un particular no puede registrarse.
- Existen librerías no oficiales que entran con teléfono y PIN. **No las vamos a usar**: incumplen las condiciones del servicio, pueden bloquear la cuenta y obligan a guardar credenciales de acceso.
- Camino honesto: importar a mano el extracto (CSV o PDF) que descargas desde la app. Se lee en el momento y no se guarda el fichero.

**Sabadell**
- PSD2 también es para proveedores con licencia. La vía normal para un particular es un **agregador regulado** (tipo Enable Banking, Tink, TrueLayer, Plaid) que ya tiene licencia y da acceso de solo lectura con tu consentimiento.
- El consentimiento PSD2 caduca (por norma, hasta 180 días) y hay que renovarlo con tu banco.
- Hay que comprobar qué agregadores aceptan uso personal con tus propias cuentas hoy y a qué coste. Esto cambia con frecuencia.
- Alternativa sin agregador: importar el extracto que descarga la banca online.

**Lo que no haremos:** guardar usuario y contraseña de un banco, ni hacer scraping de su web.

## Fases propuestas
1. Cuenta demo de cTrader, solo lectura, con saldo y posiciones abiertas en En vivo.
2. Historial de operaciones y curva de resultados.
3. Renovación de tokens y estado "Falta autorizar" en Configuración (ya existe).
4. Importar extractos de banco (Sabadell y Trade Republic) en el formato que descargues.
5. Agregador para Sabadell, si compensa.
6. Operar desde Mym (parar un robot, cerrar una posición), con Touch ID.
