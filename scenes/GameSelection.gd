# scenes/GameSelection.gd
extends Control

onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton
onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel

# Botones de minijuegos
onready var calc_button: Button = $MarginContainer/VBoxContainer/GameButtons/CalcButton
onready var stroop_button: Button = $MarginContainer/VBoxContainer/GameButtons/StroopButton
onready var head_count_button: Button = $MarginContainer/VBoxContainer/GameButtons/HeadCountButton
onready var workmem_button: Button = $MarginContainer/VBoxContainer/GameButtons/WorkMemButton
onready var symbols_button: Button = $MarginContainer/VBoxContainer/GameButtons/SymbolsButton


func _ready() -> void:
	title_label.text = "Selecciona un Ejercicio"
	
	back_button.connect("pressed", self, "_on_back_pressed")
	calc_button.connect("pressed", self, "_on_calc_pressed")
	stroop_button.connect("pressed", self, "_on_stroop_pressed")
	head_count_button.connect("pressed", self, "_on_head_count_pressed")
	workmem_button.connect("pressed", self, "_on_workmem_pressed")
	symbols_button.connect("pressed", self, "_on_symbols_pressed")
	
	MotionManager.animate_entry(calc_button)
	MotionManager.animate_entry(stroop_button)
	MotionManager.animate_entry(head_count_button)
	MotionManager.animate_entry(workmem_button)
	MotionManager.animate_entry(symbols_button)


func _on_back_pressed() -> void:
	EventBus.emit_safe("scene_change_requested", ["res://scenes/MainShell.tscn"])


func _on_calc_pressed() -> void:
	_start_game("calc.x20")


func _on_stroop_pressed() -> void:
	_start_game("stroop.voice")


func _on_head_count_pressed() -> void:
	_start_game("head.count")


func _on_workmem_pressed() -> void:
	_start_game("workmem.adaptive")


func _on_symbols_pressed() -> void:
	_start_game("symbols.speed")


func _start_game(game_id: String) -> void:
	EventBus.emit_safe("game_started", [game_id])
