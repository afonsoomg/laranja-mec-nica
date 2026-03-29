extends Resource
class_name DropTableResource

@export var guaranteed_drops: Array[DropEntryResource] = []
@export var random_drops: Array[DropEntryResource] = []
@export_range(0.0, 1.0, 0.01) var no_drop_chance: float = 0.0
@export_range(1, 10, 1) var random_rolls: int = 1


func roll_drop_scenes(rng: RandomNumberGenerator = null) -> Array[PackedScene]:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	var scenes: Array[PackedScene] = []

	for entry in guaranteed_drops:
		_append_entry_scenes(scenes, entry, rng)

	for _i in range(max(random_rolls, 0)):
		if rng.randf() < clampf(no_drop_chance, 0.0, 1.0):
			continue

		var selected := _pick_weighted_entry(rng)
		if selected == null:
			continue

		_append_entry_scenes(scenes, selected, rng)

	return scenes


func _append_entry_scenes(target: Array[PackedScene], entry: DropEntryResource, rng: RandomNumberGenerator) -> void:
	if target == null or entry == null or entry.scene == null:
		return

	var amount := entry.get_amount(rng)
	for _i in range(amount):
		target.push_back(entry.scene)


func _pick_weighted_entry(rng: RandomNumberGenerator) -> DropEntryResource:
	var total_weight: float = 0.0

	for entry in random_drops:
		if entry == null or entry.scene == null:
			continue

		if entry.weight <= 0.0:
			continue

		total_weight += entry.weight

	if total_weight <= 0.0:
		return null

	var roll := rng.randf_range(0.0, total_weight)
	var cumulative := 0.0

	for entry in random_drops:
		if entry == null or entry.scene == null:
			continue

		if entry.weight <= 0.0:
			continue

		cumulative += entry.weight
		if roll <= cumulative:
			return entry

	return null
