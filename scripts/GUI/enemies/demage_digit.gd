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
		label.text = "CRIT " + str(value) + "!"
		label.modulate = Color(0.863, 0.775, 0.0, 1.0)
		scale = Vector2(2.6, 2.6)
	else:
		label.text = str(value)
		scale = Vector2(2, 2)
