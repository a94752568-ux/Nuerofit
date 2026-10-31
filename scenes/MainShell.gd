# scenes/MainShell.gd
extends Control

const Constants = preload("res://core/constants.gd")

onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
onready var fps_label: Label = $MarginContainer/VBoxContainer/FPSLabel
onready var start_button: Button = $MarginContainer/VBoxContainer/StartButton
onready var stats_label: Label = $MarginContainer/VBoxContainer/StatsLabel

var last_press_time: float = 0.0
const PRESS_COOLDOWN: float = 0.3


func _ready() -> void:
	status_label.text = "NeuroFit — Toca 'Iniciar Entrenamiento' para comenzar"
	stats_label.text = "Dominio: Velocidad de Procesamiento | Nivel: 1"
	start_button.connect("pressed", self, "_on_start_pressed")

	EventBus.connect("thermal_state_changed", self, "_on_thermal_state_changed")
	EventBus.connect("difficulty_changed", self, "_on_difficulty_changed")

	MotionManager.animate_entry(start_button)


func _process(_delta: float) -> void:
	var fps = PlatformSupervisor.get_current_fps()
	var frame_ms = PlatformSupervisor.get_current_frame_time_ms()
	fps_label.text = "FPS: %d (%.2f ms)" % [fps, frame_ms]


func _on_start_pressed() -> void:
	var current_time = OS.get_ticks_msec() / 1000.0
	if current_time - last_press_time < PRESS_COOLDOWN:
		return
	last_press_time = current_time
	
	EventBus.emit_safe("scene_change_requested", ["res://scenes/GameSelection.tscn"])


func _on_difficulty_changed(new_level: int) -> void:
	pass


func _on_thermal_state_changed(profile_level: int) -> void:
	var profile_name = "LOW" if profile_level == Constants.ThermalProfile.LOW else "HIGH"
	print("[MainShell] Perfil Térmico cambiado a: ", profile_name)
