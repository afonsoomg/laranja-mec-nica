extends Control
class_name PlayerHUD

@export var player: Node
@onready var health_bar: ProgressBar = $HealthProgressBar

var health_component: HealthComponent


func _ready() -> void:
	if player == null:
		push_error("PlayerHUD precisa de uma referência ao Player.")
		return

	health_component = player.get_node_or_null("HealthComponent") as HealthComponent

	if health_component == null:
		push_error("PlayerHUD não encontrou HealthComponent no Player.")
		return

	if not health_component.health_changed.is_connected(_on_health_changed):
		health_component.health_changed.connect(_on_health_changed)

	_on_health_changed(health_component.current_health, health_component.max_health)


func _on_health_changed(current_health: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health
