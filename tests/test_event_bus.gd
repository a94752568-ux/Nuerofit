# tests/test_event_bus.gd
extends SceneTree

var _received_signal: bool = false
var _received_arg: String = ""


func run() -> bool:
	print("--- [TEST] EventBus ---")

	# Test 1: emit_safe con señal válida
	EventBus.connect("game_started", self, "_on_game_started")
	var success = EventBus.emit_safe("game_started", ["calc.x20"])

	if not success or not _received_signal or _received_arg != "calc.x20":
		print("FAIL: EventBus emit_safe falló en señal válida")
		return false

	# Test 2: emit_safe con señal inválida (debe retornar false sin crash)
	var invalid_success = EventBus.emit_safe("signal_non_existent", ["test"])
	if invalid_success:
		print("FAIL: EventBus permitió emitir señal inexistente")
		return false

	# Test 3: Event log
	var log_entries = EventBus.get_event_log()
	if log_entries.empty():
		print("FAIL: EventBus log de eventos está vacío")
		return false

	print("PASS: EventBus tests pasaron correctamente.")
	return true


func _on_game_started(plugin_id: String) -> void:
	_received_signal = true
	_received_arg = plugin_id
