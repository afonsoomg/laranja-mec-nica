extends Control

@export_range(0.5, 10.0, 0.1) var intro_duration: float = 2.4
@export var allow_skip: bool = true

@onready var title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel
@onready var hint_label: Label = $CenterContainer/PanelContainer/VBoxContainer/HintLabel

signal intro_finished


func _ready() -> void:
	title_label.modulate.a = 0.0
	hint_label.modulate.a = 0.0
	_play_intro()


func _unhandled_input(event: InputEvent) -> void:
	if not allow_skip:
		return

	if event.is_pressed() and event.is_action("ui_accept"):
		_finish_intro()


func _play_intro() -> void:
	var tween := create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 0.5)
	tween.tween_property(hint_label, "modulate:a", 1.0, 0.2)
	tween.tween_interval(max(intro_duration - 1.2, 0.2))
	tween.tween_interval(0.5)
	tween.tween_property(title_label, "modulate:a", 0.0, 0.5)
	tween.tween_property(hint_label, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(hint_label, "modulate:a", 1.0, 0.4)
	await tween.finished
	_finish_intro()


func _finish_intro() -> void:
	intro_finished.emit()
