extends Node

class_name Server

var skeptic_positions = []
var collectables_positions = []
var players: Array[GameManager.Preferences]
var paths: Array[Vector2i] = []
var tile_map_layer: TileMapLayer
var buildings_details: TileMapLayer
var random: RandomNumberGenerator
var ufos: Array[GameManager.Preferences] = []
var skeptics: Array[GameManager.Preferences] = []
var spawner: MultiplayerSpawner
var ready_peers_for_spawn: Dictionary = { }


func set_tile_maps(map: TileMapLayer, details: TileMapLayer):
	tile_map_layer = map
	buildings_details = details


func set_spawner(multiplayer_spawner: MultiplayerSpawner):
	spawner = multiplayer_spawner


func prepare_game():
	randomize()
	var game_map_seed = randi()
	var draw_data_paths = create_map(game_map_seed)
	random = RandomNumberGenerator.new()
	skeptic_positions = find_skeptics_positions(draw_data_paths, random)
	collectables_positions = find_collectables_placements(draw_data_paths)
	players = GameManager.players_selections
	_assign_roles(players)
	_spawn_world(game_map_seed)


func create_map(map_seed: int = 0) -> Array[Vector2i]:
	var generated_paths = generate_map(map_seed)
	var draw_data = MapCreator.create_map(generated_paths)
	Drawers.draw(tile_map_layer, buildings_details, draw_data.obstacle_rects, draw_data.paths)

	random = RandomNumberGenerator.new()
	random.seed = map_seed
	generate_map_borders()
	var paths = draw_data.paths
	return paths


func _assign_roles(players: Array[GameManager.Preferences]):
	for player in players:
		if player.type.to_lower() == "ufo":
			ufos.append(player)
		elif player.type.to_lower() == "skeptic":
			skeptics.append(player)

	if skeptics.size() != 2 and ufos.size() != 2:
		if skeptics.size() > ufos.size():
			while ufos.size() < 2:
				var ufo_player = skeptics.pick_random()
				if ufo_player:
					skeptics.erase(ufo_player)

					# === POPRAWKA: skin_idx zamiast _skin_idx ===
					ufo_player.skin_idx = randi() % 5

					ufo_player.type = "ufo"
					ufos.append(ufo_player)
		elif ufos.size() > skeptics.size():
			while skeptics.size() < 2:
				var skeptic_player = ufos.pick_random()
				if skeptic_player:
					ufos.erase(skeptic_player)
					skeptic_player.type = "skeptic"
					skeptics.append(skeptic_player)


func find_collectables_placements(paths_array: Array[Vector2i]) -> Array[Vector2i]:
	if paths_array.is_empty():
		return []
	var dead_ends: Array[Vector2i] = []
	var one_ways: Array[Vector2i] = []
	var two_ways: Array[Vector2i] = []
	for path in paths_array:
		var ways = check_ways(path, paths_array)
		if ways == 1:
			dead_ends.append(path)
		elif ways == 2:
			one_ways.append(path)
		elif ways == 3:
			two_ways.append(path)
	if dead_ends.size() > 0:
		return dead_ends
	elif one_ways.size() > 0:
		return one_ways
	return two_ways


func find_skeptics_positions(paths_array: Array[Vector2i], random: RandomNumberGenerator) -> Array[Vector2i]:
	if paths_array.is_empty():
		return []
	var dynamic_min_distance: float = sqrt(MapSettings.paths_tiles) * 0.85
	for i in range(MapSettings.paths_tiles / 2.0):
		var random_index_a = random.randi() % paths_array.size()
		var random_index_b = random.randi() % paths_array.size()

		if random_index_a == random_index_b:
			continue

		var a = paths_array[random_index_a]
		var b = paths_array[random_index_b]

		if a.distance_to(b) >= dynamic_min_distance:
			return [a, b]

	return [paths_array[0], paths_array[paths_array.size() - 1]]


func map_to_spawn_data(skeptic_positions) -> Array:
	var players_data = []
	var skeptic_count = 0

	for i in range(players.size()):
		var player_pref = players[i]

		var data = {
			"peer_id": player_pref.peer_id,
			"type": player_pref.type,
			"skin_idx": player_pref.skin_idx,
		}

		if player_pref.type == "ufo":
			var rand_x = randi_range(MapSettings.min_position.x, MapSettings.max_position.x)
			var rand_y = randi_range(MapSettings.min_position.y, MapSettings.max_position.y)
			data["spawn_position"] = Vector2i(rand_x, rand_y)
		else:
			var spawn_pos = skeptic_positions[skeptic_count] if skeptic_count < skeptic_positions.size() else Vector2i(0, 0)
			data["spawn_position"] = spawn_pos
			skeptic_count += 1

		players_data.append(data)

	return players_data


func collectable_spawn_data(collectables_spawn_positions: Array[Vector2i], random: RandomNumberGenerator):
	var collectibles_data = []
	if collectables_positions.size() > 0:
		var repair_tool_position_idx = random.randi() % collectables_spawn_positions.size()
		var repair_tool_spawn_data = {
			"type": "collectable",
			"name": "repair_tool",
			"spawn_position": collectables_spawn_positions[repair_tool_position_idx],
		}
		collectibles_data.append(repair_tool_spawn_data)
	return collectibles_data


