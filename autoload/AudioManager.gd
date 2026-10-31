# autoload/AudioManager.gd
extends Node

const Constants = preload("res://core/constants.gd")

# Pool de reproductores de SFX
var _sfx_pool: Array = []
const SFX_POOL_SIZE: int = 8

# Reproductores de temas musicales adaptativos
var _music_players: Dictionary = {}  # theme_name -> AudioStreamPlayer
var _current_active_theme: String = ""

# Rutas de los temas musicales basados en _raw/
const THEMES = {
	"grounding": "res://assets/audio/_raw/Modulo_1_Grounding & Bio-Sync(El Anclaje).mp3",
	"fluid": "res://assets/audio/_raw/Modulo_2_Fluid State(La Disolución).mp3",
	"air": "res://assets/audio/_raw/Modulo_3_Air&Breath(La Elevación).mp3",
	"return": "res://assets/audio/_raw/Modulo_5_Integration&Return(El Aterrizaje).mp3"
}

# Estado de racha actual para ajuste de pitch/armonía
var current_streak: int = 0

# Volumen maestro y silenciado térmico
var is_thermal_muted: bool = false


func _ready() -> void:
	_init_sfx_pool()
	_init_music_players()

	EventBus.connect("audio_event_triggered", self, "_on_audio_event_triggered")
	EventBus.connect("thermal_state_changed", self, "_on_thermal_state_changed")
	EventBus.connect("game_started", self, "_on_game_started")
	EventBus.connect("game_ended", self, "_on_game_ended")

	print("[AudioManager] Inicializado con pool de ", SFX_POOL_SIZE, " SFX y temas adaptativos de _raw/.")
	play_theme("grounding")


func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
		_pause_all_audio()
	elif what == MainLoop.NOTIFICATION_WM_FOCUS_IN:
		_resume_all_audio()


func _init_sfx_pool() -> void:
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_sfx_pool.append(player)


func _init_music_players() -> void:
	for theme_name in THEMES.keys():
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)

		var path = THEMES[theme_name]
		var stream = _load_mp3_runtime(path)
		if stream != null:
			player.stream = stream
		else:
			push_warning("[AudioManager] No se pudo cargar el MP3 en runtime para el tema: " + theme_name)

		_music_players[theme_name] = player


func _load_mp3_runtime(path: String) -> AudioStreamMP3:
	var file = File.new()
	if file.file_exists(path):
		var err = file.open(path, File.READ)
		if err == OK:
			var buffer = file.get_buffer(file.get_len())
			file.close()
			var mp3_stream = AudioStreamMP3.new()
			mp3_stream.data = buffer
			return mp3_stream
	# Fallback intentando load normal si falla el binario directo
	var res = load(path)
	if res is AudioStreamMP3:
		return res
	return null


func play_theme(theme_name: String) -> void:
	if not _music_players.has(theme_name) or is_thermal_muted:
		return

	if _current_active_theme == theme_name:
		return

	if _current_active_theme != "" and _music_players.has(_current_active_theme):
		var old_player: AudioStreamPlayer = _music_players[_current_active_theme]
		if old_player.playing:
			old_player.stop()

	_current_active_theme = theme_name
	var new_player: AudioStreamPlayer = _music_players[theme_name]
	if new_player.stream != null:
		new_player.play()
		print("[AudioManager] Reproduciendo tema adaptativo: ", theme_name)


func play_sfx(stream: AudioStream, pitch_scale: float = 1.0, pitch_variation: float = 0.05) -> void:
	if stream == null or is_thermal_muted:
		return

	var player: AudioStreamPlayer = _get_available_sfx_player()
	if player == null:
		return

	var var_offset = (randf() * 2.0 - 1.0) * pitch_variation
	player.stream = stream
	player.pitch_scale = clamp(pitch_scale + var_offset, 0.5, 2.0)
	player.play()


func play_correct_sfx(stream: AudioStream = null) -> void:
	current_streak += 1
	var streak_pitch = min(1.0 + (current_streak * 0.05), 1.5)
	if stream != null:
		play_sfx(stream, streak_pitch, 0.03)


func play_error_sfx(stream: AudioStream = null) -> void:
	current_streak = 0
	if stream != null:
		play_sfx(stream, 0.9, 0.02)


func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	return _sfx_pool[0]


func _pause_all_audio() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)


func _resume_all_audio() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)


func _on_audio_event_triggered(event_name: String, params: Dictionary) -> void:
	match event_name:
		"correct_answer":
			play_correct_sfx(params.get("stream", null))
		"error_answer":
			play_error_sfx(params.get("stream", null))
		"reset_streak":
			current_streak = 0
		"play_theme":
			play_theme(params.get("theme", "grounding"))


func _on_game_started(plugin_id: String) -> void:
	if "calc" in plugin_id or "symbols" in plugin_id:
		play_theme("fluid")
	else:
		play_theme("air")


func _on_game_ended(_summary: Dictionary) -> void:
	play_theme("return")


func _on_thermal_state_changed(profile_level: int) -> void:
	if profile_level == Constants.ThermalProfile.LOW:
		is_thermal_muted = true
		_pause_all_audio()
		print("[AudioManager] Modo de rendimiento bajo térmico: silenciando audio.")
	else:
		is_thermal_muted = false
		_resume_all_audio()
		print("[AudioManager] Restaurando audio normal.")
