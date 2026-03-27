extends RefCounted
class_name ComponentValidator

static func require_node(owner: Node, path: NodePath, expected_type: String = "Node", dependency_name: String = "") -> Node:
	var resolved_name := dependency_name if dependency_name != "" else String(path)
	var resolved_path := String(path)
	var dependency := owner.get_node_or_null(path)

	if dependency == null:
		_push_dependency_error(owner, resolved_name, resolved_path, expected_type, "dependency not found")
		return null

	if expected_type != "" and not _matches_expected_type(dependency, expected_type):
		var found_type := dependency.get_class()
		_push_dependency_error(owner, resolved_name, resolved_path, expected_type, "found %s" % found_type)
		return null

	return dependency

static func require_nodes(owner: Node, requirements: Array[Dictionary]) -> bool:
	for requirement in requirements:
		var path: NodePath = requirement.get("path", NodePath(""))
		var expected_type: String = requirement.get("expected_type", "Node")
		var dependency_name: String = requirement.get("name", "")
		var target_property: StringName = requirement.get("assign_to", StringName(""))

		var dependency := require_node(owner, path, expected_type, dependency_name)
		if dependency == null:
			return false

		if target_property != StringName(""):
			owner.set(target_property, dependency)

	return true

static func _matches_expected_type(dependency: Node, expected_type: String) -> bool:
	if dependency.is_class(expected_type):
		return true

	var script: Script = dependency.get_script()
	if script != null and script.get_global_name() == expected_type:
		return true

	return false

static func _push_dependency_error(owner: Node, dependency_name: String, required_path: String, expected_type: String, detail: String) -> void:
	var scene_root := owner.get_tree().current_scene
	var scene_path := "<unknown scene>"

	if scene_root != null and scene_root.scene_file_path != "":
		scene_path = scene_root.scene_file_path

	push_error(
		"[DependencyValidation] scene=%s owner=%s dependency=%s path=%s expected=%s detail=%s" % [
			scene_path,
			owner.get_path(),
			dependency_name,
			required_path,
			expected_type,
			detail,
		]
	)
