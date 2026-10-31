# scenes/HubCentral.gd
# Hub data-driven: tarjetas generadas desde PluginLoader (manifiestos).
extends Control

const BG_COLOR = Color(0.039, 0.039, 0.047)
const ACCENT_CORRECT = Color(0.0, 0.949, 0.996)
const ACCENT_ERROR = Color(1.0, 0.322, 0.322)
const TEXT_PRIMARY = Color(0.95, 0.95, 0.97)
const TEXT_SECONDARY = Color(0.5, 0.5, 0.55)

const PREFERRED_ORDER := [
	"calc.x20",
	"symbols.speed",
	"head.count",
	"workmem.adaptive",
	"stroop.voice"
]

const CATEGORY_LABELS := {
	"processing": "Velocidad",
	"processing_speed": "Velocidad",
	"attention": "Atención",
	"memory": "Memoria",
	"inhibition": "Control",
	"control": "Control"
}

const FALLBACK_COLORS := {
	"calc.x20": Color(1.0, 0.42, 0.42),
	"stroop.voice": Color(0.305, 0.804, 0.769),
	"head.count": Color(0.424, 0.388, 1.0),
	"workmem.adaptive": Color(0.424, 0.388, 1.0),
	"symbols.speed": Color(1.0, 0.722, 0.298)
}

onready var cognitive_index_label: Label = $VBoxContainer/TopSection/CognitiveIndex/HBoxContainer/ValueLabel
onready var cognitive_trend_label: Label = $VBoxContainer/TopSection/CognitiveIndex/HBoxContainer/TrendLabel
onready var game_grid: GridContainer = $VBoxContainer/GameGrid/GridContainer
onready var performance_chart: Control = $VBoxContainer/PerformanceSection/ChartContainer

var stats_data: Dictionary = {}
const STATS_FILE = "user://stats.json"


func _ready() -> void:
	_apply_oled_theme()
	_load_stats()
	_setup_game_cards()
	_update_cognitive_index()
	_draw_performance_chart()
	EventBus.connect("game_ended", self, "_on_game_ended")


func _apply_oled_theme() -> void:
	$Background.color = BG_COLOR


func _load_stats() -> void:
	var file := File.new()
	if file.file_exists(STATS_FILE):
		file.open(STATS_FILE, File.READ)
		var json := file.get_as_text()
		file.close()
		var parse_result = JSON.parse(json)
		if parse_result.error == OK and parse_result.result is Dictionary:
			stats_data = parse_result.result
		else:
			_init_empty_stats()
	else:
		_init_empty_stats()


func _init_empty_stats() -> void:
	stats_data = {
		"sessions": [],
		"cognitive_index": 100,
		"last_7_days": {
			"accuracy": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
			"reaction_time": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
		}
	}


func _setup_game_cards() -> void:
	while game_grid.get_child_count() > 0:
		game_grid.get_child(0).free()
	var plugins: Array = _sorted_plugins()
	if plugins.empty():
		_add_empty_hint()
		return
	for manifest in plugins:
		var card := _build_card(manifest)
		game_grid.add_child(card)


func _sorted_plugins() -> Array:
	var all: Array = PluginLoader.get_all_plugins()
	var by_id: Dictionary = {}
	for m in all:
		by_id[str(m.get("id", ""))] = m
	var ordered: Array = []
	for id in PREFERRED_ORDER:
		if by_id.has(id):
			ordered.append(by_id[id])
			by_id.erase(id)
	var rest: Array = by_id.keys()
	rest.sort()
	for id in rest:
		ordered.append(by_id[id])
	return ordered


func _add_empty_hint() -> void:
	var lab := Label.new()
	lab.text = "No hay plugins en res://plugins/"
	lab.align = Label.ALIGN_CENTER
	lab.add_color_override("font_color", TEXT_SECONDARY)
	game_grid.add_child(lab)


func _build_card(manifest: Dictionary) -> PanelContainer:
	var id: String = str(manifest.get("id", "unknown"))
	var display: Dictionary = {}
	if manifest.has("display") and manifest["display"] is Dictionary:
		display = manifest["display"]
	var name: String = str(display.get("name", id))
	var category: String = _category_label(str(manifest.get("category", "")), display)
	var color: Color = _resolve_color(id, display)
	var card := PanelContainer.new()
	card.rect_min_size = Vector2(200, 160)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_card_style(card, color)
	var vbox := VBoxContainer.new()
	vbox.add_constant_override("separation", 6)
	card.add_child(vbox)
	var margin := MarginContainer.new()
	margin.add_constant_override("margin_left", 12)
	margin.add_constant_override("margin_right", 12)
	margin.add_constant_override("margin_top", 12)
	margin.add_constant_override("margin_bottom", 12)
	vbox.add_child(margin)
	var inner := VBoxContainer.new()
	inner.add_constant_override("separation", 6)
	margin.add_child(inner)
	var cat_lab := Label.new()
	cat_lab.text = category.to_upper()
	cat_lab.add_color_override("font_color", color)
	inner.add_child(cat_lab)
	var name_lab := Label.new()
	name_lab.text = name
	name_lab.autowrap = true
	name_lab.add_color_override("font_color", TEXT_PRIMARY)
	inner.add_child(name_lab)
	var id_lab := Label.new()
	id_lab.text = id
	id_lab.add_color_override("font_color", TEXT_SECONDARY)
	inner.add_child(id_lab)
	var btn := Button.new()
	btn.text = "Jugar"
	btn.rect_min_size = Vector2(0, 40)
	btn.connect("pressed", self, "_on_game_selected", [id])
	inner.add_child(btn)
	return card


