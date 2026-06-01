extends Node2D

@onready var tile_map_layer = $BuildingsAndPaths
@onready var buildings_details = $BuildingsDetails
@onready var multiplayer_spawner = $MultiplayerSpawner

var city_atlas_pavement_coords: = Vector2i(9, 1)
var city_atlas_obstacles_coords = Vector2i(22, 8)
var paths: Array[Vector2i] = []
var obstacles
var skeptic_positions = []
var next_spawn_index: int = 0


func _ready():
	MultiplayerFeatures.spawn_player(multiplayer_spawner, tile_map_layer)

	if multiplayer.is_server():
		var game_map_seed = randi()
		skeptic_positions = create_map(game_map_seed)

		var server_position = skeptic_positions[0]
		next_spawn_index += 1
		if not multiplayer.peer_connected.is_connected(_on_peer_connected):
			multiplayer.peer_connected.connect(_on_peer_connected.bind(game_map_seed))

		multiplayer_spawner.spawn({ "peer_id": 1, "type": "skeptic", "spawn_position": server_position, "is_male": true, "is_ufo_team": false })


func _on_peer_connected(peer_id: int, map_seed: int):
	if not multiplayer.is_server():
		return

	client_build_map_instruction.rpc_id(peer_id, map_seed)

	next_spawn_index += 1
	var spawn_position: Vector2i
	var player_type = "skeptic"

	if next_spawn_index > 2:
		player_type = "ufo"
		var rand_x = randi_range(MapSettings.min_position.x, MapSettings.max_position.x)
		var rand_y = randi_range(MapSettings.min_position.y, MapSettings.max_position.y)
		spawn_position = Vector2i(rand_x, rand_y)
	else:
		var skeptic_index = next_spawn_index - 1
		if skeptic_positions.is_empty():
			spawn_position = Vector2i(0, 0)
		else:
			spawn_position = skeptic_positions[skeptic_index % skeptic_positions.size()]

	multiplayer_spawner.spawn(
		{
			"peer_id": peer_id,
			"type": player_type,
			"spawn_position": spawn_position,
			"is_ufo_team": (player_type == "ufo"),
		},
	)


@rpc("authority", "call_local", "reliable")
func client_build_map_instruction(map_seed: int):
	skeptic_positions = create_map(map_seed)

	if not is_multiplayer_authority():
		peer_ready.rpc_id(1)


@rpc("any_peer", "call_local", "reliable")
func peer_ready():
	if not multiplayer.is_server():
		return


func create_map(map_seed: int = 0):
	paths.clear()
	Drawers.tile_map_layer = tile_map_layer
	Drawers.details = buildings_details

	var generated_paths = genereate_map(map_seed)
	var areas = MapCreator.find_areas(generated_paths)
	var obstacle_regions = MapCreator.find_regions(areas.obstacles)
	var obstacle_rects: Array[Rect2i] = []
	for region in obstacle_regions:
		var rects = MapCreator.regions_to_rects(region)
		obstacle_rects.append_array(MapCreator.merge_small_rectangles(rects))

	Drawers.draw_map(obstacle_rects)
	Drawers.draw_pavement(areas.paths)

	var random = RandomNumberGenerator.new()
	random.seed = map_seed
	generate_map_borders()
	return find_skeptics_positions(areas.paths, random)


func genereate_map(map_seed: int = 0):
	var random = RandomNumberGenerator.new()
	random.seed = map_seed

	var rand_x = random.randi_range(MapSettings.min_position.x, MapSettings.max_position.x)
	var rand_y = random.randi_range(MapSettings.min_position.y, MapSettings.max_position.y)
	var start: Vector2i = Vector2i(rand_x, rand_y)
	var next: Array[Vector2i] = find_next_path(start, Vector2i.ZERO, random)

	for i in range(MapSettings.paths_tiles):
		var way = find_next_path(next[0], next[1], random)
		next = way
	return paths


func occupy_rect(rect: Rect2i, occupied: Dictionary):
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			occupied[Vector2i(x, y)] = true


func generate_map_borders():
	var edges = MapSettings.get_map_limits()

	var map_width_px = edges.right - edges.left
	var map_height_px = edges.bottom - edges.top

	var left_right_size = Vector2(MapSettings.tile_size, map_height_px)
	var top_bottom_size = Vector2(map_width_px, MapSettings.tile_size)

	var left_position = Vector2(
		edges.left - (MapSettings.tile_size / 2.0),
		edges.top + (map_height_px / 2.0),
	)

	var right_position = Vector2(
		edges.right + (MapSettings.tile_size / 2.0),
		edges.top + (map_height_px / 2.0),
	)

	var top_position = Vector2(
		edges.left + (map_width_px / 2.0),
		edges.top - (MapSettings.tile_size / 2.0),
	)

	var bottom_position = Vector2(
		edges.left + (map_width_px / 2.0),
		edges.bottom + (MapSettings.tile_size / 2.0),
	)

	generate_collider(left_right_size, left_position)
	generate_collider(left_right_size, right_position)
	generate_collider(top_bottom_size, top_position)
	generate_collider(top_bottom_size, bottom_position)


func generate_collider(size: Vector2, position: Vector2):
	var collider_shape = RectangleShape2D.new()
	collider_shape.size = size

	var border = StaticBody2D.new()
	border.position = position
	border.set_collision_layer_value(5, true)
	border.set_collision_layer_value(6, true)

	var border_collider = CollisionShape2D.new()
	border_collider.shape = collider_shape

	border.add_child(border_collider)
	tile_map_layer.add_child(border)


func directions(step: int) -> Dictionary:
	return {
		"up": Vector2i(0, -step),
		"down": Vector2i(0, step),
		"left": Vector2i(-step, 0),
		"right": Vector2i(step, 0),
	}


func find_next_path(position: Vector2i, previous: Vector2i, random: RandomNumberGenerator) -> Array[Vector2i]:
	var valid_dirs: Dictionary[String, Vector2i] = { }
	var valid_ways: Dictionary[String, Vector2i] = { }
	var destinations = directions(2)
	var ways_to_destinations = directions(1)

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
		return find_next_path(new_path, previous, random)

	var keys = valid_dirs.keys()
	var random_key_index = random.randi() % keys.size()
	var key = keys[random_key_index]

	var next_node = position + valid_dirs[key]
	var next_2 = position + valid_ways[key]
	paths.append_array([next_node, next_2])
	return [position + valid_dirs[key], position + valid_ways[key]]


func find_skeptics_positions(paths_array: Array[Vector2i], random: RandomNumberGenerator) -> Array[Vector2i]:
	if paths_array.is_empty():
		return []
	var dynamic_min_distance: float = sqrt(MapSettings.paths_tiles) * 0.85
	for i in range(MapSettings.paths_tiles / 2):
		var random_index_a = random.randi() % paths_array.size()
		var random_index_b = random.randi() % paths_array.size()

		if random_index_a == random_index_b:
			continue

		var a = paths_array[random_index_a]
		var b = paths_array[random_index_b]

		if a.distance_to(b) >= dynamic_min_distance:
			return [a, b]

	return [paths_array[0], paths_array[paths_array.size() - 1]]
