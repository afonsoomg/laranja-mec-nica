extends Node2D

@export var world_music: AudioStream
@export var world_ambient: AudioStream
@onready var health_component = get_node("/root/World/Player/HealthComponent")


func _ready() -> void:
	AudioManagerCustom.play_music(world_music)
	AudioManagerCustom.play_ambient(world_ambient)
	
