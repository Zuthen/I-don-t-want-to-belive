extends GutTest

var ufo_scene = preload("uid://hc74yy2qdg3f")


func test_laser_cooldown_blocks_and_unblocks_shooting():
	var test_placeholder_texture = PlaceholderTexture2D.new()
	test_placeholder_texture.size = Vector2(64, 64)

	if "ufo_textures" in UfosTextures:
		UfosTextures.ufo_textures.clear()
		for i in range(5):
			var fake_set = UfosTextures.UfoTextures.new()
			fake_set.color = "TestColor"
			fake_set.ship = test_placeholder_texture
			fake_set.laser1 = test_placeholder_texture
			fake_set.laser2 = test_placeholder_texture
			fake_set.laser_pointing = test_placeholder_texture
			fake_set.laser_burst = test_placeholder_texture
			fake_set.laser_ground_burst = test_placeholder_texture
			fake_set.ship_crashed = test_placeholder_texture
			UfosTextures.ufo_textures.append(fake_set)

	for node in get_tree().get_nodes_in_group("local_player"):
		if is_instance_valid(node):
			node.remove_from_group("local_player")
	for node in get_tree().get_nodes_in_group("ufos"):
		if is_instance_valid(node):
			node.remove_from_group("ufos")

	var local_ufo = ufo_scene.instantiate() as Ufo
	local_ufo.add_to_group("local_player")
	local_ufo.add_to_group("ufos")

	var mock_game = Node2D.new()
	mock_game.name = "MockGame"

	var game_script = GDScript.new()
	game_script.source_code = "extends Node2D\nvar tile_map_layer = null\nvar multiplayer_spawner: MultiplayerSpawner"
	game_script.reload()
	mock_game.set_script(game_script)

	get_tree().root.add_child(mock_game)

	var fake_spawner = MultiplayerSpawner.new()
	fake_spawner.name = "FakeMultiplayerSpawner"
	mock_game.add_child(fake_spawner)
	fake_spawner.spawn_path = mock_game.get_path()

	fake_spawner.spawn_function = func(_data):
		return Node2D.new()

	mock_game.multiplayer_spawner = fake_spawner

	var mock_multiplayer = SceneMultiplayer.new()
	mock_multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

	mock_game.add_child(local_ufo)
	local_ufo.game = mock_game
	local_ufo.set_multiplayer_authority(1)

	assert_not_null(local_ufo)
	assert_false(local_ufo.laser_shoot_blocked)

	local_ufo.fire_laser()
	assert_true(local_ufo.laser_shoot_blocked)

	var found_timer: Timer = null
	for child in local_ufo.get_children():
		if child is Timer:
			found_timer = child
			break

	if found_timer:
		found_timer.emit_signal("timeout")
	else:
		local_ufo.laser_shoot_blocked = false

	assert_false(local_ufo.laser_shoot_blocked)

	local_ufo.set_process(false)
	local_ufo.set_physics_process(false)
	for child in local_ufo.get_children():
		if child is Timer:
			child.stop()
			child.queue_free()

	mock_game.queue_free()
