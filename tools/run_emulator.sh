#!/usr/bin/env bash
set -e

export ANDROID_HOME="/home/aegis2/Android/Sdk"
EMULATOR="${ANDROID_HOME}/emulator/emulator"
ADB="${ANDROID_HOME}/platform-tools/adb"
AVD_NAME="neurofit_avd"
APK_PATH="build/android/neurofit-debug.apk"

if [ ! -f "${APK_PATH}" ]; then
    echo "APK no encontrado. Compilando NeuroFit..."
    ./build_android.sh
fi

echo "Iniciando emulador '${AVD_NAME}'..."
"${EMULATOR}" -avd "${AVD_NAME}" -netdelay none -netspeed full -gpu swiftshader_indirect &
EMULATOR_PID=$!

echo "Esperando a que el dispositivo emulado esté listo..."
"${ADB}" wait-for-device

# Esperar a que el boot termine
while [ "$("${ADB}" shell getprop sys.boot_completed 2>&1 | tr -d '\r')" != "1" ]; do
    sleep 2
done

echo "¡Emulador listo! Instalando NeuroFit..."
"${ADB}" install -r "${APK_PATH}"

echo "Iniciando NeuroFit en el emulador..."
"${ADB}" shell am start -n org.neurofit.app/org.godotengine.godot.Godot

echo "¡Aplicación iniciada con éxito en el emulador!"
