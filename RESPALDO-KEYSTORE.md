# RESPALDO DE KEYSTORE DE RELEASE — NEUROFIT

> [!CAUTION]
> **¡IMPORTANTE / CRÍTICO!** El archivo `signing/neurofit-release.keystore` es el **único medio** para firmar las actualizaciones oficiales de NeuroFit en Google Play Store. Si se pierde este archivo y sus contraseñas, **Google Play no permitirá actualizar la app jamás**, obligando a publicar una nueva aplicación con un paquete nuevo.

## Información del Certificado
- **Alias del certificado**: `neurofit-release`
- **Ubicación local**: `signing/neurofit-release.keystore` (Fuera de Git, bloqueado por `.gitignore`)
- **Algoritmo**: RSA 2048 bits (PKCS12)
- **Validez**: 10,000 días (~27 años)
- **Variables de entorno asociadas**: `NEUROFIT_KEYSTORE_PASS`, `NEUROFIT_KEYALIAS_PASS` (definidas en `.env.local`)

## Instrucciones de Respaldo Obligatorio
Antes de realizar la primera subida a Google Play Console, el desarrollador responsable **DEBE**:
1. Copiar el archivo `signing/neurofit-release.keystore` a **dos medios físicos independientes** (ej. disco duro encriptado local + almacenamiento en nube corporativa cifrada).
2. Guardar las contraseñas asociadas (`NEUROFIT_KEYSTORE_PASS` y `NEUROFIT_KEYALIAS_PASS`) en un gestor de contraseñas seguro (1Password, Bitwarden, etc.).

## Comando de Verificación de Integridad
Para verificar la validez e integridad del keystore en el futuro:
```bash
keytool -list -v -keystore signing/neurofit-release.keystore -alias neurofit-release
```
*(Se requerirá la contraseña del keystore).*
