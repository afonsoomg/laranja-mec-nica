extends Node
class_name AudioManager

@export var music_player: AudioStreamPlayer
@export var ambient_player: AudioStreamPlayer
@export var ui_player: AudioStreamPlayer


func play_music(track: AudioStream) -> void:
	if music_player == null or track == null:
		return

	if music_player.stream == track and music_player.playing:
		return

	music_player.stream = track
	music_player.play()


func stop_music() -> void:
	if music_player == null:
		return

	music_player.stop()


func play_ambient(loop_stream: AudioStream) -> void:
	if ambient_player == null or loop_stream == null:
		return

	if ambient_player.stream == loop_stream and ambient_player.playing:
		return

	ambient_player.stream = loop_stream
	ambient_player.play()


func stop_ambient() -> void:
	if ambient_player == null:
		return

	ambient_player.stop()


func play_ui(sound: AudioStream) -> void:
	if ui_player == null or sound == null:
		return

	ui_player.stream = sound
	ui_player.play()
