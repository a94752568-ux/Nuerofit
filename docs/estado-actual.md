# NeuroFit — Estado actual y ruta del proyecto

**Fecha de referencia:** 2026-10-30  
**Rama de trabajo:** `feature/calc-x20-stub`  
**Plataforma prioritaria:** Android (API 24+, GLES2, armv7 + arm64)

---

## Ruta conceptual

```
Playbook + ADRs
      │
      ▼
Esqueleto de sistemas  →  Fase A (cerrada)  →  Fase B (en curso)
                              │                      │
                              │                      ├─ ProblemGenerator
                              │                      ├─ NumericPad
                              │                      └─ 20 trials jugables
                              ▼
                         calc.x20 stub + PluginLoader scan + Hub path
```

---

## Inventario relevante

### Autoloads
EventBus, MotionManager, AudioManager, PlatformSupervisor, CognitiveEngine, PluginLoader (scan), SessionManager, SceneManager.

### Plugin piloto
- `plugins/calc_x20/` con `minigame.json`, `CalcX20`, `ProblemGenerator`, `NumericPad`
- Hub resuelve escena vía `PluginLoader.get_scene_path("calc.x20")`

### Escenas
- Principal: `HubCentral.tscn`
- Plugin: `plugins/calc_x20/CalcX20.tscn`

---

## Deuda técnica prioritaria (post Fase A)

| # | Deuda | Fase |
|---|-------|------|
| 1 | Hub aún hardcodea tarjetas UI (solo la ruta de escena usa loader) | C |
| 2 | Presets de motion en código, no `.tres` | B–C |
| 3 | Audio paths con espacios | B |
| 4 | Tests mínimos del loop de sesión | B |
| 5 | Persistencia sin schema version | B–C |
| 6 | `MainShell` huérfano | A cleanup |

---

## Contratos cumplidos

- GLES2, offline-first, EventBus entre sistemas
- Plugin descubierto por manifiesto
- Loop sesión: `game_started` → `game_answer` × N → `game_ended`
- Keystore fuera de Git (ADR 001)

## Criterio Fase B (en progreso)

- [x] Generador por niveles 1–8
- [x] NumericPad táctil
- [x] 20 trials con timing y summary
- [x] Feedback MotionManager + audio events
- [ ] Medición de frame time documentada en dispositivo/emulador
- [ ] APK debug smoke en API 24+

---

## Referencias

- [`plugin-calc-x20-design.md`](plugin-calc-x20-design.md)
- [`roadmap.md`](roadmap.md)
- Playbook en la raíz del repo
- ADR keystore: `docs/adr/001-keystore.md`
