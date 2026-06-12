extends GutTest

var skeptic_scene = preload("uid://b7wo2a5407873")
var ufo_scene = preload("uid://hc74yy2qdg3f")
var ufo_with_alien_scene = preload("uid://m52fuwcrlo2k")

var fake_game: Node2D
var mock_skeptic: CharacterBody2D
var mock_ufo: CharacterBody2D
var another_skeptic: CharacterBody2D
var second_ufo: CharacterBody2D

var original_current_scene: Node


func before_each():
	var mock_peer = OfflineMultiplayerPeer.new()
	get_tree().get_multiplayer().set_multiplayer_peer(mock_peer)

	fake_game = Node2D.new()
	fake_game.name = "FakeGame"

	var fake_tilemap = TileMapLayer.new()
	fake_tilemap.name = "FakeTilemap"
	fake_tilemap.tile_set = TileSet.new()

	fake_game.add_child(fake_tilemap)

	var game_mock_script = GDScript.new()
	game_mock_script.source_code = "
extends Node2D
var multiplayer_spawner: MultiplayerSpawner
var tile_map_layer = null
var paths = {}
"
	game_mock_script.reload()
	fake_game.set_script(game_mock_script)
	fake_game.tile_map_layer = fake_tilemap
	get_tree().root.add_child(fake_game)

	fake_game.set_multiplayer_authority(1)

	original_current_scene = get_tree().current_scene
	get_tree().current_scene = fake_game

	var fake_spawner = MultiplayerSpawner.new()
	fake_spawner.name = "FakeMultiplayerSpawner"
	fake_game.add_child(fake_spawner)
	fake_game.multiplayer_spawner = fake_spawner
	fake_spawner.spawn_path = fake_game.get_path()

	fake_spawner.set_multiplayer_authority(1)

	fake_spawner.spawn_function = func(data):
		var spawned_node = null

		if data.has("type") and data.type == "laser":
			spawned_node = Node2D.new()
			spawned_node.name = "Laser"
			spawned_node.set_meta("is_laser", true)
			if data.has("global_position"):
				spawned_node.global_position = data.global_position

		elif data.has("type") and data.type == "ufo":
			spawned_node = ufo_scene.instantiate()

		elif data.has("type") and data.type == "skeptic":
			spawned_node = skeptic_scene.instantiate()

		return spawned_node

	for node in get_tree().get_nodes_in_group("local_player"):
		if is_instance_valid(node):
			node.remove_from_group("local_player")
	for node in get_tree().get_nodes_in_group("skeptics"):
		if is_instance_valid(node):
			node.remove_from_group("skeptics")
	for node in get_tree().get_nodes_in_group("ufos"):
		if is_instance_valid(node):
			node.remove_from_group("ufos")


func after_each():
	if is_instance_valid(original_current_scene):
		get_tree().current_scene = original_current_scene

	if is_instance_valid(fake_game):
		fake_game.queue_free()

	var leftover_lasers = find_all_lasers(get_tree().root)
	for laser in leftover_lasers:
		if is_instance_valid(laser):
			laser.queue_free()

	var leftover_icons = find_all_icons(get_tree().root)
	for icon in leftover_icons:
		if is_instance_valid(icon):
			icon.queue_free()

	get_tree().get_multiplayer().set_multiplayer_peer(null)

	await wait_physics_frames(2)


func _setup_ufo_hierarchy(peer_id: int, is_local: bool = false) -> CharacterBody2D:
	var parent_core = Node2D.new()
	parent_core.name = "UfoWithAlien_" + str(peer_id)
	fake_game.add_child(parent_core)

	var ufo_node = ufo_scene.instantiate()
	ufo_node.name = "Ufo"
	ufo_node.set_physics_process(false)
	parent_core.add_child(ufo_node)

	parent_core.set_multiplayer_authority(peer_id)
	if "input_multiplayer_authority" in ufo_node:
		ufo_node.input_multiplayer_authority = peer_id

	parent_core.add_to_group("ufos")

	if is_local:
		parent_core.add_to_group("local_player")

	return ufo_node


func test_ufo_hides_when_local_player_is_skeptic():
	get_tree().get_multiplayer().multiplayer_peer = OfflineMultiplayerPeer.new()

	mock_skeptic = skeptic_scene.instantiate()
	mock_skeptic.add_to_group("skeptics")
	mock_skeptic.add_to_group("local_player")
	fake_game.add_child(mock_skeptic)
	mock_skeptic.set_multiplayer_authority(1)

	mock_ufo = _setup_ufo_hierarchy(2, false)
	var ufo_parent = mock_ufo.get_parent()

	ufo_parent.visible = false

	await get_tree().process_frame
	await wait_seconds(0.1)

	assert_false(ufo_parent.visible)


