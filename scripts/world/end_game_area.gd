extends Area2D
class_name EndGameArea

signal end_requested(completion_message: String, message_duration: float, delay_before_fade: float, end_scene_path: String, fade_duration: float)

@export_group("End Flow")
@export var completion_message: String = "Você saiu do laboratório"
@export_range(0.0, 10.0, 0.1) var delay_before_fade: float = 1.2
@export_range(0.1, 5.0, 0.1) var fade_duration: float = 0.8
@export_file("*.tscn") var end_scene_path: String = "res://scenes/GUI/gameUI/end_screen.tscn"

@export_group("Validation")
@export var player_group: StringName = &"player"

@export_group("Optional Interaction")
@export var require_manual_interaction: bool = false
@export var interaction_action: StringName = &"game_attack"

var _triggered: bool = false
var _candidate_player: Node = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	add_to_group("end_game_area")
	monitoring = true
	set_process(require_manual_interaction)


func _process(_delta: float) -> void:
	if not require_manual_interaction or _triggered or _candidate_player == null:
		return

	if not Input.is_action_just_pressed(interaction_action):
		return

	_request_end_flow(_candidate_player)


func _on_body_entered(body: Node) -> void:
	if _triggered or not _is_valid_player(body):
		return

	if require_manual_interaction:
		_candidate_player = body
		return

	_request_end_flow(body)


func _on_body_exited(body: Node) -> void:
	if body == _candidate_player:
		_candidate_player = null


func _is_valid_player(body: Node) -> bool:
	if body == null:
		return false

	return body.is_in_group(player_group)


func _request_end_flow(_player: Node) -> void:
	if _triggered:
		return

	_triggered = true
	_candidate_player = null
	set_deferred("monitoring", false)
	set_process(false)
	end_requested.emit(completion_message, 2.0, delay_before_fade, end_scene_path, fade_duration)
