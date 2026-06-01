extends Node2D

var min_position := Vector2i(0, -30)
var max_position := Vector2i(59, 29)
var paths_tiles: = 750
var tile_size: = 16


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
