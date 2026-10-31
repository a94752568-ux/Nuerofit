# Diseño concreto — Plugin `calc.x20`

**ID:** `calc.x20` · **Dominio:** velocidad de procesamiento (coral `#FF6B6B`)  
**Rol:** primer plugin de producción.

## Objetivo

Loop completo: Hub → plugin → EventBus → CognitiveEngine/SessionManager → Hub.

## Estructura

```
plugins/calc_x20/
  minigame.json
  CalcX20.tscn / CalcX20.gd
  ProblemGenerator.gd
  NumericPad.gd
```

## Manifiesto (campos clave)

`id`, `version`, `engine_min`, `category`, `difficulty_range` [1,8], `session_shape.target_trials` 20, `input` [tap, keyboard], `scene` → `CalcX20.tscn`.

## Estados

`INTRO → PLAYING → RESULTS` (+ pausa en focus out).

## Generador por nivel

| Nivel | Operaciones |
|-------|-------------|
| 1–2 | `+` |
| 3–4 | `+` `−` |
| 5–6 | `+` `−` `×` |
| 7–8 | `+` `−` `×` `÷` exacta |

## EventBus

| Momento | Señal |
|---------|-------|
| Inicio PLAYING | `game_started` |
| Cada respuesta | `game_answer` `{correct, time_ms, difficulty, stimulus, response}` |
| Fin | `game_ended` summary |
| Volver | `scene_change_requested` → HubCentral |

## Criterios

**Fase A:** stub integrado. **Fase B:** 20 trials, pad, generador, feedback, APK smoke.

## Fuera de alcance v0.1

Trazo vectorial, multiplayer, Vosk, asset packs.
