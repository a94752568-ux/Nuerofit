# autoload/DebugOverlay.gd
# Overlay de rendimiento para Fase D (gama baja): FPS, frame time y perfil.
# Se alterna con F10 (o auto-inicio con la setting neurofit/debug_overlay=true).
extends Node

const Constants = preload("res://core/constants.gd")

const UPDATE_EVERY_FRAMES := 10
const COLOR_OK := Color(0.30, 0.90, 0.55)
const COLOR_WARN := Color(1.0, 0.85, 0.29)
const COLOR_BAD := Color(1.0, 0.32, 0.32)

var _canvas: CanvasLayer
var _panel: PanelContainer
var _fps_label: Label
var _frame_label: Label
var _profile_label: Label
var _frame_counter: int = 0
var _visible: bool = false


func _ready() -> void:
	_build_ui()
	if ProjectSettings.has_setting("neurofit/debug_overlay"):
		set_overlay_visible(bool(ProjectSettings.get_setting("neurofit/debug_overlay")))
	else:
		set_overlay_visible(false)
	EventBus.connect("thermal_state_changed", self, "_on_thermal_state_changed")


func _build_ui() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 90  # debajo del overlay de transiciones (100)
	add_child(_canvas)

	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.039, 0.039, 0.047, 0.82)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	_panel.add_stylebox_override("panel", style)
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.margin_left = 12
	_panel.margin_top = 12
	_panel.rect_min_size = Vector2(232, 0)
	_canvas.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_constant_override("separation", 2)
	_panel.add_child(box)

	_fps_label = _make_label("FPS: —")
	box.add_child(_fps_label)
	_frame_label = _make_label("Frame: —")
	box.add_child(_frame_label)
	_profile_label = _make_label("Perfil: —")
	box.add_child(_profile_label)


func _make_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_color_override("font_color", Color(0.75, 0.95, 0.95))
	return l


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.scancode == KEY_F10:
			set_overlay_visible(not _visible)


func set_overlay_visible(v: bool) -> void:
	_visible = v
	_canvas.visible = v
	set_process(v)
	_frame_counter = 0
	if v:
		_refresh()


func _process(_delta: float) -> void:
	_frame_counter += 1
	if _frame_counter >= UPDATE_EVERY_FRAMES:
		_frame_counter = 0
		_refresh()


func _refresh() -> void:
	var fps := PlatformSupervisor.get_current_fps()
	var frame_ms := PlatformSupervisor.get_current_frame_time_ms()
	var profile_name := "LOW" if PlatformSupervisor.current_profile == Constants.ThermalProfile.LOW else "HIGH"
	_fps_label.text = "FPS: %d" % int(round(fps))
	_fps_label.add_color_override("font_color", _color_for_fps(fps))
	_frame_label.text = "Frame: %.1f ms" % frame_ms
	_profile_label.text = "Perfil: %s · Plugins: %d" % [profile_name, PluginLoader.loaded_plugins.size()]


func _color_for_fps(fps: float) -> Color:
	if fps >= 58.0:
		return COLOR_OK
	if fps >= 45.0:
		return COLOR_WARN
	return COLOR_BAD


func _on_thermal_state_changed(_profile_level: int) -> void:
	if not _visible:
		return
	_refresh()
