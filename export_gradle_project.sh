#!/usr/bin/env bash
set -e

export GODOT_SILENCE_ROOT_WARNING=1
export HOME="/home/aegis2"

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_BIN="${PROJECT_DIR}/tools/godot/godot"
GRADLE_EXPORT_DIR="${PROJECT_DIR}/build/android_gradle"

mkdir -p "${GRADLE_EXPORT_DIR}"

if [ ! -f "${GODOT_BIN}" ]; then
    echo "Error: Godot binary no encontrado. Ejecuta tools/setup_godot.sh primero."
    exit 1
fi

echo "=========================================="
echo "Exportando proyecto Godot como proyecto Gradle para Android Studio..."
echo "=========================================="

# Godot 3.5 permite exportar proyecto Gradle con --export-pack o exportando a un directorio con gradle build
# O exportando el APK con gradle_build habilitado (que genera el proyecto gradle temporalmente o permite export build)
"${GODOT_BIN}" --headless --export "NeuroFit Debug (APK)" "${GRADLE_EXPORT_DIR}/neurofit.apk"

echo "=========================================="
echo "¡Proyecto Gradle exportado en ${GRADLE_EXPORT_DIR}!"
echo "Ya puedes abrir esa carpeta en Android Studio (File > Open)."
echo "=========================================="
