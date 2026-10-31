# NeuroFit

**Plataforma de entrenamiento cognitivo offline-first**  
Sucesora espiritual de *Dr. Kawashima's Brain Training* — multiplataforma, código abierto, orientada a Android.

![Godot 3.5](https://img.shields.io/badge/Godot-3.5-478CBF?logo=godot-engine)
![GLES2](https://img.shields.io/badge/Render-GLES2-success)
![Android API 24+](https://img.shields.io/badge/Android-API%2024%2B-3DDC84?logo=android)
![Offline-first](https://img.shields.io/badge/Offline--first-yes-blue)

## Qué es

App de **juegos mentales** para hardware de bajo consumo. Entrena dominios cognitivos con minijuegos cortos, dificultad adaptativa y feedback premium **sin red ni cuenta**.

| Dominio | Color | Minijuego v1.0 |
|---------|-------|----------------|
| Velocidad de procesamiento | Coral `#FF6B6B` | `calc.x20` |
| Control inhibitorio | Teal `#4ECDC4` | `stroop.voice` |
| Memoria | Índigo `#6C63FF` | `head.count`, `workmem.adaptive` |
| Atención | Ámbar `#FFB84C` | `symbols.speed` |

**Prioridad:** Android (API 24+, armv7 + arm64, GLES2).

## Estado actual (Fase A)

| Capa | Estado |
|------|--------|
| EventBus + autoloads | Esqueleto operativo |
| Hub central | OLED; lanza plugins vía PluginLoader |
| PluginLoader | Escanea `plugins/*/minigame.json` |
| `calc.x20` | **Stub** INTRO → PLAYING → RESULTS |
| Resto de minijuegos | Pendiente |

Documentos: `docs/estado-actual.md`, `docs/plugin-calc-x20-design.md`, `docs/roadmap.md`, playbook en la raíz.

## Arranque

```bash
git clone https://github.com/a94752568-ux/Nuerofit.git
cd Nuerofit
# Abrir project.godot con Godot 3.5 → F5 (HubCentral)
```

Probar stub: tarjeta **Cálculos ×20** → Empezar → Responder ×5 → Volver al Hub.

Build Android: `./build_android.sh` (ver `agent_build.md` y ADR keystore).

## Arquitectura

Comunicación entre capas solo por **EventBus**. Minijuegos = plugins en `plugins/<id>/` con `minigame.json`. GLES2, offline-first, presupuesto de frame 16.6 ms.

## Roadmap resumido

- **A** (en curso): stub plugin + loop EventBus  
- **B**: `calc.x20` jugable (generador + pad + 20 trials)  
- **C**: 5 minijuegos + dashboard  
- **D**: beta F-Droid / rendimiento gama baja  

Detalle en `docs/roadmap.md`.

## Licencia

Código orientado a MIT / F-Droid. Sin analytics ni tracking.
