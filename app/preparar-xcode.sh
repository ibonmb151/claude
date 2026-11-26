#!/bin/bash
# Genera el proyecto de Xcode y lo deja en el formato que entiende Xcode 14.2 (macOS Monterey).
# Uso:  ./preparar-xcode.sh            (si xcodegen está instalado)
#       ./preparar-xcode.sh /ruta/a/xcodegen
set -e
cd "$(dirname "$0")"
XG="${1:-xcodegen}"
"$XG" generate
# Xcode 14.2 entiende como máximo el formato 56 del proyecto.
sed -i '' -E 's/objectVersion = [0-9]+;/objectVersion = 56;/' Mym.xcodeproj/project.pbxproj
sed -i '' -E 's/compatibilityVersion = "Xcode [0-9.]+";/compatibilityVersion = "Xcode 14.0";/' Mym.xcodeproj/project.pbxproj || true
echo "Listo: abriendo Mym.xcodeproj"
open Mym.xcodeproj
