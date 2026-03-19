extends Node2D

@export var value: int = 0

func _ready():
	$Node2D/Label.text = str(value)
