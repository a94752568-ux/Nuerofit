# core/constants.gd
class_name Constants

# Dominios cognitivos y colores del sistema
const DOMAIN_PROCESSING_SPEED = "processing_speed"
const DOMAIN_MEMORY = "memory"
const DOMAIN_INHIBITORY_CONTROL = "inhibitory_control"
const DOMAIN_DUAL_ATTENTION = "dual_attention"

const COLOR_CORAL = Color("#FF6B6B")       # Procesamiento
const COLOR_INDIGO = Color("#6C63FF")      # Memoria
const COLOR_TEAL = Color("#4ECDC4")        # Autocontrol
const COLOR_AMBER = Color("#FFB84C")       # Atención Dual

# Configuración de rendimiento
const TARGET_FRAME_TIME_MS = 16.6
const HIT_PAUSE_DURATION_MS = 50.0

# Perfiles de calidad
enum ThermalProfile {
	HIGH = 0,
	LOW = 1
}

# Estados de minijuego
enum GameState {
	INTRO,
	PLAYING,
	RESULTS,
	PAUSED
}
