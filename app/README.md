# Mym · app de Mac e iPhone (datos ficticios)

Panel para vigilar y gobernar tus bots de trading: células, cuentas, estrategias, órdenes, riesgo y las propuestas de Jev.
Es una sola app en SwiftUI para **macOS 14+** e **iOS 17+**, con widgets, icono en la barra de menús y firma con Face ID o Touch ID.

> **Estado:** todos los datos son ficticios y se generan en local. No hay conexión con ningún bróker ni con el plano de control.
> **Importante:** este código se escribió en un entorno Linux sin Swift ni Xcode. **No se ha compilado nunca.**
> Haz una primera compilación y arregla lo que salga; es lo esperable en una base de unas 4.500 líneas escritas sin compilador.

## Cómo abrirla

Necesitas un Mac con Xcode 15 o superior.

```bash
brew install xcodegen
cd app
xcodegen generate
open Mym.xcodeproj
```

1. En `project.yml`, cambia `bundleIdPrefix` y los dos `PRODUCT_BUNDLE_IDENTIFIER` (`com.tuempresa.mym` y `com.tuempresa.mym.widgets`) por los tuyos.
2. En Xcode, en **Signing & Capabilities** de los dos destinos (`Mym` y `MymWidgets`), elige tu equipo. Sirve la cuenta de pago de 99 $/año; con la gratuita las apps caducan a los 7 días.
3. Elige el esquema `Mym` y el destino **My Mac** o tu iPhone, y dale a Ejecutar.
4. Widgets: en el Mac, clic derecho en el escritorio › Editar widgets › Mym. En el iPhone, mantén pulsado el inicio › + › Mym.

Si prefieres no usar XcodeGen, crea un proyecto multiplataforma a mano, arrastra las carpetas `Shared`, `Mym` y `MymWidgets`, y añade un destino de extensión de widgets.

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

- **Mac:** ventana con riel de iconos (indicador del módulo activo y avisos), ocho pantallas, búsqueda y acciones con **⌘K**, atajos **⌘1…⌘8**, icono en la barra de menús con el resultado del día y «Parar todo».
- **iPhone:** cuatro pestañas. Se ve y se para. Reanudar y aprobar se hacen en el Mac.
- **Firma:** pausar, parar, aprobar o rechazar abre «Firmar y enviar», con cuenta atrás de 2 minutos y confirmación biométrica. El resultado queda en el registro de comandos de Riesgo.
- **Datos vivos:** cada 4 segundos varían la latencia y el latido, para que se note que algo se mueve.
- **Widgets:** Equity (pequeño y mediano), Hoy con anillos (pequeño), Flota (mediano y grande) y, en iPhone, tres de pantalla de bloqueo.

## Qué falta (en este orden)

1. Compilar y arreglar errores. Probar en un Mac real y en el iPhone.
2. Capturas y ajustes de maquetación frente a los diseños del lienzo.
3. Modo oscuro (ahora solo hay claro).
4. Conectar con el plano de control real: API de lectura, comandos firmados con Ed25519 (CryptoKit) y claves en el llavero.
5. Actividades en directo y Dynamic Island (necesitan avisos desde tu servidor a través de Apple).
6. Compartir datos entre app y widgets con un grupo de apps cuando haya datos reales.

## Decisiones de diseño

- Un riel flotante sin cabecera ni nombre de la plataforma arriba a la izquierda.
- Títulos de una a tres palabras y un ⓘ en lugar de subtítulos.
- Verde y rojo solo para ganar y perder. Selección en gris grafito claro, nunca en negro.
- Iconos de SF Symbols (los más cercanos a los diseñados). Se pueden cambiar por activos propios.
