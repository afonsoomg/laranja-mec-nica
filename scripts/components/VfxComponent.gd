extends Node2D
class_name VfxComponent

@export var heal_burst: GPUParticles2D
@export var crit_buff_burst: GPUParticles2D
@export var hit_burst: GPUParticles2D

@export_group("Reactions")
@export var hurtbox_component: HurtboxComponent

func _ready() -> void:
	if hurtbox_component == null:
		hurtbox_component = get_node_or_null("../HurtboxComponent") as HurtboxComponent

	if hurtbox_component != null and not hurtbox_component.hit_received.is_connected(_on_hit_received):
		hurtbox_component.hit_received.connect(_on_hit_received)


func _on_hit_received(_damage: int, _direction: Vector2, _force: float, _is_critical: bool) -> void:
	play_hit_burst()

func play_heal_burst() -> void:
	_restart_particles(heal_burst)


func play_crit_buff_burst() -> void:
	_restart_particles(crit_buff_burst)


func play_hit_burst() -> void:
	_restart_particles(hit_burst)


func _restart_particles(particles: GPUParticles2D) -> void:
	if particles == null:
		return

	particles.restart()
	particles.emitting = true
