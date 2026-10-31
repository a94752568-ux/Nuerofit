Actúa como agente de seguridad de build para el proyecto NeuroFit (Godot 3.5, 
exportación Android). Tu misión en esta tarea es ÚNICAMENTE generar, respaldar 
y documentar el keystore de firma de release para Google Play. No generes 
APK/AAB todavía, no toques código del juego.

CONTEXTO
- El keystore firma la app de forma permanente en Play Store: si se pierde 
  tras publicar, NO se puede actualizar la app nunca más con otro keystore.
- Todo lo que generes debe quedar FUERA del repositorio git (el .gitignore 
  debe bloquearlo explícitamente).
- Sistema operativo del entorno de build: [ESPECIFICA: Linux/Windows/macOS].

PASOS A SEGUIR

1. Verifica prerrequisitos y repórtalos:
   - keytool (JDK) disponible: keytool -help debe responder.
   - Directorio de build creado y con permisos adecuados.
   Si algo falta, detente e indica exactamente qué instalar.

2. Genera el keystore de release con keytool:
   - Alias: neurofit-release
   - Algoritmo: RSA 2048 bits (o Ed25519/ECC si el soporte lo permite; 
     si dudas, RSA 2048 que es lo universalmente aceptado).
   - Validez: 10000 días (mínimo exigido por Play Store para subidas 
     desde 2033 en adelante).
   - CN/O: datos de NeuroFit como organización open source.
   - UBICACIÓN: fuera del repo, p. ej. signing/neurofit-release.keystore 
     en un directorio no versionado.

3. Gestión de credenciales (CRÍTICO):
   - Genera una contraseña fuerte (≥24 caracteres) para keystore y otra 
     distinta para el alias.
   - NO las escribas en ningún archivo del repo ni en el código.
   - Guárdalas en variables de entorno del entorno de build 
     (p. ej. en .env.local NO versionado o el gestor de secretos 
     disponible), con los nombres exactos que export_presets.cfg 
     espera de Godot.
   - Verifica que .gitignore bloquea: *.keystore, *.jks, .env.local, 
     signing/.

4. Respaldo obligatorio (reporta cada uno como verificado):
   - Copia del keystore en un segundo medio distinto (directorio 
     de respaldo externo al proyecto).
   - Un archivo RESPALDO-KEYSTORE.md (fuera del repo o en docs/ sin 
     secretos) que indique: ubicación del keystore, ubicación de los 
     respaldos, nombres de variables de entorno usadas, fecha de 
     creación, validez en años, y el comando keytool para verificar 
     integridad del keystore en el futuro.
   - Instruccion explícita al humano: descargar y guardar el keystore 
     en 2 medios físicos (nube cifrada + disco local) ANTES de la 
     primera subida a Play Store.

5. Verifica y REPORTA con evidencia:
   - keytool -list -v -keystore <ruta> (mostrar solo metadatos: alias, 
     algoritmo, validez; JAMÁS mostrar contraseñas en el reporte).
   - Confirmación de que un "git status" no muestra el keystore ni 
     archivos de secretos.
   - Confirmación de que .gitignore contiene las entradas correctas.

REGLAS
- Jamás imprimas, copies al portapapeles ni escribas en logs las 
  contraseñas (menciona solo que existen y dónde viven).
- No subas nada al repo salvo la actualización de .gitignore y, si 
  aplica, la plantilla de variables de entorno (.env.example con 
  nombres SIN valores).
- Si el entorno no tiene un gestor de secretos, documenta la 
  alternativa más simple y reversible en docs/adr/NNN-keystore.md.

ENTREGABLE FINAL
Reporta: ruta del keystore (sin secretos), metadados del certificado, 
variables de entorno definidas, contenido de .gitignore actualizado, 
estado de los 2 respaldos, contenido del archivo RESPALDO-KEYSTORE.md, 
y el ADR si creaste uno. Recuerda al humano, en negritas, que debe 
descargar y respaldar el keystore antes de la primera publicación.
