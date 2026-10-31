# tests/test_plugin_loader.gd
extends SceneTree


func run() -> bool:
	print("--- [TEST] PluginLoader (Manifiesto Malicioso/Incompleto) ---")

	# Test 1: Manifiesto incompleto
	var incomplete_json = '{"id": "broken_game", "version": "1.0"}'
	var result1 = PluginLoader.load_plugin_from_manifest_json(incomplete_json)
	if result1:
		print("FAIL: PluginLoader aceptó un manifiesto incompleto")
		return false

	# Test 2: Manifiesto con JSON corrupto
	var corrupt_json = '{ id: broken_game, version: '
	var result2 = PluginLoader.load_plugin_from_manifest_json(corrupt_json)
	if result2:
		print("FAIL: PluginLoader aceptó un JSON corrupto")
		return false

	# Test 3: Manifiesto válido completo (§3.4)
	var valid_json = """
	{
		"id": "calc.x20",
		"version": "1.0.0",
		"engine_min": "3.5.0",
		"category": "processing_speed",
		"difficulty_range": [1, 8],
		"session_shape": [120, 300],
		"input": ["touch_trace", "keyboard"],
		"render_profile": "Low",
		"scene": "res://plugins/calc_x20/main.tscn",
		"cognitive_hooks": {}
	}
	"""
	var result3 = PluginLoader.load_plugin_from_manifest_json(valid_json)
	if not result3:
		print("FAIL: PluginLoader rechazó un manifiesto válido")
		return false

	print("PASS: PluginLoader tests de robustez pasaron correctamente.")
	return true
