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
	for node in get_tree().get_nodes_in_group("local_player"):
		if is_instance_valid(node):
			node.remove_from_group("local_player")
	for node in get_tree().get_nodes_in_group("skeptics"):
		if is_instance_valid(node):
			node.remove_from_group("skeptics")

	mock_skeptic = skeptic_scene.instantiate()
	mock_skeptic.belive_points = mock_skeptic.max_belive_points - 1
	mock_skeptic.add_to_group("local_player")
	mock_skeptic.add_to_group("skeptics")
	get_tree().root.add_child(mock_skeptic)

	ui_instance = ui_scene.instantiate() as UserInterface
	get_tree().root.add_child(ui_instance)

	mock_counter = ui_instance.belive_points_counter
	mock_sprite1 = TextureRect.new()
	mock_sprite2 = TextureRect.new()
	mock_sprite1.visible = false
	mock_sprite2.visible = false

	for child in mock_counter.get_children():
		child.queue_free()
	mock_counter.add_child(mock_sprite1)
	mock_counter.add_child(mock_sprite2)

	ui_instance.ufos_sprites = [mock_sprite1, mock_sprite2]
	ui_instance.hit_points = 0


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
	ui_instance.show_ufo_victory_screen()

	await wait_frames(2)

	assert_true(ui_instance.win_label.visible)
	assert_eq(ui_instance.win_label.text, UserInterface.UFO_WINS)


func test_show_skeptic_wins_when_skeptics_find_other():
	# Arrange
	var mock_other_area = Area2D.new()
	var mock_other_skeptic = skeptic_scene.instantiate()
	mock_other_skeptic.add_child(mock_other_area)
	get_tree().root.add_child(mock_other_skeptic)

	# Act
	mock_skeptic._on_skeptic_find_other_skeptic(mock_other_area)
	ui_instance.show_skeptics_victory_screen()

	await wait_frames(2)

	assert_true(ui_instance.win_label.visible)
	assert_eq(ui_instance.win_label.text, UserInterface.SKEPTICS_WIN)

	mock_other_skeptic.queue_free()


func test_should_activate_ufo_sprites_on_belive_points_changed():
	ui_instance._on_belive_points_changed(1)

	assert_true(mock_sprite1.visible)
	assert_false(mock_sprite2.visible)
	assert_eq(ui_instance.hit_points, 1)

	ui_instance._on_belive_points_changed(1)

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
