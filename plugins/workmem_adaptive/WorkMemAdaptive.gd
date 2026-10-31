# plugins/workmem_adaptive/WorkMemAdaptive.gd
# N-back ligero adaptativo — memoria de trabajo (índigo).
extends Control

const PLUGIN_ID := "workmem.adaptive"
const TARGET_JUDGMENTS := 20
const Constants = preload("res://core/constants.gd")
const STIMULI := ["A", "B", "C", "D", "E", "F", "G", "H"]

var _rng := RandomNumberGenerator.new()

var _bg: ColorRect
var _title: Label
var _subtitle: Label
var _progress: Label
var _status: Label
var _stim_panel: PanelContainer
var _stim_label: Label
var _btn_yes: Button
var _btn_no: Button
var _btn_row: HBoxContainer
var _primary_btn: Button

var _state: int = Constants.GameState.INTRO
var _n_back: int = 1
var _sequence: Array = []
var _judgment_index: int = 0
var _stream_index: int = 0
var _correct_count: int = 0
var _reaction_sum_ms: float = 0.0
var _session_start_ms: int = 0
var _trial_start_ms: int = 0
var _busy: bool = false
var _awaiting_judgment: bool = false
var _current_is_match: bool = false


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
	root.add_constant_override("separation", 14)
	margin.add_child(root)
	_title = _lab("Memoria de trabajo", Color(0.95, 0.95, 0.97))
	root.add_child(_title)
	_subtitle = _lab("", Color(0.5, 0.5, 0.55))
	_subtitle.autowrap = true
	root.add_child(_subtitle)
	_progress = _lab("", Color(0.424, 0.388, 1.0))
	root.add_child(_progress)
	_stim_panel = PanelContainer.new()
	_stim_panel.rect_min_size = Vector2(0, 140)
	_stim_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	_stim_panel.add_stylebox_override("panel", style)
	root.add_child(_stim_panel)
	_stim_label = _lab("—", Color(0.95, 0.95, 0.97))
	_stim_label.align = Label.ALIGN_CENTER
	_stim_label.valign = Label.VALIGN_CENTER
	_stim_label.rect_min_size = Vector2(0, 120)
	_stim_panel.add_child(_stim_label)
	_status = _lab("", Color(0.7, 0.7, 0.75))
	_status.autowrap = true
	root.add_child(_status)
	_btn_row = HBoxContainer.new()
	_btn_row.add_constant_override("separation", 12)
	_btn_row.size_flags_horizontal = SIZE_EXPAND_FILL
	root.add_child(_btn_row)
	_btn_yes = Button.new()
	_btn_yes.text = "Sí · igual"
	_btn_yes.rect_min_size = Vector2(0, 64)
	_btn_yes.size_flags_horizontal = SIZE_EXPAND_FILL
	_btn_yes.connect("pressed", self, "_on_yes")
	_btn_row.add_child(_btn_yes)
	_btn_no = Button.new()
	_btn_no.text = "No · distinto"
	_btn_no.rect_min_size = Vector2(0, 64)
	_btn_no.size_flags_horizontal = SIZE_EXPAND_FILL
	_btn_no.connect("pressed", self, "_on_no")
	_btn_row.add_child(_btn_no)
	_primary_btn = Button.new()
	_primary_btn.rect_min_size = Vector2(0, 52)
	_primary_btn.text = "Empezar"
	_primary_btn.connect("pressed", self, "_on_primary_pressed")
	root.add_child(_primary_btn)
	_stim_panel.visible = false
	_btn_row.visible = false


