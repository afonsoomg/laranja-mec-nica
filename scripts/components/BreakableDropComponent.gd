extends Node
class_name BreakableDropComponent

@export var breakable: Breakable
@export var drop_table: DropTableResource
@export var spawn_parent_path: NodePath
@export_range(0.0, 64.0, 0.5) var scatter_radius: float = 6.0

var _did_spawn: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()

	if breakable == null:
		breakable = get_parent() as Breakable

	if breakable == null:
		return

	if not breakable.broken.is_connected(_on_breakable_broken):
		breakable.broken.connect(_on_breakable_broken)


func _on_breakable_broken(_reason: String) -> void:
	if _did_spawn:
		return

	_did_spawn = true

	if drop_table == null:
		return

	var scenes := drop_table.roll_drop_scenes(_rng)
	if scenes.is_empty():
		return

	var spawn_parent := _resolve_spawn_parent()
	if spawn_parent == null:
		spawn_parent = breakable.get_parent()

	if spawn_parent == null:
		return

	for drop_scene in scenes:
		call_deferred("_spawn_drop", drop_scene, spawn_parent)


func _resolve_spawn_parent() -> Node:
	if spawn_parent_path != NodePath():
		var explicit_parent := get_node_or_null(spawn_parent_path)
		if explicit_parent != null:
			return explicit_parent

	var current: Node = breakable
	while current != null:
		if current.has_node("Collectables"):
			var collectables := current.get_node_or_null("Collectables")
			if collectables != null:
				return collectables
		current = current.get_parent()

	return null


func _spawn_drop(drop_scene: PackedScene, spawn_parent: Node) -> void:
	if drop_scene == null or spawn_parent == null:
		return

	var instance := drop_scene.instantiate()
	spawn_parent.add_child(instance)
	instance.global_position = owner.global_position

	if instance is Node2D and breakable != null:
		var offset := Vector2.ZERO
		if scatter_radius > 0.0:
			offset = Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU)) * _rng.randf_range(0.0, scatter_radius)
		(instance as Node2D).global_position = breakable.global_position + offset
