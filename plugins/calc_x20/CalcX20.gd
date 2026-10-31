# plugins/calc_x20/CalcX20.gd
# Fase B: generador real, pad numérico, 20 trials, feedback motion/audio vía bus.
extends Control

const PLUGIN_ID := "calc.x20"
const TARGET_TRIALS := 20
const Constants = preload("res://core/constants.gd")
const ProblemGenerator = preload("res://plugins/calc_x20/ProblemGenerator.gd")
const NumericPadScript = preload("res://plugins/calc_x20/NumericPad.gd")

var _bg: ColorRect
var _title: Label
var _subtitle: Label
var _expression: Label
var _answer_label: Label
var _progress: Label
var _status: Label
var _primary_btn: Button
var _pad: VBoxContainer
var _expression_panel: PanelContainer

var _state: int = Constants.GameState.INTRO
var _generator
var _trial_index: int = 0
var _correct_count: int = 0
var _reaction_sum_ms: float = 0.0
var _session_start_ms: int = 0
var _trial_start_ms: int = 0
var _busy: bool = false
var _current: Dictionary = {}
var _user_input: String = ""


func _ready() -> void:
	_generator = ProblemGenerator.new(OS.get_unix_time())
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
	_title = _make_label("Cálculos ×20", Color(0.95, 0.95, 0.97), true)
	root.add_child(_title)
	_subtitle = _make_label("", Color(0.5, 0.5, 0.55), false)
	_subtitle.autowrap = true
	root.add_child(_subtitle)
	_progress = _make_label("", Color(1.0, 0.42, 0.42), false)
	root.add_child(_progress)
	_expression_panel = PanelContainer.new()
	_expression_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	_expression_panel.rect_min_size = Vector2(0, 88)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	_expression_panel.add_stylebox_override("panel", style)
	root.add_child(_expression_panel)
	var expr_box := VBoxContainer.new()
	expr_box.add_constant_override("separation", 4)
	_expression_panel.add_child(expr_box)
	_expression = _make_label("—", Color(0.95, 0.95, 0.97), true)
	_expression.align = Label.ALIGN_CENTER
	expr_box.add_child(_expression)
	_answer_label = _make_label("", Color(0.0, 0.949, 0.996), true)
	_answer_label.align = Label.ALIGN_CENTER
	expr_box.add_child(_answer_label)
	_status = _make_label("", Color(0.7, 0.7, 0.75), false)
	_status.autowrap = true
	root.add_child(_status)
	_primary_btn = Button.new()
	_primary_btn.rect_min_size = Vector2(0, 52)
	_primary_btn.text = "Empezar"
	_primary_btn.connect("pressed", self, "_on_primary_pressed")
	root.add_child(_primary_btn)
	_pad = NumericPadScript.new()
	_pad.size_flags_horizontal = SIZE_EXPAND_FILL
	_pad.size_flags_vertical = SIZE_EXPAND_FILL
	_pad.connect("digit_pressed", self, "_on_digit")
	_pad.connect("backspace_pressed", self, "_on_backspace")
	_pad.connect("confirm_pressed", self, "_on_confirm")
	root.add_child(_pad)
	_set_pad_visible(false)
	_expression_panel.visible = false


func _make_label(text: String, color: Color, large: bool) -> Label:
	var l := Label.new()
	l.text = text
	l.align = Label.ALIGN_CENTER
	l.add_color_override("font_color", color)
	if large:
		l.rect_min_size = Vector2(0, 36)
	return l


func _set_pad_visible(v: bool) -> void:
	_pad.visible = v
	_pad.mouse_filter = Control.MOUSE_FILTER_STOP if v else Control.MOUSE_FILTER_IGNORE


