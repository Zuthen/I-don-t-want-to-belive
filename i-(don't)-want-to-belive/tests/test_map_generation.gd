extends GutTest



func test_bush_created():
	var game: PackedScene = preload("uid://c4twc836ak4bd")
	var test_game = autoqfree(game.instantiate())
	add_child(test_game)
	test_game.create_bush(Vector2i.ZERO)
	var obstacles = test_game.paths
	assert_true(!obstacles.is_empty())
	test_game.queue_free()
