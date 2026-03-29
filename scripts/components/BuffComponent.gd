extends Node
class_name BuffComponent

const Observer = preload("res://scripts/utils/observability.gd")
const LOG_CATEGORY := "BuffComponent"

@onready var stats_component: StatsComponent = $"../StatsComponent"
@onready var audio_component: AudioComponent = get_node_or_null("../AudioComponent") as AudioComponent
@onready var vfx_component: VfxComponent = get_node_or_null("../VfxComponent") as VfxComponent
@onready var animated_sprite_2d: AnimatedSprite2D = $"../AnimatedSprite2D"


var _crit_buff_active: bool = false
var _crit_buff_bonus: float = 0.0
var _crit_buff_token: int = 0
var _crit_modifier_id: StringName = &""


func apply_crit_buff(bonus: float, duration: float) -> bool:	
	if stats_component == null:
		Observer.log_error(LOG_CATEGORY, "Cannot apply crit buff without StatsComponent.")
		assert(false, "[BuffComponent] Critical setup failure: missing StatsComponent.")
		return false

	if bonus <= 0.0 or duration <= 0.0:
		return false

	# Se já existir buff, remove o anterior antes de reaplicar
	if _crit_buff_active:
		_remove_crit_modifier()
		
	_crit_buff_active = true
	_crit_buff_bonus = bonus
	_crit_buff_token += 1
	_crit_modifier_id = StringName("crit_buff_%d" % _crit_buff_token)

	var current_token := _crit_buff_token

	stats_component.add_modifier(&"crit_chance", _crit_modifier_id, bonus)
	Observer.log_info(LOG_CATEGORY, "Crit buff applied. Current crit chance=%.3f" % stats_component.get_crit_chance())
	
	if audio_component:
		audio_component.play_collect()
		audio_component.play_crit_buff_start()
	
	_remove_crit_buff_later(current_token, duration)
	return true


func _remove_crit_buff_later(token: int, duration: float) -> void:
	await get_tree().create_timer(duration).timeout

	if not is_inside_tree():
		return

	# Só remove se esse timer ainda for o buff válido atual
	if token != _crit_buff_token:
		return

	if not _crit_buff_active or stats_component == null:
		return

	_remove_crit_modifier()
	
	Observer.log_info(LOG_CATEGORY, "Crit buff ended. Current crit chance=%.3f" % stats_component.get_crit_chance())
	
	if audio_component:
		audio_component.play_crit_buff_end()
		
	_crit_buff_active = false
	_crit_buff_bonus = 0.0
	_crit_modifier_id = &""


func _remove_crit_modifier() -> void:
	if stats_component == null:
		return

	if _crit_modifier_id == StringName(""):
		return

	stats_component.remove_modifier(&"crit_chance", _crit_modifier_id)
