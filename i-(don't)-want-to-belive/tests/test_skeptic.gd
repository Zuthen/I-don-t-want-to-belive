extends GutTest

var game: Node
var skeptic_scene = preload("uid://b7wo2a5407873")
var mock_skeptic: CharacterBody2D
var other_skeptic: CharacterBody2D


func before_each():
	game = preload("uid://c4twc836ak4bd").instantiate()
	game.name = "Game"
	get_tree().root.add_child(game)

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

	await wait_physics_frames(2)


func test_player_can_call_other_player():
	# Arrange
	mock_skeptic = skeptic_scene.instantiate()
	get_tree().root.add_child(mock_skeptic)

	other_skeptic = skeptic_scene.instantiate()
	get_tree().root.add_child(other_skeptic)

	# Act
	mock_skeptic.call_other_skeptic()
	var icons = []
	var attempts = 0
	while icons.size() == 0 and attempts < 10:
		await wait_physics_frames(1)
		icons = find_all_icons_in_engine(get_tree().root)
		attempts += 1

	# Assert
	assert_gt(icons.size(), 0)


func test_player_can_t_call_outside_range_size():
	# Arrange
	mock_skeptic = skeptic_scene.instantiate()
	get_tree().root.add_child(mock_skeptic)
	mock_skeptic.global_position = Vector2(99999, 99999)

	# Act
	mock_skeptic.call_other_skeptic()
	await wait_physics_frames(5)

	# Assert
	var icons = find_all_icons_in_engine(get_tree().root)
	assert_eq(icons.size(), 0)


func test_walkie_talkie_adds_message_to_ui_for_everyone():
	await wait_physics_frames(1)

	var canvas = game.get_node_or_null("CanvasLayer")
	if not canvas:
		fail_test("missing canvas layer")
		return

	var initial_child_count = canvas.get_child_count()

	mock_skeptic = skeptic_scene.instantiate()
	game.add_child(mock_skeptic)

	await wait_physics_frames(1)

	# Act
	mock_skeptic.send_walkie_talkie_message("C15")
	await wait_physics_frames(2)

	# Assert
	assert_eq(
		canvas.get_child_count(),
		initial_child_count + 1,
	)

	var last_child = canvas.get_child(canvas.get_child_count() - 1)

	if "coordinates_text" in last_child:
		assert_eq(
			last_child.coordinates_text,
			"C15",
		)
	else:
		var found_prop := false
		for child in last_child.get_children():
			if "coordinates_text" in child:
				assert_eq(child.coordinates_text, "C15")
				found_prop = true
				break
		if not found_prop:
			fail_test("no prop")


func find_all_icons_in_engine(node: Node) -> Array:
	var result = []
	if not is_instance_valid(node):
		return result
	if node is IconPlaceholder:
		result.append(node)
	for child in node.get_children():
		result += find_all_icons_in_engine(child)
	return result
