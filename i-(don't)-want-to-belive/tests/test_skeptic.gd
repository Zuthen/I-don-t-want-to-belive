extends GutTest

var game: Node
var skeptic_scene = preload("uid://b7wo2a5407873")
var mock_skeptic: CharacterBody2D
var other_skeptic: CharacterBody2D
var mock_spawner: MultiplayerSpawner


func before_each():
	var mock_peer = OfflineMultiplayerPeer.new()
	get_tree().get_multiplayer().set_multiplayer_peer(mock_peer)

	game = preload("uid://c4twc836ak4bd").instantiate()
	game.name = "Game"
	get_tree().root.add_child(game)
	get_tree().current_scene = game

	mock_spawner = MultiplayerSpawner.new()
	mock_spawner.name = "MultiplayerSpawner"
	game.add_child(mock_spawner)

	if "server_icon_cooldowns" in MultiplayerFeatures:
		MultiplayerFeatures.server_icon_cooldowns.clear()

	for node in get_tree().get_nodes_in_group("local_player"):
		node.remove_from_group("local_player")


func after_each():
	var leftover_icons = find_all_icons_in_engine(get_tree().root)
	for icon in leftover_icons:
		if is_instance_valid(icon):
			icon.free()

	if is_instance_valid(mock_skeptic):
		mock_skeptic.queue_free()
	if is_instance_valid(other_skeptic):
		other_skeptic.queue_free()
	if is_instance_valid(game):
		game.queue_free()

	get_tree().get_multiplayer().set_multiplayer_peer(null)
	await wait_physics_frames(2)


func test_player_can_call_other_player():
	# Arrange
	mock_skeptic = skeptic_scene.instantiate()
	mock_skeptic.id = 1
	mock_skeptic.role = Player.Role.SKEPTIC
	mock_skeptic.add_to_group("skeptics")
	game.add_child(mock_skeptic)

	other_skeptic = skeptic_scene.instantiate()
	other_skeptic.id = 2
	other_skeptic.role = Player.Role.SKEPTIC
	other_skeptic.add_to_group("skeptics")
	game.add_child(other_skeptic)

	await wait_physics_frames(3)

	mock_spawner.spawn_function = func(data):
		var icon_scene = preload("uid://d03xota05sdvx")
		var node = icon_scene.instantiate()
		node.name = "LaserWarningIcon_Test"
		node.net_target_pos = data.get("global_position", Vector2.ZERO)
		node.net_icon_key = data.get("icon_key", "call")
		node.net_sender_id = data.get("sender_id", 0)
		node.net_target_id = data.get("target_id", 0)
		node.net_is_laser_type = data.get("is_laser_type", false)
		get_tree().root.add_child(node)
		return node

	# Act
	mock_skeptic.call_other_skeptic()

	await wait_physics_frames(5)
	var icons = find_all_icons_in_engine(get_tree().root)

	# Assert
	assert_gt(icons.size(), 0, "Ikona wezwania nie pojawiła się w drzewie sceny!")


func test_player_can_t_call_outside_range_size():
	# Arrange
	mock_skeptic = skeptic_scene.instantiate()
	mock_skeptic.id = 1
	mock_skeptic.role = Player.Role.SKEPTIC
	mock_skeptic.add_to_group("skeptics")
	game.add_child(mock_skeptic)
	mock_skeptic.global_position = Vector2(0, 0)

	other_skeptic = skeptic_scene.instantiate()
	other_skeptic.id = 2
	other_skeptic.role = Player.Role.SKEPTIC
	other_skeptic.add_to_group("skeptics")
	game.add_child(other_skeptic)
	other_skeptic.global_position = Vector2(99999, 99999)

	await wait_physics_frames(3)

	mock_spawner.spawn_function = func(data):
		var icon_scene = preload("uid://d03xota05sdvx")
		var node = icon_scene.instantiate()
		node.net_target_pos = data.get("global_position", Vector2.ZERO)
		node.net_icon_key = data.get("icon_key", "call")
		node.net_sender_id = data.get("sender_id", 0)
		node.net_target_id = data.get("target_id", 0)
		node.net_is_laser_type = data.get("is_laser_type", false)
		get_tree().root.add_child(node)
		return node

	# Act:
	mock_skeptic.call_other_skeptic()
	await wait_physics_frames(5)

	# Assert:
	var icons = find_all_icons_in_engine(get_tree().root)
	assert_eq(icons.size(), 0, "Gracze byli za daleko! Spawner nie miał prawa wygenerować ikony!")


func test_walkie_talkie_adds_message_to_ui_for_everyone():
	await wait_physics_frames(2)

	var ui_scene = preload("uid://cjks5cw6xyieq")
	var mock_ui = ui_scene.instantiate()
	mock_ui.name = "UserInterface"
	game.add_child(mock_ui)

	mock_ui.set_multiplayer_authority(1)
	mock_ui.walkie_talkie_message.visible = false

	mock_skeptic = skeptic_scene.instantiate()
	mock_skeptic.id = 1
	mock_skeptic.set_multiplayer_authority(1)
	mock_skeptic.add_to_group("skeptics")
	game.add_child(mock_skeptic)

	await wait_physics_frames(4)

	MultiplayerFeatures.local_ui = mock_ui

	if mock_ui.has_method("receive_walkie_talkie_message"):
		mock_ui.receive_walkie_talkie_message("C15")
	else:
		mock_skeptic.send_walkie_talkie_message("C15")

	await wait_physics_frames(5)

	# Assert
	var walkie_talkie_ui_component = mock_ui.walkie_talkie_message
	assert_true(walkie_talkie_ui_component.visible, "Komponent WalkieTalkieMessage powinien być widoczny na ekranie!")
	assert_eq(walkie_talkie_ui_component.coordinates_text, "C15", "Współrzędne w UI nie pasują do wysłanej wiadomości!")


func find_all_icons_in_engine(node: Node) -> Array:
	var result = []
	if not is_instance_valid(node):
		return result
	if node is IconPlaceholder:
		result.append(node)
	for child in node.get_children():
		result += find_all_icons_in_engine(child)
	return result
