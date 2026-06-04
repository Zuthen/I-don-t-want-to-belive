extends Node2D

var paths: Array[Vector2i] = []
var tile_map_layer: Node2D


func local_to_map(pos: Vector2) -> Vector2i:
	return Vector2i(int(pos.x / 16), int(pos.y / 16))


func map_to_local(grid_position: Vector2i) -> Vector2:
	return Vector2(grid_position.x * 16, grid_position.y * 16)
