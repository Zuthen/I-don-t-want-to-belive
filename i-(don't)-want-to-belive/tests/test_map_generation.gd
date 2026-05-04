extends GutTest

func test_bush_created():
	# Arrange
	var game: PackedScene = preload("uid://c4twc836ak4bd")
	var test_game = autoqfree(game.instantiate())
	add_child(test_game)
	# Act
	test_game.create_bush(Vector2i.ZERO)
	var obstacles = test_game.paths
#	Assert
	assert_true(!obstacles.is_empty())

func test_directions():
#	Arrange
	var game: PackedScene = preload("uid://c4twc836ak4bd")
	var test_game = autoqfree(game.instantiate())
	var expected: Dictionary = {
		"up": Vector2i(0, -8),
		"down": Vector2i(0, 8),
		"left": Vector2i(-8, 0),
		"right":Vector2i(8, 0)
	}
# 	Act
	var sut = test_game.directions(8)
# Assert
	assert_eq(sut, expected)
