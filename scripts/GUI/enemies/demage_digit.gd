extends Node2D

@export var value: int = 0

@onready var label: Label = $Node2D/Label

func _ready() -> void:
	if label == null:
		push_error("Label não encontrado no DamageDigit.")
		return

	top_level = true
	label.text = str(value)
	label.visible = true
	label.modulate = Color(1, 0, 0, 1)

	visible = true
	modulate = Color(1, 1, 1, 1)
	scale = Vector2(2, 2)
	z_index = 100