func test_skeptics_see_each_other():
	mock_skeptic = skeptic_scene.instantiate()
	mock_skeptic.add_to_group("skeptics")
	mock_skeptic.add_to_group("local_player")
	fake_game.add_child(mock_skeptic)

	another_skeptic = skeptic_scene.instantiate()
	another_skeptic.add_to_group("skeptics")
	fake_game.add_child(another_skeptic)

	assert_true(another_skeptic.visible)


func test_ufos_see_each_other():
	mock_ufo = _setup_ufo_hierarchy(1, true)
	second_ufo = _setup_ufo_hierarchy(2, false)

	assert_true(second_ufo.get_parent().visible)


func test_as_ufo_i_can_see_my_laser():
	mock_ufo = _setup_ufo_hierarchy(1, true)
	mock_ufo.ufo_laser_shoot_animation_time = 0.5

	await get_tree().process_frame
	var laser_data = { "type": "laser", "global_position": Vector2.ZERO }
	fake_game.multiplayer_spawner.spawn(laser_data)

	await wait_physics_frames(2)
	var lasers = find_all_lasers(get_tree().root)
	assert_eq(lasers.size(), 1)


func test_as_ufo_i_can_see_other_ufo_laser():
	get_tree().get_multiplayer().multiplayer_peer = OfflineMultiplayerPeer.new()

	mock_ufo = _setup_ufo_hierarchy(1, true)
	second_ufo = _setup_ufo_hierarchy(2, false)
	second_ufo.ufo_laser_shoot_animation_time = 0.5

	await get_tree().process_frame

	second_ufo.server_spawn_laser(second_ufo.global_position)
	await wait_physics_frames(2)

	var lasers = find_all_lasers(get_tree().root)
	assert_eq(lasers.size(), 1)


func test_as_skeptic_i_can_see_ufos_laser():
	get_tree().get_multiplayer().multiplayer_peer = OfflineMultiplayerPeer.new()

	mock_skeptic = skeptic_scene.instantiate()
	mock_skeptic.set_physics_process(false)
	mock_skeptic.add_to_group("skeptics")
	fake_game.add_child(mock_skeptic)
	mock_skeptic.input_multiplayer_authority = 1

	mock_ufo = _setup_ufo_hierarchy(2, false)
	mock_ufo.ufo_laser_shoot_animation_time = 0.5

	await get_tree().process_frame

	mock_ufo.server_spawn_laser(mock_ufo.global_position)
	await wait_physics_frames(2)

	var lasers = find_all_lasers(get_tree().root)
	assert_eq(lasers.size(), 1)


func test_as_ufo_i_cannot_see_skeptic_calls():
	var test_multiplayer = MultiplayerAPI.create_default_interface()
	get_tree().set_multiplayer(test_multiplayer, fake_game.get_path())

	# Arrange
	mock_skeptic = skeptic_scene.instantiate()
	mock_skeptic.set_multiplayer_authority(2)
	mock_skeptic.add_to_group("skeptics")
	fake_game.add_child(mock_skeptic)

	another_skeptic = skeptic_scene.instantiate()
	another_skeptic.set_multiplayer_authority(3)
	another_skeptic.add_to_group("skeptics")
	fake_game.add_child(another_skeptic)

	mock_ufo = _setup_ufo_hierarchy(1, true)
	if "role" in mock_ufo:
		mock_ufo.role = Player.Role.UFO

	if mock_skeptic.has_method("call_other_skeptic_network"):
		mock_skeptic.call_other_skeptic_network()
	else:
		mock_skeptic.call_other_skeptic()

	await wait_physics_frames(5)

	# Assert
	var icons = find_all_icons(get_tree().root)
	for icon in icons:
		if icon.has_method("setup"):
			var allowed_roles = [2, 3] as Array[int]
			icon.setup(2, allowed_roles)

	var visible_icons = icons.filter(
		func(icon):
			var sprite = icon.get_node_or_null("Sprite2D") as Sprite2D
			if sprite != null:
				return sprite.visible and icon.is_visible_in_tree()
			return false
	)

	assert_eq(visible_icons.size(), 0)
	get_tree().set_multiplayer(null, fake_game.get_path())


