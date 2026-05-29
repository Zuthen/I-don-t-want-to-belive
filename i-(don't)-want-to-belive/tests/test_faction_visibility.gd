extends GutTest

var skeptic_scene = preload("uid://b7wo2a5407873")
var ufo_scene = preload("uid://hc74yy2qdg3f")

var mock_skeptic: CharacterBody2D
var mock_ufo: CharacterBody2D
var another_skeptic: CharacterBody2D
var second_ufo: CharacterBody2D


func before_each():
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
	if is_instance_valid(mock_skeptic):
		mock_skeptic.queue_free()
	if is_instance_valid(mock_ufo):
		mock_ufo.queue_free()
	if is_instance_valid(another_skeptic):
		another_skeptic.queue_free()
	if is_instance_valid(second_ufo):
		second_ufo.queue_free()

	var leftover_lasers = find_all_lasers(get_tree().root)
	for laser in leftover_lasers:
		if is_instance_valid(laser):
			laser.queue_free()

	var leftover_icons = find_all_icons(get_tree().root)
	for icon in leftover_icons:
		if is_instance_valid(icon):
			icon.queue_free()

	await wait_physics_frames(2)


func test_ufo_hides_when_local_player_is_skeptic():
	# Arrange
	mock_skeptic = skeptic_scene.instantiate()
	mock_skeptic.add_to_group("skeptics")
	get_tree().root.add_child(mock_skeptic)
	mock_skeptic.set_multiplayer_authority(1)

	mock_ufo = ufo_scene.instantiate()
	mock_ufo.add_to_group("ufos")
	get_tree().root.add_child(mock_ufo)
	mock_ufo.set_multiplayer_authority(2)

	#Act
	await wait_frames(2)
	await wait_physics_frames(2)

	# Assert
	assert_false(mock_ufo.visible)


func test_skeptic_hides_when_local_player_is_ufo():
	# Arrange
	mock_ufo = ufo_scene.instantiate()
	mock_ufo.add_to_group("ufos")
	mock_ufo.input_multiplayer_authority = 1
	get_tree().root.add_child(mock_ufo)

	# Act
	mock_skeptic = skeptic_scene.instantiate()
	mock_skeptic.add_to_group("skeptics")
	mock_skeptic.input_multiplayer_authority = 999
	get_tree().root.add_child(mock_skeptic)

	await wait_frames(2)

	# Assert
	assert_false(mock_skeptic.visible)


func test_skeptics_see_each_other():
	# Arrange
	mock_skeptic = skeptic_scene.instantiate()
	mock_skeptic.add_to_group("skeptics")
	mock_skeptic.add_to_group("local_player")
	get_tree().root.add_child(mock_skeptic)

	# Act
	another_skeptic = skeptic_scene.instantiate()
	another_skeptic.add_to_group("skeptics")
	get_tree().root.add_child(another_skeptic)

	# Assert
	assert_true(another_skeptic.visible)


func test_ufos_see_each_other():
	mock_ufo = ufo_scene.instantiate()
	mock_ufo.add_to_group("ufos")
	mock_ufo.add_to_group("local_player")
	get_tree().root.add_child(mock_ufo)

	# Act
	second_ufo = ufo_scene.instantiate()
	second_ufo.add_to_group("ufos")
	get_tree().root.add_child(second_ufo)

	# Assert
	assert_true(second_ufo.visible)


func test_as_ufo_i_can_see_my_laser():
	# Arrange
	mock_ufo = ufo_scene.instantiate()
	mock_ufo.add_to_group("ufos")
	mock_ufo.add_to_group("local_player")
	get_tree().root.add_child(mock_ufo)

	# Act
	mock_ufo.spawn_laser(Vector2.ZERO)

	# Assert
	var lasers = find_all_lasers(get_tree().root)
	assert_true(lasers.size() == 1)


func test_as_ufo_i_can_see_other_ufo_laser():
	# Arrange
	mock_ufo = ufo_scene.instantiate()
	mock_ufo.add_to_group("ufos")
	get_tree().root.add_child(mock_ufo)
	mock_ufo.set_multiplayer_authority(1)

	second_ufo = ufo_scene.instantiate()
	second_ufo.add_to_group("ufos")
	get_tree().root.add_child(second_ufo)
	second_ufo.set_multiplayer_authority(2)

	# Act
	second_ufo.server_spawn_laser(second_ufo.global_position)

	# Assert
	var lasers = find_all_lasers(get_tree().root)
	assert_true(lasers.size() == 1)


func test_as_skeptic_i_can_see_ufos_laser():
	# Arrange
	mock_skeptic = skeptic_scene.instantiate()
	mock_skeptic.add_to_group("skeptics")
	get_tree().root.add_child(mock_skeptic)
	mock_skeptic.set_multiplayer_authority(1)

	mock_ufo = ufo_scene.instantiate()
	mock_ufo.add_to_group("ufos")
	get_tree().root.add_child(mock_ufo)
	mock_ufo.set_multiplayer_authority(2)

	# Act
	mock_ufo.server_spawn_laser(mock_ufo.global_position)

	# Assert
	var lasers = find_all_lasers(get_tree().root)
	assert_true(lasers.size() == 1)


func test_as_ufo_i_cannot_see_skeptic_calls():
	# Arrange
	mock_skeptic = skeptic_scene.instantiate()
	mock_skeptic.set_multiplayer_authority(2)
	mock_skeptic.add_to_group("skeptics")
	get_tree().root.add_child(mock_skeptic)

	another_skeptic = skeptic_scene.instantiate()
	another_skeptic.set_multiplayer_authority(3)
	another_skeptic.add_to_group("skeptics")
	get_tree().root.add_child(another_skeptic)

	mock_ufo = ufo_scene.instantiate()
	mock_ufo.set_multiplayer_authority(1)
	mock_ufo.add_to_group("ufos")
	mock_ufo.add_to_group("local_player")
	get_tree().root.add_child(mock_ufo)

	# Act
	mock_skeptic.call_other_skeptic()

	await wait_physics_frames(5)

	# Assert
	var icons = find_all_icons(get_tree().root)
	for icon in icons:
		if icon is IconPlaceholder:
			icon.setup(MultiplayerFeatures.Role.UFO)
	var visible_icons = icons.filter(
		func(icon):
			var sprite = icon.get_node_or_null("Sprite2D") as Sprite2D
			if sprite != null:
				return sprite.visible and icon.is_visible_in_tree()
			return false
	)

	assert_eq(visible_icons.size(), 0)


func find_all_lasers(node: Node) -> Array:
	var result = []
	if not is_instance_valid(node):
		return result
	if node is UfoLaser:
		result.append(node)
	for child in node.get_children():
		result += find_all_lasers(child)
	return result


func find_all_icons(node: Node) -> Array:
	var result = []
	if not is_instance_valid(node):
		return result
	if node is IconPlaceholder:
		result.append(node)
	for child in node.get_children():
		result += find_all_icons(child)
	return result
