# ADR 001: Estrategia de Firma y Gestión de Keystore para Android

## Contexto
NeuroFit requiere la publicación de artefactos en Google Play (AAB release) y compilaciones de prueba (APK debug). La firma digital con keystore es obligatoria y permanente en Google Play Store; la pérdida del keystore impide actualizaciones futuras de la aplicación.

## Opciones Consideradas
1. **Keystore versionado en Git**: Descartado por motivos críticos de seguridad (riesgo de exposición de credenciales y apropiación de la app).
2. **Keystore externo fuera de Git con gestión por variables de entorno (.env.local)**: Seleccionado. El archivo binario `.keystore` se almacena localmente en la carpeta no versionada `signing/`, bloqueado por `.gitignore`, y las contraseñas se inyectan mediante variables de entorno locales.

## Decisión
- Se genera un keystore PKCS12 con algoritmo RSA de 2048 bits y validez de 10,000 días (alias: `neurofit-release`).
- Se almacena en `signing/neurofit-release.keystore`.
- Se ignoran en `.gitignore` todos los archivos de extensión `.keystore`, `.jks` y `.env.local`.
- Se requiere respaldo físico obligatorio en al menos dos medios externos antes de la publicación oficial en Google Play.

## Consecuencias
- Seguridad robusta contra fugas de credenciales.
- Necesidad de documentar el procedimiento de respaldo en `RESPALDO-KEYSTORE.md` para el equipo de desarrollo.
