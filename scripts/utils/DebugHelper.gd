extends Node
class_name DebugEventBus

const CLI_ENABLE_FLAG := "--trace-events"
const CLI_DISABLE_FLAG := "--no-trace-events"


var enabled: bool = false


func _ready() -> void:
	enabled = OS.is_debug_build()

	for arg in OS.get_cmdline_args():
		if arg == CLI_ENABLE_FLAG:
			enabled = true
		elif arg == CLI_DISABLE_FLAG:
			enabled = false


func set_enabled(value: bool) -> void:
	enabled = value


func trace(system_name: String, entity: Node, event_name: String, payload: Dictionary = {}) -> void:
	if not enabled:
		return

	var entity_name := _resolve_entity_name(entity)
	var serialized_payload := JSON.stringify(payload)
	print("[%s][%s][%s] %s" % [system_name, entity_name, event_name, serialized_payload])


func _resolve_entity_name(entity: Node) -> String:
	if entity == null:
		return "Unknown"

	if "name" in entity:
		return String(entity.name)

	return entity.get_class()
