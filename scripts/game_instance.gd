extends Node

const Observer = preload("res://scripts/utils/observability.gd")
const LOG_CATEGORY := "GameInstance"

@export var main_menu_scene: PackedScene
@export var world_scene: PackedScene
@export var game_over_scene: PackedScene
@export var player_hud_scene: PackedScene

@onready var current_scene_holder: Node = $CurrentScene
@onready var ui_root: CanvasLayer = $UIRoot

var current_scene: Node = null
var current_hud: PlayerHUD = null

func _ready() -> void:
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
	get_tree().paused = false
	_clear_current_hud()

	var menu := _set_scene(main_menu_scene)
	if menu == null:
		Observer.log_error(LOG_CATEGORY, "Main menu scene failed to load.")
		return
		
	if menu.has_signal("start_game"):
		Observer.connect_once_safe(menu.start_game, _on_start_game, "GameInstance.load_main_menu start_game")
	else:
		Observer.log_warning(LOG_CATEGORY, "Main menu scene is missing start_game signal.")

func load_world() -> void:
	get_tree().paused = false

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

	_set_hud(player_hud_scene, player)

func load_game_over() -> void:
	get_tree().paused = false
	_clear_current_hud()

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

func _on_start_game() -> void:
	load_world()

func _on_player_died() -> void:
	await get_tree().create_timer(2).timeout
	load_game_over()

func _on_retry() -> void:
	load_world()

func _on_hud_exit_requested() -> void:
	Observer.log_info(LOG_CATEGORY, "Received exit request from HUD.")
	load_main_menu()

func _on_hud_back_to_menu_requested() -> void:
	Observer.log_info(LOG_CATEGORY, "Received back_to_menu request from HUD.")
	load_main_menu()
