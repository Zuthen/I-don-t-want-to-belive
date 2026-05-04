extends GutTest

func arrange():
	# Arrange
	var game: PackedScene = preload("uid://c4twc836ak4bd")
	var test_game = autoqfree(game.instantiate())

	var cam = Camera2D.new()
	cam.name = "Camera2D"
	test_game.add_child(cam) 

	add_child(test_game) 
	return test_game

func test_bush_created():
	# Arrange
	var test_game = arrange()    
	
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
