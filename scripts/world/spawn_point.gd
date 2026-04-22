@tool
extends Marker2D
class_name SpawnPoint

enum SpawnType {
	COLLECTABLE,
	BREAKABLE,
	ENEMY,
	PLAYER,
}

const TYPE_COLORS := {
	SpawnType.COLLECTABLE: Color(0.2, 0.8, 1.0, 0.95),
	SpawnType.BREAKABLE: Color(1.0, 0.7, 0.2, 0.95),
	SpawnType.ENEMY: Color(1.0, 0.2, 0.3, 0.95),
	SpawnType.PLAYER: Color(0.3, 1.0, 0.4, 0.95),
}

@export var spawn_type: SpawnType = SpawnType.ENEMY:
	set(value):
		spawn_type = value
		_queue_editor_refresh()
@export var spawn_scene: PackedScene:
	set(value):
		spawn_scene = value
		_queue_editor_refresh()
@export var spawn_id: StringName:
	set(value):
		spawn_id = value
		_queue_editor_refresh()
@export var auto_spawn: bool = true:
	set(value):
		auto_spawn = value
		_queue_editor_refresh()
@export var spawn_priority: int = 0
@export_range(6.0, 96.0, 1.0) var marker_radius: float = 28.0:
	set(value):
		marker_radius = value
		_queue_editor_refresh()


func _ready() -> void:
	_queue_editor_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		_queue_editor_refresh()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	var color = TYPE_COLORS.get(spawn_type, Color.WHITE)
	var fill_color = color
	fill_color.a = 0.22 if auto_spawn else 0.08
	var ring_color = color
	ring_color.a = 1.0 if auto_spawn else 0.35

	draw_circle(Vector2.ZERO, marker_radius, fill_color)
	draw_arc(Vector2.ZERO, marker_radius, 0.0, TAU, 48, ring_color, 2.5)
	draw_line(Vector2(-marker_radius, 0), Vector2(marker_radius, 0), ring_color, 1.4)
	draw_line(Vector2(0, -marker_radius), Vector2(0, marker_radius), ring_color, 1.4)

	var label_text := "%s%s" % [get_spawn_type_name(), " (OFF)" if not auto_spawn else ""]
	if not String(spawn_id).is_empty():
		label_text += "\n#%s" % String(spawn_id)

	var font := ThemeDB.fallback_font
	if font != null:
		draw_string(font, Vector2(marker_radius + 6.0, -4.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, ring_color)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if auto_spawn and requires_scene() and spawn_scene == null:
		warnings.append("spawn_scene is required for this spawn_type when auto_spawn is enabled.")
	if name.strip_edges().is_empty():
		warnings.append("SpawnPoint should have a descriptive node name (e.g. Enemy_Raiz_01).")
	return warnings


func _queue_editor_refresh() -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		notify_property_list_changed()
		update_configuration_warnings()


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
