extends TileMapLayer

class_name NightLayer

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
var is_initial_fog_uncovered := false


func _ready():
	z_index = 10
	y_sort_enabled = false
	if not buildings_layer:
		push_error("Set buildings layer")
		return

	_initialize_fog()

	var my_network_id = multiplayer.get_unique_id()
	for pref in GameManager.players_selections:
		if pref.peer_id == my_network_id:
			my_lobby_role = pref.type.to_lower()
			break

	await get_tree().process_frame

	if my_lobby_role == "":
		var local_player = MultiplayerFeatures.get_local_player()
		if local_player and local_player.is_in_group("ufos"):
			my_lobby_role = "ufo"
		else:
			my_lobby_role = "skeptic"


func _process(_delta):
	var local_player = MultiplayerFeatures.get_local_player()
	if not local_player:
		return

	var is_alien = local_player.is_in_group("aliens")
	var is_ufo = local_player.is_in_group("ufos")

	if is_ufo and not is_alien:
		_setup_ufo_view(local_player)
		return

	_setup_ground_entities_view(local_player)


func _setup_ufo_view(local_player):
	if not ufo_view_setup:
		ufo_view_setup = true
		last_player_tile = Vector2i(-999, -999)
		var cells_to_update: Array[Vector2i] = []
		for x in range(MapSettings.min_position.x - 15, MapSettings.max_position.x + 15):
			for y in range(MapSettings.min_position.y - 15, MapSettings.max_position.y + 15):
				cells_to_update.append(Vector2i(x, y))
		for cell in cells_to_update:
			set_cell(cell, ATLAS_SOURCE_ID, black_tile_coords, TILE_HALF_SHADOW)
			GameManager.is_local_fog_ready = true
	_update_players_visibility(local_player)


func _setup_ground_entities_view(local_player):
	if ufo_view_setup:
		ufo_view_setup = false
		_initialize_fog()
		last_player_tile = Vector2i(-999, -999)

	var current_tile = buildings_layer.local_to_map(local_player.global_position)

	if last_player_tile == Vector2i(-999, -999):
		last_player_tile = current_tile
		_apply_new_fog(last_player_tile)
		GameManager.is_local_fog_ready = true

	if current_tile != last_player_tile:
		if last_player_tile != Vector2i(-999, -999):
			_reset_old_fog(last_player_tile)

		last_player_tile = current_tile
		_apply_new_fog(current_tile)

	_update_players_visibility(local_player)


func _initialize_fog():
	clear()
	for x in range(MapSettings.min_position.x - 15, MapSettings.max_position.x + 15):
		for y in range(MapSettings.min_position.y - 15, MapSettings.max_position.y + 15):
			set_cell(Vector2i(x, y), ATLAS_SOURCE_ID, black_tile_coords, TILE_DEEP_NIGHT)


func _update_players_visibility(local_player: Node2D):
	var my_network_id = multiplayer.get_unique_id()
	var all_ground_players = get_tree().get_nodes_in_group("skeptics") + get_tree().get_nodes_in_group("aliens")
	var items = get_tree().get_nodes_in_group("collectable_items")
	var is_local_ufo = local_player.is_in_group("ufos") and not local_player.is_in_group("aliens")

	if is_local_ufo:
		for player in all_ground_players:
			var player_net_id = player.id if "id" in player else player.get_multiplayer_authority()
			if player_net_id == my_network_id or player.is_multiplayer_authority():
				player.visible = true
				continue
			player.visible = false
		for collectable in items:
			collectable.visible = false
		return

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
		player.visible = is_visible_by_fog

	for collectable in items:
		var item_tile = buildings_layer.local_to_map(collectable.global_position)
		var distance_in_tiles = local_tile.distance_to(item_tile)
		var fog_tile_alternative = get_cell_alternative_tile(item_tile)

		var is_item_visible = (fog_tile_alternative != TILE_DEEP_NIGHT and distance_in_tiles <= vision_radius)
		collectable.visible = is_item_visible


func _reset_old_fog(center_tile: Vector2i):
	for x in range(-vision_radius, vision_radius + 1):
		for y in range(-vision_radius, vision_radius + 1):
			var target_tile = center_tile + Vector2i(x, y)
			if vision_radius == 1 or center_tile.distance_to(target_tile) <= vision_radius:
				set_cell(target_tile, ATLAS_SOURCE_ID, black_tile_coords, TILE_DEEP_NIGHT)


func _apply_new_fog(center_tile: Vector2i):
	for x in range(-vision_radius, vision_radius + 1):
		for y in range(-vision_radius, vision_radius + 1):
			var target_tile = center_tile + Vector2i(x, y)
			if vision_radius == 1 or center_tile.distance_to(target_tile) <= vision_radius:
				set_cell(target_tile, ATLAS_SOURCE_ID, black_tile_coords, TILE_NEAR_LIGHT)
