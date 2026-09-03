extends Node2D

class_name Game

const GAME_MUSIC = preload("uid://bimjd1o2muktk")

@onready var tile_map_layer: TileMapLayer = $BuildingsAndPaths
@onready var buildings_details: TileMapLayer = $BuildingsDetails
@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner

var random: RandomNumberGenerator
var server: Server
var map_paths: Array[Vector2i] = []


func _ready():
	BackgroundMusic.stop()
	BackgroundMusic.stream = GAME_MUSIC
	BackgroundMusic.play()
	MultiplayerFeatures.spawn(multiplayer_spawner, tile_map_layer)

	if multiplayer.is_server():
		server = Server.new()
		server.name = "Server"
		add_child(server)
		server.set_tile_maps(tile_map_layer, buildings_details)
		server.set_spawner(multiplayer_spawner)
		server.prepare_game(self)


@rpc("any_peer", "call_remote", "reliable")
func _client_signals_ready_to_spawn(peer_id: int):
	if multiplayer.is_server() and is_instance_valid(server):
		server.check_if_everyone_is_ready_to_spawn(peer_id)


@rpc("authority", "call_remote", "reliable")
func client_build_map_instruction(map_payload: Dictionary):
	var client_server = Server.new()
	client_server.name = "Server"
	add_child(client_server)
	client_server.set_tile_maps(tile_map_layer, buildings_details)

	GameManager.map_config = map_payload["config"] as GameManager.MapConfig
	GameManager.map_tiles_size = map_payload["tiles_size"]
	GameManager.map_paths_tiles = map_payload["paths_tiles"]

	map_paths = client_server.create_map(map_payload["seed"])

	_client_signals_ready_to_spawn.rpc_id(1, multiplayer.get_unique_id())


@rpc("authority", "call_local", "reliable")
func _sync_final_roles_to_all_clients(sync_data: Dictionary):
	if sync_data.has("map_paths_tiles"):
		GameManager.map_config = sync_data["map_config"] as GameManager.MapConfig
		GameManager.map_tiles_size = sync_data["map_tiles_size"]
		GameManager.map_paths_tiles = sync_data["map_paths_tiles"]

	GameManager.players_selections.clear()

	for peer_str in sync_data:
		if peer_str == "map_config" or peer_str == "map_tiles_size" or peer_str == "map_paths_tiles":
			continue

		var p_id = int(peer_str)
		var pref = GameManager.Preferences.new()
		pref.peer_id = p_id
		pref.type = sync_data[peer_str]["type"]
		pref.skin_idx = sync_data[peer_str]["skin_idx"]

		GameManager.players_selections.append(pref)

	get_tree().call_group("local_user_interface", "initialize_ui")
