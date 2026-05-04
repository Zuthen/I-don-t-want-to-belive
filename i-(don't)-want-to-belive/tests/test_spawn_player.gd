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

func test_find_spawn_position():
	var test_game = arrange()
	# Act
	var spawn_position = test_game.find_spawn_position()
	var available_positions = test_game.spawn_points
	# Assert
	assert_true(available_positions.has(spawn_position))
	
func test_spawn_player():
	# Arrange
	var test_game = arrange()      
	
	# Act
	var spawn_position = test_game.find_spawn_position()
	test_game.spawn_player(spawn_position)
	
	# Assert
	var players = test_game.get_children().filter(func(n):
		return n is Player
	)
	assert_false(players.is_empty())
