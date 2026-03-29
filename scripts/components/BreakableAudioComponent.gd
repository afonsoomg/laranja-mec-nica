extends Node2D
class_name BreakableAudioComponent

@export var sfx_player: AudioStreamPlayer2D
@export var breakable: Breakable

@export_group("Sounds")
@export var hit_sfx: AudioStream
@export var break_sfx: AudioStream

@export_group("Behavior")
@export_range(0.0, 1.0, 0.01) var min_hit_interval_sec: float = 0.03
@export var random_pitch_range: Vector2 = Vector2(0.98, 1.02)

var _has_played_break_sfx: bool = false
var _last_hit_sfx_time_sec: float = -9999.0


func _ready() -> void:
	if breakable == null:
		breakable = get_parent() as Breakable

	if breakable == null:
		return

	if not breakable.damaged.is_connected(_on_breakable_damaged):
		breakable.damaged.connect(_on_breakable_damaged)

	if not breakable.broken.is_connected(_on_breakable_broken):
		breakable.broken.connect(_on_breakable_broken)


func _on_breakable_damaged(_damage: int, _direction: Vector2, _force: float, _is_critical: bool) -> void:
	if _has_played_break_sfx:
		return

	var now_sec := Time.get_ticks_msec() / 1000.0
	if now_sec - _last_hit_sfx_time_sec < min_hit_interval_sec:
		return

	_last_hit_sfx_time_sec = now_sec
	_play(hit_sfx)


func _on_breakable_broken(_reason: String) -> void:
	if _has_played_break_sfx:
		return

	_has_played_break_sfx = true
	_play(break_sfx)


func _play(stream: AudioStream) -> void:
	if sfx_player == null or stream == null:
		return

	if random_pitch_range.x > 0.0 and random_pitch_range.y > 0.0 and random_pitch_range.x <= random_pitch_range.y:
		sfx_player.pitch_scale = randf_range(random_pitch_range.x, random_pitch_range.y)
	else:
		sfx_player.pitch_scale = 1.0

	sfx_player.stream = stream
	sfx_player.play()
