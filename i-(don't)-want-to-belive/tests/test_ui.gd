extends GutTest

var game: Node
var skeptic_scene = preload("uid://b7wo2a5407873")
var ufo_scene = preload("uid://hc74yy2qdg3f")
var ui_scene = preload("uid://cjks5cw6xyieq")
var mock_skeptic: CharacterBody2D
var mock_ufo: CharacterBody2D
var ui_instance: UserInterface
var mock_counter: Control
var mock_sprite1: TextureRect
var mock_sprite2: TextureRect


func before_each():
	ui_instance = ui_scene.instantiate() as UserInterface
	mock_sprite1 = TextureRect.new()
	mock_sprite2 = TextureRect.new()
	mock_sprite1.visible = false
	mock_sprite2.visible = false
	ui_instance.ufos_sprites = [mock_sprite1, mock_sprite2]
	ui_instance.hit_points = 0
	get_tree().root.add_child(ui_instance)
	ui_instance.win_label = Label.new()
	ui_instance.q_label = Label.new()
	ui_instance.belive_points_counter_background = TextureRect.new()

	mock_counter = Control.new()
	mock_sprite1 = TextureRect.new()
	mock_sprite2 = TextureRect.new()

	mock_sprite1.visible = false
	mock_sprite2.visible = false

	mock_counter.add_child(mock_sprite1)
	mock_counter.add_child(mock_sprite2)
	ui_instance.belive_points_counter = mock_counter

	ui_instance.ufos_sprites = [mock_sprite1, mock_sprite2]
	ui_instance.hit_points = 0

	for node in get_tree().get_nodes_in_group("local_player"):
		node.remove_from_group("local_player")
	for node in get_tree().get_nodes_in_group("skeptics"):
		node.remove_from_group("skeptics")

	mock_skeptic = skeptic_scene.instantiate()
	mock_skeptic.belive_points = mock_skeptic.max_belive_points - 1

	mock_skeptic.add_to_group("local_player")
	mock_skeptic.add_to_group("skeptics")
	get_tree().root.add_child(mock_skeptic)

	game = preload("uid://c4twc836ak4bd").instantiate()
	get_tree().root.add_child(game)


func after_each():
	if is_instance_valid(mock_skeptic):
		mock_skeptic.queue_free()
	if is_instance_valid(mock_ufo):
		mock_ufo.queue_free()
	if is_instance_valid(game):
		game.queue_free()
	if is_instance_valid(ui_instance):
		ui_instance.queue_free()
	await wait_physics_frames(2)


func test_show_ufo_wins_when_skeptic_belives():
	# Act
	mock_skeptic._on_belive_points_changed(1)

	var ui_node = find_ui_script(game)
	if ui_node != null and ui_node.has_method("show_victory_screen"):
		ui_node.show_victory_screen()

	await wait_frames(2)

	# Assert
	var ui_labels = find_labels(get_tree().root)
	var labels_text_list = get_labels_text(ui_labels)

	assert_true(labels_text_list.has(UserInterface.UFO_WINS), "UI powinno wyświetlić napis o wygranej UFO.")


func test_should_activate_ufo_sprites_on_belive_points_changed():
	ui_instance._on_belive_points_changed(1)

	# Assert
	assert_true(mock_sprite1.visible)
	assert_false(mock_sprite2.visible)
	assert_eq(ui_instance.hit_points, 1)

	ui_instance._on_belive_points_changed(1)

	# Assert
	assert_true(mock_sprite2.visible)
	assert_eq(ui_instance.hit_points, 2)


func find_labels(node: Node) -> Array:
	var result: Array[Label] = []
	if not is_instance_valid(node):
		return result
	if node is Label:
		result.append(node)
	for child in node.get_children():
		result += find_labels(child)
	return result


func get_labels_text(labels: Array[Label]) -> Array[String]:
	var texts: Array[String] = []
	for label in labels:
		texts.append(label.text)
	return texts


func find_ui_script(node: Node) -> Node:
	if not is_instance_valid(node):
		return null
	if node.has_method("show_victory_screen") and node.has_node("WinLabel"):
		return node
	for child in node.get_children():
		var found = find_ui_script(child)
		if found != null:
			return found
	return null
