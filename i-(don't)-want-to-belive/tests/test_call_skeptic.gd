extends GutTest

var game


func before_each():
	game = preload("uid://c4twc836ak4bd").instantiate()
	add_child_autoqfree(game)
	await wait_physics_frames(2)


func after_each():
	# Czyścimy TileMapLayer z Godota 4, o którym rozmawialiśmy,
	# aby całkowicie zresetować fizykę kafelków między testami
	if is_instance_valid(game):
		for child in game.get_children():
			if child is TileMapLayer:
				child.update_internals()
				child.clear()
	game = null


func test_player_can_call_other_player():
	# Arrange
	var player = game.spawn_player(Vector2i(0, 0))
	game.spawn_player(Vector2i(2, 2))

	# Act
	player.call_other_skeptic()

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
	var player = game.spawn_player(Vector2i(0, 0))
	game.spawn_player(Vector2i(10, 10))

	# Act
	player.call_other_skeptic()

	# W teście negatywnym czekamy stałe 5 klatek fizyki,
	# dając silnikowi pełną szansę na ewentualne błędne wykrycie kolizji.
	await wait_physics_frames(5)

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
