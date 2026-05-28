class_name Multiplayer
extends Node

var skeptic_scene: PackedScene = preload("uid://b7wo2a5407873")
var ufo_scene: PackedScene = preload("uid://hc74yy2qdg3f")


func spawn_player(multiplayer_spawner: MultiplayerSpawner, tile_map: TileMapLayer):
	multiplayer_spawner.spawn_function = func(data):
		var player_node = null
		if data.has("type") and data.type == "ufo":
			player_node = ufo_scene.instantiate() as Ufo
		else:
			player_node = skeptic_scene.instantiate() as Skeptic

		player_node.name = str(data.peer_id)
		player_node.id = data.peer_id
		player_node.input_multiplayer_authority = data.peer_id

		if data.has("spawn_position"):
			player_node.position = tile_map.map_to_local(data.spawn_position)

		if player_node is Skeptic and data.has("is_male"):
			player_node.is_male = data.is_male
		if player_node.has_node("PlayerInput"):
			player_node.get_node("PlayerInput").set_multiplayer_authority(data.peer_id)
		if player_node.get_multiplayer_authority() == multiplayer.get_unique_id():
			player_node.add_to_group("local_player")
		assign_to_group(data, player_node)
		return player_node


func assign_to_group(data, player_node):
	if data.has("type") and data.type == "ufo":
		player_node.add_to_group("ufos")

	elif data.has("type") and data.type == "skeptic":
		player_node.add_to_group("skeptics")
