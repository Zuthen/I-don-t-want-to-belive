extends GutTest

var game: PackedScene = preload("uid://c4twc836ak4bd")

func test_bush_created():
	var test_game = game.instantiate()
	add_child(test_game)
	test_game.create_bush(0,0)
	var obstacles = test_game.paths
	assert_true(!obstacles.is_empty())
