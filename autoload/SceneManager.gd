# autoload/SceneManager.gd
extends Node

# Capa de UI independiente para la animación de transición
var _overlay_layer: CanvasLayer
var _overlay_rect: ColorRect
var _is_transitioning: bool = false

# Cargador interactivo
var _loader: ResourceInteractiveLoader
var _target_scene_path: String = ""


func _ready() -> void:
	_create_overlay()
	EventBus.connect("scene_change_requested", self, "_on_scene_change_requested")
	print("[SceneManager] Inicializado con overlay de transición cross-fade.")


func _create_overlay() -> void:
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 100  # Por encima de la escena principal
	add_child(_overlay_layer)

	_overlay_rect = ColorRect.new()
	_overlay_rect.anchor_right = 1.0
	_overlay_rect.anchor_bottom = 1.0
	_overlay_rect.color = Color(0.95, 0.95, 0.96, 0.0)  # Color dashboard "clean" transparente
	_overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_layer.add_child(_overlay_rect)


func change_scene(scene_path: String, duration: float = 0.35) -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	_target_scene_path = scene_path
	_overlay_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	# Fade-in del overlay
	var tw = Tween.new()
	add_child(tw)
	tw.interpolate_property(_overlay_rect, "color:a", 0.0, 1.0, duration * 0.5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	tw.start()
	yield(tw, "tween_all_completed")
	tw.queue_free()

	# Carga asíncrona de la nueva escena
	_loader = ResourceLoader.load_interactive(scene_path)
	if _loader == null:
		push_error("[SceneManager] Error al abrir la escena: " + scene_path)
		_finish_transition(duration)
		return

	set_process(true)


func _process(_delta: float) -> void:
	if _loader == null:
		set_process(false)
		return

	var err = _loader.poll()

	if err == ERR_FILE_EOF:
		var new_scene_resource = _loader.get_resource()
		_loader = null
		set_process(false)

		# Cambiar escena en el árbol
		get_tree().change_scene_to(new_scene_resource)

		_finish_transition(0.35)
	elif err != OK:
		push_error("[SceneManager] Error durante la carga interactiva: " + str(err))
		_loader = null
		set_process(false)
		_finish_transition(0.35)


func _finish_transition(duration: float) -> void:
	var tw = Tween.new()
	add_child(tw)
	tw.interpolate_property(_overlay_rect, "color:a", 1.0, 0.0, duration * 0.5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	tw.start()
	yield(tw, "tween_all_completed")
	tw.queue_free()

	_overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false


func _on_scene_change_requested(scene_path: String) -> void:
	change_scene(scene_path)
