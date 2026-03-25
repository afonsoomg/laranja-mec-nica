extends Node2D
class_name AudioComponent

@export var sfx_player: AudioStreamPlayer2D

@export_group("Sounds")
@export var attack_sfx: AudioStream
@export var hurt_sfx: AudioStream
@export var death_sfx: AudioStream
@export var collect_sfx: AudioStream
@export var heal_sfx: AudioStream
@export var crit_buff_start_sfx: AudioStream
@export var crit_buff_end_sfx: AudioStream




func play_attack() -> void:
	_play(attack_sfx)


func play_hurt() -> void:
	_play(hurt_sfx)


func play_death() -> void:
	_play(death_sfx)


func play_collect() -> void:
	_play(collect_sfx)


func play_heal() -> void:
	_play(heal_sfx)


func play_crit_buff_start() -> void:
	_play(crit_buff_start_sfx)


func play_crit_buff_end() -> void:
	_play(crit_buff_end_sfx)


func _play(stream: AudioStream) -> void:
	if sfx_player == null or stream == null:
		return

	sfx_player.stream = stream
	sfx_player.play()
