#!/usr/bin/env bash
set -e

export GODOT_SILENCE_ROOT_WARNING=1
export HOME="/home/aegis2"

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_BIN="${PROJECT_DIR}/tools/godot/godot"
BUILD_DIR="${PROJECT_DIR}/build/android"

mkdir -p "${BUILD_DIR}"

if [ ! -f "${GODOT_BIN}" ]; then
    echo "Error: Godot binary no encontrado en ${GODOT_BIN}. Ejecuta tools/setup_godot.sh primero."
    exit 1
fi

echo "=========================================="
echo "Ejecutando verificación estática de scripts..."
echo "=========================================="
"${GODOT_BIN}" --headless --quit

echo "=========================================="
echo "Ejecutando tests headless..."
echo "=========================================="
"${GODOT_BIN}" --headless -s tests/run_all.gd

echo "=========================================="
echo "Generando APK Debug..."
echo "=========================================="
"${GODOT_BIN}" --headless --export-debug "NeuroFit Debug (APK)" "${BUILD_DIR}/neurofit-debug.apk"

echo "=========================================="
echo "¡Build de Android completada con éxito!"
echo "Artefacto generado en ${BUILD_DIR}:"
ls -lh "${BUILD_DIR}"
echo "=========================================="
