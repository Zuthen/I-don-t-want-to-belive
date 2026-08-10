extends Node

class_name Server

var tile_map_layer: TileMapLayer
var buildings_details: TileMapLayer
var spawner: MultiplayerSpawner

var map_generator: MapGenerator
var random: RandomNumberGenerator

var players: Array[GameManager.Preferences] = []

var ufos: Array[GameManager.Preferences] = []
var skeptics: Array[GameManager.Preferences] = []
var roberts: Array[GameManager.Preferences] = []
var no_role_assigned: Array[GameManager.Preferences] = []

var skeptic_positions: Array[Vector2i] = []
var robert_position: Vector2i
var collectables_positions: Array[Vector2i] = []
var ready_peers_for_spawn: Dictionary = { }
var collectables: Findings.CollectablesData
var game: Game


func _init():
	map_generator = MapGenerator.new()
	random = RandomNumberGenerator.new()


func _set_game(my_game: Game):
	game = my_game


func set_tile_maps(map: TileMapLayer, details: TileMapLayer):
	tile_map_layer = map
	buildings_details = details


func set_spawner(multiplayer_spawner: MultiplayerSpawner):
	spawner = multiplayer_spawner


func prepare_game(my_game: Game):
	_set_game(my_game)
	randomize()
	var game_map_seed = randi()
	game.map_paths = create_map(game_map_seed)

	skeptic_positions = _find_skeptics_positions(game.map_paths, random)
	if GameManager.with_robert:
		robert_position = _find_robert_position(game.map_paths, random)
	collectables = Findings.create_collectables()
	collectables_positions = _find_collectables_placements(game.map_paths, collectables.count)

	players = GameManager.players_selections
	_assign_roles(players)
	_spawn_world(game_map_seed)


func create_map(map_seed: int = 0) -> Array[Vector2i]:
	map_generator.set_tile_map_layer(tile_map_layer)
	var generated_paths = map_generator.generate_map(map_seed)
	var draw_data = map_generator.create_map(generated_paths)
	Drawers.draw(tile_map_layer, buildings_details, draw_data.obstacle_rects, draw_data.paths)
	random = RandomNumberGenerator.new()
	random.seed = map_seed
	map_generator.generate_map_borders()
	return draw_data.paths


func get_map_paths() -> Array[Vector2i]:
	if map_generator:
		return map_generator.paths
	return []


func _assign_roles(players: Array[GameManager.Preferences]):
	ufos.clear()
	skeptics.clear()
	roberts.clear()
	no_role_assigned.clear()

	var want_ufo: Array[GameManager.Preferences] = []
	var want_skeptic: Array[GameManager.Preferences] = []
	var want_robert: Array[GameManager.Preferences] = []

	for player in players:
		match player.type.to_lower():
			"ufo":
				want_ufo.append(player)
			"skeptic":
				want_skeptic.append(player)
			"robert":
				want_robert.append(player)
			_:
				no_role_assigned.append(player)

	want_ufo.shuffle()
	want_skeptic.shuffle()
	want_robert.shuffle()

	_assign_role(ufos, GameManager.ufos_count, want_ufo, "ufo")
	_assign_role(skeptics, GameManager.skeptics_count, want_skeptic, "skeptic")

	var robert_limit = 1 if GameManager.with_robert else 0
	_assign_role(roberts, robert_limit, want_robert, "robert")

	no_role_assigned.shuffle()

	_fill_missing_role(ufos, GameManager.ufos_count, "ufo")
	_fill_missing_role(skeptics, GameManager.skeptics_count, "skeptic")
	_fill_missing_role(roberts, robert_limit, "robert")


func _assign_role(destination_array: Array[GameManager.Preferences], role_limit: int, preferences_array: Array[GameManager.Preferences], type: String):
	while destination_array.size() < role_limit and not preferences_array.is_empty():
		var player = preferences_array.pop_back()
		player.type = type
		destination_array.append(player)
	no_role_assigned.append_array(preferences_array)


func _fill_missing_role(destination_array: Array[GameManager.Preferences], limit: int, type: String):
	while destination_array.size() < limit and not no_role_assigned.is_empty():
		var player = no_role_assigned.pop_back()
		player.type = type
		destination_array.append(player)


