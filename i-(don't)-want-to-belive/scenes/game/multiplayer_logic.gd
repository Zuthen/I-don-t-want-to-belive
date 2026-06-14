class_name Multiplayer
extends Node

var skeptic_scene: PackedScene = preload("uid://b7wo2a5407873")
var ufo_scene: PackedScene = preload("uid://m52fuwcrlo2k")
var crashed_ufo_scene = preload("uid://bddko8bky1tp7")
var laser_scene = preload("uid://dnsiqidfpctrc")


func spawn(multiplayer_spawner: MultiplayerSpawner, tile_map: TileMapLayer):
	multiplayer_spawner.spawn_function = func(data: Dictionary):
		if not data.has("type"):
			return null

		var node: Node = null
		var type = data.type

		match type:
			"ufo":
				node = ufo_scene.instantiate()
				node.role = Player.Role.UFO
				node.name = str(data.peer_id)
				node.id = data.peer_id
				node.input_multiplayer_authority = data.peer_id
			"skeptic":
				node = skeptic_scene.instantiate()
				node.role = Player.Role.SKEPTIC
				node.name = str(data.peer_id)
				node.id = data.peer_id
				node.input_multiplayer_authority = data.peer_id
			"wreck":
				node = crashed_ufo_scene.instantiate()
				node.name = "CrashedUfo_" + str(data.peer_id)
				node.peer_id = data.peer_id
			"laser":
				node = laser_scene.instantiate()
				node.z_index = 11
				node.name = "Laser"
			_:
				return null

		if data.has("spawn_position") and type != "laser":
			node.position = tile_map.map_to_local(data.spawn_position)

		match type:
			"wreck":
				if data.has("skin_idx"):
					node.ufo_texture_idx = data.skin_idx
				return node
			"laser":
				if data.has("color_idx"):
					node.color_idx = data.color_idx
				if data.has("global_position"):
					var target_pos: Vector2 = data.global_position
					node.tree_entered.connect(
						func():
							node.position = Vector2.ZERO
							node.global_position = target_pos,
						CONNECT_ONE_SHOT,
					)
				return node
			"ufo", "skeptic":
				if data.has("skin_idx"):
					_apply_skin(node, data.skin_idx)

		var synchronizer_path = "PlayerInput" if node.has_node("PlayerInput") else "PlayerInputSynchronizer"
		if node.has_node(synchronizer_path):
			node.get_node(synchronizer_path).set_multiplayer_authority(data.peer_id)

		if node.get_multiplayer_authority() == multiplayer.get_unique_id():
			get_tree().call_group("local_player", "remove_from_group", "local_player")
			node.add_to_group("local_player")

		assign_to_group(data, node)
		return node


func _apply_skin(node: Node, skin_idx: int):
	if "ufo_index_sync" in node:
		node.ufo_index_sync = skin_idx
	if node.has_node("Ufo"):
		node.get_node("Ufo").skin_idx = skin_idx
	if node.has_node("Alien"):
		node.get_node("Alien").skin_idx = skin_idx
	if node is Skeptic:
		node.animation_sprite_idx = skin_idx


func assign_to_group(data: Dictionary, node: Node):
	if data.has("type"):
		var group_name = data.type + "s"
		node.add_to_group(group_name)


func get_local_player() -> Player:
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return
	var my_id = multiplayer.get_unique_id()
	var all_players = get_tree().get_nodes_in_group("ufos") + get_tree().get_nodes_in_group("skeptics")

	for player in all_players:
		if player is Player and player.id == my_id:
			return player
	return null
