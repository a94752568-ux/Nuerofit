# Guía de plugins — cómo escribir un minijuego para NeuroFit

Un minijuego es una carpeta en `res://plugins/<plugin_id>/` con tres piezas: manifiesto, escena y lógica. `PluginLoader` la descubre sola al escanear; no hay registro manual.

## 1. Estructura mínima

```
plugins/
└── mi_juego/
    ├── minigame.json      ← manifiesto (obligatorio)
    ├── MiJuego.tscn       ← escena raíz (la ruta va en el manifiesto)
    ├── MiJuego.gd         ← lógica
    └── README.md          ← qué entrena y cómo se calibra
```

## 2. El manifiesto `minigame.json`

Campos obligatorios (los valida `PluginLoader.validate_manifest`; sin uno, el plugin se ignora con warning):

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | String | Identificador único, ej. `"mi.juego"` |
| `version` | String | Semántica, ej. `"1.0.0"` |
| `engine_min` | String | Mínimo de Godot, ej. `"3.5.0"` |
| `category` | String | Dominio cognitivo (`processing_speed`, `memory`, `inhibition`, `attention`) |
| `difficulty_range` | Array | `[min, max]` de niveles usados |
| `session_shape` | Object | Duración/trials de la sesión |
| `input` | Array | `["tap", "keyboard"]` |
| `render_profile` | String | Perfil de render, ej. `"ui_2d_low"` |
| `scene` | String | Ruta de la escena raíz, `res://plugins/...` |

Opcionales: `cognitive_hooks` (métricas y estrategia adaptativa) y `display` (`name`, `short_name`, `color` `#RRGGBB`, `icon`) — el Hub usa `display` para la tarjeta.

Ejemplo completo: [`plugins/calc_x20/minigame.json`](../plugins/calc_x20/minigame.json).

## 3. Contrato EventBus

El juego **debe** emitir por el `EventBus` (usa siempre `EventBus.emit_safe("señal", [args])`):

1. `game_started` con su `plugin_id` al iniciar la sesión (arranca SessionManager y AudioManager).
2. `game_answer` por cada trial:

```json
{ "plugin_id": "mi.juego", "correct": true, "time_ms": 1234.0, "difficulty": 3, "stimulus": "7 + 5", "response": "12" }
```

   (`CognitiveEngine` ajusta el nivel 1–8 con esta señal: ventana móvil de 8 respuestas).

3. `game_ended` con el summary al terminar:

```json
{ "plugin_id": "mi.juego", "session_id": "...", "trials": 20, "correct_count": 17, "accuracy": 0.85, "avg_reaction_time": 2100.0, "final_difficulty": 4, "duration_ms": 63000 }
```

   (El Hub lo persiste en `user://stats.json` y refresca índice y gráfica).

## 4. Máquina de estados

Sigue `Constants.GameState`: `INTRO → PLAYING → RESULTS`. Reglas duras:

- **Guard tras cada `yield`**: `if _state != Constants.GameState.PLAYING: return` — protege contra cambio de escena a mitad del feedback.
- Tras `game_ended`, el botón de salida emite `scene_change_requested` con `res://scenes/HubCentral.tscn`.
- Lee `CognitiveEngine.current_difficulty` al **inicio** de cada trial, no a mitad.

## 5. Presupuesto de rendimiento

- GLES2 y **16.6 ms** por frame: sin allocations por frame ni `_process` innecesario.
- Animaciones solo vía `MotionManager` (pool de tweens con prioridad), nunca Tweens sueltos.
- Audio solo vía `audio_event_triggered`: `correct_answer`, `error_answer`, `play_theme`.
- Temas musicales disponibles: `grounding`, `fluid`, `air`, `return`.
- Con el overlay F10 activo, el juego debe sostener 60 FPS en gama baja.

## 6. Checklist de publicación

- [ ] `minigame.json` pasa `validate_manifest` (ver `tests/`)
- [ ] 20 trials con timing y feedback correcto/error
- [ ] Summary con el schema exacto del §3
- [ ] Guard tras todos los `yield`
- [ ] README del plugin con dominio y calibración
- [ ] Probado en desktop y en un Android de gama baja (overlay F10 activo)
