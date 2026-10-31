Actúa como agente de build de NeuroFit (Godot 3.5, proyecto multiplataforma: 
Linux, Windows, Android). Tu misión en esta tarea es ÚNICAMENTE configurar y 
generar los artefactos de exportación Android: un APK de prueba/debug y un 
AAB release firmado listo para subir a Google Play. No agregues gameplay ni 
toques otro código.

CONTEXTO
- Motor: Godot 3.5.x con export templates para Android instaladas.
- Proyecto ya existe con autoloads (EventBus, MotionManager, AudioManager, 
  PlatformSupervisor, CognitiveEngine, PluginLoader, SessionManager, 
  SceneManager) en res://autoload/ y escena principal configurada.
- Render: GLES2 obligatorio. Nada de Vulkan ni GLES3.
- Min spec Android: API 24, OpenGL ES 2.0, armv7 + arm64, 2 GB RAM.
- Idioma del proyecto y de los comentarios: español.

PASOS A SEGUIR

1. Verifica prerrequisitos ANTES de todo y repórtalos:
   - Versión de Godot y plantillas de exportación Android instaladas.
   - Android SDK con build-tools y platform-tools en PATH.
   - Java/JDK (17 o el que requiera tu SDK) y herramienta de alineación.
   - keystore de firma (si no existe, genera uno de release con keytool 
     y guárdalo FUERA del repo; documenta la contraseña en variables de 
     entorno, jamás en el código).
   Si algo falta, detente y reporta exactamente qué instalar y cómo.

2. Configura export_presets.cfg con DOS presets "Android":
   a) Preset "NeuroFit Debug (APK)":
      - Export format: APK.
      - Min SDK 24, target SDK el más reciente disponible.
      - Arquitecturas: armv7 y arm64.
      - Modo debug, firma con keystore debug o el de release en modo 
        debuggable.
      - Permiso RECORD_AUDIO declarado pero marcarlo para uso condicional 
        (Vosk de Stroop); el juego debe funcionar sin él.
      - Sin permisos de red, sin tracking, sin ANALYTICS.
   b) Preset "NeuroFit Release (AAB)":
      - Export format: AAB (Google Play).
      - Firma release con el keystore, v1+v2 signing activados.
      - Package name: com.neurofit.game (o el que esté en el proyecto).
      - Version code/version name leídos de un único lugar (evita 
        divergencia entre APK y AAB).
      - Texturas: ASTC si el soporte lo permite, fallback ETC2; verificar 
        compatibilidad GLES2.
      - Asset packs on-demand preparados para minijuegos extra (si Godot 
        3.5 lo soporta en el preset; si no, documéntalo como limitación 
        en docs/adr/ y propón la alternativa).

3. Crea o verifica AndroidManifest customizado (si aplica en 3.5) para:
   - Orientación: retrato y paisaje soportadas (o la que defina el 
     proyecto; ver README o settings del proyecto).
   - Audio focus: la app debe silenciar su audio ante llamadas o 
     reproducción de música externa (USE_FOCUS_AUDIO en Godot).

4. Genera los artefactos:
   a) APK debug: godot --headless --export-debug "NeuroFit Debug (APK)" 
      build/android/neurofit-debug.apk
   b) AAB release: godot --headless --export-release "NeuroFit Release 
      (AAB)" build/android/neurofit-release.aab
   Repite la build 2 veces si la primera falla por caché de export 
   templates; si persiste el fallo, reporta el error completo.

5. Verifica y REPORTA con evidencia (no afirmes nada sin verificar):
   - APK: instálalo en emulador o dispositivo con API 24 y ábrelo; 
     confirma que arranca a la escena principal sin crash.
   - AAB: valida su firma y estructura (apksigner verify o bundletool 
     con build-apks --mode=universal como smoke test).
   - godot --headless --check-only sin errores nuevos.
   - Tamaños finales de APK y AAB.
   - Línea de tiempo de la build (para detectar regresiones de tamaño).

6. Registra en el repo:
   - export_presets.cfg versionado (SIN secretos ni contraseñas).
   - docs/adr/NNN-export-android.md con decisiones: package name, 
     versionado, keystore (ubicación, NO el archivo), permisos, 
     limitaciones de asset packs en Godot 3.5.
   - Script reproducible build_android.sh (o .ps1) que regenere ambos 
     artefactos con un solo comando.

REGLAS
- No modifiques código de juego, escenas ni autoloads salvo ajuste mínimo 
  imprescindible para exportar (documéntalo si ocurre).
- No subas el keystore ni contraseñas al repo.
- No uses permisos, SDKs ni servicios de terceros que no estén en el 
  playbook del proyecto.
- Si una decisión no está cubierta por el playbook, elige la opción más 
  simple y reversible y regístrala como ADR.

ENTREGABLE FINAL
Reporta: prerrequisitos OK, contenido de ambos presets, rutas de los 
artefactos generados, evidencia de verificación (logs), tamaño de cada 
artefacto, y el contenido del ADR creado. Si algo falla, reporta el error 
exacto y tu plan de corrección antes de reintentar.
