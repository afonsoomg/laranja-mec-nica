extends Node2D

const Observer = preload("res://scripts/utils/observability.gd")
const Spawn = preload("res://scripts/world/spawn_point.gd")
const LOG_CATEGORY := "World"

@export var world_music: AudioStream
@export var world_ambient: AudioStream
@export var enemy_scene: PackedScene
@export var collectable_scene: PackedScene
@export var breakable_scene: PackedScene

@onready var level_holder: Node = $LevelHolder
@onready var player : CharacterBase = $PlayerCharacter
@onready var health_component = $PlayerCharacter/HealthComponent
@onready var enemies_holder: Node = $Enemies
@onready var collectables_holder: Node = $Collectables
@onready var breakables_holder: Node = $Breakables

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
	_clear_holder(enemies_holder)
	_clear_holder(collectables_holder)
	_clear_holder(breakables_holder)

	var spawn_root := level.get_node_or_null("SpawnPoints")
	if spawn_root == null:
		return

	var player_spawns: Array[Spawn] = []
	for marker in spawn_root.get_children():
		if marker is Spawn:
			var spawn_point := marker as Spawn
			if not spawn_point.auto_spawn:
				continue

			if spawn_point.spawn_type == Spawn.SpawnType.PLAYER:
				player_spawns.append(spawn_point)
				continue

			var resolved_scene := _resolve_scene_for_spawn_type(spawn_point)
			if resolved_scene == null:
				push_warning("SpawnPoint '%s' has no configured scene for type %s." % [spawn_point.name, spawn_point.get_spawn_type_name()])
				continue

			spawn_point.spawn_scene = resolved_scene
			if not spawn_point.validate_configuration("World._setup_spawns"):
				continue

			var holder := _get_holder_for_spawn_type(spawn_point.spawn_type)
			var spawned := spawn_point.spawn_into(holder)
			if spawned != null:
				DebugHelper.trace(
					"World",
					spawned,
					"spawn",
					{
						"source": "spawn_point",
						"spawn_type": spawn_point.get_spawn_type_name(),
						"spawn_point": spawn_point.name,
						"position": spawn_point.global_position,
						"spawn_id": str(spawn_point.spawn_id)
					}
				)
			continue

		_setup_legacy_spawn(marker)

	_apply_player_spawn(player_spawns, spawn_root)


func _apply_player_spawn(player_spawns: Array[Spawn], spawn_root: Node) -> void:
	if player_spawns.size() > 0:
		if player_spawns.size() > 1:
			push_warning("Multiple player SpawnPoints found (%d). Using lowest spawn_priority then scene order." % player_spawns.size())
		player_spawns.sort_custom(func(a: Spawn, b: Spawn) -> bool:
			if a.spawn_priority == b.spawn_priority:
				return a.get_index() < b.get_index()
			return a.spawn_priority < b.spawn_priority
		)

		var selected_spawn := player_spawns[0]
		player.global_position = selected_spawn.global_position
		DebugHelper.trace(
			"World",
			player,
			"spawn",
			{
				"source": "player_spawn_point",
				"spawn_point": selected_spawn.name,
				"priority": selected_spawn.spawn_priority,
				"position": selected_spawn.global_position
			}
		)
		return

	var legacy_spawn := spawn_root.get_node_or_null("PlayerSpawn")
	if legacy_spawn != null and legacy_spawn is Node2D:
		player.global_position = (legacy_spawn as Node2D).global_position


func _setup_legacy_spawn(marker: Node) -> void:
	if marker.name.begins_with("EnemySpawn"):
		_spawn_legacy_scene(enemy_scene, enemies_holder, marker, "enemy_spawn_point")

	if marker.name.begins_with("CollectableSpawn"):
		_spawn_legacy_scene(collectable_scene, collectables_holder, marker, "collectable_spawn_point")


func _spawn_legacy_scene(scene: PackedScene, holder: Node, marker: Node, source: String) -> void:
	if scene == null or holder == null:
		return
		
	if not (marker is Node2D):
		return

	var instance := scene.instantiate()
	holder.add_child(instance)

	if instance is Node2D:
		(instance as Node2D).global_position = (marker as Node2D).global_position

	DebugHelper.trace(
		"World",
		instance,
		"spawn",
		{
			"source": source,
			"marker": marker.name,
			"position": (marker as Node2D).global_position
		}
	)


func _resolve_scene_for_spawn_type(spawn_point: Spawn) -> PackedScene:
	if spawn_point.spawn_scene != null:
		return spawn_point.spawn_scene

	match spawn_point.spawn_type:
		Spawn.SpawnType.COLLECTABLE:
			return collectable_scene
		Spawn.SpawnType.ENEMY:
			return enemy_scene
		Spawn.SpawnType.BREAKABLE:
			return breakable_scene
		_:
			return null


func _get_holder_for_spawn_type(spawn_type: int) -> Node:
	match spawn_type:
		Spawn.SpawnType.COLLECTABLE:
			return collectables_holder
		Spawn.SpawnType.BREAKABLE:
			return breakables_holder
		Spawn.SpawnType.ENEMY:
			return enemies_holder
		_:
			return null


func _clear_holder(holder: Node) -> void:
	if holder == null:
		return

	for child in holder.get_children():
		child.queue_free()


func _register_tilemaps_for_audio(root: Node) -> void:
	for child in root.get_children():
		if child is TileMapLayer:
			AudioManagerCustom.add_tilemap(child)

		_register_tilemaps_for_audio(child)


func _on_player_died() -> void:
	player_died.emit()


func get_player() -> CharacterBase:
	return $PlayerCharacter
