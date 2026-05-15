extends GutTest

var game
var container

func before_each():
	container = Node.new()
	get_tree().root.add_child(container)

	game = preload("uid://c4twc836ak4bd").instantiate()
	container.add_child(game)

	await get_tree().process_frame

func after_each():
	if is_instance_valid(container):
		container.queue_free()
		container = null
		game = null

	await get_tree().process_frame
	await get_tree().process_frame


func test_spawn_player():
	var spawn_position = Vector2i(2, 9)

	game.spawn_player(spawn_position)

	var players = game.get_children().filter(func(n):
		return n is Player
	)

	assert_gt(players.size(), 0)
