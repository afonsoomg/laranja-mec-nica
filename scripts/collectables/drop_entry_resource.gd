extends Resource
class_name DropEntryResource

@export var scene: PackedScene
@export_range(0.0, 999.0, 0.01) var weight: float = 1.0
@export_range(1, 99, 1) var min_amount: int = 1
@export_range(1, 99, 1) var max_amount: int = 1


func get_amount(rng: RandomNumberGenerator) -> int:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	var safe_min: int = max(min_amount, 1)
	var safe_max: int = max(max_amount, safe_min)
	return rng.randi_range(safe_min, safe_max)
