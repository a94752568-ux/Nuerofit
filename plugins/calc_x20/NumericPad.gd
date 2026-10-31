# plugins/calc_x20/NumericPad.gd
# Teclado numérico táctil (48 dp mínimo). Emite dígitos, borrar y confirmar.
extends VBoxContainer

signal digit_pressed(digit)
signal backspace_pressed()
signal confirm_pressed()

const BTN_MIN := Vector2(64, 56)


func _ready() -> void:
	add_constant_override("separation", 8)
	_build()


func _build() -> void:
	var rows := [
		["1", "2", "3"],
		["4", "5", "6"],
		["7", "8", "9"],
		["⌫", "0", "OK"]
	]
	for row in rows:
		var h := HBoxContainer.new()
		h.add_constant_override("separation", 8)
		h.size_flags_horizontal = SIZE_EXPAND_FILL
		add_child(h)
		for label in row:
			var btn := Button.new()
			btn.text = label
			btn.rect_min_size = BTN_MIN
			btn.size_flags_horizontal = SIZE_EXPAND_FILL
			btn.size_flags_vertical = SIZE_EXPAND_FILL
			var captured: String = label
			btn.connect("pressed", self, "_on_btn", [captured])
			h.add_child(btn)


func _on_btn(label: String) -> void:
	match label:
		"⌫":
			emit_signal("backspace_pressed")
		"OK":
			emit_signal("confirm_pressed")
		_:
			emit_signal("digit_pressed", label)
