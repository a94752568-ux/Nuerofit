# autoload/EventBus.gd
extends Node

# Señales de ciclo de vida de juego / minijuego
signal game_started(plugin_id)
signal game_paused()
signal game_resumed()
signal game_ended(summary)
signal game_answer(answer_data)

# Señales de motor cognitivo y dificultad
signal difficulty_changed(new_level)
signal calibration_updated(domain, baseline_score)

# Señales de plataforma y rendimiento
signal thermal_state_changed(profile_level)
signal input_event_normalized(input_type, position, value)

# Señales de UI y navegación
signal scene_change_requested(scene_path)

# Señales de audio
signal audio_event_triggered(event_name, params)

# Registro opcional de eventos para debugging/telemetría
var _event_log: Array = []
const MAX_LOG_SIZE: int = 100


func _ready() -> void:
	print("[EventBus] Inicializado correctamente.")


# Emisión segura de señales con verificación sintáctica
func emit_safe(signal_name: String, args: Array = []) -> bool:
	if not has_signal(signal_name):
		push_error("[EventBus] Intento de emitir señal inexistente: " + signal_name)
		return false

	_log_event(signal_name, args)

	match args.size():
		0:
			emit_signal(signal_name)
		1:
			emit_signal(signal_name, args[0])
		2:
			emit_signal(signal_name, args[0], args[1])
		3:
			emit_signal(signal_name, args[0], args[1], args[2])
		4:
			emit_signal(signal_name, args[0], args[1], args[2], args[3])
		_:
			push_error("[EventBus] Demasiados argumentos para emit_safe: " + str(args.size()))
			return false

	return true


func _log_event(signal_name: String, args: Array) -> void:
	var entry = {
		"timestamp": OS.get_ticks_msec(),
		"signal": signal_name,
		"args": args
	}
	_event_log.append(entry)
	if _event_log.size() > MAX_LOG_SIZE:
		_event_log.pop_front()


func get_event_log() -> Array:
	return _event_log.duplicate()


func clear_event_log() -> void:
	_event_log.clear()
