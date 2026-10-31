# scenes/HubCentral.gd
extends Control

# Estética OLED
const BG_COLOR = Color(0.039, 0.039, 0.047)  # #0A0A0C
const ACCENT_CORRECT = Color(0.0, 0.949, 0.996)  # #00F2FE
const ACCENT_ERROR = Color(1.0, 0.322, 0.322)  # #FF5252
const TEXT_PRIMARY = Color(0.95, 0.95, 0.97)
const TEXT_SECONDARY = Color(0.5, 0.5, 0.55)

# Referencias UI
onready var cognitive_index_label: Label = $VBoxContainer/TopSection/CognitiveIndex/HBoxContainer/ValueLabel
onready var cognitive_trend_label: Label = $VBoxContainer/TopSection/CognitiveIndex/HBoxContainer/TrendLabel
onready var game_grid: GridContainer = $VBoxContainer/GameGrid/GridContainer
onready var performance_chart: Control = $VBoxContainer/PerformanceSection/ChartContainer

# Datos de estadísticas
var stats_data: Dictionary = {}
const STATS_FILE = "user://stats.json"

# Definición de minijuegos
var games_data: Array = [
	{
		"id": "calc.x20",
		"name": "Cálculos ×20",
		"category": "Velocidad",
		"color": Color(1.0, 0.42, 0.42),  # Coral
		"icon": "calc"
	},
	{
		"id": "stroop.voice",
		"name": "Test de Stroop",
		"category": "Control",
		"color": Color(0.305, 0.804, 0.769),  # Verde
		"icon": "stroop"
	},
	{
		"id": "head.count",
		"name": "Head Count",
		"category": "Memoria",
		"color": Color(0.424, 0.388, 1.0),  # Índigo
		"icon": "head"
	},
	{
		"id": "workmem.adaptive",
		"name": "Memoria de Trabajo",
		"category": "Memoria",
		"color": Color(0.424, 0.388, 1.0),  # Índigo
		"icon": "workmem"
	},
	{
		"id": "symbols.speed",
		"name": "Velocidad de Símbolos",
		"category": "Atención",
		"color": Color(1.0, 0.722, 0.298),  # Ámbar
		"icon": "symbols"
	}
]


func _ready() -> void:
	_apply_oled_theme()
	_load_stats()
	_setup_game_cards()
	_update_cognitive_index()
	_draw_performance_chart()
	
	# Conectar eventos
	EventBus.connect("game_ended", self, "_on_game_ended")


func _apply_oled_theme() -> void:
	var bg = $Background
	bg.color = BG_COLOR


func _load_stats() -> void:
	var file = File.new()
	if file.file_exists(STATS_FILE):
		file.open(STATS_FILE, File.READ)
		var json = file.get_as_text()
		file.close()
		
		var parse_result = JSON.parse(json)
		if parse_result.error == OK:
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
	# Conectar botones estáticos
	$VBoxContainer/GameGrid/GridContainer/CalcCard/CalcButton.connect("pressed", self, "_on_game_selected", ["calc.x20"])
	$VBoxContainer/GameGrid/GridContainer/StroopCard/StroopButton.connect("pressed", self, "_on_game_selected", ["stroop.voice"])
	$VBoxContainer/GameGrid/GridContainer/HeadCountCard/HeadButton.connect("pressed", self, "_on_game_selected", ["head.count"])
	$VBoxContainer/GameGrid/GridContainer/WorkMemCard/WorkButton.connect("pressed", self, "_on_game_selected", ["workmem.adaptive"])
	$VBoxContainer/GameGrid/GridContainer/SymbolsCard/SymbolsButton.connect("pressed", self, "_on_game_selected", ["symbols.speed"])
	
	# Aplicar estilos a las tarjetas
	_apply_card_style($VBoxContainer/GameGrid/GridContainer/CalcCard, Color(1.0, 0.42, 0.42))
	_apply_card_style($VBoxContainer/GameGrid/GridContainer/StroopCard, Color(0.305, 0.804, 0.769))
	_apply_card_style($VBoxContainer/GameGrid/GridContainer/HeadCountCard, Color(0.424, 0.388, 1.0))
	_apply_card_style($VBoxContainer/GameGrid/GridContainer/WorkMemCard, Color(0.424, 0.388, 1.0))
	_apply_card_style($VBoxContainer/GameGrid/GridContainer/SymbolsCard, Color(1.0, 0.722, 0.298))


func _apply_card_style(card: PanelContainer, accent_color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	card.add_stylebox_override("panel", style)


func _update_cognitive_index() -> void:
	var index = stats_data.get("cognitive_index", 100)
	cognitive_index_label.text = str(index)
	
	# Calcular tendencia
	var last_7 = stats_data.get("last_7_days", {}).get("accuracy", [])
	if last_7.size() >= 2:
		var recent_avg = 0.0
		var older_avg = 0.0
		for i in range(3):
			recent_avg += last_7[last_7.size() - 1 - i]
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
	# Dibujar gráfica simple usando Control draw
	performance_chart.connect("draw", self, "_on_chart_draw")


func _on_chart_draw() -> void:
	var accuracy_data = stats_data.get("last_7_days", {}).get("accuracy", [])
	if accuracy_data.size() < 2:
		return
	
	var rect = performance_chart.get_rect()
	var width = rect.size.x
	var height = rect.size.y
	
	# Dibujar línea de precisión
	var points = PoolVector2Array()
	for i in range(accuracy_data.size()):
		var x = (float(i) / (accuracy_data.size() - 1)) * width
		var y = height - (accuracy_data[i] * height)
		points.append(Vector2(x, y))
	
	performance_chart.draw_polyline(points, ACCENT_CORRECT, 2.0)


func _on_game_selected(game_id: String) -> void:
	EventBus.emit_safe("scene_change_requested", [_get_game_scene_path(game_id)])


func _get_game_scene_path(game_id: String) -> String:
	# Preferir escena del plugin registrado; fallback a GameSelection
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
	var file = File.new()
	file.open(STATS_FILE, File.WRITE)
	
	# Actualizar datos
	stats_data.sessions.append(summary)
	
	# Actualizar últimos 7 días
	var last_7 = stats_data.last_7_days
	var accuracy = summary.get("accuracy", 0.0)
	var reaction_time = summary.get("avg_reaction_time", 0.0)
	
	last_7.accuracy.pop_front()
	last_7.accuracy.append(accuracy)
	last_7.reaction_time.pop_front()
	last_7.reaction_time.append(reaction_time)
	
	# Recalcular índice cognitivo
	stats_data.cognitive_index = _calculate_cognitive_index()
	
	file.store_string(JSON.print(stats_data))
	file.close()


func _calculate_cognitive_index() -> int:
	var last_7 = stats_data.get("last_7_days", {}).get("accuracy", [])
	if last_7.size() == 0:
		return 100
	
	var avg_accuracy = 0.0
	for acc in last_7:
		avg_accuracy += acc
	avg_accuracy /= last_7.size()
	
	return int(50 + avg_accuracy * 50)  # 50-100 range
