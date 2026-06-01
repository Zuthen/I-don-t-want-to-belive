extends TileMapLayer

@export var buildings_layer: TileMapLayer
@export var vision_radius: int = 12

var min_position := Vector2i(0, -10)
var max_position := Vector2i(19, 9)
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

	initialize_fog()


func initialize_fog():
	for x in range(min_position.x - 15, max_position.x + 15):
		for y in range(min_position.y - 15, max_position.y + 15):
			set_cell(Vector2i(x, y), ATLAS_SOURCE_ID, black_tile_coords, TILE_DEEP_NIGHT)


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
	for x in range(min_position.x - 15, max_position.x + 15):
		for y in range(min_position.y - 15, max_position.y + 15):
			set_cell(Vector2i(x, y), ATLAS_SOURCE_ID, black_tile_coords, TILE_HALF_SHADOW)


func reset_old_fog(center_tile: Vector2i):
	for x in range(-1, 2):
		for y in range(-1, 2):
			set_cell(center_tile + Vector2i(x, y), ATLAS_SOURCE_ID, black_tile_coords, TILE_DEEP_NIGHT)


func apply_new_fog(center_tile: Vector2i):
	for x in range(-1, 2):
		for y in range(-1, 2):
			set_cell(center_tile + Vector2i(x, y), ATLAS_SOURCE_ID, black_tile_coords, TILE_NEAR_LIGHT)


func get_local_player() -> Node2D:
	for group in ["skeptics", "ufos"]:
		for node in get_tree().get_nodes_in_group(group):
			if node.is_multiplayer_authority():
				return node
	return null
