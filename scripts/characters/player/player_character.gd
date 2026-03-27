extends CharacterBase

@onready var input_component: InputComponent = $InputComponent
@onready var weapon_component: WeaponComponent = $WeaponComponent

func _ready() -> void:
	super._ready()
	if weapon_component != null and audio_component != null:
		if not weapon_component.attack_started.is_connected(_on_attack_started):
			weapon_component.attack_started.connect(_on_attack_started)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	var move_vector := input_component.get_input_vector()
	var run_pressed := input_component.is_run_pressed()

	move_component.set_move_input(move_vector)
	move_component.set_running(run_pressed)
	move_component.update_velocity(delta)

	if input_component.is_attack_just_pressed():
		weapon_component.try_attack()

	if animation_component:
		animation_component.update_animation()

	super._physics_process(delta)
	
	
func collect_collectable(collectable: CollectableBase) -> void:
	if collectable == null:
		return

	var collected_successfully := collectable.apply_to_collector(self)

	if collected_successfully:
		collectable.on_collected(self)
		
		
func _on_attack_started() -> void:
	if audio_component:
		audio_component.play_attack()
		
