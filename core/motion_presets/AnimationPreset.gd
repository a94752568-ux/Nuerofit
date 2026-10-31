# core/motion_presets/AnimationPreset.gd
class_name AnimationPreset
extends Resource

export (String) var name = ""
export (float) var duration = 0.3
export (int) var trans_type = Tween.TRANS_BACK
export (int) var ease_type = Tween.EASE_OUT
export (Vector2) var scale_factor = Vector2.ONE
export (Vector2) var offset = Vector2.ZERO