func _category_label(category: String, display: Dictionary) -> String:
	if display.has("category_label"):
		return str(display["category_label"])
	if CATEGORY_LABELS.has(category):
		return CATEGORY_LABELS[category]
	if category != "":
		return category.capitalize()
	return "Juego"


func _resolve_color(id: String, display: Dictionary) -> Color:
	if display.has("color"):
		var c = display["color"]
		if c is String:
			return Color(str(c))
		if c is Color:
			return c
	if FALLBACK_COLORS.has(id):
		return FALLBACK_COLORS[id]
	return Color(0.6, 0.6, 0.65)


func _apply_card_style(card: PanelContainer, accent_color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_color = accent_color.darkened(0.2)
	card.add_stylebox_override("panel", style)


func _update_cognitive_index() -> void:
	var index = stats_data.get("cognitive_index", 100)
	cognitive_index_label.text = str(index)
	var last_7 = stats_data.get("last_7_days", {}).get("accuracy", [])
	if last_7.size() >= 2:
		var recent_avg = 0.0
		var older_avg = 0.0
		for i in range(3):
			if last_7.size() - 1 - i >= 0:
				recent_avg += last_7[last_7.size() - 1 - i]
			if last_7.size() - 4 - i >= 0:
				older_avg += last_7[last_7.size() - 4 - i]
		recent_avg /= 3.0
		older_avg /= 3.0
		if recent_avg > older_avg:
			cognitive_trend_label.text = "↑ Mejorando"
			cognitive_trend_label.add_color_override("font_color", ACCENT_CORRECT)
		elif recent_avg < older_avg:
			cognitive_trend_label.text = "↓ Necesita práctica"
			cognitive_trend_label.add_color_override("font_color", ACCENT_ERROR)
		else:
			cognitive_trend_label.text = "→ Estable"
			cognitive_trend_label.add_color_override("font_color", TEXT_SECONDARY)


func _draw_performance_chart() -> void:
	if not performance_chart.is_connected("draw", self, "_on_chart_draw"):
		performance_chart.connect("draw", self, "_on_chart_draw")
	performance_chart.update()


func _on_chart_draw() -> void:
	var accuracy_data = stats_data.get("last_7_days", {}).get("accuracy", [])
	if accuracy_data.size() < 2:
		return
	var rect = performance_chart.get_rect()
	var width = rect.size.x
	var height = rect.size.y
	var points = PoolVector2Array()
	for i in range(accuracy_data.size()):
		var x = (float(i) / (accuracy_data.size() - 1)) * width
		var y = height - (float(accuracy_data[i]) * height)
		points.append(Vector2(x, y))
	performance_chart.draw_polyline(points, ACCENT_CORRECT, 2.0)


func _on_game_selected(game_id: String) -> void:
	EventBus.emit_safe("scene_change_requested", [_get_game_scene_path(game_id)])


func _get_game_scene_path(game_id: String) -> String:
	if PluginLoader.has_plugin(game_id):
		var scene_path: String = PluginLoader.get_scene_path(game_id)
		if scene_path != "":
			return scene_path
	push_warning("[HubCentral] Plugin no encontrado o sin escena: " + game_id)
	return "res://scenes/GameSelection.tscn"


func _on_game_ended(summary: Dictionary) -> void:
	_save_session(summary)
	_load_stats()
	_update_cognitive_index()
	_draw_performance_chart()


func _save_session(summary: Dictionary) -> void:
	var file := File.new()
	file.open(STATS_FILE, File.WRITE)
	if not stats_data.has("sessions"):
		stats_data["sessions"] = []
	stats_data.sessions.append(summary)
	if not stats_data.has("last_7_days"):
		stats_data["last_7_days"] = {
			"accuracy": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
			"reaction_time": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
		}
	var last_7 = stats_data.last_7_days
	var accuracy = summary.get("accuracy", 0.0)
	var reaction_time = summary.get("avg_reaction_time", 0.0)
	last_7.accuracy.pop_front()
	last_7.accuracy.append(accuracy)
	last_7.reaction_time.pop_front()
	last_7.reaction_time.append(reaction_time)
	stats_data.cognitive_index = _calculate_cognitive_index()
	file.store_string(JSON.print(stats_data, "\t"))
	file.close()


func _calculate_cognitive_index() -> int:
	var last_7 = stats_data.get("last_7_days", {}).get("accuracy", [])
	if last_7.empty():
		return 100
	var sum := 0.0
	for v in last_7:
		sum += float(v)
	var avg = sum / float(last_7.size())
	return int(clamp(round(avg * 100.0), 0, 200))
