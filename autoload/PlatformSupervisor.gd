# autoload/PlatformSupervisor.gd
extends Node

const Constants = preload("res://core/constants.gd")

# Estado de perfil de calidad
var current_profile: int = Constants.ThermalProfile.HIGH

# Contadores para monitoreo de rendimiento
var _low_fps_frame_count: int = 0
var _high_fps_frame_count: int = 0
const LOW_FPS_THRESHOLD: float = 45.0
const HIGH_FPS_THRESHOLD: float = 58.0
const FRAMES_TO_DEGRADE: int = 180  # ~3s de bajo rendimiento
const FRAMES_TO_RECOVER: int = 300  # ~5s de rendimiento alto constante

# Información de la plataforma
var is_android: bool = false
var is_mobile: bool = false


func _ready() -> void:
	is_android = OS.get_name() == "Android"
	is_mobile = is_android or OS.get_name() == "iOS"
	print("[PlatformSupervisor] Inicializado en plataforma: ", OS.get_name())


func _process(_delta: float) -> void:
	_monitor_performance()


func _unhandled_input(event: InputEvent) -> void:
	_normalize_and_dispatch_input(event)


func _monitor_performance() -> void:
	var fps: float = Performance.get_monitor(Performance.TIME_FPS)

	if current_profile == Constants.ThermalProfile.HIGH:
		if fps < LOW_FPS_THRESHOLD:
			_low_fps_frame_count += 1
			if _low_fps_frame_count >= FRAMES_TO_DEGRADE:
				_set_quality_profile(Constants.ThermalProfile.LOW)
		else:
			_low_fps_frame_count = max(0, _low_fps_frame_count - 1)
	elif current_profile == Constants.ThermalProfile.LOW:
		if fps >= HIGH_FPS_THRESHOLD:
			_high_fps_frame_count += 1
			if _high_fps_frame_count >= FRAMES_TO_RECOVER:
				_set_quality_profile(Constants.ThermalProfile.HIGH)
		else:
			_high_fps_frame_count = max(0, _high_fps_frame_count - 1)


func _set_quality_profile(new_profile: int) -> void:
	if current_profile == new_profile:
		return

	current_profile = new_profile
	_low_fps_frame_count = 0
	_high_fps_frame_count = 0

	print("[PlatformSupervisor] Cambio de perfil de calidad a: ", "LOW" if new_profile == Constants.ThermalProfile.LOW else "HIGH")

	EventBus.emit_safe("thermal_state_changed", [current_profile])


func _normalize_and_dispatch_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			EventBus.emit_safe("input_event_normalized", ["touch_down", event.position, 1.0])
		else:
			EventBus.emit_safe("input_event_normalized", ["touch_up", event.position, 0.0])
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				EventBus.emit_safe("input_event_normalized", ["touch_down", event.position, 1.0])
			else:
				EventBus.emit_safe("input_event_normalized", ["touch_up", event.position, 0.0])
	elif event is InputEventKey and event.pressed:
		EventBus.emit_safe("input_event_normalized", ["key_press", Vector2.ZERO, event.scancode])


func get_current_frame_time_ms() -> float:
	return Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0


func get_current_fps() -> float:
	return Performance.get_monitor(Performance.TIME_FPS)
