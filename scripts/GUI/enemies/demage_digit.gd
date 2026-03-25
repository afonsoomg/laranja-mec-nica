extends Node2D

@export var value: int = 0
@export var is_critical: bool = false

@onready var label: Label = $Node2D/Label

func _ready() -> void:
	if label == null:
		push_error("Label não encontrado no DamageDigit.")
		return

	top_level = true
	label.text = str(value)
	label.visible = true
	
	if is_critical:
		label.text = "CRIT " + str(value)
		label.add_theme_color_override("font_color", Color("#ffd54a"))
		label.add_theme_color_override("font_outline_color", Color("#5a3200"))
		label.add_theme_constant_override("outline_size", 5)
		scale = Vector2(2.6, 2.6)
	else:
		label.text = str(value)
		label.add_theme_color_override("font_color", Color("#ffffff"))
		label.add_theme_color_override("font_outline_color", Color("#000000"))
		label.add_theme_constant_override("outline_size", 3)
		scale = Vector2(2, 2)
