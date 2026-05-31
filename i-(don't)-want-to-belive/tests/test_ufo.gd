extends GutTest

var ufo_scene = preload("uid://hc74yy2qdg3f")
var mock_ufo: Ufo # Używamy class_name Twojego Ufoka


func before_each():
	for node in get_tree().get_nodes_in_group("local_player"):
		if is_instance_valid(node):
			node.remove_from_group("local_player")
	for node in get_tree().get_nodes_in_group("ufos"):
		if is_instance_valid(node):
			node.remove_from_group("ufos")

	mock_ufo = ufo_scene.instantiate() as Ufo

	mock_ufo.add_to_group("local_player")
	mock_ufo.add_to_group("ufos")
	mock_ufo.set_multiplayer_authority(1)

	get_tree().root.add_child(mock_ufo)


func after_each():
	if is_instance_valid(mock_ufo):
		mock_ufo.queue_free()

	await wait_physics_frames(2)


func test_laser_cooldown_blocks_and_unblocks_shooting():
	assert_false(mock_ufo.laser_shoot_blocked)
	mock_ufo.fire_laser()

	assert_true(mock_ufo.laser_shoot_blocked)

	await wait_seconds(5.1)

	# Assert
	assert_false(mock_ufo.laser_shoot_blocked)
