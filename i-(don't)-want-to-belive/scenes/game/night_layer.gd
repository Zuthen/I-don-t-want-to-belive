extends TileMapLayer

@export var buildings_layer: TileMapLayer
@export var vision_radius: int = 1

var black_tile_coords: Vector2i = Vector2i(9, 1)

const ATLAS_SOURCE_ID: int = 2

const TILE_DEEP_NIGHT = 3
const TILE_HALF_SHADOW = 7
const TILE_NEAR_LIGHT = 8

var last_player_tile := Vector2i(-999, -999)


func _ready():
	z_index = 10
	y_sort_enabled = false
	if not buildings_layer:
		push_error("Set buildings layer")
		return

	await get_tree().process_frame
	initialize_fog()


func initialize_fog():
	var cells_pck: Array[Vector2i] = []

	for x in range(MapSettings.min_position.x - 15, MapSettings.max_position.x + 15):
		for y in range(MapSettings.min_position.y - 15, MapSettings.max_position.y + 15):
			cells_pck.append(Vector2i(x, y))

	for cell in cells_pck:
		set_cell(cell, ATLAS_SOURCE_ID, black_tile_coords, TILE_DEEP_NIGHT)


func _process(_delta):
	var local_player = get_local_player()
	if not local_player:
		return

	if local_player.is_in_group("ufos") and not local_player.is_in_group("aliens"):
		if last_player_tile == Vector2i(-999, -999):
			last_player_tile = Vector2i(0, 0)
			setup_ufo_view()
		update_players_visibility(local_player)
		return

	if last_player_tile == Vector2i(0, 0) or (last_player_tile == Vector2i(-999, -999) and (local_player.is_in_group("aliens") or local_player.is_in_group("skeptics"))):
		last_player_tile = buildings_layer.local_to_map(local_player.global_position)
		initialize_fog()
		apply_new_fog(last_player_tile)

	var current_tile = buildings_layer.local_to_map(local_player.global_position)

	if current_tile != last_player_tile:
		if last_player_tile != Vector2i(-999, -999):
			reset_old_fog(last_player_tile)

		last_player_tile = current_tile
		apply_new_fog(current_tile)
	update_players_visibility(local_player)


func update_players_visibility(local_player: Node2D):
	var my_network_id = multiplayer.get_unique_id()
	if local_player.is_in_group("ufos") and not local_player.is_in_group("aliens"):
		var ground_entities = get_tree().get_nodes_in_group("skeptics") + get_tree().get_nodes_in_group("aliens") + get_tree().get_nodes_in_group("wrecks")
		for entity in ground_entities:
			entity.visible = false

		var ufo_players = get_tree().get_nodes_in_group("ufos")
		for ufo in ufo_players:
			ufo.visible = true
		return

	var all_ground_players = get_tree().get_nodes_in_group("skeptics") + get_tree().get_nodes_in_group("aliens")
	var local_tile = buildings_layer.local_to_map(local_player.global_position)

	for player in all_ground_players:
		if player.get_multiplayer_authority() == my_network_id:
			player.visible = true
			continue

		var player_tile = buildings_layer.local_to_map(player.global_position)
		var distance_in_tiles = local_tile.distance_to(player_tile)
		var fog_tile_alternative = get_cell_alternative_tile(player_tile)

		if fog_tile_alternative != TILE_DEEP_NIGHT and distance_in_tiles <= vision_radius:
			player.visible = true
		else:
			player.visible = false
	var all_wrecks = get_tree().get_nodes_in_group("wrecks")
	for wreck in all_wrecks:
		var wreck_tile = buildings_layer.local_to_map(wreck.global_position)
		var distance_to_wreck = local_tile.distance_to(wreck_tile)
		var fog_at_wreck = get_cell_alternative_tile(wreck_tile)

		if fog_at_wreck != TILE_DEEP_NIGHT and distance_to_wreck <= vision_radius:
			wreck.visible = true
		else:
			wreck.visible = false


func setup_ufo_view():
	var cells_pck: Array[Vector2i] = []

	for x in range(MapSettings.min_position.x - 15, MapSettings.max_position.x + 15):
		for y in range(MapSettings.min_position.y - 15, MapSettings.max_position.y + 15):
			cells_pck.append(Vector2i(x, y))

	for cell in cells_pck:
		set_cell(cell, ATLAS_SOURCE_ID, black_tile_coords, TILE_HALF_SHADOW)


func reset_old_fog(center_tile: Vector2i):
	for x in range(-vision_radius, vision_radius + 1):
		for y in range(-vision_radius, vision_radius + 1):
			var target_tile = center_tile + Vector2i(x, y)

			if vision_radius == 1 or center_tile.distance_to(target_tile) <= vision_radius:
				set_cell(target_tile, ATLAS_SOURCE_ID, black_tile_coords, TILE_DEEP_NIGHT)


func apply_new_fog(center_tile: Vector2i):
	for x in range(-vision_radius, vision_radius + 1):
		for y in range(-vision_radius, vision_radius + 1):
			var target_tile = center_tile + Vector2i(x, y)

			if vision_radius == 1 or center_tile.distance_to(target_tile) <= vision_radius:
				set_cell(target_tile, ATLAS_SOURCE_ID, black_tile_coords, TILE_NEAR_LIGHT)


func get_local_player() -> Node2D:
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return null

	var my_id = multiplayer.get_unique_id()
	var all_nodes = get_tree().get_nodes_in_group("skeptics") + get_tree().get_nodes_in_group("ufos") + get_tree().get_nodes_in_group("aliens")

	for node in all_nodes:
		if node.get_multiplayer_authority() == my_id:
			return node
		if node.get_parent() and node.get_parent().get_multiplayer_authority() == my_id:
			return node.get_parent() as Node2D

	return null
