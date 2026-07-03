extends Node2D

var tile_size: = 16
var paths_tiles: int:
	get:
		return GameManager.map_paths_tiles
var sector_tile_size: int:
	get:
		return GameManager.map_tiles_size
var sector_pixel_size: float = tile_size * sector_tile_size

var min_position := Vector2i(0, -sector_tile_size * 5)
var max_position := Vector2i(sector_tile_size * 10 - 1, sector_tile_size * 5 - 1)


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


func get_map_limits() -> MapLimits:
	var limits = MapLimits.new()
	limits.left = min_position.x * tile_size
	limits.right = max_position.x * tile_size
	limits.top = min_position.y * tile_size
	limits.bottom = max_position.y * tile_size
	return limits
