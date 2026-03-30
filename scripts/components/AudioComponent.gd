extends Node2D
class_name AudioComponent

@export var sfx_player: AudioStreamPlayer2D

@export_group("Sounds")
@export var attack_sfx: AudioStream
@export var hurt_sfx: AudioStream
@export var death_sfx: AudioStream
@export var footstep_sfx: Array[AudioStream] = []
@export var collect_sfx: AudioStream
@export var heal_sfx: AudioStream
@export var crit_buff_start_sfx: AudioStream
@export var crit_buff_end_sfx: AudioStream

@export_group("Playback")
@export var random_pitch_range: Vector2 = Vector2(0.98, 1.02)
@export_range(0.0, 1.0, 0.01) var footstep_volume_scale: float = 0.75

@export_group("Reactions")
@export var hurtbox_component: HurtboxComponent

func play_attack() -> void:
	_play(attack_sfx)

func _ready() -> void:
	if hurtbox_component == null:
		hurtbox_component = get_node_or_null("../HurtboxComponent") as HurtboxComponent

	if hurtbox_component != null and not hurtbox_component.hit_received.is_connected(_on_hit_received):
		hurtbox_component.hit_received.connect(_on_hit_received)


func _on_hit_received(_damage: int, _direction: Vector2, _force: float, _is_critical: bool) -> void:
	play_hurt()


func play_hurt() -> void:
	_play(hurt_sfx)


func play_death() -> void:
	_play(death_sfx)


func play_footstep() -> void:
	if footstep_sfx.is_empty():
		return

	var stream: AudioStream = footstep_sfx.pick_random()
	if stream == null:
		return

	_play(stream, footstep_volume_scale)


func play_collect() -> void:
	_play(collect_sfx)


func play_heal() -> void:
	_play(heal_sfx)


func play_crit_buff_start() -> void:
	_play(crit_buff_start_sfx)


func play_crit_buff_end() -> void:
	_play(crit_buff_end_sfx)


func _play(stream: AudioStream, volume_scale: float = 1.0) -> void:
	if sfx_player == null or stream == null:
		return

	if sfx_player.playing:
		var overlap_player := AudioStreamPlayer2D.new()
		overlap_player.bus = sfx_player.bus
		overlap_player.max_distance = sfx_player.max_distance
		overlap_player.attenuation = sfx_player.attenuation
		overlap_player.global_position = sfx_player.global_position
		add_child(overlap_player)
		_apply_playback(overlap_player, stream, volume_scale)
		overlap_player.finished.connect(overlap_player.queue_free)
		overlap_player.play()
		return

	_apply_playback(sfx_player, stream, volume_scale)
	sfx_player.play()


func _apply_playback(player: AudioStreamPlayer2D, stream: AudioStream, volume_scale: float) -> void:
	player.stream = stream
	player.pitch_scale = _get_random_pitch()
	player.volume_db = linear_to_db(max(volume_scale, 0.001))


func _get_random_pitch() -> float:
	if random_pitch_range.x > 0.0 and random_pitch_range.y > 0.0 and random_pitch_range.x <= random_pitch_range.y:
		return randf_range(random_pitch_range.x, random_pitch_range.y)
	return 1.0
