# Mym · app de Mac e iPhone (datos ficticios)

Panel para vigilar y gobernar tus bots de trading: células, cuentas, estrategias, órdenes, riesgo y las propuestas de Jev.
Es una sola app en SwiftUI para **macOS 12+** e **iOS 16+**, con widgets, icono en la barra de menús y firma con Face ID o Touch ID.

> **Estado:** todos los datos son ficticios y se generan en local. No hay conexión con ningún bróker ni con el plano de control.
> **Importante:** este código se escribió en un entorno Linux sin Swift ni Xcode. **No se ha compilado nunca.**
> Haz una primera compilación y arregla lo que salga; es lo esperable en una base de unas 4.500 líneas escritas sin compilador.

## Cómo abrirla (macOS Monterey + Xcode 14.2)

Esta versión apunta a **macOS 12 e iOS 16**, para compilarse con **Xcode 14.2**, el último que funciona en Monterey.

1. **Instala Xcode 14.2.** Descárgalo en `developer.apple.com/download/all` (necesitas tu Apple ID; busca «Xcode 14.2»), descomprime el `.xip` y arrastra Xcode a Aplicaciones. Ábrelo una vez y acepta la licencia.
2. **Baja XcodeGen 2.32.0**, que genera el proyecto. Las versiones nuevas no funcionan en Monterey (piden una librería que macOS 12 no tiene). Descarga `xcodegen.zip` desde `github.com/yonaskolb/XcodeGen/releases/tag/2.32.0` y descomprímelo en Descargas. Si esa versión tampoco arranca, prueba con la 2.30.0.
3. **Genera y abre el proyecto** desde la Terminal, dentro de la carpeta `app`:

```bash
./preparar-xcode.sh ~/Downloads/xcodegen/bin/xcodegen
```

Si el sistema bloquea el script o XcodeGen por venir de internet, ejecuta `xattr -dr com.apple.quarantine ~/Downloads/xcodegen .` y repite.

4. En `project.yml` (antes del paso 3), cambia `com.tuempresa` por tu identificador. En Xcode, en **Signing & Capabilities** de los destinos `Mym` y `MymWidgets` (y `MymPhone` y `MymPhoneWidgets` si usas el iPhone), elige tu Apple ID como equipo.
5. Elige el esquema `Mym` (Mac) o `MymPhone` (iPhone), el destino y pulsa ▶.

> **iPhone:** Xcode 14.2 solo conoce iPhones con iOS 16.2 como máximo. Con un iPhone más nuevo puede negarse a instalar la app. El Mac es el destino principal de esta versión.

## Estructura (de lo grande a lo pequeño)

```
app/
  project.yml            Proyecto de Xcode (XcodeGen): app + extensión de widgets
  Shared/                Lo que comparten la app y los widgets
    Theme/Palette.swift      Paleta Grafito: sin negro puro ni verde lima
    Model/Models.swift       Módulos, cuentas, células, estrategias, órdenes, avisos, Jev, riesgo
    Data/MockData.swift      Datos ficticios deterministas (cuadran entre pantallas)
    Data/Format.swift        Formato a la española (coma decimal, − tipográfico)
    Components/Basics.swift  Tarjeta, píldora, botón ⓘ, títulos cortos, barras
    Components/Charts.swift  Sparkline, anillos, donut, barras por hora, cono, radar
  Mym/                   La app
    MymApp.swift             Entrada: ventana de Mac + barra de menús, o pestañas en iPhone
    Common/AppStore.swift    Estado, comandos simulados y Face ID / Touch ID
    Common/SignSheet.swift   Hoja «Firmar y enviar»
    Common/Cards.swift       Cifras, mapa de red, fila de órdenes, flota en donut
    Common/RiskCards.swift   Capas de límites y exposición por divisa
    Mac/                     Riel en cápsula + Torre, Órdenes, Flota, Cuentas, Estrategias,
                             Ajustes, Jev, Riesgo, búsqueda ⌘K y menú de la barra superior
    iOS/PhoneRootView.swift  Hoy, Órdenes, Avisos y Jev (se ve y se para)
  MymWidgets/            Equity, Hoy, Flota y pantalla de bloqueo
```

## Qué hace ya

- **Mac:** ventana con riel de iconos (indicador del módulo activo y avisos), ocho pantallas, búsqueda y acciones con **⌘K**, atajos **⌘1…⌘8**, icono en la barra de menús (hecho con AppKit, porque MenuBarExtra pide macOS 13) con el resultado del día y «Parar todo».
- **iPhone:** cuatro pestañas. Se ve y se para. Reanudar y aprobar se hacen en el Mac.
- **Firma:** pausar, parar, aprobar o rechazar abre «Firmar y enviar», con cuenta atrás de 2 minutos y confirmación biométrica. El resultado queda en el registro de comandos de Riesgo.
- **Datos vivos:** cada 4 segundos varían la latencia y el latido, para que se note que algo se mueve.
- **Widgets:** Equity (pequeño y mediano), Hoy con anillos (pequeño), Flota (mediano y grande) y, en iPhone, tres de pantalla de bloqueo.

## Qué falta (en este orden)

1. Compilar y arreglar errores. Probar en un Mac real y en el iPhone.
2. Capturas y ajustes de maquetación frente a los diseños del lienzo.
3. Modo oscuro (ahora solo hay claro). Widgets con el fondo nuevo de iOS 17 / macOS 14 cuando se pueda subir de versión.
4. Conectar con el plano de control real: API de lectura, comandos firmados con Ed25519 (CryptoKit) y claves en el llavero.
5. Actividades en directo y Dynamic Island (necesitan avisos desde tu servidor a través de Apple).
6. Compartir datos entre app y widgets con un grupo de apps cuando haya datos reales.

## Decisiones de diseño

- Un riel flotante sin cabecera ni nombre de la plataforma arriba a la izquierda.
- Títulos de una a tres palabras y un ⓘ en lugar de subtítulos.
- Verde y rojo solo para ganar y perder. Selección en gris grafito claro, nunca en negro.
- Iconos de SF Symbols (los más cercanos a los diseñados). Se pueden cambiar por activos propios.
