extends CanvasLayer

@onready var tile_map_layer = get_node_or_null("/root/Game/BuildingsAndPaths")

var TILE_PIXEL_SIZE: float = MapSettings.tile_size
var SECTOR_TILE_SIZE = GameManager.map_tiles_size
var SECTOR_PIXEL_SIZE: float = MapSettings.tile_size * MapSettings.sector_tile_size

var target_player: Node2D
var player_camera: Camera2D
var last_player_tile := Vector2i(-999, -999)

var letter_label: Label
var number_label: Label


func _ready():
	letter_label = get_node_or_null("HBoxContainer/Letter") as Label
	number_label = get_node_or_null("HBoxContainer/Number") as Label

	target_player = get_parent() as Node2D
	if target_player:
		player_camera = target_player.get_node_or_null("Camera2D")


func _process(_delta):
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return

	if not tile_map_layer:
		return

	if not target_player.is_multiplayer_authority():
		visible = false
		return
	visible = true

	var current_tile = tile_map_layer.local_to_map(target_player.global_position)

	if current_tile != last_player_tile:
		last_player_tile = current_tile
		_update_sector_labels()


func _update_sector_labels():
	var player_position: Player.PlayerPosition = target_player.get_coordinates(target_player.global_position)
	letter_label.text = player_position.letter
	number_label.text = str(player_position.number)
