# Plugin `calc.x20` — Fase B

Minijuego de **velocidad de procesamiento** (coral `#FF6B6B`).

## Estado

- **Fase B (actual):** jugable
  - 20 trials reales
  - `ProblemGenerator` por niveles 1–8
  - `NumericPad` táctil (dígitos, ⌫, OK)
  - Feedback vía `MotionManager` + eventos de `AudioManager`
  - Señales EventBus: `game_started` / `game_answer` / `game_ended`

## Archivos

| Archivo | Rol |
|---------|-----|
| `minigame.json` | Manifiesto |
| `CalcX20.tscn` / `CalcX20.gd` | Escena + state machine |
| `ProblemGenerator.gd` | Estímulos por dificultad |
| `NumericPad.gd` | Teclado numérico |

## Cómo probar

1. Godot 3.5 → F5 → Hub → **Cálculos ×20**
2. Empezar → 20 operaciones con el pad → Volver al Hub

| Nivel | Operaciones |
|-------|-------------|
| 1–2 | Suma simple |
| 3–4 | Suma / resta |
| 5–6 | + − × |
| 7–8 | + − × ÷ exacta |
