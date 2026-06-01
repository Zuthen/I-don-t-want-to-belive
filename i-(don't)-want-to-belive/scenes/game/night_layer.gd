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

	if local_player.is_in_group("ufos"):
		if last_player_tile == Vector2i(-999, -999):
			last_player_tile = Vector2i(0, 0)
			setup_ufo_view()
		return

	var current_tile = buildings_layer.local_to_map(local_player.global_position)

	if current_tile != last_player_tile:
		if last_player_tile != Vector2i(-999, -999):
			reset_old_fog(last_player_tile)

		last_player_tile = current_tile
		apply_new_fog(current_tile)


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
	for group in ["skeptics", "ufos"]:
		for node in get_tree().get_nodes_in_group(group):
			if node.is_multiplayer_authority():
				return node
	return null