func _enter_intro() -> void:
	_state = Constants.GameState.INTRO
	_trial_index = 0
	_correct_count = 0
	_reaction_sum_ms = 0.0
	_user_input = ""
	_title.text = "Cálculos ×20"
	_subtitle.text = "Resuelve %d operaciones lo más rápido que puedas.\nUsa el teclado numérico y confirma con OK." % TARGET_TRIALS
	_progress.text = ""
	_status.text = "Dominio: velocidad de procesamiento · niveles 1–8"
	_expression.text = "—"
	_answer_label.text = ""
	_expression_panel.visible = false
	_set_pad_visible(false)
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
	_expression_panel.visible = true
	_set_pad_visible(true)
	EventBus.emit_safe("game_started", [PLUGIN_ID])
	EventBus.emit_safe("audio_event_triggered", ["play_theme", {"theme": "fluid"}])
	_start_trial()


func _start_trial() -> void:
	_trial_index += 1
	_user_input = ""
	_busy = false
	_trial_start_ms = OS.get_ticks_msec()
	var diff: int = CognitiveEngine.current_difficulty
	_current = _generator.generate(diff)
	_expression.text = _current["display"]
	_answer_label.text = ""
	_progress.text = "Trial %d / %d  ·  Nivel %d" % [_trial_index, TARGET_TRIALS, diff]
	_status.text = "Escribe el resultado y pulsa OK"
	if MotionManager and _expression_panel:
		MotionManager.animate_entry(_expression_panel)


func _on_digit(digit: String) -> void:
	if _busy or _state != Constants.GameState.PLAYING:
		return
	if _user_input.length() >= 6:
		return
	_user_input += digit
	_answer_label.text = _user_input


func _on_backspace() -> void:
	if _busy or _state != Constants.GameState.PLAYING:
		return
	if _user_input.length() == 0:
		return
	_user_input = _user_input.substr(0, _user_input.length() - 1)
	_answer_label.text = _user_input


func _on_confirm() -> void:
	if _busy or _state != Constants.GameState.PLAYING:
		return
	if _user_input == "":
		_status.text = "Introduce un número"
		return
	_submit_answer()


func _submit_answer() -> void:
	_busy = true
	var time_ms: float = float(OS.get_ticks_msec() - _trial_start_ms)
	var user_val: int = int(_user_input)
	var correct: bool = (user_val == int(_current["correct_answer"]))
	if correct:
		_correct_count += 1
	_reaction_sum_ms += time_ms
	var difficulty: int = CognitiveEngine.current_difficulty
	var answer := {
		"plugin_id": PLUGIN_ID,
		"correct": correct,
		"time_ms": time_ms,
		"difficulty": difficulty,
		"stimulus": _current["display"],
		"response": _user_input
	}
	EventBus.emit_safe("game_answer", [answer])
	if correct:
		EventBus.emit_safe("audio_event_triggered", ["correct_answer", {}])
		if MotionManager:
			MotionManager.animate_correct(_expression_panel)
		_status.text = "Correcto"
		_answer_label.add_color_override("font_color", Color(0.0, 0.949, 0.996))
	else:
		EventBus.emit_safe("audio_event_triggered", ["error_answer", {}])
		if MotionManager:
			MotionManager.animate_error(_expression_panel)
		_status.text = "Era %d" % int(_current["correct_answer"])
		_answer_label.add_color_override("font_color", Color(1.0, 0.322, 0.322))
	yield(get_tree().create_timer(0.45), "timeout")
	_answer_label.add_color_override("font_color", Color(0.0, 0.949, 0.996))
	if _trial_index >= TARGET_TRIALS:
		_enter_results()
	else:
		_start_trial()


func _enter_results() -> void:
	_state = Constants.GameState.RESULTS
	_set_pad_visible(false)
	_expression_panel.visible = true
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
	_expression.text = "%d / %d correctas" % [_correct_count, TARGET_TRIALS]
	_answer_label.text = "%.0f%%" % (accuracy * 100.0)
	_progress.text = ""
	_status.text = "RT medio: %.0f ms  ·  Nivel final: %d  ·  %d s" % [avg_rt, final_diff, int(duration_ms / 1000.0)]
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
