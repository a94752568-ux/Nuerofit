# plugins/head_count/HeadCount.gd
# Conteo de siluetas: memoria a corto plazo (índigo).
extends Control

const PLUGIN_ID := "head.count"
const TARGET_TRIALS := 20
const Constants = preload("res://core/constants.gd")
const FIGURE := "👤"

var _rng := RandomNumberGenerator.new()

var _bg: ColorRect
var _title: Label
var _subtitle: Label
var _progress: Label
var _status: Label
var _display_panel: PanelContainer
var _display_label: Label
var _answer_grid: GridContainer
var _primary_btn: Button

var _state: int = Constants.GameState.INTRO
var _phase: String = "idle"
var _trial_index: int = 0
var _correct_count: int = 0
var _reaction_sum_ms: float = 0.0
var _session_start_ms: int = 0
var _trial_start_ms: int = 0
var _busy: bool = false
var _true_count: int = 0
var _answer_buttons: Array = []


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
	_title = _lab("Head Count", Color(0.95, 0.95, 0.97))
	root.add_child(_title)
	_subtitle = _lab("", Color(0.5, 0.5, 0.55))
	_subtitle.autowrap = true
	root.add_child(_subtitle)
	_progress = _lab("", Color(0.424, 0.388, 1.0))
	root.add_child(_progress)
	_display_panel = PanelContainer.new()
	_display_panel.rect_min_size = Vector2(0, 140)
	_display_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	_display_panel.add_stylebox_override("panel", style)
	root.add_child(_display_panel)
	_display_label = _lab("", Color(0.95, 0.95, 0.97))
	_display_label.align = Label.ALIGN_CENTER
	_display_label.valign = Label.VALIGN_CENTER
	_display_label.autowrap = true
	_display_label.rect_min_size = Vector2(0, 120)
	_display_panel.add_child(_display_label)
	_status = _lab("", Color(0.7, 0.7, 0.75))
	_status.autowrap = true
	root.add_child(_status)
	_answer_grid = GridContainer.new()
	_answer_grid.columns = 5
	_answer_grid.add_constant_override("hseparation", 8)
	_answer_grid.add_constant_override("vseparation", 8)
	_answer_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	root.add_child(_answer_grid)
	_primary_btn = Button.new()
	_primary_btn.rect_min_size = Vector2(0, 52)
	_primary_btn.text = "Empezar"
	_primary_btn.connect("pressed", self, "_on_primary_pressed")
	root.add_child(_primary_btn)
	_display_panel.visible = false
	_answer_grid.visible = false


func _lab(text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.align = Label.ALIGN_CENTER
	l.add_color_override("font_color", color)
	return l


func _count_range(diff: int) -> Vector2:
	if diff <= 2:
		return Vector2(2, 4)
	elif diff <= 4:
		return Vector2(3, 6)
	elif diff <= 6:
		return Vector2(4, 8)
	else:
		return Vector2(5, 9)


func _show_ms(diff: int) -> float:
	if diff <= 2:
		return 1800.0
	elif diff <= 4:
		return 1400.0
	elif diff <= 6:
		return 1000.0
	else:
		return 700.0


func _enter_intro() -> void:
	_state = Constants.GameState.INTRO
	_phase = "idle"
	_trial_index = 0
	_correct_count = 0
	_reaction_sum_ms = 0.0
	_title.text = "Head Count"
	_subtitle.text = "Cuenta las siluetas antes de que desaparezcan.\n%d rondas." % TARGET_TRIALS
	_progress.text = ""
	_status.text = "Dominio: memoria a corto plazo"
	_display_label.text = ""
	_display_panel.visible = false
	_answer_grid.visible = false
	_clear_answers()
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
	_display_panel.visible = true
	EventBus.emit_safe("game_started", [PLUGIN_ID])
	EventBus.emit_safe("audio_event_triggered", ["play_theme", {"theme": "air"}])
	_start_trial()


func _clear_answers() -> void:
	for c in _answer_grid.get_children():
		c.queue_free()
	_answer_buttons.clear()


func _start_trial() -> void:
	_trial_index += 1
	_busy = true
	_phase = "show"
	_answer_grid.visible = false
	_clear_answers()
	var diff: int = CognitiveEngine.current_difficulty
	var rng_r: Vector2 = _count_range(diff)
	_true_count = _rng.randi_range(int(rng_r.x), int(rng_r.y))
	var line := ""
	for i in range(_true_count):
		if i > 0 and i % 5 == 0:
			line += "\n"
		elif i > 0:
			line += " "
		line += FIGURE
	_display_label.text = line
	_progress.text = "Trial %d / %d  ·  Nivel %d" % [_trial_index, TARGET_TRIALS, diff]
	_status.text = "¡Cuenta!"
	if MotionManager and _display_panel:
		MotionManager.animate_entry(_display_panel)
	var show_time: float = _show_ms(diff) / 1000.0
	yield(get_tree().create_timer(show_time), "timeout")
	if _state != Constants.GameState.PLAYING:
		return
	_ask_count()


func _ask_count() -> void:
	_phase = "ask"
	_display_label.text = "¿Cuántas?"
	_status.text = "Toca el número"
	_trial_start_ms = OS.get_ticks_msec()
	_busy = false
	_answer_grid.visible = true
	_clear_answers()
	for n in range(1, 10):
		var btn := Button.new()
		btn.text = str(n)
		btn.rect_min_size = Vector2(56, 56)
		btn.size_flags_horizontal = SIZE_EXPAND_FILL
		var captured: int = n
		btn.connect("pressed", self, "_on_answer", [captured, btn])
		_answer_grid.add_child(btn)
		_answer_buttons.append(btn)


func _on_answer(value: int, btn: Button) -> void:
	if _busy or _state != Constants.GameState.PLAYING or _phase != "ask":
		return
	_busy = true
	for b in _answer_buttons:
		if is_instance_valid(b):
			b.disabled = true
	var time_ms: float = float(OS.get_ticks_msec() - _trial_start_ms)
	var correct: bool = (value == _true_count)
	if correct:
		_correct_count += 1
	_reaction_sum_ms += time_ms
	var difficulty: int = CognitiveEngine.current_difficulty
	EventBus.emit_safe("game_answer", [{
		"plugin_id": PLUGIN_ID,
		"correct": correct,
		"time_ms": time_ms,
		"difficulty": difficulty,
		"stimulus": str(_true_count),
		"response": str(value)
	}])
	if correct:
		EventBus.emit_safe("audio_event_triggered", ["correct_answer", {}])
		if MotionManager and btn:
			MotionManager.animate_correct(btn)
		_status.text = "Correcto"
	else:
		EventBus.emit_safe("audio_event_triggered", ["error_answer", {}])
		if MotionManager and btn:
			MotionManager.animate_error(btn)
		_status.text = "Había %d" % _true_count
	yield(get_tree().create_timer(0.45), "timeout")
	if _state != Constants.GameState.PLAYING:
		return
	if _trial_index >= TARGET_TRIALS:
		_enter_results()
	else:
		_start_trial()


func _enter_results() -> void:
	_state = Constants.GameState.RESULTS
	_phase = "idle"
	_answer_grid.visible = false
	_clear_answers()
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
	_subtitle.text = "Sesión completada"
	_display_label.text = "%d / %d" % [_correct_count, TARGET_TRIALS]
	_progress.text = "%.0f%% aciertos" % (accuracy * 100.0)
	_status.text = "RT medio: %.0f ms  ·  Nivel: %d  ·  %d s" % [avg_rt, final_diff, int(duration_ms / 1000.0)]
	_display_panel.visible = true
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
