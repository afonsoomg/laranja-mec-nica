extends Node

const Observer = preload("res://scripts/utils/observability.gd")
const LOG_CATEGORY := "GameInstance"


@export var main_menu_scene: PackedScene
@export var world_scene: PackedScene
@export var game_over_scene: PackedScene
@export var player_hud_scene: PackedScene
@export var default_end_screen_scene: PackedScene

@export_group("End Flow")
@export_range(0.1, 5.0, 0.1) var default_fade_duration: float = 0.8
@export_range(0.1, 10.0, 0.1) var default_message_duration: float = 1.2
@export_range(0.0, 10.0, 0.1) var default_end_delay: float = 1.2

@onready var current_scene_holder: Node = $CurrentScene
@onready var ui_root: CanvasLayer = $UIRoot

var current_scene: Node = null
var current_hud: PlayerHUD = null
var fade_overlay: ColorRect = null
var _flow_state: StringName = &"idle"

func _ready() -> void:
	_ensure_fade_overlay()
	load_main_menu()

func _clear_current_scene() -> void:
	if current_scene:
		current_scene.queue_free()
		current_scene = null

func _clear_current_hud() -> void:
	if current_hud:
		current_hud.queue_free()
		current_hud = null

func _set_scene(scene_resource: PackedScene) -> Node:
	assert(current_scene_holder != null, "[GameInstance] CurrentScene node is required.")
	if scene_resource == null:
		Observer.log_error(LOG_CATEGORY, "Cannot set scene: PackedScene is null.")
		assert(false, "[GameInstance] Critical setup failure: scene_resource is null.")
		return null
		
	_clear_current_scene()
	current_scene = scene_resource.instantiate()
	
	if current_scene == null:
		Observer.log_error(LOG_CATEGORY, "Failed to instantiate scene resource.")
		assert(false, "[GameInstance] Critical setup failure: scene instantiate failed.")
		return null
	
	current_scene_holder.add_child(current_scene)
	return current_scene

func _set_hud(scene_resource: PackedScene, player: CharacterBase) -> PlayerHUD:
	assert(ui_root != null, "[GameInstance] UIRoot node is required.")
	if scene_resource == null:
		Observer.log_error(LOG_CATEGORY, "Cannot set HUD: PackedScene is null.")
		assert(false, "[GameInstance] Critical setup failure: HUD scene is null.")
		return null

	if player == null:
		Observer.log_error(LOG_CATEGORY, "Cannot setup HUD: player is null.")
		assert(false, "[GameInstance] Critical setup failure: HUD player is null.")
		return null
	
	_clear_current_hud()
	current_hud = scene_resource.instantiate() as PlayerHUD
	if current_hud == null:
		Observer.log_error(LOG_CATEGORY, "Failed to instantiate PlayerHUD scene.")
		assert(false, "[GameInstance] Critical setup failure: PlayerHUD instantiate failed.")
		return null
	
	ui_root.add_child(current_hud)
	
	current_hud.call_deferred("setup", player)

	Observer.connect_once_safe(current_hud.exit_requested, _on_hud_exit_requested, "GameInstance._set_hud exit_requested")
	Observer.connect_once_safe(current_hud.back_to_menu_requested, _on_hud_back_to_menu_requested, "GameInstance._set_hud back_to_menu_requested")
		
	return current_hud


func load_main_menu() -> void:
	_flow_state = &"idle"
	get_tree().paused = false
	_clear_current_hud()
	_reset_fade_overlay()

	var menu := _set_scene(main_menu_scene)
	if menu == null:
		Observer.log_error(LOG_CATEGORY, "Main menu scene failed to load.")
		return
		
	if menu.has_signal("start_game"):
		Observer.connect_once_safe(menu.start_game, _on_start_game, "GameInstance.load_main_menu start_game")
	else:
		Observer.log_warning(LOG_CATEGORY, "Main menu scene is missing start_game signal.")


func load_world() -> void:
	_flow_state = &"running"
	get_tree().paused = false
	_reset_fade_overlay()
	
	var world := _set_scene(world_scene)
	if world == null:
		Observer.log_error(LOG_CATEGORY, "World scene failed to load.")
		assert(false, "[GameInstance] Critical setup failure: world scene failed.")
		return

	if not world.has_method("get_player"):
		Observer.log_error(LOG_CATEGORY, "World scene is missing get_player().")
		assert(false, "[GameInstance] Critical setup failure: get_player() missing.")
		return

	var player := world.get_player() as CharacterBase
	Observer.log_debug(LOG_CATEGORY, "World instantiated: %s" % world)
	Observer.log_debug(LOG_CATEGORY, "World player resolved: %s" % player)
	
	if world.has_signal("player_died"):
		Observer.connect_once_safe(world.player_died, _on_player_died, "GameInstance.load_world player_died")
	else:
		Observer.log_warning(LOG_CATEGORY, "World scene is missing player_died signal.")

	if world.has_signal("level_completed"):
		Observer.connect_once_safe(world.level_completed, _on_level_completed, "GameInstance.load_world level_completed")
	else:
		Observer.log_warning(LOG_CATEGORY, "World scene is missing level_completed signal.")

	_set_hud(player_hud_scene, player)


