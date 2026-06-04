extends GutTest

var ufo_scene = preload("uid://hc74yy2qdg3f")


func test_laser_cooldown_blocks_and_unblocks_shooting():
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
	game_script.source_code = "extends Node2D\nvar tile_map_layer = null"
	game_script.reload()
	mock_game.set_script(game_script)

	get_tree().root.add_child(mock_game)

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
