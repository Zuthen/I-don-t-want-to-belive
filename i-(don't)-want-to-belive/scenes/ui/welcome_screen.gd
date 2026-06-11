extends Node2D

@onready var create_game = $CanvasLayer/Buttons/CreateGame
@onready var join = $CanvasLayer/Buttons/Join
@onready var room_popup = $CanvasLayer/RoomPopup


func _ready():
	create_game.pressed.connect(func(): _show_popup(room_popup.NetworkRole.HOST))
	join.pressed.connect(func(): _show_popup(room_popup.NetworkRole.CLIENT))


func _show_popup(role):
	room_popup.network_role = role
	room_popup.set_deferred("visible", true)
