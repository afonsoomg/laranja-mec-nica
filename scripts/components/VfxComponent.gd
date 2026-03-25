extends Node2D
class_name VfxComponent

@export var heal_burst: GPUParticles2D
@export var crit_buff_burst: GPUParticles2D
@export var crit_aura: GPUParticles2D
@export var death_burst: GPUParticles2D


func play_heal_burst() -> void:
	_restart_particles(heal_burst)


func play_crit_buff_burst() -> void:
	_restart_particles(crit_buff_burst)


func set_crit_aura_active(active: bool) -> void:
	if crit_aura == null:
		return

	crit_aura.visible = active
	crit_aura.emitting = active

	if active:
		crit_aura.restart()


func play_death_burst() -> void:
	_restart_particles(death_burst)


func _restart_particles(particles: GPUParticles2D) -> void:
	if particles == null:
		return

	particles.restart()
	particles.emitting = true
