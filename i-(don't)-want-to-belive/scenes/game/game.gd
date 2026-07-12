extends Node2D

@onready var tile_map_layer = $BuildingsAndPaths
@onready var buildings_details = $BuildingsDetails
@onready var multiplayer_spawner = $MultiplayerSpawner

var random: RandomNumberGenerator
var game_music = preload("uid://bimjd1o2muktk")

var server: Server


func _ready():
	BackgroundMusic.stop()
	BackgroundMusic.stream = game_music
	BackgroundMusic.play()
	MultiplayerFeatures.spawn(multiplayer_spawner, tile_map_layer)

	if multiplayer.is_server():
		server = Server.new()
		add_child(server)
		server.set_tile_maps(tile_map_layer, buildings_details)
		server.set_spawner(multiplayer_spawner)
		server.prepare_game()


@rpc("any_peer", "call_remote", "reliable")
func _client_signals_ready_to_spawn(peer_id: int):
	if multiplayer.is_server():
		server.check_if_everyone_is_ready_to_spawn(peer_id)


@rpc("any_peer", "call_local", "reliable")
func peer_ready():
	if not multiplayer.is_server():
		return


func occupy_rect(rect: Rect2i, occupied: Dictionary):
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			occupied[Vector2i(x, y)] = true


class CollectablesPlacement:
	var dead_ends: Array[Vector2i]
	var one_way: Array[Vector2i]
	var two_ways: Array[Vector2i]


@rpc("authority", "call_remote", "reliable")
func client_build_map_instruction(map_payload):
	var client_server = Server.new()
	add_child(client_server)
	client_server.set_tile_maps(tile_map_layer, buildings_details)

	if map_payload is Dictionary:
		GameManager.map_config = map_payload["config"] as GameManager.MapConfig
		GameManager.map_tiles_size = map_payload["tiles_size"]
		GameManager.map_paths_tiles = map_payload["paths_tiles"]
		client_server.create_map(map_payload["seed"])
	else:
		client_server.create_map(map_payload)

	_client_signals_ready_to_spawn.rpc_id(1, multiplayer.get_unique_id())
