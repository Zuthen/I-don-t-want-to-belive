extends Control

const PORT: int = 3000

var game_scene: PackedScene = preload("uid://c4twc836ak4bd")

@onready var create = $HBoxContainer/Create
@onready var join = $HBoxContainer/Join


func _ready():
	create.pressed.connect(_host)
	join.pressed.connect(_join)
	multiplayer.connected_to_server.connect(_on_connected_to_server)


func _host():
	var server_peer := ENetMultiplayerPeer.new()
	server_peer.create_server(PORT)
	multiplayer.multiplayer_peer = server_peer
	get_tree().change_scene_to_packed(game_scene)


func _join():
	var client_peer := ENetMultiplayerPeer.new()
	client_peer.create_client("127.0.0.1", PORT)
	multiplayer.multiplayer_peer = client_peer


func _on_connected_to_server():
	get_tree().change_scene_to_packed(game_scene)
