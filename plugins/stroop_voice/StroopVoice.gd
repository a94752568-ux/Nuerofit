# plugins/stroop_voice/StroopVoice.gd
# Stroop clásico por tap: responde el color de la TINTA, no la palabra.
# Voz (Vosk) queda fuera de v0.1.
extends Control

const PLUGIN_ID := "stroop.voice"
const TARGET_TRIALS := 20
const Constants = preload("res://core/constants.gd")

const COLOR_KEYS := ["rojo", "verde", "azul", "amarillo"]
const COLOR_RGB := {
	"rojo": Color(1.0, 0.28, 0.28),
	"verde": Color(0.25, 0.85, 0.45),
	"azul": Color(0.35, 0.55, 1.0),
	"amarillo": Color(1.0, 0.85, 0.2)
}

var _rng := RandomNumberGenerator.new()

var _bg: ColorRect
var _title: Label
var _subtitle: Label
var _progress: Label
var _status: Label
var _word_panel: PanelContainer
var _word_label: Label
var _choice_grid: GridContainer
var _primary_btn: Button

var _state: int = Constants.GameState.INTRO
var _trial_index: int = 0
var _correct_count: int = 0
var _reaction_sum_ms: float = 0.0
var _session_start_ms: int = 0
var _trial_start_ms: int = 0
var _busy: bool = false
var _ink_key: String = ""
var _word_key: String = ""
var _choice_buttons: Array = []


func _ready() -> void:
	_rng.randomize()
	_build_ui()
	_enter_intro()


func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	_bg = ColorRect.new()
	_bg.anchor_right = 1.0
	_bg.anchor_bottom = 1.0
	_bg.color = Color(0.039, 0.039, 0.047)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	var margin := MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_constant_override("margin_left", 24)
	margin.add_constant_override("margin_right", 24)
	margin.add_constant_override("margin_top", 32)
	margin.add_constant_override("margin_bottom", 24)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_constant_override("separation", 12)
	margin.add_child(root)
	_title = _lab("Test de Stroop", Color(0.95, 0.95, 0.97))
	root.add_child(_title)
	_subtitle = _lab("", Color(0.5, 0.5, 0.55))
	_subtitle.autowrap = true
	root.add_child(_subtitle)
	_progress = _lab("", Color(0.305, 0.804, 0.769))
	root.add_child(_progress)
	_word_panel = PanelContainer.new()
	_word_panel.rect_min_size = Vector2(0, 130)
	_word_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	_word_panel.add_stylebox_override("panel", style)
	root.add_child(_word_panel)
	_word_label = _lab("ROJO", Color(1, 1, 1))
	_word_label.align = Label.ALIGN_CENTER
	_word_label.valign = Label.VALIGN_CENTER
	_word_label.rect_min_size = Vector2(0, 110)
	_word_panel.add_child(_word_label)
	_status = _lab("", Color(0.7, 0.7, 0.75))
	_status.autowrap = true
	root.add_child(_status)
	_choice_grid = GridContainer.new()
	_choice_grid.columns = 2
	_choice_grid.add_constant_override("hseparation", 10)
	_choice_grid.add_constant_override("vseparation", 10)
	_choice_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	root.add_child(_choice_grid)
	_primary_btn = Button.new()
	_primary_btn.rect_min_size = Vector2(0, 52)
	_primary_btn.text = "Empezar"
	_primary_btn.connect("pressed", self, "_on_primary_pressed")
	root.add_child(_primary_btn)
	_word_panel.visible = false
	_choice_grid.visible = false


