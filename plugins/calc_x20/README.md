# Plugin `calc.x20` — stub Fase A

Minijuego piloto de **velocidad de procesamiento**.

## Estado

- **Fase A (actual):** stub jugable que cierra el loop EventBus.
  - INTRO → PLAYING (5 trials sintéticos) → RESULTS → Hub
  - Emite `game_started`, `game_answer`, `game_ended`
- **Fase B:** generador real, teclado numérico, 20 trials (ver `docs/plugin-calc-x20-design.md`)

## Archivos

| Archivo | Rol |
|---------|-----|
| `minigame.json` | Manifiesto para `PluginLoader` |
| `CalcX20.tscn` | Escena raíz |
| `CalcX20.gd` | State machine + UI mínima en código |

## Cómo probar

1. Abrir el proyecto en Godot 3.5
2. Ejecutar (F5) → HubCentral
3. Tocar la tarjeta **Cálculos ×20**
4. Empezar → pulsar «Responder» cinco veces → Volver al Hub

En consola deberías ver cargas de `PluginLoader`, `game_started`, respuestas y `game_ended`.