func load_game_over() -> void:
	_flow_state = &"idle"
	get_tree().paused = false
	_clear_current_hud()
	_reset_fade_overlay()
	
	var game_over := _set_scene(game_over_scene)
	if game_over == null:
		Observer.log_error(LOG_CATEGORY, "Game over scene failed to load.")
		return
		
	if game_over.has_signal("retry"):
		Observer.connect_once_safe(game_over.retry, _on_retry, "GameInstance.load_game_over retry")
	else:
		Observer.log_warning(LOG_CATEGORY, "Game over scene is missing retry signal.")
	
	if game_over.has_signal("back_to_menu"):
		Observer.connect_once_safe(game_over.back_to_menu, load_main_menu, "GameInstance.load_game_over back_to_menu")
	else:
		Observer.log_warning(LOG_CATEGORY, "Game over scene is missing back_to_menu signal.")


func load_end_screen(scene_override: PackedScene = null) -> void:
	_flow_state = &"idle"
	get_tree().paused = false
	_clear_current_hud()
	_reset_fade_overlay()

	var target_scene := scene_override if scene_override != null else default_end_screen_scene
	if target_scene == null:
		Observer.log_warning(LOG_CATEGORY, "End screen scene is null; falling back to main menu.")
		load_main_menu()
		return

	var end_screen := _set_scene(target_scene)
	if end_screen == null:
		Observer.log_error(LOG_CATEGORY, "End screen failed to load.")
		load_main_menu()
		return

	if end_screen.has_signal("retry"):
		Observer.connect_once_safe(end_screen.retry, _on_retry, "GameInstance.load_end_screen retry")
	if end_screen.has_signal("back_to_menu"):
		Observer.connect_once_safe(end_screen.back_to_menu, load_main_menu, "GameInstance.load_end_screen back_to_menu")


func _ensure_fade_overlay() -> void:
	if fade_overlay != null:
		return

	fade_overlay = ColorRect.new()
	fade_overlay.name = "FadeOverlay"
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.color = Color(0, 0, 0, 0)
	fade_overlay.visible = false
	ui_root.add_child(fade_overlay)


func _reset_fade_overlay() -> void:
	if fade_overlay == null:
		return
	fade_overlay.visible = false
	fade_overlay.color = Color(0, 0, 0, 0)


func _resolve_end_scene(scene_path: String) -> PackedScene:
	if scene_path.is_empty():
		return default_end_screen_scene

	var loaded := load(scene_path)
	if loaded is PackedScene:
		return loaded as PackedScene

	Observer.log_warning(LOG_CATEGORY, "Invalid end screen path '%s'. Using default end screen scene." % scene_path)
	return default_end_screen_scene


func _lock_player_control() -> void:
	if current_scene == null or not current_scene.has_method("get_player"):
		return

	var player: CharacterBase = current_scene.get_player()
	if player != null and player.has_method("set_controls_locked"):
		player.set_controls_locked(true)


func _play_fade_out(duration: float) -> void:
	if fade_overlay == null:
		return

	fade_overlay.visible = true
	fade_overlay.color = Color(0, 0, 0, 0)
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, max(duration, 0.01))
	await tween.finished


func _on_start_game() -> void:
	load_world()


func _on_player_died() -> void:
	if _flow_state != &"running":
		return

	_flow_state = &"game_over"
	await get_tree().create_timer(2).timeout
	if _flow_state == &"game_over":
		load_game_over()


func _on_level_completed(completion_message: String, message_duration: float, delay_before_fade: float, end_scene_path: String, fade_duration: float) -> void:
	if _flow_state != &"running":
		return

	_flow_state = &"ending"
	_lock_player_control()
	var resolved_message := completion_message if not completion_message.is_empty() else "You escaped."
	var resolved_message_duration := message_duration if message_duration > 0.0 else default_message_duration
	var resolved_delay := delay_before_fade if delay_before_fade >= 0.0 else default_end_delay
	var resolved_fade_duration := fade_duration if fade_duration > 0.0 else default_fade_duration

	if current_hud != null:
		current_hud.show_completion_message(resolved_message, resolved_message_duration)

	await get_tree().create_timer(resolved_delay).timeout
	await _play_fade_out(resolved_fade_duration)
	load_end_screen(_resolve_end_scene(end_scene_path))


func _on_retry() -> void:
	load_world()


func _on_hud_exit_requested() -> void:
	Observer.log_info(LOG_CATEGORY, "Received exit request from HUD.")
	load_main_menu()


func _on_hud_back_to_menu_requested() -> void:
	Observer.log_info(LOG_CATEGORY, "Received back_to_menu request from HUD.")
	load_main_menu()
