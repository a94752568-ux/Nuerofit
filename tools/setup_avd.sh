#!/usr/bin/env bash
set -e

export ANDROID_HOME="/home/aegis2/Android/Sdk"
AVDMANAGER="${ANDROID_HOME}/cmdline-tools/latest/bin/avdmanager"
EMULATOR="${ANDROID_HOME}/emulator/emulator"

AVD_NAME="neurofit_avd"

# Verificar si el AVD ya existe
if ! "${AVDMANAGER}" list avd | grep -q "${AVD_NAME}"; then
    echo "Creando AVD '${AVD_NAME}' (API 37 Google Play x86_64)..."
    echo "no" | "${AVDMANAGER}" create avd \
        --name "${AVD_NAME}" \
        --package "system-images;android-37.0;google_apis_playstore;x86_64" \
        --device "pixel"
    echo "AVD creado exitosamente."
else
    echo "El AVD '${AVD_NAME}' ya existe."
fi

echo "Para iniciar el emulador y correr la app automáticamente, ejecuta:"
echo "  ./tools/run_emulator.sh"
