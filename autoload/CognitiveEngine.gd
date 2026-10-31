# autoload/CognitiveEngine.gd
extends Node

# Niveles de dificultad (1..8)
var current_difficulty: int = 1
var moving_window: Array = []
const WINDOW_SIZE: int = 8


func _ready() -> void:
	EventBus.connect("game_answer", self, "_on_game_answer")
	print("[CognitiveEngine] Inicializado.")


func process_answer(correct: bool, time_ms: float) -> Dictionary:
	var entry = {
		"correct": correct,
		"time_ms": time_ms,
		"difficulty": current_difficulty
	}
	moving_window.append(entry)
	if moving_window.size() > WINDOW_SIZE:
		moving_window.pop_front()

	_evaluate_staircase()
	return entry


func _evaluate_staircase() -> void:
	if moving_window.size() < WINDOW_SIZE:
		return

	var correct_count = 0
	for entry in moving_window:
		if entry["correct"]:
			correct_count += 1

	var accuracy = float(correct_count) / float(WINDOW_SIZE)

	if accuracy >= 0.875:
		_change_difficulty(min(current_difficulty + 2, 8))
	elif accuracy >= 0.75:
		_change_difficulty(min(current_difficulty + 1, 8))
	elif accuracy < 0.63:
		_change_difficulty(max(current_difficulty - 1, 1))


func _change_difficulty(new_diff: int) -> void:
	if new_diff != current_difficulty:
		current_difficulty = new_diff
		moving_window.clear()
		EventBus.emit_safe("difficulty_changed", [current_difficulty])


func _on_game_answer(answer_data: Dictionary) -> void:
	var correct = answer_data.get("correct", false)
	var time_ms = answer_data.get("time_ms", 0.0)
	process_answer(correct, time_ms)
