extends Node2D

var min_position := Vector2i(0, -30)
var max_position := Vector2i(59, 29)
var paths_tiles: = 750
var tile_size: = 16


class MapArea:
	var start: Vector2i
	var end: Vector2i


func get_map_area() -> MapArea:
	var map_area = MapArea.new()
	map_area.start = Vector2i(min_position.x, max_position.x)
	map_area.end = Vector2i(min_position.y, max_position.y)
	return map_area
