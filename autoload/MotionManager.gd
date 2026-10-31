# autoload/MotionManager.gd
extends Node

const Constants = preload("res://core/constants.gd")

# Niveles de prioridad para animaciones
enum Priority {
	AMBIENT = 0,
	TRANSITION = 1,
	IMPACT = 2
}

# Límite de tweens por widget
const MAX_TWEENS_PER_NODE: int = 2

# Pool de Tweens reciclables
var _tween_pool: Array = []
var _active_tweens_by_node: Dictionary = {}  # instance_id -> Array de Dictionaries

# Presets precargados
var presets: Dictionary = {}


func _ready() -> void:
	_load_presets()
	_initialize_tween_pool(8)
	print("[MotionManager] Inicializado con ", presets.size(), " presets precargados.")


func _load_presets() -> void:
	presets["entry_bounce"] = preload("res://core/motion_presets/entry_bounce.tres")
	presets["correct_reward"] = preload("res://core/motion_presets/correct_reward.tres")
	presets["error_shake"] = preload("res://core/motion_presets/error_shake.tres")
	presets["scene_crossfade"] = preload("res://core/motion_presets/scene_crossfade.tres")


func _initialize_tween_pool(count: int) -> void:
	for i in range(count):
		var tw = Tween.new()
		add_child(tw)
		_tween_pool.append(tw)


func acquire_tween(target_node: Node, priority: int = Priority.TRANSITION) -> Tween:
	if not is_instance_valid(target_node):
		return null

	var node_id = target_node.get_instance_id()

	if not _active_tweens_by_node.has(node_id):
		_active_tweens_by_node[node_id] = []

	var node_tweens: Array = _active_tweens_by_node[node_id]

	# Verificar límite de tweens por nodo
	if node_tweens.size() >= MAX_TWEENS_PER_NODE:
		# Buscar el tween de menor prioridad
		var lowest_priority_idx = -1
		var lowest_priority_val = 999

		for i in range(node_tweens.size()):
			if node_tweens[i]["priority"] < lowest_priority_val:
				lowest_priority_val = node_tweens[i]["priority"]
				lowest_priority_idx = i

		if priority >= lowest_priority_val and lowest_priority_idx != -1:
			# Reemplazar el tween de menor prioridad
			var old_record = node_tweens[lowest_priority_idx]
			_release_tween_record(node_id, old_record)
		else:
			# La prioridad solicitada es menor que las activas, ignorar
			return null

	# Obtener tween del pool
	var tw: Tween
	if _tween_pool.size() > 0:
		tw = _tween_pool.pop_back()
	else:
		tw = Tween.new()
		add_child(tw)

	tw.reset_all()

	var record = {
		"tween": tw,
		"priority": priority,
		"target_id": node_id
	}

	_active_tweens_by_node[node_id].append(record)

	tw.connect("tween_all_completed", self, "_on_tween_completed", [node_id, record], CONNECT_ONESHOT)

	return tw


func _on_tween_completed(node_id: int, record: Dictionary) -> void:
	_release_tween_record(node_id, record)


func _release_tween_record(node_id: int, record: Dictionary) -> void:
	var tw: Tween = record["tween"]
	if is_instance_valid(tw):
		tw.stop_all()
		if tw.is_connected("tween_all_completed", self, "_on_tween_completed"):
			tw.disconnect("tween_all_completed", self, "_on_tween_completed")
		_tween_pool.append(tw)

	if _active_tweens_by_node.has(node_id):
		_active_tweens_by_node[node_id].erase(record)
		if _active_tweens_by_node[node_id].empty():
			_active_tweens_by_node.erase(node_id)


# Hit-Pause seguro (40-60 ms) — mide tiempo REAL con OS.get_ticks_msec.
# El SceneTreeTimer respeta Engine.time_scale, así que el timer anterior
# quedaba en 0 s: la pausa duraba 1 frame en vez de los ms previstos.
func trigger_hit_pause(duration_ms: float = Constants.HIT_PAUSE_DURATION_MS) -> void:
	if Engine.time_scale != 1.0:
		return  # evita pausas anidadas que dejen el time_scale colgado
	Engine.time_scale = 0.0
	var start_ms := OS.get_ticks_msec()
	var target_ms := int(duration_ms)
	while OS.get_ticks_msec() - start_ms < target_ms:
		yield(get_tree(), "idle_frame")
	Engine.time_scale = 1.0

# Funciones de conveniencia para aplicar presets
func animate_entry(target: Control) -> void:
	var tw = acquire_tween(target, Priority.IMPACT)
	if tw == null:
		return
	var preset = presets["entry_bounce"]
	target.rect_scale = Vector2.ZERO
	tw.interpolate_property(target, "rect_scale", Vector2.ZERO, Vector2.ONE, preset.duration, preset.trans_type, preset.ease_type)
	tw.start()


func animate_correct(target: Control) -> void:
	var tw = acquire_tween(target, Priority.IMPACT)
	if tw == null:
		return
	var preset = presets["correct_reward"]
	var orig_scale = target.rect_scale
	tw.interpolate_property(target, "rect_scale", orig_scale, orig_scale * preset.scale_factor, preset.duration * 0.5, preset.trans_type, preset.ease_type)
	tw.interpolate_property(target, "rect_scale", orig_scale * preset.scale_factor, orig_scale, preset.duration * 0.5, preset.trans_type, preset.ease_type, preset.duration * 0.5)
	tw.start()
	trigger_hit_pause()


func animate_error(target: Control) -> void:
	var tw = acquire_tween(target, Priority.IMPACT)
	if tw == null:
		return
	var preset = presets["error_shake"]
	var orig_pos = target.rect_position
	tw.interpolate_property(target, "rect_position", orig_pos, orig_pos + Vector2(-4, 0), preset.duration * 0.25, preset.trans_type, preset.ease_type)
	tw.interpolate_property(target, "rect_position", orig_pos + Vector2(-4, 0), orig_pos + Vector2(4, 0), preset.duration * 0.5, preset.trans_type, preset.ease_type, preset.duration * 0.25)
	tw.interpolate_property(target, "rect_position", orig_pos + Vector2(4, 0), orig_pos, preset.duration * 0.25, preset.trans_type, preset.ease_type, preset.duration * 0.75)
	tw.start()
