extends StaticBody2D
class_name Breakable

signal broken(reason: String)
signal damaged(damage: int, direction: Vector2, force: float, is_critical: bool)

@export var queue_free_on_break: bool = true
@export var break_free_delay: float = 0.0
@export var break_on_player_dodge: bool = false

@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var hurtbox_collision: CollisionShape2D = $HurtboxComponent/CollisionShape2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dodge_trigger: Area2D = $DodgeTrigger

var is_broken: bool = false


func _ready() -> void:
	if health_component != null and not health_component.died.is_connected(_on_died):
		health_component.died.connect(_on_died)

	if dodge_trigger != null and not dodge_trigger.body_entered.is_connected(_on_dodge_trigger_body_entered):
		dodge_trigger.body_entered.connect(_on_dodge_trigger_body_entered)

	if hurtbox_component != null and not hurtbox_component.hit_received.is_connected(_on_hit_receive):
		hurtbox_component.hit_received.connect(_on_hit_receive)

	if dodge_trigger != null:
		dodge_trigger.monitoring = break_on_player_dodge
		dodge_trigger.monitorable = break_on_player_dodge

	if animated_sprite != null and animated_sprite.sprite_frames != null:
		if animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")


func break_now(reason: String = "manual") -> void:
	if is_broken:
		return

	is_broken = true

	if hurtbox_component != null:
		hurtbox_component.can_receive_hits = false
		hurtbox_component.set_deferred("monitoring", false)
		hurtbox_component.set_deferred("monitorable", false)

	if hurtbox_collision != null:
		hurtbox_collision.set_deferred("disabled", true)

	if body_collision != null:
		body_collision.set_deferred("disabled", true)

	if dodge_trigger != null:
		dodge_trigger.set_deferred("monitoring", false)
		dodge_trigger.set_deferred("monitorable", false)

	if animated_sprite != null and animated_sprite.sprite_frames != null:
		if animated_sprite.sprite_frames.has_animation("break"):
			animated_sprite.play("break")

	broken.emit(reason)

	if queue_free_on_break:
		call_deferred("_queue_free_after_break")


func _queue_free_after_break() -> void:
	if animated_sprite != null and animated_sprite.sprite_frames != null:
		if animated_sprite.sprite_frames.has_animation("break") and animated_sprite.animation == "break":
			await animated_sprite.animation_finished

	if break_free_delay > 0.0:
		await get_tree().create_timer(break_free_delay).timeout

	queue_free()


func _on_died() -> void:
	break_now("hit")


func _on_dodge_trigger_body_entered(body: Node) -> void:
	if not break_on_player_dodge or is_broken:
		return

	if body == null or not body.is_in_group("player"):
		return

	var combat_state := body.get_node_or_null("CombatStateComponent")
	if combat_state != null and combat_state.is_dodging:
		break_now("dodge")

func _on_hit_receive(damage: int, direction: Vector2, force: float, is_critical: bool) -> void:
	if is_broken:
		return
		
	damaged.emit(damage, direction, force, is_critical)
