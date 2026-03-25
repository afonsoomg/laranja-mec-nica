extends Node
class_name HitFlashComponent

@export var hurtbox_component: HurtboxComponent
@export var animated_sprite: AnimatedSprite2D

@export var flash_color: Color = Color(1.0, 0.3, 0.3, 1.0)
@export var flash_duration: float = 0.08
@export var use_white_flash: bool = false

var _is_flashing: bool = false
var _original_modulate: Color = Color(1, 1, 1, 1)
var _flash_token: int = 0


func _ready() -> void:
	if hurtbox_component == null:
		hurtbox_component = get_parent().get_node_or_null("HurtboxComponent") as HurtboxComponent

	if animated_sprite == null:
		animated_sprite = get_parent().get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

	if hurtbox_component == null:
		push_error("HitFlashComponent precisa de um HurtboxComponent.")
		return

	if animated_sprite == null:
		push_error("HitFlashComponent precisa de um AnimatedSprite2D.")
		return

	_original_modulate = animated_sprite.modulate

	if not hurtbox_component.hit_received.is_connected(_on_hit_received):
		hurtbox_component.hit_received.connect(_on_hit_received)


func _on_hit_received(_damage: int, _direction: Vector2, _force: float, _is_critical: bool) -> void:
	_play_flash()


func _play_flash() -> void:
	if animated_sprite == null:
		return

	_flash_token += 1
	var current_token := _flash_token

	_is_flashing = true
	animated_sprite.modulate = Color(1, 1, 1, 1) if use_white_flash else flash_color

	_end_flash_later(current_token)


func _end_flash_later(token: int) -> void:
	await get_tree().create_timer(flash_duration).timeout

	if not is_inside_tree():
		return

	if token != _flash_token:
		return

	if animated_sprite != null:
		animated_sprite.modulate = _original_modulate

	_is_flashing = false


func reset_flash() -> void:
	_flash_token += 1
	_is_flashing = false

	if animated_sprite != null:
		animated_sprite.modulate = _original_modulate
