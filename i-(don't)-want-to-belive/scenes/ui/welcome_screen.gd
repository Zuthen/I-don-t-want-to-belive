extends Node2D

@onready var create_game = $CanvasLayer/Buttons/CreateGame
@onready var join = $CanvasLayer/Buttons/Join
@onready var room_popup = $CanvasLayer/RoomPopup
@onready var quick_game = $CanvasLayer/Buttons/QuickGame
@onready var buttons = $CanvasLayer/Buttons


func _ready():
	if NakamaNetworkManager.is_connected_to_server:
		buttons.visible = true
	else:
		buttons.visible = false
	create_game.pressed.connect(_create_game_and_go_to_lobby)
	join.pressed.connect(_show_popup)
	quick_game.pressed.connect(_join_existing_game)
	buttons.visible = false
	NakamaNetworkManager.connection_established.connect(_on_connect)


func _on_connect():
	buttons.visible = true


func _show_popup():
	room_popup.popup_centered()


func _create_game_and_go_to_lobby():
	NakamaNetworkManager.host_create_match()


func _join_existing_game():
	quick_game.disabled = true
	await NakamaNetworkManager.join_existing_game()


func _go_to_lobby():
	var lobby_scene = load("uid://dg7q16m0w6dnx") as PackedScene
	get_tree().change_scene_to_packed(lobby_scene)