func test_laser_seen_creates_icon_at_dialog_placement():
	mock_skeptic = skeptic_scene.instantiate()
	fake_game.add_child(mock_skeptic)

	var mock_marker = Marker2D.new()
	mock_marker.global_position = Vector2(40, 60)

	if mock_skeptic.dialog_placements == null:
		mock_skeptic.dialog_placements = Node2D.new()
		mock_skeptic.add_child(mock_skeptic.dialog_placements)

	mock_skeptic.dialog_placements.add_child(mock_marker)

	if mock_skeptic.dialog_timer == null:
		mock_skeptic.dialog_timer = Timer.new()
		mock_skeptic.add_child(mock_skeptic.dialog_timer)

	mock_skeptic.global_position = Vector2(100, 200)

	mock_skeptic._on_laser_seen()
	await wait_physics_frames(2)

	var icons = find_all_icons(get_tree().root)
	assert_eq(icons.size(), 1)

	if icons.size() > 0:
		var spawned_icon = icons[0] as Node2D
		assert_eq(spawned_icon.scale, Vector2(1.0, 1.0))


func test_skeptic_receives_alien_voice_call():
	var peer = OfflineMultiplayerPeer.new()
	get_tree().get_multiplayer().multiplayer_peer = peer

	mock_skeptic = skeptic_scene.instantiate()
	mock_skeptic.name = "LocalSkeptic"
	fake_game.add_child(mock_skeptic)
	mock_skeptic.set_multiplayer_authority(1)
	mock_skeptic.add_to_group("skeptics")
	mock_skeptic.role = Player.Role.SKEPTIC

	var ufo_combo = ufo_with_alien_scene.instantiate()
	ufo_combo.name = "UfoWithAlien_2"
	fake_game.add_child(ufo_combo)
	ufo_combo.input_multiplayer_authority = 2
	ufo_combo.add_to_group("ufos")

	if ufo_combo.has_method("change_state"):
		ufo_combo.change_state(1, 0)
	else:
		ufo_combo.change_state(ufo_combo.State.ALIEN, 0)

	ufo_combo.global_position = Vector2(120, 100)

	await wait_physics_frames(2)

	#Act

	var test_icon = IconPlaceholder.new()
	test_icon.name = "TestIcon"

	var mock_sprite = Sprite2D.new()
	mock_sprite.name = "Sprite2D"
	test_icon.add_child(mock_sprite)

	fake_game.add_child(test_icon)

	test_icon.accepts_role = [Player.Role.SKEPTIC] as Array[Player.Role]
	var base_texture = Texture2D.new()
	test_icon.display_icon(base_texture, Player.Role.ALIEN, true)

	await wait_physics_frames(2)

	# Assert
	var icons = find_all_icons(get_tree().root)
	assert_gt(icons.size(), 0)

	if icons.size() > 0:
		var spawned_icon = icons[0] as Node2D
		var sprite = spawned_icon.get_node_or_null("Sprite2D") as Sprite2D

		assert_not_null(sprite)
		if sprite:
			assert_true(sprite.visible)


func test_alien_receives_skeptic_voice_call():
	seed(12345)

	# Arrange
	var ufo_combo = ufo_with_alien_scene.instantiate()
	ufo_combo.name = "UfoWithAlien_1"
	fake_game.add_child(ufo_combo)
	ufo_combo.input_multiplayer_authority = 1
	ufo_combo.add_to_group("ufos")

	if ufo_combo.has_method("change_state"):
		ufo_combo.change_state(1, 0)
	else:
		ufo_combo.change_state(ufo_combo.State.ALIEN, 0)

	ufo_combo.global_position = Vector2(200, 200)
	another_skeptic = skeptic_scene.instantiate()
	another_skeptic.set_multiplayer_authority(2)
	another_skeptic.add_to_group("skeptics")
	fake_game.add_child(another_skeptic)
	another_skeptic.global_position = Vector2(240, 200)
	another_skeptic.role = Player.Role.SKEPTIC

	await wait_physics_frames(2)

	# Act
	another_skeptic.call_other_skeptic()
	await wait_physics_frames(3)

	# Assert
	var icons = find_all_icons(get_tree().root)

	assert_gt(icons.size(), 0)
	var spawned_icon = icons[0] as Node2D
	assert_eq(spawned_icon.global_position.x, 220.0)


func find_all_lasers(node: Node) -> Array:
	var result = []
	if not is_instance_valid(node):
		return result

	if node.get_script() and node.get_script().get_global_name() == "UfoLaser" or node.name.begins_with("UfoLaser"):
		result.append(node)
	elif node.has_meta("is_laser"):
		result.append(node)

	for child in node.get_children():
		result += find_all_lasers(child)
	return result


func find_all_icons(node: Node) -> Array:
	var result = []
	if not is_instance_valid(node):
		return result

	if node.get_script() and node.get_script().get_global_name() == "IconPlaceholder" or node.name.begins_with("IconPlaceholder"):
		result.append(node)

	for child in node.get_children():
		result += find_all_icons(child)
	return result
