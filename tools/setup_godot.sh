#!/usr/bin/env bash
set -e

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_DIR="${TOOLS_DIR}/godot"

# Instalar tanto para el usuario actual como para /root (por si se ejecuta como root)
USERS_TEMPLATES="${HOME}/.local/share/godot/templates/3.5.3.stable"
ROOT_TEMPLATES="/root/.local/share/godot/templates/3.5.3.stable"

mkdir -p "${GODOT_DIR}"
mkdir -p "${USERS_TEMPLATES}"
mkdir -p "${ROOT_TEMPLATES}"

GODOT_URL="https://github.com/godotengine/godot-builds/releases/download/3.5.3-stable/Godot_v3.5.3-stable_x11.64.zip"
TEMPLATES_URL="https://github.com/godotengine/godot-builds/releases/download/3.5.3-stable/Godot_v3.5.3-stable_export_templates.tpz"

if [ ! -f "${GODOT_DIR}/godot" ]; then
    echo "Descargando Godot 3.5.3-stable..."
    curl -L -o "${TOOLS_DIR}/godot.zip" "${GODOT_URL}"
    unzip -o "${TOOLS_DIR}/godot.zip" -d "${GODOT_DIR}"
    mv "${GODOT_DIR}"/Godot_v3.5.3-stable_x11.64 "${GODOT_DIR}/godot"
    chmod +x "${GODOT_DIR}/godot"
    rm "${TOOLS_DIR}/godot.zip"
    echo "Godot instalado en ${GODOT_DIR}/godot"
else
    echo "Godot 3.5.3 ya está instalado en ${GODOT_DIR}/godot"
fi

if [ ! -f "${USERS_TEMPLATES}/android_release.apk" ] || [ ! -f "${ROOT_TEMPLATES}/android_release.apk" ]; then
    echo "Descargando plantillas de exportación para Godot 3.5.3..."
    curl -L -o "${TOOLS_DIR}/templates.tpz" "${TEMPLATES_URL}"
    unzip -o "${TOOLS_DIR}/templates.tpz" -d "${TOOLS_DIR}/templates_extract"
    cp -r "${TOOLS_DIR}/templates_extract/templates/"* "${USERS_TEMPLATES}/"
    cp -r "${TOOLS_DIR}/templates_extract/templates/"* "${ROOT_TEMPLATES}/"
    rm -rf "${TOOLS_DIR}/templates.tpz" "${TOOLS_DIR}/templates_extract"
    echo "Plantillas de exportación instaladas."
else
    echo "Plantillas de exportación ya instaladas."
fi

echo "Verificando Godot:"
"${GODOT_DIR}/godot" --version