func check_ways(path: Vector2i, paths: Array[Vector2i]) -> int:
	var neighbors_count = 0
	var neighbors: Array[Vector2i] = [
		Vector2i(path.x - 1, path.y),
		Vector2i(path.x + 1, path.y),
		Vector2i(path.x, path.y - 1),
		Vector2i(path.x, path.y + 1),
	]

	for neighbor in neighbors:
		if paths.has(neighbor):
			neighbors_count += 1

	return neighbors_count


func _spawn_world(game_map_seed: int):
	var map_payload = {
		"seed": game_map_seed,
		"paths_tiles": GameManager.map_paths_tiles,
		"tiles_size": GameManager.map_tiles_size,
		"config": GameManager.map_config,
	}
	await get_tree().process_frame
	await get_tree().process_frame

	if get_parent().has_method("client_build_map_instruction"):
		get_parent().client_build_map_instruction.rpc(map_payload)

	check_if_everyone_is_ready_to_spawn(1)


@rpc("any_peer", "call_local", "reliable")
func peer_ready():
	if not multiplayer.is_server():
		return


func _execute_server_spawn_after_sync():
	var spawner_data = map_to_spawn_data(skeptic_positions)
	for data in spawner_data:
		spawner.spawn(data)


func _execute_server_spawn():
	players = GameManager.players_selections
	_assign_roles(players)

	var spawner_data = map_to_spawn_data(skeptic_positions)
	for data in spawner_data:
		spawner.spawn(data)


func check_if_everyone_is_ready_to_spawn(peer_id: int):
	ready_peers_for_spawn[peer_id] = true
	var total_players_in_match = multiplayer.get_peers().size() + 1

	if ready_peers_for_spawn.size() == total_players_in_match:
		players = GameManager.players_selections
		_assign_roles(players)

		var sync_data: Dictionary = {
			"map_paths_tiles": GameManager.map_paths_tiles,
			"map_config": GameManager.map_config,
			"map_tiles_size": GameManager.map_tiles_size,
		}

		for p in players:
			# POPRAWKA: Czytamy poprawne pole p.skin_idx i pakujemy je pod bezpieczny klucz "skin_idx"
			sync_data[str(p.peer_id)] = {
				"type": p.type,
				"skin_idx": p.skin_idx,
			}

		# Wysyłamy RPC do skryptu game.gd
		if get_parent().has_method("_sync_final_roles_to_all_clients"):
			get_parent()._sync_final_roles_to_all_clients.rpc(sync_data)

		var spawner_data = map_to_spawn_data(skeptic_positions)
		var collectibles_data = collectable_spawn_data(collectables_positions, random)
		spawner_data.append_array(collectibles_data)

		for data in spawner_data:
			spawner.spawn(data)


func _create_map(map_seed: int = 0):
	var generated_paths = generate_map(map_seed)
	var areas = MapCreator.find_areas(generated_paths)
	var obstacle_regions = MapCreator.find_regions(areas.obstacles)
	var obstacle_rects: Array[Rect2i] = []

	for region in obstacle_regions:
		var rects = MapCreator.regions_to_rects(region)
		obstacle_rects.append_array(MapCreator.merge_small_rectangles(rects))


@rpc("authority", "call_local", "reliable")
func _sync_final_roles_to_all_clients(sync_data: Dictionary):
	if sync_data.has("map_paths_tiles"):
		GameManager.map_config = sync_data["map_config"] as GameManager.MapConfig
		GameManager.map_tiles_size = sync_data["map_tiles_size"]
		GameManager.map_paths_tiles = sync_data["map_paths_tiles"]

	GameManager.players_selections.clear()

	for peer_str in sync_data:
		if peer_str == "map_config" or peer_str == "map_tiles_size" or peer_str == "map_paths_tiles":
			continue

		var p_id = int(peer_str)
		var pref = GameManager.Preferences.new()
		pref.peer_id = p_id
		pref.type = sync_data[peer_str]["type"]

		# POPRAWKA: Czytamy z klucza "skin_idx" i przypisujemy do poprawnego pola pref.skin_idx
		pref.skin_idx = sync_data[peer_str]["skin_idx"]

		GameManager.players_selections.append(pref)

	get_tree().call_group("local_user_interface", "initialize_ui")


func generate_map(map_seed: int = 0):
	random = RandomNumberGenerator.new()
	random.seed = map_seed

	var rand_x = random.randi_range(MapSettings.min_position.x, MapSettings.max_position.x)
	var rand_y = random.randi_range(MapSettings.min_position.y, MapSettings.max_position.y)
	var start: Vector2i = Vector2i(rand_x, rand_y)
	var next: Array[Vector2i] = find_next_path(start, Vector2i.ZERO, random)

	for i in range(MapSettings.paths_tiles):
		var way = find_next_path(next[0], next[1], random)
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


func directions(step: int) -> Dictionary:
	return {
		"up": Vector2i(0, -step),
		"down": Vector2i(0, step),
		"left": Vector2i(-step, 0),
		"right": Vector2i(step, 0),
	}
