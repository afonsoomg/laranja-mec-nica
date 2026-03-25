extends Node2D

@export var world_music: AudioStream
@export var world_ambient: AudioStream

func _ready() -> void:
	AudioManagerCustom.play_music(world_music)
	AudioManagerCustom.play_ambient(world_ambient)