func _find_collectables_placements(paths_array: Array[Vector2i], count: int) -> Array[Vector2i]:
	var available_placements = paths_array.duplicate()
	for skeptic_position in skeptic_positions:
		var idx = available_placements.find(skeptic_position)
		available_placements.pop_at(idx)
	if GameManager.with_robert:
		var robert_position_idx = available_placements.find(robert_position)
		available_placements.pop_at(robert_position_idx)
	if available_placements.is_empty():
		return []
	var dead_ends: Array[Vector2i] = []
	var one_ways: Array[Vector2i] = []
	var two_ways: Array[Vector2i] = []
	for path in available_placements:
		var ways = _check_ways(path, available_placements)
		if ways == 1:
			dead_ends.append(path)
		elif ways == 2:
			one_ways.append(path)
		elif ways == 3:
			two_ways.append(path)
	var collectables_placement: Array[Vector2i] = []
	collectables_placement.append_array(dead_ends)
	if collectables_placement.size() >= count:
		return collectables_placement
	collectables_placement.append_array(one_ways)
	if collectables_placement.size() >= count:
		return collectables_placement
	collectables_placement.append_array(two_ways)
	if collectables_placement.size() >= count:
		return collectables_placement
	return available_placements


func _find_skeptics_positions(paths_array: Array[Vector2i], random: RandomNumberGenerator) -> Array[Vector2i]:
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


func _find_robert_position(paths_array: Array[Vector2i], random: RandomNumberGenerator) -> Vector2i:
	if paths_array.is_empty():
		return Vector2i(0, 0)
	var available_positions = paths_array.duplicate()
	var dynamic_min_distance: float = sqrt(MapSettings.paths_tiles) * 0.85
	for skeptic_position in skeptic_positions:
		var position_idx = available_positions.find(skeptic_position)
		if position_idx != -1:
			available_positions.pop_at(position_idx)

	for i in range(MapSettings.paths_tiles / 2.0):
		var random_index = random.randi() % available_positions.size()
		var position_candidate = available_positions[random_index]
		if position_candidate.distance_to(skeptic_positions[0]) >= dynamic_min_distance and position_candidate.distance_to(skeptic_positions[0]) >= dynamic_min_distance:
			return position_candidate
	return available_positions[0]


func _map_to_spawn_data(skeptic_positions, _robert_position = null) -> Array:
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
		elif player_pref.type == "skeptic":
			var spawn_pos = skeptic_positions[skeptic_count] if skeptic_count < skeptic_positions.size() else Vector2i(0, 0)
			data["spawn_position"] = spawn_pos
			skeptic_count += 1
		elif player_pref.type == "robert":
			data["spawn_position"] = _robert_position

		players_data.append(data)

	return players_data


func _map_to_collectable_spawn_data(collectables_spawn_positions: Array[Vector2i], random: RandomNumberGenerator):
	var collectables_data = []
	var available_positions = collectables_spawn_positions.duplicate()
	print("collectables: ", collectables)
	print("collectables.collectables: ", collectables.collectables)
	if collectables_positions.size() > 0:
		for item_name in collectables.collectables:
			var count = collectables.collectables[item_name]
			for i in range(count):
				var item_position_idx = random.randi() % available_positions.size()
				var spawn_data = {
					"type": "collectable",
					"name": item_name,
					"spawn_position": available_positions[item_position_idx],
				}
				available_positions.remove_at(item_position_idx)
				collectables_data.append(spawn_data)
	return collectables_data


func _check_ways(path: Vector2i, paths: Array[Vector2i]) -> int:
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

	if is_instance_valid(game) and game.has_method("client_build_map_instruction"):
		game.client_build_map_instruction.rpc(map_payload)

	check_if_everyone_is_ready_to_spawn(1)


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
			sync_data[str(p.peer_id)] = {
				"type": p.type,
				"skin_idx": p.skin_idx,
			}

		if is_instance_valid(game) and game.has_method("_sync_final_roles_to_all_clients"):
			game._sync_final_roles_to_all_clients.rpc(sync_data)
		var spawner_data
		if GameManager.with_robert:
			spawner_data = _map_to_spawn_data(skeptic_positions, robert_position)
		else:
			spawner_data = _map_to_spawn_data(skeptic_positions)
		var collectables_data = _map_to_collectable_spawn_data(collectables_positions, random)
		spawner_data.append_array(collectables_data)

		for data in spawner_data:
			spawner.spawn(data)
