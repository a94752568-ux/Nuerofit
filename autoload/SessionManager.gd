# autoload/SessionManager.gd
extends Node

var current_session_id: String = ""
var active_plugin_id: String = ""
var session_answers: Array = []


func _ready() -> void:
	EventBus.connect("game_started", self, "_on_game_started")
	EventBus.connect("game_ended", self, "_on_game_ended")
	EventBus.connect("game_answer", self, "_on_game_answer")
	print("[SessionManager] Inicializado.")


func start_new_session(plugin_id: String) -> void:
	active_plugin_id = plugin_id
	current_session_id = str(OS.get_unix_time()) + "_" + plugin_id
	session_answers.clear()
	print("[SessionManager] Nueva sesión iniciada: ", current_session_id)


func record_answer(answer_data: Dictionary) -> void:
	session_answers.append(answer_data)


func end_session() -> Dictionary:
	var summary = {
		"session_id": current_session_id,
		"plugin_id": active_plugin_id,
		"total_answers": session_answers.size(),
		"answers": session_answers.duplicate()
	}
	print("[SessionManager] Sesión finalizada: ", current_session_id, " con ", session_answers.size(), " respuestas.")
	current_session_id = ""
	active_plugin_id = ""
	session_answers.clear()
	return summary


func _on_game_started(plugin_id: String) -> void:
	start_new_session(plugin_id)


func _on_game_ended(_summary: Dictionary) -> void:
	end_session()


func _on_game_answer(answer_data: Dictionary) -> void:
	record_answer(answer_data)
