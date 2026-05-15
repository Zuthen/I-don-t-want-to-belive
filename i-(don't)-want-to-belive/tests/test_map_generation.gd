extends GutTest

var game

func before_each():
	game = preload("uid://c4twc836ak4bd").instantiate()
	add_child_autofree(game)
	await get_tree().process_frame


func test_directions():
	var expected = {
		"up": Vector2i(0, -8),
		"down": Vector2i(0, 8),
		"left": Vector2i(-8, 0),
		"right": Vector2i(8, 0)
	}

	var sut = game.directions(8)

	assert_eq(sut, expected)
