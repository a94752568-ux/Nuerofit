# NeuroFit — Roadmap por fases

**Producto:** app Android de entrenamiento cognitivo (Godot 3.5, GLES2, offline-first)  
**Horizonte v1.0:** 5 minijuegos del playbook  
**Hermanos:** [estado-actual.md](estado-actual.md) · [guia-plugins.md](guia-plugins.md) · [plugin-calc-x20-design.md](plugin-calc-x20-design.md)

## Vista general

| Fase | Nombre | Gate de salida | Estado |
|------|--------|----------------|--------|
| **A** | Cerrar el esqueleto | Loop sesión plugin en desktop/Android | ✅ cerrada |
| **B** | Piloto jugable | 20 trials reales + save + APK estable | ✅ cerrada en desktop |
| **C** | Suite v1.0 | 5 juegos + dashboard | ✅ cerrada |
| **D** | Beta pública | 60 FPS gama baja + F-Droid | 🚧 en curso |

## Fase B — `calc.x20` jugable *(cerrada)*

- [x] ProblemGenerator niveles 1–8
- [x] NumericPad táctil
- [x] 20 trials + summary
- [x] Feedback MotionManager + audio events
- [x] Hit-pause con tiempo real + guardas de yield (PR #2)
- [ ] Frame time medido en estrés **en dispositivo** (pendiente pruebas en móvil)

## Fase C — Suite *(cerrada)*

- [x] `calc.x20` → `symbols.speed` → `head.count` → `workmem.adaptive` → `stroop.voice` (voz fuera de v0.1)
- [x] Hub data-driven desde manifiestos + gráfica de rendimiento
- [x] Tests headless del loop

## Fase D — Beta pública *(en curso)*

**Rendimiento gama baja**

- [x] Audio perezoso (~20 MB → bajo demanda) + loop musical
- [x] Overlay de rendimiento (F10): FPS, frame time y perfil de calidad
- [ ] Medición 60 FPS en dispositivo gama baja — pendiente pruebas en móvil

**F-Droid**

- [x] `LICENSE` (MIT)
- [x] `PRIVACY.md` — declaración offline/sin tracking
- [x] Fastlane metadata (título, descripciones, changelog)
- [x] APK: solo ARM (sin x86/x86_64) y sin permiso `INTERNET`
- [ ] Screenshots y smoke test en dispositivo — pendiente pruebas en móvil
- [ ] AAB release firmado con keystore local (fuera de git)
- [ ] MR a fdroiddata tras validar en dispositivo

**Guía de plugins**

- [x] `docs/guia-plugins.md`

## Fuera de v1.0

Cuentas/nube, ranking online, más de 5 minijuegos, GLES3 obligatorio, voz (Vosk) en stroop.voice.

```
A → B → C → D
```
