extends Marker2D
class_name SpawnPoint

enum SpawnType {
	COLLECTABLE,
	BREAKABLE,
	ENEMY,
	PLAYER,
}

@export var spawn_type: SpawnType = SpawnType.ENEMY
@export var spawn_scene: PackedScene
@export var spawn_id: StringName
@export var auto_spawn: bool = true
@export var spawn_priority: int = 0


func requires_scene() -> bool:
	return spawn_type != SpawnType.PLAYER


func validate_configuration(context: String = "") -> bool:
	if not auto_spawn:
		return true

	if requires_scene() and spawn_scene == null:
		var from_context := ""
		if not context.is_empty():
			from_context = " (%s)" % context
		push_warning("SpawnPoint '%s' requires spawn_scene for type %s%s." % [name, get_spawn_type_name(), from_context])
		return false

	return true


func get_spawn_type_name() -> String:
	return SpawnType.keys()[spawn_type]


func spawn_into(parent: Node) -> Node:
	if parent == null:
		push_warning("SpawnPoint '%s' cannot spawn without a parent node." % name)
		return null

	if not auto_spawn:
		return null

	if requires_scene() and spawn_scene == null:
		push_warning("SpawnPoint '%s' skipped: spawn_scene is not configured." % name)
		return null

	if spawn_scene == null:
		return null

	var spawned := spawn_scene.instantiate()
	parent.add_child(spawned)

	if spawned is Node2D:
		var node_2d := spawned as Node2D
		node_2d.global_position = global_position
		node_2d.global_rotation = global_rotation

	return spawned
