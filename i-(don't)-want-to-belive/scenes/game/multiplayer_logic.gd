class_name Multiplayer
extends Node

var skeptic_scene: PackedScene = preload("uid://b7wo2a5407873")
var ufo_scene: PackedScene = preload("uid://m52fuwcrlo2k")
var crashed_ufo_scene = preload("uid://bddko8bky1tp7")
var laser_scene = preload("uid://dnsiqidfpctrc")


func spawn(multiplayer_spawner: MultiplayerSpawner, tile_map: TileMapLayer):
	multiplayer_spawner.spawn_function = func(data):
		var node = null

		if data.has("type") and data.type == "ufo":
			node = ufo_scene.instantiate()
			node.role = Player.Role.UFO
			node.name = str(data.peer_id)
			node.id = data.peer_id
			node.input_multiplayer_authority = data.peer_id

		elif data.has("type") and data.type == "wreck":
			node = crashed_ufo_scene.instantiate() as CrashedUfo

		elif data.has("type") and data.type == "laser":
			node = laser_scene.instantiate() as UfoLaser
			node.name = "Laser"

		else:
			node = skeptic_scene.instantiate() as Skeptic
			node.role = Player.Role.SKEPTIC
			node.name = str(data.peer_id)
			node.id = data.peer_id
			node.input_multiplayer_authority = data.peer_id

		if data.has("spawn_position") and node and data.type != "laser":
			node.position = tile_map.map_to_local(data.spawn_position)

		if data.has("type") and data.type == "wreck":
			node.name = "CrashedUfo_" + str(data.peer_id)
			node.peer_id = data.peer_id
			if data.has("ufo_idx"):
				node.ufo_texture_idx = data.ufo_idx
			return node

		if data.has("type") and data.type == "laser":
			if data.has("color_idx"):
				node.color_idx = data.color_idx

			if data.has("global_position"):
				var target_pos: Vector2 = data.global_position

				node.tree_entered.connect(
					func():
						node.position = Vector2.ZERO
						node.global_position = target_pos
				)
			return node

		if data.has("ufo_idx"):
			if "ufo_index_sync" in node:
				node.ufo_index_sync = data.ufo_idx
			if node.has_node("Ufo"):
				node.get_node("Ufo").ufo_idx = data.ufo_idx
			if node.has_node("Alien"):
				var alien_node = node.get_node("Alien")
				alien_node.ufo_idx = data.ufo_idx

		if node is Skeptic and data.has("is_male"):
			node.is_male = data.is_male

		if node.has_node("PlayerInput"):
			node.get_node("PlayerInput").set_multiplayer_authority(data.peer_id)
		elif node.has_node("PlayerInputSynchronizer"):
			node.get_node("PlayerInputSynchronizer").set_multiplayer_authority(data.peer_id)

		if node.get_multiplayer_authority() == multiplayer.get_unique_id():
			for old_local in get_tree().get_nodes_in_group("local_player"):
				old_local.remove_from_group("local_player")
			node.add_to_group("local_player")

		assign_to_group(data, node)
		return node


func assign_to_group(data, node):
	if data.has("type"):
		match data.type:
			"ufo":
				node.add_to_group("ufos")
			"skeptic":
				node.add_to_group("skeptics")


func get_local_player() -> Player:
	var my_id = multiplayer.get_unique_id()
	var all_players = get_tree().get_nodes_in_group("ufos") + get_tree().get_nodes_in_group("skeptics")

	for player in all_players:
		if player is Player and player.id == my_id:
			return player

	return null
