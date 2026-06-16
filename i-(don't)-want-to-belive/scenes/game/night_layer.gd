extends TileMapLayer

@export var buildings_layer: TileMapLayer
@export var vision_radius: int = 2

var black_tile_coords: Vector2i = Vector2i(9, 1)

const ATLAS_SOURCE_ID: int = 2

const TILE_DEEP_NIGHT = 3
const TILE_HALF_SHADOW = 7
const TILE_NEAR_LIGHT = 8

var last_player_tile := Vector2i(-999, -999)
var ufo_view_setup := false
var my_lobby_role: String = ""


func _ready():
	z_index = 10
	y_sort_enabled = false
	if not buildings_layer:
		push_error("Set buildings layer")
		return
	var my_network_id = multiplayer.get_unique_id()

	for pref in GameManager.players_selections:
		if pref.peer_id == my_network_id:
			my_lobby_role = pref.type.to_lower()
			break

	await get_tree().process_frame

	if my_lobby_role == "":
		var local_player = get_local_player()
		if local_player and local_player.is_in_group("ufos"):
			my_lobby_role = "ufo"
		else:
			my_lobby_role = "skeptic"


func _process(_delta):
	var local_player = get_local_player()
	if not local_player:
		return

	var is_alien = local_player.is_in_group("aliens")
	var is_ufo = local_player.is_in_group("ufos")

	if is_ufo and not is_alien:
		if not ufo_view_setup:
			ufo_view_setup = true
			setup_ufo_view()
		update_players_visibility(local_player)
		return

	if ufo_view_setup:
		ufo_view_setup = false
		initialize_fog()
		last_player_tile = Vector2i(-999, -999)

	if last_player_tile == Vector2i(-999, -999):
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


func initialize_fog():
	var cells_pck: Array[Vector2i] = []

	for x in range(MapSettings.min_position.x - 15, MapSettings.max_position.x + 15):
		for y in range(MapSettings.min_position.y - 15, MapSettings.max_position.y + 15):
			cells_pck.append(Vector2i(x, y))

	for cell in cells_pck:
		set_cell(cell, ATLAS_SOURCE_ID, black_tile_coords, TILE_DEEP_NIGHT)


func update_players_visibility(local_player: Node2D):
	var my_network_id = multiplayer.get_unique_id()

	var all_ground_players = get_tree().get_nodes_in_group("skeptics") + get_tree().get_nodes_in_group("aliens")
	var local_tile = buildings_layer.local_to_map(local_player.global_position)

	for player in all_ground_players:
		var player_net_id = player.id if "id" in player else player.get_multiplayer_authority()
		var player_tile = buildings_layer.local_to_map(player.global_position)

		if player_net_id == my_network_id or player.is_multiplayer_authority():
			player.visible = true
			continue

		var distance_in_tiles = local_tile.distance_to(player_tile)
		var fog_tile_alternative = get_cell_alternative_tile(player_tile)

		var is_visible_by_fog = (fog_tile_alternative != TILE_DEEP_NIGHT and distance_in_tiles <= vision_radius)

		if is_visible_by_fog:
			player.visible = true
		else:
			player.visible = false


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
	var all_actual_players = get_tree().get_nodes_in_group("ufos") + get_tree().get_nodes_in_group("skeptics") + get_tree().get_nodes_in_group("aliens")

	for node in all_actual_players:
		if not node is Node2D:
			continue

		if "id" in node and node.id == my_id:
			return node

		if node.name == str(my_id):
			return node

	var local_group = get_tree().get_nodes_in_group("local_player")
	if not local_group.is_empty() and local_group[0] is Node2D:
		return local_group[0]

	return null
