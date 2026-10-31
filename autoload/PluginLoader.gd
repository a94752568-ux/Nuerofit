# autoload/PluginLoader.gd
extends Node

var loaded_plugins: Dictionary = {}  # plugin_id -> Dictionary (manifest)

const PLUGINS_ROOT := "res://plugins"


func _ready() -> void:
	scan_plugins()
	print("[PluginLoader] Inicializado. Plugins cargados: ", loaded_plugins.size())


func scan_plugins() -> void:
	loaded_plugins.clear()
	var dir := Directory.new()
	if dir.open(PLUGINS_ROOT) != OK:
		push_warning("[PluginLoader] No existe carpeta de plugins: " + PLUGINS_ROOT)
		return

	dir.list_dir_begin(true, true)  # skip navigational, skip hidden
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			var manifest_path := PLUGINS_ROOT + "/" + entry + "/minigame.json"
			_load_manifest_file(manifest_path)
		entry = dir.get_next()
	dir.list_dir_end()


func _load_manifest_file(path: String) -> bool:
	var file := File.new()
	if not file.file_exists(path):
		return false
	var err := file.open(path, File.READ)
	if err != OK:
		push_warning("[PluginLoader] No se pudo abrir: " + path)
		return false
	var text := file.get_as_text()
	file.close()
	return load_plugin_from_manifest_json(text)


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
	print("[PluginLoader] Minijuego cargado: ", manifest["id"], " → ", manifest.get("scene", ""))
	return true


func get_all_plugins() -> Array:
	var list: Array = []
	for id in loaded_plugins.keys():
		list.append(loaded_plugins[id])
	return list


func get_plugin(plugin_id: String) -> Dictionary:
	if loaded_plugins.has(plugin_id):
		return loaded_plugins[plugin_id]
	return {}


func has_plugin(plugin_id: String) -> bool:
	return loaded_plugins.has(plugin_id)


func get_scene_path(plugin_id: String) -> String:
	var m: Dictionary = get_plugin(plugin_id)
	if m.empty():
		return ""
	return str(m.get("scene", ""))
