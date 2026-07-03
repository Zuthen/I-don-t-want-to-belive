extends Node

var map_tiles_size: int = 6


class Preferences:
	var type: String
	var skin_idx: int
	var peer_id: int


enum MapConfig { NARROWLY, BALANCED, WIDE }
var is_local_fog_ready: bool = false
var players_selections: Array[Preferences]
var map_config: MapConfig = MapConfig.WIDE
var map_paths_tiles: int = 750


func get_map_paths_tiles() -> int:
	var pavement_tiles: int
	match map_config:
		MapConfig.NARROWLY:
			pavement_tiles = randi_range(8, 10) * map_tiles_size * 10 # użyliśmy 10 zamiast tile_size, pamiętasz?
		MapConfig.BALANCED:
			pavement_tiles = randi_range(11, 12) * map_tiles_size * 10
		MapConfig.WIDE:
			pavement_tiles = randi_range(14, 25) * map_tiles_size * 10
		_:
			pavement_tiles = 750
	return pavement_tiles
