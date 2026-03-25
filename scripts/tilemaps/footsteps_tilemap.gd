extends TileMapLayer

func _ready() -> void:
	AudioManagerCustom.tilemaps.push_back(self)