func _lab(text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.align = Label.ALIGN_CENTER
	l.add_color_override("font_color", color)
	return l


func _congruent_chance(diff: int) -> float:
	if diff <= 2:
		return 0.55
	elif diff <= 4:
		return 0.35
	elif diff <= 6:
		return 0.2
	else:
		return 0.1


func _enter_intro() -> void:
	_state = Constants.GameState.INTRO
	_trial_index = 0
	_correct_count = 0
	_reaction_sum_ms = 0.0
	_title.text = "Test de Stroop"
	_subtitle.text = "Toca el color de la TINTA, no la palabra escrita.\n%d rondas · modo tap (voz más adelante)." % TARGET_TRIALS
	_progress.text = ""
	_status.text = "Dominio: control inhibitorio"
	_word_label.text = "—"
	_word_label.add_color_override("font_color", Color(0.95, 0.95, 0.97))
	_word_panel.visible = false
	_choice_grid.visible = false
	_clear_choices()
	_primary_btn.visible = true
	_primary_btn.text = "Empezar"
	_primary_btn.disabled = false
	_busy = false
	if MotionManager:
		MotionManager.animate_entry(_primary_btn)


func _enter_playing() -> void:
	_state = Constants.GameState.PLAYING
	_session_start_ms = OS.get_ticks_msec()
	_trial_index = 0
	_correct_count = 0
	_reaction_sum_ms = 0.0
	_subtitle.text = "Sesión en curso"
	_primary_btn.visible = false
	_word_panel.visible = true
	_choice_grid.visible = true
	EventBus.emit_safe("game_started", [PLUGIN_ID])
	EventBus.emit_safe("audio_event_triggered", ["play_theme", {"theme": "focus"}])
	_start_trial()


func _clear_choices() -> void:
	for c in _choice_grid.get_children():
		c.queue_free()
	_choice_buttons.clear()


func _start_trial() -> void:
	_trial_index += 1
	_busy = false
	_trial_start_ms = OS.get_ticks_msec()
	var diff: int = CognitiveEngine.current_difficulty
	_word_key = COLOR_KEYS[_rng.randi() % COLOR_KEYS.size()]
	var congruent: bool = _rng.randf() < _congruent_chance(diff)
	if congruent:
		_ink_key = _word_key
	else:
		_ink_key = COLOR_KEYS[_rng.randi() % COLOR_KEYS.size()]
		var guard := 0
		while _ink_key == _word_key and guard < 8:
			_ink_key = COLOR_KEYS[_rng.randi() % COLOR_KEYS.size()]
			guard += 1
	_word_label.text = _word_key.to_upper()
	_word_label.add_color_override("font_color", COLOR_RGB[_ink_key])
	_progress.text = "Trial %d / %d  ·  Nivel %d" % [_trial_index, TARGET_TRIALS, diff]
	_status.text = "¿De qué color está escrita la palabra?"
	_clear_choices()
	for key in COLOR_KEYS:
		var btn := Button.new()
		btn.text = str(key).capitalize()
		btn.rect_min_size = Vector2(0, 56)
		btn.size_flags_horizontal = SIZE_EXPAND_FILL
		var style_btn := StyleBoxFlat.new()
		style_btn.bg_color = COLOR_RGB[key].darkened(0.35)
		style_btn.corner_radius_top_left = 8
		style_btn.corner_radius_top_right = 8
		style_btn.corner_radius_bottom_left = 8
		style_btn.corner_radius_bottom_right = 8
		btn.add_stylebox_override("normal", style_btn)
		var captured: String = key
		btn.connect("pressed", self, "_on_choice", [captured, btn])
		_choice_grid.add_child(btn)
		_choice_buttons.append(btn)
	if MotionManager and _word_panel:
		MotionManager.animate_entry(_word_panel)


func _on_choice(key: String, btn: Button) -> void:
	if _busy or _state != Constants.GameState.PLAYING:
		return
	_busy = true
	for b in _choice_buttons:
		if is_instance_valid(b):
			b.disabled = true
	var time_ms: float = float(OS.get_ticks_msec() - _trial_start_ms)
	var correct: bool = (key == _ink_key)
	if correct:
		_correct_count += 1
	_reaction_sum_ms += time_ms
	var difficulty: int = CognitiveEngine.current_difficulty
	EventBus.emit_safe("game_answer", [{
		"plugin_id": PLUGIN_ID,
		"correct": correct,
		"time_ms": time_ms,
		"difficulty": difficulty,
		"stimulus": "%s@%s" % [_word_key, _ink_key],
		"response": key
	}])
	if correct:
		EventBus.emit_safe("audio_event_triggered", ["correct_answer", {}])
		if MotionManager and btn:
			MotionManager.animate_correct(btn)
		_status.text = "Correcto (tinta: %s)" % _ink_key
	else:
		EventBus.emit_safe("audio_event_triggered", ["error_answer", {}])
		if MotionManager and btn:
			MotionManager.animate_error(btn)
		_status.text = "Era %s (tinta)" % _ink_key
	yield(get_tree().create_timer(0.45), "timeout")
	if _trial_index >= TARGET_TRIALS:
		_enter_results()
	else:
		_start_trial()


func _enter_results() -> void:
	_state = Constants.GameState.RESULTS
	_choice_grid.visible = false
	_clear_choices()
	var duration_ms: int = OS.get_ticks_msec() - _session_start_ms
	var accuracy: float = float(_correct_count) / float(TARGET_TRIALS)
	var avg_rt: float = _reaction_sum_ms / float(TARGET_TRIALS)
	var final_diff: int = CognitiveEngine.current_difficulty
	var summary := {
		"plugin_id": PLUGIN_ID,
		"session_id": SessionManager.current_session_id,
		"trials": TARGET_TRIALS,
		"correct_count": _correct_count,
		"accuracy": accuracy,
		"avg_reaction_time": avg_rt,
		"final_difficulty": final_diff,
		"duration_ms": duration_ms
	}
	_title.text = "Resultados"
	_subtitle.text = "Sesión completada · modo tap"
	_word_label.text = "%d / %d" % [_correct_count, TARGET_TRIALS]
	_word_label.add_color_override("font_color", Color(0.305, 0.804, 0.769))
	_progress.text = "%.0f%% aciertos" % (accuracy * 100.0)
	_status.text = "RT medio: %.0f ms  ·  Nivel: %d  ·  %d s" % [avg_rt, final_diff, int(duration_ms / 1000.0)]
	_word_panel.visible = true
	_primary_btn.visible = true
	_primary_btn.text = "Volver al Hub"
	_primary_btn.disabled = false
	_busy = false
	EventBus.emit_safe("game_ended", [summary])
	EventBus.emit_safe("audio_event_triggered", ["play_theme", {"theme": "return"}])


func _return_to_hub() -> void:
	EventBus.emit_safe("scene_change_requested", ["res://scenes/HubCentral.tscn"])


func _on_primary_pressed() -> void:
	match _state:
		Constants.GameState.INTRO:
			_enter_playing()
		Constants.GameState.RESULTS:
			_return_to_hub()
