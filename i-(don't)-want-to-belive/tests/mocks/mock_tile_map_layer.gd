extends Node2D

func map_to_local(grid_position: Vector2i) -> Vector2:
	return Vector2(grid_position.x * 16, grid_position.y * 16)
