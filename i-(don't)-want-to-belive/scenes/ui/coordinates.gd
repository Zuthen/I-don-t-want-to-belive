extends CanvasLayer

@onready var letter_label = $HBoxContainer/Letter
@onready var number_label = $HBoxContainer/Number

@onready var tile_map_layer = get_node_or_null("/root/Game/BuildingsAndPaths")

const SECTOR_TILE_SIZE: int = 6
const TILE_PIXEL_SIZE: float = 16.0
const SECTOR_PIXEL_SIZE: float = TILE_PIXEL_SIZE * SECTOR_TILE_SIZE

var target_player: Node2D
var player_camera: Camera2D
var last_player_tile := Vector2i(-999, -999)


func _ready():
	target_player = get_parent()
	if target_player:
		player_camera = target_player.get_node_or_null("Camera2D")


func _process(_delta):
	if not tile_map_layer:
		return

	var player = get_parent()

	if not player.is_multiplayer_authority():
		visible = false
		return
	visible = true

	var current_tile = tile_map_layer.local_to_map(player.global_position)

	if current_tile != last_player_tile:
		last_player_tile = current_tile
		update_sector_labels(current_tile)


func update_sector_labels(tile_coords: Vector2i):
	var current_x = clampi(tile_coords.x, MapSettings.min_position.x, MapSettings.max_position.x)
	var current_y = clampi(tile_coords.y, MapSettings.min_position.y, MapSettings.max_position.y)

	if letter_label:
		var sector_x_idx = current_x / SECTOR_TILE_SIZE
		var letter = get_excel_column_name(sector_x_idx)
		letter_label.text = letter

	if number_label:
		var shifted_y = current_y - MapSettings.min_position.y
		var row_number = (shifted_y / SECTOR_TILE_SIZE) + 1
		number_label.text = str(row_number)


func get_excel_column_name(col_idx: int) -> String:
	var name := ""
	var temp = col_idx
	while temp >= 0:
		name = char(65 + (temp % 26)) + name
		temp = (temp / 26) - 1
	return name
