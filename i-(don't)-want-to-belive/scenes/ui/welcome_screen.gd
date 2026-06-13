extends Node2D

@onready var create_game = $CanvasLayer/Buttons/CreateGame
@onready var join = $CanvasLayer/Buttons/Join
@onready var room_popup = $CanvasLayer/RoomPopup
@onready var quick_game = $CanvasLayer/Buttons/QuickGame


func _ready():
	create_game.pressed.connect(_create_game_and_go_to_lobby)
	join.pressed.connect(func(): _show_popup(room_popup.NetworkRole.CLIENT))
	quick_game.pressed.connect(_join_existing_game)


func _show_popup(role):
	room_popup.network_role = role
	room_popup.set_deferred("visible", true)


func _create_game_and_go_to_lobby():
	NakamaNetworkManager.host_create_match()


func _join_existing_game():
	quick_game.disabled = true
	print("[Menu] Szukam gry, blokuję przycisk...")
	await NakamaNetworkManager.join_existing_game()


func _go_to_lobby():
	var lobby_scene = load("uid://dg7q16m0w6dnx") as PackedScene
	get_tree().change_scene_to_packed(lobby_scene)
