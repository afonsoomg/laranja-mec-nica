extends Resource
class_name CombatTuningResource

@export_group("Stamina Costs")
@export var light_attack_stamina_cost: float = 20.0
@export var heavy_attack_stamina_cost: float = 30.0
@export var dodge_stamina_cost: float = 30.0
@export var run_stamina_cost_per_second: float = 18.0

@export_group("Heavy Attack")
@export var heavy_hold_threshold: float = 0.2
@export var heavy_max_charge_time: float = 1.0
@export var heavy_min_damage_multiplier: float = 1.35
@export var heavy_max_damage_multiplier: float = 2.2
@export var heavy_min_knockback_multiplier: float = 1.1
@export var heavy_max_knockback_multiplier: float = 1.8
@export var heavy_hitbox_duration: float = 0.18
@export var heavy_recovery_duration: float = 0.35
@export var heavy_lunge_speed: float = 120.0
@export var heavy_lunge_duration: float = 0.08
