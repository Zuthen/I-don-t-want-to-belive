extends GutTest

var game


func before_each():
	game = preload("uid://c4twc836ak4bd").instantiate()
	add_child_autoqfree(game)
	await wait_physics_frames(2)


func after_each():
	game = null
	await wait_physics_frames(2)


func test_player_can_call_other_player():
	# Arrange
	var player = autoqfree(game.spawn_player(Vector2i(0, 0)))
	var second_player = autoqfree(game.spawn_player(Vector2i(2, 2)))

	# Act
	player.call_other_skeptic()
	await wait_physics_frames(3)

	# Assert
	var icons = find_all_icons_in_engine(get_tree().root)
	for icon in icons:
		autoqfree(icon)

	assert_gt(icons.size(), 0)


func test_player_can_t_call_outside_range_size():
	# Arrange
	var player = autoqfree(game.spawn_player(Vector2i(0, 0)))
	var second_player = autoqfree(game.spawn_player(Vector2i(10, 10)))

	# Act
	player.call_other_skeptic()
	await wait_physics_frames(3)

	# Assert
	var icons = find_all_icons_in_engine(get_tree().root)
	assert_eq(icons.size(), 0)


func find_all_icons_in_engine(node: Node) -> Array:
	var result = []
	if not is_instance_valid(node):
		return result
	if node is IconPlaceholder:
		result.append(node)
	for child in node.get_children():
		result += find_all_icons_in_engine(child)
	return result
