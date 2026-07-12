class_name Multiplayer
extends Node

var skeptic_scene: PackedScene = preload("uid://b7wo2a5407873")
var ufo_scene: PackedScene = preload("uid://m52fuwcrlo2k")
var crashed_ufo_scene = preload("uid://bddko8bky1tp7")
var laser_scene = preload("uid://dnsiqidfpctrc")
var collectible_scene = preload("uid://cvjiggvhnjfsh")
var icon_placeholder_scene: PackedScene = preload("uid://d03xota05sdvx")
var local_ui: UserInterface
var server_icon_cooldowns: Array[int] = []


func spawn(multiplayer_spawner: MultiplayerSpawner, tile_map: TileMapLayer):
	if not multiplayer_spawner.spawned.is_connected(_on_network_node_spawned):
		multiplayer_spawner.spawned.connect(_on_network_node_spawned)

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
			"icon":
				node = icon_placeholder_scene.instantiate()
				node.z_index = 15
				node.name = "LaserWarningIcon_" + str(randi())
				if data.has("global_position"):
					var target_pos: Vector2 = data.global_position
					node.net_target_pos = target_pos
					node.tree_entered.connect(
						func():
							node.position = Vector2.ZERO
							node.global_position = target_pos,
						CONNECT_ONE_SHOT,
					)
				node.net_icon_key = data.get("icon_key", "call")
				node.net_sender_id = data.get("sender_id", 0)
				node.net_target_id = data.get("target_id", 0)
				node.net_is_laser_type = data.get("is_laser_type", false)
				return node
			"collectable":
				node = collectible_scene.instantiate()
				node.name = "Collectable_" + str(randi())

				if data.get("name") == "repair_tool":
					node.texture = load("uid://mucvykffmbay")
					node.item_name = "repair_tool"
				if data.has("spawn_position"):
					var local_pos = tile_map.map_to_local(data.spawn_position)
					node.tree_entered.connect(func(): node.global_position = local_pos, CONNECT_ONE_SHOT)
				node.add_to_group("collectable_items")
				return node
			_:
				return null

		if data.has("spawn_position") and type != "laser" and type != "icon":
			var local_pos = tile_map.map_to_local(data.spawn_position)
			node.tree_entered.connect(func(): node.global_position = local_pos, CONNECT_ONE_SHOT)

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
				if data.has("peer_id"):
					node.peer_id = data.peer_id
				return node
			"ufo", "skeptic":
				if data.has("skin_idx"):
					_apply_skin(node, data.skin_idx)

		_assign_to_group(data, node)

		if data.peer_id == multiplayer.get_unique_id():
			get_tree().call_group("local_player", "remove_from_group", "local_player")
			node.add_to_group("local_player")

		node.name = str(data.peer_id)
		node.tree_entered.connect(
			func():
				node.set_multiplayer_authority(data.peer_id)

				var sync_node = node.get_node_or_null("PlayerInputSynchronizer")
				if is_instance_valid(sync_node):
					sync_node.set_multiplayer_authority(data.peer_id)

				var pos_sync = node.get_node_or_null("MultiplayerSynchronizer")
				if is_instance_valid(pos_sync):
					pos_sync.set_multiplayer_authority(data.peer_id),
			CONNECT_ONE_SHOT,
		)

		if multiplayer.is_server():
			call_deferred("_force_refresh_visibility")

		return node


func _force_refresh_visibility():
	get_tree().call_group("skeptics", "_update_visibility_for_local_player")
	get_tree().call_group("ufos", "_update_visibility_for_local_player")
	get_tree().call_group("aliens", "_update_visibility_for_local_player")


func _apply_skin(node: Node, skin_idx: int):
	if "ufo_index_sync" in node:
		node.ufo_index_sync = skin_idx
	if node.has_node("Ufo"):
		node.get_node("Ufo").skin_idx = skin_idx
	if node.has_node("Alien"):
		node.get_node("Alien").skin_idx = skin_idx
	if node is Skeptic:
		node.animation_sprite_idx = skin_idx


func _assign_to_group(data: Dictionary, node: Node):
	if data.has("type"):
		var group_name = data.type + "s"
		node.add_to_group(group_name)


func get_local_player() -> Player:
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return null
	var my_id = multiplayer.get_unique_id()
	var all_players = _get_all_players()

	for player in all_players:
		if player is Player and player.id == my_id:
			return player
	return null


func _get_all_players() -> Array[Node]:
	var all_players: Array[Node] = []
	all_players.append_array(get_tree().get_nodes_in_group("ufos"))
	all_players.append_array(get_tree().get_nodes_in_group("skeptics"))
	all_players.append_array(get_tree().get_nodes_in_group("aliens"))
	return all_players


@rpc("any_peer", "call_local", "reliable")
func broadcast_walkie_talkie(message_content: String):
	if is_instance_valid(local_ui):
		var sender_id = multiplayer.get_remote_sender_id()
		var my_id = multiplayer.get_unique_id()

		var label_type = "Nadana wiadomość:" if sender_id == my_id else "Odebrana wiadomość:"

		if is_instance_valid(local_ui.walkie_talkie_message):
			local_ui.walkie_talkie_message.setup(label_type, message_content)


func _on_network_node_spawned(_node: Node):
	await get_tree().process_frame
	await get_tree().process_frame
	_force_refresh_visibility()


func get_local_player_role() -> Player.Role:
	var local_hero = get_local_player()
	if is_instance_valid(local_hero) and "role" in local_hero:
		return local_hero.role
	return Player.Role.SKEPTIC
