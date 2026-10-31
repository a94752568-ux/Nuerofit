# autoload/PluginLoader.gd
extends Node

var loaded_plugins: Dictionary = {}  # plugin_id -> Dictionary (manifest)


func _ready() -> void:
	print("[PluginLoader] Inicializado.")


func validate_manifest(manifest: Dictionary) -> bool:
	var required_fields = [
		"id", "version", "engine_min", "category",
		"difficulty_range", "session_shape", "input",
		"render_profile", "scene"
	]

	for field in required_fields:
		if not manifest.has(field):
			push_warning("[PluginLoader] Manifiesto inválido: falta campo obligatorio '" + field + "'")
			return false

	if not (manifest["input"] is Array):
		push_warning("[PluginLoader] Manifiesto inválido: 'input' debe ser un Array")
		return false

	return true


func load_plugin_from_manifest_json(json_text: String) -> bool:
	var parse_result = JSON.parse(json_text)
	if parse_result.error != OK:
		push_warning("[PluginLoader] Error al parsear JSON de manifiesto: " + parse_result.error_string)
		return false

	var manifest = parse_result.result
	if not (manifest is Dictionary):
		push_warning("[PluginLoader] Manifiesto inválido: la raíz no es un Objeto/Dictionary")
		return false

	if not validate_manifest(manifest):
		push_warning("[PluginLoader] Ignorando minijuego con manifiesto inválido.")
		return false

	loaded_plugins[manifest["id"]] = manifest
	print("[PluginLoader] Minijuego cargado exitosamente: ", manifest["id"])
	return true