func _lab(text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.align = Label.ALIGN_CENTER
	l.add_color_override("font_color", color)
	return l


func _n_from_difficulty(diff: int) -> int:
	if diff <= 2:
		return 1
	elif diff <= 5:
		return 2
	else:
		return 3


func _enter_intro() -> void:
	_state = Constants.GameState.INTRO
	_judgment_index = 0
	_correct_count = 0
	_reaction_sum_ms = 0.0
	_sequence.clear()
	_title.text = "Memoria de trabajo"
	_subtitle.text = "¿El símbolo actual es igual al de hace n posiciones?\nResponde Sí o No. %d juicios." % TARGET_JUDGMENTS
	_progress.text = ""
	_status.text = "Dominio: memoria de trabajo · n-back adaptativo"
	_stim_label.text = "—"
	_stim_panel.visible = false
	_btn_row.visible = false
	_primary_btn.visible = true
	_primary_btn.text = "Empezar"
	_primary_btn.disabled = false
	_busy = false
	_awaiting_judgment = false
	if MotionManager:
		MotionManager.animate_entry(_primary_btn)


func _enter_playing() -> void:
	_state = Constants.GameState.PLAYING
	_session_start_ms = OS.get_ticks_msec()
	_judgment_index = 0
	_stream_index = 0
	_correct_count = 0
	_reaction_sum_ms = 0.0
	_sequence.clear()
	_n_back = _n_from_difficulty(CognitiveEngine.current_difficulty)
	_subtitle.text = "Sesión en curso · %d-back" % _n_back
	_primary_btn.visible = false
	_stim_panel.visible = true
	_btn_row.visible = true
	_set_answer_enabled(false)
	EventBus.emit_safe("game_started", [PLUGIN_ID])
	EventBus.emit_safe("audio_event_triggered", ["play_theme", {"theme": "air"}])
	_show_next_stimulus()


func _set_answer_enabled(v: bool) -> void:
	_btn_yes.disabled = not v
	_btn_no.disabled = not v
	_awaiting_judgment = v


func _pick_next_symbol(force_match: bool) -> String:
	if force_match and _sequence.size() >= _n_back:
		return str(_sequence[_sequence.size() - _n_back])
	var cand: String = STIMULI[_rng.randi() % STIMULI.size()]
	if _sequence.size() >= _n_back and not force_match:
		var target: String = str(_sequence[_sequence.size() - _n_back])
		var guard := 0
		while cand == target and guard < 12:
			cand = STIMULI[_rng.randi() % STIMULI.size()]
			guard += 1
	return cand


func _show_next_stimulus() -> void:
	_busy = true
	_set_answer_enabled(false)
	var needs_preamble: bool = _sequence.size() < _n_back
	var force_match: bool = false
	if not needs_preamble:
		force_match = _rng.randf() < 0.4
	var sym: String = _pick_next_symbol(force_match and not needs_preamble)
	_sequence.append(sym)
	_stream_index = _sequence.size()
	_stim_label.text = sym
	if needs_preamble:
		_progress.text = "Memoriza… %d / %d" % [_sequence.size(), _n_back]
		_status.text = "Observa la secuencia (%d-back)" % _n_back
	else:
		_progress.text = "Juicio %d / %d  ·  %d-back" % [_judgment_index + 1, TARGET_JUDGMENTS, _n_back]
		_status.text = "¿Igual al de hace %d?" % _n_back
	if MotionManager and _stim_panel:
		MotionManager.animate_entry(_stim_panel)
	yield(get_tree().create_timer(0.55), "timeout")
	if _state != Constants.GameState.PLAYING:
		return
	if needs_preamble:
		_show_next_stimulus()
		return
	var ref: String = str(_sequence[_sequence.size() - 1 - _n_back])
	_current_is_match = (sym == ref)
	_trial_start_ms = OS.get_ticks_msec()
	_busy = false
	_set_answer_enabled(true)


func _submit(said_match: bool) -> void:
	if _busy or not _awaiting_judgment or _state != Constants.GameState.PLAYING:
		return
	_busy = true
	_set_answer_enabled(false)
	var time_ms: float = float(OS.get_ticks_msec() - _trial_start_ms)
	var correct: bool = (said_match == _current_is_match)
	if correct:
		_correct_count += 1
	_reaction_sum_ms += time_ms
	_judgment_index += 1
	var difficulty: int = CognitiveEngine.current_difficulty
	EventBus.emit_safe("game_answer", [{
		"plugin_id": PLUGIN_ID,
		"correct": correct,
		"time_ms": time_ms,
		"difficulty": difficulty,
		"stimulus": "%d-back" % _n_back,
		"response": "match" if said_match else "nonmatch"
	}])
	if correct:
		EventBus.emit_safe("audio_event_triggered", ["correct_answer", {}])
		if MotionManager:
			MotionManager.animate_correct(_stim_panel)
		_status.text = "Correcto"
	else:
		EventBus.emit_safe("audio_event_triggered", ["error_answer", {}])
		if MotionManager:
			MotionManager.animate_error(_stim_panel)
		_status.text = "Era %s" % ("igual" if _current_is_match else "distinto")
	yield(get_tree().create_timer(0.4), "timeout")
	if _state != Constants.GameState.PLAYING:
		return
	var new_n: int = _n_from_difficulty(CognitiveEngine.current_difficulty)
	if new_n != _n_back:
		_n_back = new_n
		_subtitle.text = "Sesión en curso · %d-back" % _n_back
	if _judgment_index >= TARGET_JUDGMENTS:
		_enter_results()
	else:
		_show_next_stimulus()


func _on_yes() -> void:
	_submit(true)


func _on_no() -> void:
	_submit(false)


func _enter_results() -> void:
	_state = Constants.GameState.RESULTS
	_btn_row.visible = false
	var duration_ms: int = OS.get_ticks_msec() - _session_start_ms
	var accuracy: float = float(_correct_count) / float(TARGET_JUDGMENTS)
	var avg_rt: float = _reaction_sum_ms / float(TARGET_JUDGMENTS)
	var final_diff: int = CognitiveEngine.current_difficulty
	var summary := {
		"plugin_id": PLUGIN_ID,
		"session_id": SessionManager.current_session_id,
		"trials": TARGET_JUDGMENTS,
		"correct_count": _correct_count,
		"accuracy": accuracy,
		"avg_reaction_time": avg_rt,
		"final_difficulty": final_diff,
		"duration_ms": duration_ms
	}
	_title.text = "Resultados"
	_subtitle.text = "Sesión completada"
	_stim_label.text = "%d / %d" % [_correct_count, TARGET_JUDGMENTS]
	_progress.text = "%.0f%% aciertos" % (accuracy * 100.0)
	_status.text = "RT medio: %.0f ms  ·  Nivel: %d  ·  %d s" % [avg_rt, final_diff, int(duration_ms / 1000.0)]
	_stim_panel.visible = true
	_primary_btn.visible = true
	_primary_btn.text = "Volver al Hub"
	_primary_btn.disabled = false
	_busy = false
	_awaiting_judgment = false
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
