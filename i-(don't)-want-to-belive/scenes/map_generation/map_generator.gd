extends Node

class_name MapGenerator

var random: RandomNumberGenerator
var paths: Array[Vector2i] = []
var map_layer: TileMapLayer
var region_math: RegionMath


func _init():
	region_math = RegionMath.new()


class DrawData:
	var paths: Array[Vector2i]
	var obstacle_rects: Array[Rect2i]


	func _init(p: Array[Vector2i], o: Array[Rect2i]):
		paths = p
		obstacle_rects = o


func set_tile_map_layer(new_map_layer: TileMapLayer):
	map_layer = new_map_layer


func create_map(paths: Array[Vector2i]) -> DrawData:
	var areas = region_math.find_areas(paths)
	var obstacle_regions = region_math.find_regions(areas.obstacles)
	var obstacle_rects: Array[Rect2i] = region_math.map_regions_to_obstacle_rects(obstacle_regions)
	return DrawData.new(areas.paths, obstacle_rects)


func generate_map(map_seed: int = 0):
	random = RandomNumberGenerator.new()
	random.seed = map_seed

	var rand_x = random.randi_range(MapSettings.min_position.x, MapSettings.max_position.x)
	var rand_y = random.randi_range(MapSettings.min_position.y, MapSettings.max_position.y)
	var start: Vector2i = Vector2i(rand_x, rand_y)
	var next: Array[Vector2i] = _find_next_path(start, Vector2i.ZERO, random)

	for i in range(MapSettings.paths_tiles):
		var way = _find_next_path(next[0], next[1], random)
		next = way
	return paths


func generate_map_borders():
	var edges = MapSettings.get_map_limits()
	var map_width_px = edges.right - edges.left - 1
	var map_height_px = edges.bottom - edges.top - 1
	var wall_thickness = 64.0
	var left_right_size = Vector2(wall_thickness, map_height_px)
	var top_bottom_size = Vector2(map_width_px, wall_thickness)

	var left_position = Vector2(edges.left - (wall_thickness / 2.0), edges.top + (map_height_px / 2.0))
	var right_position = Vector2(edges.right + (wall_thickness / 2.0), edges.top + (map_height_px / 2.0))
	var top_position = Vector2(edges.left + (map_width_px / 2.0), edges.top - (wall_thickness / 2.0))
	var bottom_position = Vector2(edges.left + (map_width_px / 2.0), edges.bottom + (wall_thickness / 2.0))

	_generate_collider(left_right_size, left_position)
	_generate_collider(left_right_size, right_position)
	_generate_collider(top_bottom_size, top_position)
	_generate_collider(top_bottom_size, bottom_position)


func _generate_collider(size: Vector2, position: Vector2):
	var collider_shape = RectangleShape2D.new()
	collider_shape.size = size

	var border = StaticBody2D.new()
	border.position = position
	border.set_collision_layer_value(5, true)
	border.set_collision_layer_value(6, true)

	var border_collider = CollisionShape2D.new()
	border_collider.shape = collider_shape

	border.add_child(border_collider)
	map_layer.add_child(border)


func _find_next_path(position: Vector2i, previous: Vector2i, random: RandomNumberGenerator) -> Array[Vector2i]:
	var valid_dirs: Dictionary[String, Vector2i] = { }
	var valid_ways: Dictionary[String, Vector2i] = { }
	var destinations = _directions(2)
	var ways_to_destinations = _directions(1)

	for key in destinations:
		var dest_vec = destinations[key]

		if not ways_to_destinations.has(key):
			continue

		var way_vec = ways_to_destinations[key]
		var next = position + dest_vec
		if next == previous:
			continue
		if paths.has(next):
			continue
		if next.x < MapSettings.min_position.x or next.x > MapSettings.max_position.x:
			continue
		if next.y < MapSettings.min_position.y or next.y > MapSettings.max_position.y:
			continue

		valid_dirs[key] = dest_vec
		valid_ways[key] = way_vec

	if valid_dirs.is_empty():
		var random_index = random.randi() % paths.size()
		var new_path = paths[random_index]
		return _find_next_path(new_path, previous, random)

	var keys = valid_dirs.keys()
	var random_key_index = random.randi() % keys.size()
	var key = keys[random_key_index]

	var next_node = position + valid_dirs[key]
	var next_2 = position + valid_ways[key]
	paths.append_array([next_node, next_2])
	return [position + valid_dirs[key], position + valid_ways[key]]


func _directions(step: int) -> Dictionary:
	return {
		"up": Vector2i(0, -step),
		"down": Vector2i(0, step),
		"left": Vector2i(-step, 0),
		"right": Vector2i(step, 0),
	}
