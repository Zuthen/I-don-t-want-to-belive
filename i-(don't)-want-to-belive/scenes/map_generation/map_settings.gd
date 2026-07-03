extends Node2D

var tile_size: = 16
var paths_tiles: int:
	get:
		return GameManager.map_paths_tiles
var sector_pixel_size: float = tile_size * sector_tile_size


class MapArea:
	var start: Vector2i
	var end: Vector2i


class MapLimits:
	var left: int
	var right: int
	var top: int
	var bottom: int


func get_map_area() -> MapArea:
	var map_area = MapArea.new()
	map_area.start = Vector2i(min_position.x, min_position.y)
	map_area.end = Vector2i(max_position.x, max_position.y)
	return map_area


var sector_tile_size: int:
	get:
		return GameManager.map_tiles_size

var min_position := Vector2i(0, 0)

var max_position: Vector2i:
	get:
		var limit = (sector_tile_size * 10) - 1
		return Vector2i(limit, limit)

var total_axis_tiles: int:
	get:
		return sector_tile_size * 10


func get_map_limits() -> Dictionary:
	return {
		"left": 0,
		"right": total_axis_tiles * tile_size,
		"top": 0,
		"bottom": total_axis_tiles * tile_size,
	}
