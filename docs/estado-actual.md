# NeuroFit — Estado actual y ruta del proyecto

**Fecha de referencia:** 2026-10-31  
**Rama de trabajo:** `main` (PRs por feature)  
**Plataforma prioritaria:** Android (API 24+, GLES2, armv7 + arm64)

---

## Fases

- **A** ✅ esqueleto: PluginLoader scan + loop EventBus
- **B** ✅ `calc.x20` jugable: generador 1–8, pad, 20 trials, summary persistente
- **C** ✅ suite: 5 minijuegos + Hub data-driven + gráfica
- **D** 🚧 beta pública: rendimiento gama baja + F-Droid (MIT, fastlane, privacidad)

---

## Inventario

- **Plugins jugables:** `calc.x20`, `symbols.speed`, `head.count`, `workmem.adaptive`, `stroop.voice` (voz fuera de v0.1)
- **Autoloads:** EventBus, MotionManager, AudioManager (carga perezosa + loop), PlatformSupervisor, CognitiveEngine, PluginLoader, SessionManager, SceneManager, DebugOverlay (F10)
- **Datos:** `user://stats.json` (sesiones + últimos 7 + índice cognitivo)
- **Docs:** README, roadmap, guía de plugins, diseño calc.x20, ADR keystore, PRIVACY, LICENSE

---

## Deuda técnica abierta

| # | Deuda | Prioridad |
|---|-------|-----------|
| 1 | Glifos (`👤`, `●■▲`) por validar en la fuente por defecto de Godot 3.5 — riesgo de tofu en dispositivo | antes de beta |
| 2 | Dificultad global compartida entre dominios (staircase único) | post-beta |
| 3 | `GameSelection`/`MainShell` redundantes frente al Hub | post-beta |
| 4 | Persistencia sin schema version | post-beta |
| 5 | Teclado físico declarado en `calc.x20` pero sin implementar | post-beta |
| 6 | `sessions` crece sin límite en stats.json | post-beta |

---

## Criterios Fase D (en curso)

- [x] LICENSE (MIT) + PRIVACY.md
- [x] Fastlane metadata
- [x] APK arm-only sin `INTERNET`
- [x] Audio perezoso + loop musical
- [x] Overlay de rendimiento (F10)
- [ ] 60 FPS medidos en dispositivo gama baja — pendiente pruebas en móvil
- [ ] Screenshots + smoke test en dispositivo — pendiente pruebas en móvil
- [ ] AAB release firmado (keystore local, fuera de git)
- [ ] MR a fdroiddata tras validar en dispositivo

---

## Referencias

- [`roadmap.md`](roadmap.md) · [`guia-plugins.md`](guia-plugins.md) · [`plugin-calc-x20-design.md`](plugin-calc-x20-design.md)
- ADR keystore: [`adr/001-keystore.md`](adr/001-keystore.md)
- Playbook en la raíz del repo
