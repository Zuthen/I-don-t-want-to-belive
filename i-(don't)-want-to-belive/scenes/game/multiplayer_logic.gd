class_name Multiplayer
extends Node

enum Role { NONE, UFO, SKEPTIC, ALIEN }

var skeptic_scene: PackedScene = preload("uid://b7wo2a5407873")
var ufo_scene: PackedScene = preload("uid://m52fuwcrlo2k")
var crashed_ufo_scene = preload("uid://bddko8bky1tp7")
var player_role = Role.NONE


func spawn(multiplayer_spawner: MultiplayerSpawner, tile_map: TileMapLayer):
	multiplayer_spawner.spawn_function = func(data):
		var player_node = null
		var role_name = Role.NONE

		if data.has("type") and data.type == "ufo":
			player_node = ufo_scene.instantiate()
			role_name = Role.UFO
		elif data.has("type") and data.type == "wreck":
			player_node = crashed_ufo_scene.instantiate() as CrashedUfo
		else:
			player_node = skeptic_scene.instantiate() as Skeptic
			role_name = Role.SKEPTIC

		if data.has("spawn_position") and player_node:
			player_node.position = tile_map.map_to_local(data.spawn_position)

		if data.has("type") and data.type == "wreck":
			player_node.name = "CrashedUfo_" + str(data.peer_id)
			player_node.peer_id = data.peer_id
			if data.has("ufo_idx"):
				player_node.ufo_texture_idx = data.ufo_idx
			return player_node

		player_node.name = str(data.peer_id)
		player_node.id = data.peer_id
		player_node.input_multiplayer_authority = data.peer_id

		if data.has("ufo_idx"):
			if "ufo_index_sync" in player_node:
				player_node.ufo_index_sync = data.ufo_idx
			if player_node.has_node("Ufo"):
				player_node.get_node("Ufo").ufo_idx = data.ufo_idx
			if player_node.has_node("Alien"):
				var alien_node = player_node.get_node("Alien")
				alien_node.ufo_idx = data.ufo_idx

		if player_node is Skeptic and data.has("is_male"):
			player_node.is_male = data.is_male

		if player_node.has_node("PlayerInput"):
			player_node.get_node("PlayerInput").set_multiplayer_authority(data.peer_id)
		elif player_node.has_node("PlayerInputSynchronizer"):
			player_node.get_node("PlayerInputSynchronizer").set_multiplayer_authority(data.peer_id)

		if player_node.get_multiplayer_authority() == multiplayer.get_unique_id():
			for old_local in get_tree().get_nodes_in_group("local_player"):
				old_local.remove_from_group("local_player")
			player_node.add_to_group("local_player")
			player_role = role_name

		assign_to_group(data, player_node)
		return player_node


func assign_to_group(data, player_node):
	if data.has("type"):
		match data.type:
			"ufo":
				player_node.add_to_group("ufos")
			"skeptic":
				player_node.add_to_group("skeptics")


func get_role() -> Role:
	return player_role


func get_local_player() -> Player:
	var my_id = multiplayer.get_unique_id()
	var all_players = get_tree().get_nodes_in_group("ufos") + get_tree().get_nodes_in_group("skeptics")

	for player in all_players:
		if player is Player and player.id == my_id:
			return player

	return null
