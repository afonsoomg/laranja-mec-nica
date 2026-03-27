extends Node2D
class_name VfxComponent

@export var heal_burst: GPUParticles2D
@export var crit_buff_burst: GPUParticles2D
@export var hit_burst: GPUParticles2D

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
