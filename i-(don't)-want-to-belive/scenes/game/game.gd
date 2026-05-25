extends Node2D

@onready var tile_map_layer = $BuildingsAndPaths
@onready var buildings_details = $BuildingsDetails
@onready var multiplayer_spawner = $MultiplayerSpawner

var skeptic_scene: PackedScene = preload("uid://b7wo2a5407873")
var min_position := Vector2i(0, -10)
var max_position := Vector2i(19, 9)
var city_atlas_pavement_coords: = Vector2i(9, 1)
var city_atlas_obstacles_coords = Vector2i(22, 8)
var paths: Array[Vector2i] = []
var obstacles
var skeptic_positions = []
var next_spawn_index: int = 0


func _ready():
	multiplayer_spawner.spawn_function = func(data):
		var skeptic = skeptic_scene.instantiate() as Skeptic
		skeptic.name = str(data.peer_id)
		skeptic.input_multiplayer_authority = data.peer_id
		if data.has("spawn_position"):
			skeptic.position = tile_map_layer.map_to_local(data.spawn_position)
		if data.has("is_male"):
			skeptic.is_male = data.is_male

		return skeptic

	if is_multiplayer_authority():
		var game_map_seed = randi()
		skeptic_positions = create_map(game_map_seed)

		var server_position = skeptic_positions[next_spawn_index]
		next_spawn_index += 1
		multiplayer_spawner.spawn({ "peer_id": 1, "spawn_position": server_position, "is_male": true })
		multiplayer.peer_connected.connect(_on_peer_connected.bind(game_map_seed))


func _on_peer_connected(peer_id: int, map_seed: int):
	client_build_map_instruction.rpc_id(peer_id, map_seed)


@rpc("authority", "call_local", "reliable")
func client_build_map_instruction(map_seed: int):
	skeptic_positions = create_map(map_seed)

	if not is_multiplayer_authority():
		peer_ready.rpc_id(1)


@rpc("any_peer", "call_local", "reliable")
func peer_ready():
	if not is_multiplayer_authority():
		return

	var sender_id = multiplayer.get_remote_sender_id()
	var spawn_index = next_spawn_index % skeptic_positions.size()
	var chosen_position = skeptic_positions[spawn_index]
	next_spawn_index += 1
	multiplayer_spawner.spawn({ "peer_id": sender_id, "spawn_position": chosen_position })


func create_map(map_seed: int = 0):
	paths.clear()
	Drawers.tile_map_layer = tile_map_layer
	Drawers.details = buildings_details

	var generated_paths = genereate_map(map_seed)
	var areas = MapCreator.find_areas(generated_paths)
	var obstacle_regions = MapCreator.find_regions(areas.obstacles)
	var obstacle_rects: Array[Rect2i] = []
	var map_borders_obstacle_rects := MapCreator.create_left_borders(Rect2i(Vector2i(-1, -10), Vector2i(8, 19)))
	for region in obstacle_regions:
		var rects = MapCreator.regions_to_rects(region)
		obstacle_rects.append_array(MapCreator.merge_small_rectangles(rects))

	Drawers.draw_map(obstacle_rects)
	Drawers.draw_pavement(areas.paths)

	var random = RandomNumberGenerator.new()
	random.seed = map_seed
	return find_skeptics_positions(areas.paths, random)


func genereate_map(map_seed: int = 0):
	var random = RandomNumberGenerator.new()
	random.seed = map_seed

	var start: Vector2i = Vector2i(random.randi_range(0, 19), random.randi_range(-10, 9))
	var next: Array[Vector2i] = find_next_path(start, Vector2i.ZERO, random)

	for i in range(100):
		var way = find_next_path(next[0], next[1], random)
		next = way
	return paths


func occupy_rect(rect: Rect2i, occupied: Dictionary):
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			occupied[Vector2i(x, y)] = true


func directions(step: int) -> Dictionary:
	return {
		"up": Vector2i(0, -step),
		"down": Vector2i(0, step),
		"left": Vector2i(-step, 0),
		"right": Vector2i(step, 0),
	}


func spawn_player(spawn_position: Vector2i) -> Skeptic:
	var player = skeptic_scene.instantiate()
	player.position = tile_map_layer.map_to_local(spawn_position)
	add_child(player)
	return player


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
		if next.x < min_position.x or next.x > max_position.x:
			continue
		if next.y < min_position.y or next.y > max_position.y:
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
	for i in range(100):
		var random_index_a = random.randi() % paths_array.size()
		var a = paths_array[random_index_a]

		var candidates = paths_array.filter(
			func(p):
				return p.distance_to(a) > 9
		)

		if candidates.is_empty():
			continue

		var random_index_b = random.randi() % candidates.size()
		var b = candidates[random_index_b]
		return [a, b]
	return []
