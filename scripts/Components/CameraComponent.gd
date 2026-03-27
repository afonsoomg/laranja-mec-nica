class_name CameraComponent
extends Camera2D

@export var target: Node2D
var move_component: MoveComponent
var weapon_component: WeaponComponent
var hurtbox_component: HurtboxComponent

@export_group("Follow")
@export var follow_enabled: bool = true
@export var follow_smoothing: float = 8.0

@export_group("Look Ahead")
@export var look_ahead_enabled: bool = true
@export var look_ahead_distance: float = 24.0
@export var look_ahead_smoothing: float = 10.0

@export_group("Shake")
@export var shake_decay: float = 18.0
@export var shake_max_offset: Vector2 = Vector2(6.0, 6.0)

@export_group("Combat Feedback")
@export var shake_on_attack: float = 0.12
@export var shake_on_hit_target: float = 0.3
@export var shake_on_receive_hit: float = 0.45

@export_group("Zoom")
@export var zoom_enabled: bool = true
@export var normal_zoom: Vector2 = Vector2(1.0, 1.0)
@export var run_zoom: Vector2 = Vector2(0.94, 0.94)
@export var zoom_smoothing: float = 6.0

var look_ahead_offset: Vector2 = Vector2.ZERO
var shake_strength: float = 0.0
var base_offset: Vector2 = Vector2.ZERO
var target_zoom_value: Vector2 = Vector2.ONE


func _ready() -> void:
	if target == null:
		push_error("CameraComponent precisa de um target.")
		set_process(false)
		return
		
	move_component = ComponentValidator.require_node(self, NodePath("../MoveComponent"), "MoveComponent", "MoveComponent") as MoveComponent
	if move_component == null:
		set_process(false)
		return

	weapon_component = get_node_or_null("../WeaponComponent") as WeaponComponent
	hurtbox_component = get_node_or_null("../HurtboxComponent") as HurtboxComponent

	base_offset = offset
	target_zoom_value = run_zoom if move_component.is_running else normal_zoom
	zoom = target_zoom_value

	make_current()
	_connect_signals()


func _process(delta: float) -> void:
	if target == null:
		return

	if follow_enabled:
		var desired_position := target.global_position
		global_position = global_position.lerp(desired_position, follow_smoothing * delta)

	_update_look_ahead(delta)
	_update_shake(delta)
	_update_zoom(delta)

	offset = base_offset + look_ahead_offset + _get_shake_offset()


func _connect_signals() -> void:
	if weapon_component != null:
		if not weapon_component.attack_started.is_connected(_on_attack_started):
			weapon_component.attack_started.connect(_on_attack_started)

		if not weapon_component.target_hit.is_connected(_on_target_hit):
			weapon_component.target_hit.connect(_on_target_hit)

	if hurtbox_component != null:
		if not hurtbox_component.hit_received.is_connected(_on_hit_received):
			hurtbox_component.hit_received.connect(_on_hit_received)

	if move_component != null:
		if not move_component.run_state_changed.is_connected(_on_run_state_changed):
			move_component.run_state_changed.connect(_on_run_state_changed)


func _update_look_ahead(delta: float) -> void:
	if not look_ahead_enabled or move_component == null:
		look_ahead_offset = look_ahead_offset.lerp(Vector2.ZERO, look_ahead_smoothing * delta)
		return

	var desired_offset := Vector2.ZERO
	var input_vector := move_component.get_move_input()

	if input_vector != Vector2.ZERO:
		desired_offset = input_vector.normalized() * look_ahead_distance

	look_ahead_offset = look_ahead_offset.lerp(desired_offset, look_ahead_smoothing * delta)


func _update_shake(delta: float) -> void:
	shake_strength = max(shake_strength - shake_decay * delta, 0.0)


func _update_zoom(delta: float) -> void:
	if not zoom_enabled:
		target_zoom_value = normal_zoom
		zoom = zoom.lerp(normal_zoom, zoom_smoothing * delta)
		return

	zoom = zoom.lerp(target_zoom_value, zoom_smoothing * delta)


func add_shake(amount: float) -> void:
	shake_strength = max(shake_strength, amount)


func snap_to_target() -> void:
	if target != null:
		global_position = target.global_position


func _get_shake_offset() -> Vector2:
	if shake_strength <= 0.0:
		return Vector2.ZERO

	return Vector2(
		randf_range(-shake_max_offset.x, shake_max_offset.x),
		randf_range(-shake_max_offset.y, shake_max_offset.y)
	) * shake_strength


func _on_attack_started(_direction: Vector2) -> void:
	add_shake(shake_on_attack)


func _on_target_hit(_target_hit: Node, _damage: int) -> void:
	add_shake(shake_on_hit_target)


func _on_hit_received(_damage: int, _direction: Vector2, _force: float, _is_critical: bool) -> void:
	add_shake(shake_on_receive_hit)


func _on_run_state_changed(is_running: bool) -> void:
	target_zoom_value = run_zoom if is_running else normal_zoom
