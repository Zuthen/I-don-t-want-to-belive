extends GutTest

var skeptic_scene = preload("uid://b7wo2a5407873")
var ufo_scene = preload("uid://hc74yy2qdg3f")

var mock_skeptic: CharacterBody2D
var mock_ufo: CharacterBody2D
var another_skeptic: CharacterBody2D
var second_ufo: CharacterBody2D


func before_each():
	for node in get_tree().get_nodes_in_group("local_player"):
		node.remove_from_group("local_player")
	for node in get_tree().get_nodes_in_group("skeptics"):
		node.remove_from_group("skeptics")
	for node in get_tree().get_nodes_in_group("ufos"):
		node.remove_from_group("ufos")


func after_each():
	if is_instance_valid(mock_skeptic):
		mock_skeptic.queue_free()
	if is_instance_valid(mock_ufo):
		mock_ufo.free()
	if is_instance_valid(another_skeptic):
		another_skeptic.queue_free()
	if is_instance_valid(second_ufo):
		second_ufo.queue_free()

	await wait_physics_frames(2)


func test_ufo_hides_when_local_player_is_skeptic():
	# Arrange
	mock_skeptic = skeptic_scene.instantiate()
	mock_skeptic.add_to_group("skeptics")
	mock_skeptic.add_to_group("local_player")
	get_tree().root.add_child(mock_skeptic)

	# Act
	mock_ufo = ufo_scene.instantiate()
	mock_ufo.add_to_group("ufos")
	get_tree().root.add_child(mock_ufo)

	# Assert
	assert_false(mock_ufo.visible, "UFO powinno być ukryte dla Sceptyka")


func test_skeptic_hides_when_local_player_is_ufo():
	# Arrange
	mock_ufo = ufo_scene.instantiate()
	mock_ufo.add_to_group("ufos")
	mock_ufo.add_to_group("local_player")
	get_tree().root.add_child(mock_ufo)

	# Act
	mock_skeptic = skeptic_scene.instantiate()
	mock_skeptic.add_to_group("skeptics")
	get_tree().root.add_child(mock_skeptic)

	# Assert
	assert_false(mock_skeptic.visible, "Sceptyk powinien być ukryte dla UFO")


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
	assert_true(another_skeptic.visible, "Sceptycy powinni widzieć siebie nawzajem")


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
	assert_true(second_ufo.visible, "UFO powinny widzieć inne UFO")
