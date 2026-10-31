# tests/run_all.gd
extends SceneTree


func _init() -> void:
	print("==========================================")
	print("Ejecutando Suite de Pruebas Headless NeuroFit")
	print("==========================================")

	var test_eb = load("res://tests/test_event_bus.gd").new()
	var test_mm = load("res://tests/test_motion_manager.gd").new()
	var test_pl = load("res://tests/test_plugin_loader.gd").new()

	var pass_eb = test_eb.run()
	var pass_mm = test_mm.run()
	var pass_pl = test_pl.run()

	print("==========================================")
	if pass_eb and pass_mm and pass_pl:
		print("RESULTADO GLOBAL: TODAS LAS PRUEBAS PASARON [SUCCESS]")
		print("==========================================")
		OS.exit_code = 0
	else:
		print("RESULTADO GLOBAL: FALLO EN LAS PRUEBAS [FAILURE]")
		print("==========================================")
		OS.exit_code = 1

	quit()
