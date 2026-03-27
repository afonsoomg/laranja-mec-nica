extends Node2D

const Observer = preload("res://scripts/utils/observability.gd")
const LOG_CATEGORY := "World"

@export var world_music: AudioStream
@export var world_ambient: AudioStream
@export var enemy_scene: PackedScene
@export var collectable_scene: PackedScene

@onready var level_holder: Node = $LevelHolder
@onready var player : CharacterBase = $PlayerCharacter
@onready var health_component = $PlayerCharacter/HealthComponent
@onready var enemies_holder: Node = $Enemies
@onready var collectables_holder: Node = $Collectables

signal player_died

func _ready() -> void:
	AudioManagerCustom.play_music(world_music)
	AudioManagerCustom.play_ambient(world_ambient)
	load_level("res://scenes/Levels/Lab/Lab_Scene.tscn")
		
	if health_component == null:
		Observer.log_error(LOG_CATEGORY, "Player HealthComponent not found.")
		assert(false, "[World] Critical setup failure: missing player health component.")
		return

	Observer.connect_once_safe(health_component.died, _on_player_died, "World._ready player_died")
		

func load_level(level_path: String) -> void:
	AudioManagerCustom.clear_tilemaps()
	
	for child in level_holder.get_children():
		child.queue_free()

	var packed := load(level_path) as PackedScene
	var level = packed.instantiate()
	level_holder.add_child(level)
	
	_register_tilemaps_for_audio(level)
	_setup_spawns(level)


func _setup_spawns(level: Node) -> void:
	var player_spawn := level.get_node_or_null("SpawnPoints/PlayerSpawn")
	if player_spawn:
		player.global_position = player_spawn.global_position
		DebugHelper.trace(
			"World",
			player,
			"spawn",
			{
				"source": "player_spawn_point",
				"position": player_spawn.global_position
			}
		)

	for child in enemies_holder.get_children():
		child.queue_free()

	for child in collectables_holder.get_children():
		child.queue_free()

	var enemy_spawns := level.get_node_or_null("SpawnPoints")
	if enemy_spawns == null:
		return

	for marker in enemy_spawns.get_children():
		if marker.name.begins_with("EnemySpawn"):
			var enemy = enemy_scene.instantiate()
			enemies_holder.add_child(enemy)
			enemy.global_position = marker.global_position
			DebugHelper.trace(
				"World",
				enemy,
				"spawn",
				{
					"source": "enemy_spawn_point",
					"marker": marker.name,
					"position": marker.global_position
				}
			)

		if marker.name.begins_with("CollectableSpawn"):
			var collectable = collectable_scene.instantiate()
			collectables_holder.add_child(collectable)
			collectable.global_position = marker.global_position
			DebugHelper.trace(
				"World",
				collectable,
				"spawn",
				{
					"source": "collectable_spawn_point",
					"marker": marker.name,
					"position": marker.global_position
				}
			)


func _register_tilemaps_for_audio(root: Node) -> void:
	for child in root.get_children():
		if child is TileMapLayer:
			AudioManagerCustom.add_tilemap(child)

		_register_tilemaps_for_audio(child)


func _on_player_died() -> void:
	player_died.emit()


func get_player() -> CharacterBase:
	return $PlayerCharacter
