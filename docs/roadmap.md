# NeuroFit — Roadmap por fases

**Producto:** app Android de entrenamiento cognitivo (Godot 3.5, GLES2, offline-first)  
**Horizonte v1.0:** 5 minijuegos del playbook  
**Hermanos:** [estado-actual.md](estado-actual.md) · [plugin-calc-x20-design.md](plugin-calc-x20-design.md)

## Vista general

| Fase | Nombre | Gate de salida |
|------|--------|----------------|
| **A** | Cerrar el esqueleto | Loop sesión plugin en desktop/Android |
| **B** | Piloto jugable | 20 trials reales + save + APK estable |
| **C** | Suite v1.0 | 5 juegos + dashboard |
| **D** | Beta pública | 60 FPS gama baja + F-Droid |

## Fase A — Esqueleto *(cerrada en código)*

- [x] `plugins/calc_x20/minigame.json` + escena
- [x] `PluginLoader.scan_plugins()`
- [x] Hub resuelve escena vía loader
- [x] Loop `game_started` → `game_answer` → `game_ended`

## Fase B — `calc.x20` jugable *(en curso)*

- [x] ProblemGenerator niveles 1–8
- [x] NumericPad táctil
- [x] 20 trials + summary
- [x] Feedback MotionManager + audio events
- [ ] Frame time medido en estrés
- [ ] APK debug smoke API 24+

## Fase C — Suite

Orden: `calc` → `symbols.speed` → `head.count` → `workmem.adaptive` → `stroop.voice` (voz al final).

## Fase D — Beta

Rendimiento, AAB firmado, guía de plugins, privacidad offline.

## Fuera de v1.0

Cuentas/nube, ranking online, más de 5 minijuegos, GLES3 obligatorio.

```
A → B → C → D
```
