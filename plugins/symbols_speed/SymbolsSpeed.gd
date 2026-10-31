# plugins/symbols_speed/SymbolsSpeed.gd
# Matching de símbolos por tap. Dominio: atención (ámbar).
extends Control

const PLUGIN_ID := "symbols.speed"
const TARGET_TRIALS := 20
const Constants = preload("res://core/constants.gd")

const SYMBOLS_EASY := ["●", "■", "▲", "★", "◆", "♥", "＋", "×"]
const SYMBOLS_HARD := ["●", "○", "■", "□", "▲", "△", "◆", "◇", "★", "☆", "♥", "♡"]

var _rng := RandomNumberGenerator.new()

var _bg: ColorRect
var _title: Label
var _subtitle: Label
var _progress: Label
var _status: Label
var _target_label: Label
var _target_panel: PanelContainer
var _grid: GridContainer
var _primary_btn: Button

var _state: int = Constants.GameState.INTRO
var _trial_index: int = 0
var _correct_count: int = 0
var _reaction_sum_ms: float = 0.0
var _session_start_ms: int = 0
var _trial_start_ms: int = 0
var _busy: bool = false
var _target_symbol: String = ""
var _option_buttons: Array = []


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
	_title = _label("Velocidad de Símbolos", Color(0.95, 0.95, 0.97))
	root.add_child(_title)
	_subtitle = _label("", Color(0.5, 0.5, 0.55))
	_subtitle.autowrap = true
	root.add_child(_subtitle)
	_progress = _label("", Color(1.0, 0.722, 0.298))
	root.add_child(_progress)
	_target_panel = PanelContainer.new()
	_target_panel.rect_min_size = Vector2(0, 100)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	_target_panel.add_stylebox_override("panel", style)
	root.add_child(_target_panel)
	_target_label = _label("?", Color(1.0, 0.722, 0.298))
	_target_label.align = Label.ALIGN_CENTER
	_target_label.valign = Label.VALIGN_CENTER
	_target_label.rect_min_size = Vector2(0, 88)
	_target_panel.add_child(_target_label)
	_status = _label("", Color(0.7, 0.7, 0.75))
	_status.autowrap = true
	root.add_child(_status)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_constant_override("hseparation", 10)
	_grid.add_constant_override("vseparation", 10)
	_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	_grid.size_flags_vertical = SIZE_EXPAND_FILL
	root.add_child(_grid)
	_primary_btn = Button.new()
	_primary_btn.rect_min_size = Vector2(0, 52)
	_primary_btn.text = "Empezar"
	_primary_btn.connect("pressed", self, "_on_primary_pressed")
	root.add_child(_primary_btn)
	_target_panel.visible = false
	_grid.visible = false


func _label(text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.align = Label.ALIGN_CENTER
	l.add_color_override("font_color", color)
	return l


func _option_count(diff: int) -> int:
	if diff <= 2:
		return 4
	elif diff <= 4:
		return 6
	else:
		return 9


func _symbol_pool(diff: int) -> Array:
	if diff >= 5:
		return SYMBOLS_HARD.duplicate()
	return SYMBOLS_EASY.duplicate()


func _enter_intro() -> void:
	_state = Constants.GameState.INTRO
	_trial_index = 0
	_correct_count = 0
	_reaction_sum_ms = 0.0
	_title.text = "Velocidad de Símbolos"
	_subtitle.text = "Toca el símbolo que coincida con el objetivo.\n%d rondas · dificultad adaptativa." % TARGET_TRIALS
	_progress.text = ""
	_status.text = "Dominio: atención"
	_target_label.text = "?"
	_target_panel.visible = false
	_grid.visible = false
	_clear_grid()
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
	_target_panel.visible = true
	_grid.visible = true
	EventBus.emit_safe("game_started", [PLUGIN_ID])
	EventBus.emit_safe("audio_event_triggered", ["play_theme", {"theme": "air"}])
	_start_trial()


func _clear_grid() -> void:
	for c in _grid.get_children():
		c.queue_free()
	_option_buttons.clear()


func _start_trial() -> void:
	_trial_index += 1
	_busy = false
	_trial_start_ms = OS.get_ticks_msec()
	var diff: int = CognitiveEngine.current_difficulty
	var n: int = _option_count(diff)
	var pool: Array = _symbol_pool(diff)
	pool.shuffle()
	_target_symbol = pool[0]
	var options: Array = [_target_symbol]
	var i := 1
	while options.size() < n and i < pool.size():
		options.append(pool[i])
		i += 1
	while options.size() < n:
		options.append(pool[_rng.randi() % pool.size()])
	options.shuffle()
	_progress.text = "Trial %d / %d  ·  Nivel %d" % [_trial_index, TARGET_TRIALS, diff]
	_status.text = "Toca el símbolo igual al de arriba"
	_target_label.text = _target_symbol
	_clear_grid()
	if n <= 4:
		_grid.columns = 2
	elif n <= 6:
		_grid.columns = 3
	else:
		_grid.columns = 3
	for sym in options:
		var btn := Button.new()
		btn.text = str(sym)
		btn.rect_min_size = Vector2(72, 72)
		btn.size_flags_horizontal = SIZE_EXPAND_FILL
		btn.size_flags_vertical = SIZE_EXPAND_FILL
		var captured: String = str(sym)
		btn.connect("pressed", self, "_on_option", [captured, btn])
		_grid.add_child(btn)
		_option_buttons.append(btn)
	if MotionManager and _target_panel:
		MotionManager.animate_entry(_target_panel)


func _on_option(symbol: String, btn: Button) -> void:
	if _busy or _state != Constants.GameState.PLAYING:
		return
	_busy = true
	for b in _option_buttons:
		if is_instance_valid(b):
			b.disabled = true
	var time_ms: float = float(OS.get_ticks_msec() - _trial_start_ms)
	var correct: bool = (symbol == _target_symbol)
	if correct:
		_correct_count += 1
	_reaction_sum_ms += time_ms
	var difficulty: int = CognitiveEngine.current_difficulty
	EventBus.emit_safe("game_answer", [{
		"plugin_id": PLUGIN_ID,
		"correct": correct,
		"time_ms": time_ms,
		"difficulty": difficulty,
		"stimulus": _target_symbol,
		"response": symbol
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
		_status.text = "Era %s" % _target_symbol
	yield(get_tree().create_timer(0.4), "timeout")
	if _state != Constants.GameState.PLAYING:
		return
	if _trial_index >= TARGET_TRIALS:
		_enter_results()
	else:
		_start_trial()


func _enter_results() -> void:
	_state = Constants.GameState.RESULTS
	_grid.visible = false
	_clear_grid()
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
	_target_label.text = "%d / %d" % [_correct_count, TARGET_TRIALS]
	_progress.text = "%.0f%% aciertos" % (accuracy * 100.0)
	_status.text = "RT medio: %.0f ms  ·  Nivel: %d  ·  %d s" % [avg_rt, final_diff, int(duration_ms / 1000.0)]
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
