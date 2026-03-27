extends Node
class_name AudioManager

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var ambient_player: AudioStreamPlayer = $AmbientPlayer
@onready var ui_root: Node = $UIRoot

var tilemaps: Array[TileMapLayer] = []

const footstep_sounds = {
	"c": [
		preload("res://assets/audio/sfx/footsteps/08_Step_rock_02.wav"),
		#preload("res://assets/audio/sfx/footsteps/12_Step_wood_03.wav"),
		#preload("res://assets/audio/sfx/footsteps/03_Step_grass_03.wav")
	]
}

func _ready() -> void:
	if music_player:
		music_player.bus = "Música"
	if ambient_player:
		ambient_player.bus = "Ambiente"


func play_footstep(position: Vector2):
	var tile_data = []
	for tilemap in tilemaps:
		var tile_position = tilemap.local_to_map(position)
		var data = tilemap.get_cell_tile_data(tile_position)
		if data:
			tile_data.push_back(data)
			
	if tile_data.size() > 0:
		var tile_type = tile_data.back().get_custom_data("footsteps_sound")
		
		if footstep_sounds.has(tile_type):
			var audio_player = AudioStreamPlayer2D.new()
			audio_player.stream = footstep_sounds[tile_type].pick_random()
			get_tree().root.add_child(audio_player)
			audio_player.global_position = position
			audio_player.play()
			await audio_player.finished
			audio_player.queue_free()


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
	if ui_root == null or sound == null:
		return

	var player := AudioStreamPlayer.new()
	ui_root.add_child(player)

	player.bus = "UI"
	player.stream = sound
	player.finished.connect(player.queue_free)
	player.play()
