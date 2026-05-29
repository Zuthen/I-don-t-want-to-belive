extends GutTest

var game: Node
var skeptic_scene = preload("uid://b7wo2a5407873")
var mock_skeptic: CharacterBody2D
var other_skeptic: CharacterBody2D


func before_each():
	game = preload("uid://c4twc836ak4bd").instantiate()
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
	get_tree().root.add_child(other_skeptic) # Dodany do drzewa, żeby test miał sens fizyczny

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


func find_all_icons_in_engine(node: Node) -> Array:
	var result = []
	if not is_instance_valid(node):
		return result
	if node is IconPlaceholder:
		result.append(node)
	for child in node.get_children():
		result += find_all_icons_in_engine(child)
	return result
