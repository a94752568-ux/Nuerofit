# plugins/calc_x20/CalcX20.gd
# Stub Fase A: cierra el loop Hub → plugin → EventBus → Hub.
# PLAYING emite respuestas sintéticas; el generador real y el pad llegan en Fase B.
extends Control

const PLUGIN_ID := "calc.x20"
const STUB_TRIALS := 5  # Fase B: 20 (session_shape.target_trials)
const Constants = preload("res://core/constants.gd")

# UI (creada en código para no depender de un .tscn frágil)
var _bg: ColorRect
var _title: Label
var _subtitle: Label
var _progress: Label
var _primary_btn: Button
var _status: Label

var _state: int = Constants.GameState.INTRO
var _trial_index: int = 0
var _correct_count: int = 0
var _reaction_sum_ms: float = 0.0
var _session_start_ms: int = 0
var _trial_start_ms: int = 0
var _busy: bool = false


func _ready() -> void:
	_build_ui()
	_enter_intro()


func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	_bg = ColorRect.new()
	_bg.anchor_right = 1.0
	_bg.anchor_bottom = 1.0
	_bg.color = Color(0.039, 0.039, 0.047)  # OLED
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	var margin := MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_constant_override("margin_left", 32)
	margin.add_constant_override("margin_right", 32)
	margin.add_constant_override("margin_top", 48)
	margin.add_constant_override("margin_bottom", 48)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_constant_override("separation", 20)
	margin.add_child(vbox)

	_title = Label.new()
	_title.align = Label.ALIGN_CENTER
	_title.valign = Label.VALIGN_CENTER
	_title.add_color_override("font_color", Color(0.95, 0.95, 0.97))
	_title.text = "Cálculos ×20"
	vbox.add_child(_title)

	_subtitle = Label.new()
	_subtitle.align = Label.ALIGN_CENTER
	_subtitle.autowrap = true
	_subtitle.add_color_override("font_color", Color(0.5, 0.5, 0.55))
	_subtitle.text = "Stub Fase A — respuestas sintéticas para validar el bus"
	vbox.add_child(_subtitle)

	_progress = Label.new()
	_progress.align = Label.ALIGN_CENTER
	_progress.add_color_override("font_color", Color(1.0, 0.42, 0.42))  # coral
	_progress.text = ""
	vbox.add_child(_progress)

	_status = Label.new()
	_status.align = Label.ALIGN_CENTER
	_status.autowrap = true
	_status.add_color_override("font_color", Color(0.7, 0.7, 0.75))
	_status.text = ""
	vbox.add_child(_status)

	_primary_btn = Button.new()
	_primary_btn.rect_min_size = Vector2(0, 56)
	_primary_btn.text = "Empezar"
	_primary_btn.connect("pressed", self, "_on_primary_pressed")
	vbox.add_child(_primary_btn)


func _enter_intro() -> void:
	_state = Constants.GameState.INTRO
	_trial_index = 0
	_correct_count = 0
	_reaction_sum_ms = 0.0
	_title.text = "Cálculos ×20"
	_subtitle.text = "Resuelve operaciones lo más rápido que puedas.\n(Stub: %d trials sintéticos)" % STUB_TRIALS
	_progress.text = ""
	_status.text = "Dominio: velocidad de procesamiento"
	_primary_btn.text = "Empezar"
	_primary_btn.disabled = false
	_busy = false


func _enter_playing() -> void:
	_state = Constants.GameState.PLAYING
	_session_start_ms = OS.get_ticks_msec()
	_trial_index = 0
	_correct_count = 0
	_reaction_sum_ms = 0.0
	_subtitle.text = "Sesión en curso"
	_primary_btn.text = "Responder (stub)"
	_primary_btn.disabled = false
	EventBus.emit_safe("game_started", [PLUGIN_ID])
	_start_trial()


func _start_trial() -> void:
	_trial_index += 1
	_trial_start_ms = OS.get_ticks_msec()
	_progress.text = "Trial %d / %d" % [_trial_index, STUB_TRIALS]
	_status.text = "Toca «Responder» para emitir game_answer"
	_busy = false
	_primary_btn.disabled = false


func _submit_stub_answer() -> void:
	if _busy or _state != Constants.GameState.PLAYING:
		return
	_busy = true
	_primary_btn.disabled = true

	var time_ms: float = float(OS.get_ticks_msec() - _trial_start_ms)
	# Alterna acierto/error para ejercitar la escalera del CognitiveEngine
	var correct: bool = (_trial_index % 3) != 0
	if correct:
		_correct_count += 1
	_reaction_sum_ms += time_ms

	var difficulty: int = CognitiveEngine.current_difficulty

	var answer := {
		"plugin_id": PLUGIN_ID,
		"correct": correct,
		"time_ms": time_ms,
		"difficulty": difficulty,
		"stimulus": "stub_%d" % _trial_index,
		"response": "ok" if correct else "x"
	}
	EventBus.emit_safe("game_answer", [answer])

	if correct:
		EventBus.emit_safe("audio_event_triggered", ["correct_answer", {}])
	else:
		EventBus.emit_safe("audio_event_triggered", ["error_answer", {}])

	_status.text = "OK" if correct else "Error (stub)"
	yield(get_tree().create_timer(0.35), "timeout")

	if _trial_index >= STUB_TRIALS:
		_enter_results()
	else:
		_start_trial()


func _enter_results() -> void:
	_state = Constants.GameState.RESULTS
	var duration_ms: int = OS.get_ticks_msec() - _session_start_ms
	var accuracy: float = 0.0
	if STUB_TRIALS > 0:
		accuracy = float(_correct_count) / float(STUB_TRIALS)
	var avg_rt: float = 0.0
	if STUB_TRIALS > 0:
		avg_rt = _reaction_sum_ms / float(STUB_TRIALS)

	var final_diff: int = CognitiveEngine.current_difficulty

	var summary := {
		"plugin_id": PLUGIN_ID,
		"session_id": SessionManager.current_session_id,
		"trials": STUB_TRIALS,
		"correct_count": _correct_count,
		"accuracy": accuracy,
		"avg_reaction_time": avg_rt,
		"final_difficulty": final_diff,
		"duration_ms": duration_ms
	}

	_title.text = "Resultados"
	_subtitle.text = "Sesión stub completada"
	_progress.text = "Aciertos: %d / %d (%.0f%%)" % [_correct_count, STUB_TRIALS, accuracy * 100.0]
	_status.text = "RT medio: %.0f ms  ·  Dificultad: %d  ·  %d ms" % [avg_rt, final_diff, duration_ms]
	_primary_btn.text = "Volver al Hub"
	_primary_btn.disabled = false
	_busy = false

	EventBus.emit_safe("game_ended", [summary])


func _return_to_hub() -> void:
	EventBus.emit_safe("scene_change_requested", ["res://scenes/HubCentral.tscn"])


func _on_primary_pressed() -> void:
	match _state:
		Constants.GameState.INTRO:
			_enter_playing()
		Constants.GameState.PLAYING:
			_submit_stub_answer()
		Constants.GameState.RESULTS:
			_return_to_hub()
