# tests/test_motion_manager.gd
extends SceneTree


func run() -> bool:
	print("--- [TEST] MotionManager ---")

	var mm = MotionManager
	if mm == null:
		print("FAIL: MotionManager no disponible")
		return false

	var node = Control.new()
	root.add_child(node)

	# Test 1: Adquisición de Tween
	var tw1 = mm.acquire_tween(node, mm.Priority.TRANSITION)
	if tw1 == null:
		print("FAIL: No se pudo adquirir primer tween")
		node.free()
		return false

	# Test 2: Adquisición de segundo Tween (límite es 2)
	var tw2 = mm.acquire_tween(node, mm.Priority.IMPACT)
	if tw2 == null:
		print("FAIL: No se pudo adquirir segundo tween")
		node.free()
		return false

	# Test 3: Reemplazo por prioridad (tercer tween con prioridad igual o mayor reacciona)
	var tw3 = mm.acquire_tween(node, mm.Priority.IMPACT)
	if tw3 == null:
		print("FAIL: No se reemplazó el tween de menor prioridad adecuadamente")
		node.free()
		return false

	node.free()
	print("PASS: MotionManager tests pasaron correctamente.")
	return true
