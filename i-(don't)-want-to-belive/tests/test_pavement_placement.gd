extends GutTest

func create_test_map(tile_map):
	var results = []
	for tile in tile_map:
		var borders := Pavement.get_neighbors(tile,tile_map)
		var result = Pavement.get_tile(borders)
		results.append(result)
	return results

func test_wide_pavement_borders():
	# Arrange
	var test_map : Array[Vector2i]= [Vector2i.LEFT + Vector2i.UP, Vector2i.UP, Vector2i.RIGHT +Vector2i.UP,
	Vector2i.LEFT, Vector2i.ZERO, Vector2i.RIGHT,
	Vector2i.LEFT + Vector2i.DOWN, Vector2i.DOWN,Vector2i.RIGHT+Vector2i.DOWN]
	
	# Act
	var results = create_test_map(test_map)
	# Assert
	assert_true(results.has(PavementTilesMap.wide_top_left))
	assert_true(results.has(PavementTilesMap.wide_top))
	assert_true(results.has(PavementTilesMap.wide_top_right))
	assert_true(results.has(PavementTilesMap.wide_left))
	assert_true(results.has(PavementTilesMap.wide_center))
	assert_true(results.has(PavementTilesMap.wide_right))
	assert_true(results.has(PavementTilesMap.wide_bottom_left))
	assert_true(results.has(PavementTilesMap.wide_bottom))
	assert_true(results.has(PavementTilesMap.wide_bottom_right))

func test_single_paths():
	#Arrange
	var test_map : Array[Vector2i]= [Vector2i.LEFT + Vector2i.UP, Vector2i.UP, Vector2i.RIGHT +Vector2i.UP,
	Vector2i.LEFT, Vector2i.RIGHT,
	Vector2i.LEFT + Vector2i.DOWN, Vector2i.DOWN,Vector2i.RIGHT+Vector2i.DOWN]
	#Act
	var results = create_test_map(test_map)
	#Assert
	assert_true(results.has(PavementTilesMap.top_left))
	assert_true(results.has(PavementTilesMap.top_right))
	assert_true(results.has(PavementTilesMap.bottom_left))
	assert_true(results.has(PavementTilesMap.bottom_right))
	assert_true(results.has(PavementTilesMap.left_right))
	assert_true(results.has(PavementTilesMap.top_bottom))
	
func test_single_horizontal_ends():
	#Arrange
	var left_right_end: Array[Vector2i] = [Vector2i.ZERO, Vector2i.RIGHT]
	
	#Act
	var horizontal = create_test_map(left_right_end)
	#Assert
	assert_true(horizontal.has(PavementTilesMap.left_end))
	assert_true(horizontal.has(PavementTilesMap.right_end))

func test_single_vertical_ends():
	#Arrange
	var top_bottom_end: Array[Vector2i] = [Vector2i.ZERO, Vector2i.UP]
	#Act
	var vertical = create_test_map(top_bottom_end)
	#Assert
	assert_true(vertical.has(PavementTilesMap.bottom_end))
	assert_true(vertical.has(PavementTilesMap.top_end))
	
func test_corners_right_bottom():
	#Arrange
	var paths: Array[Vector2i] = [Vector2i.ZERO,Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN,
	Vector2i.LEFT +Vector2i.UP,
	Vector2i.RIGHT+ Vector2i.UP,
	Vector2i.LEFT + Vector2i.DOWN]
	#Act
	var map = create_test_map(paths)
	#Assert
	assert_true(map.has(PavementTilesMap.corner_bottom_right))
func test_corners_left_bottom():
	#Arrange
	var paths: Array[Vector2i] = [Vector2i.ZERO,Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN,
	Vector2i.LEFT +Vector2i.UP,
	Vector2i.RIGHT+ Vector2i.UP,
	Vector2i.RIGHT + Vector2i.DOWN]
	#Act
	var map = create_test_map(paths)
	#Assert
	assert_true(map.has(PavementTilesMap.corner_bottom_left))
func test_corners_left_up():
	#Arrange
	var paths: Array[Vector2i] = [Vector2i.ZERO,Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN,
	Vector2i.LEFT +Vector2i.DOWN,
	Vector2i.RIGHT+ Vector2i.DOWN,
	Vector2i.RIGHT + Vector2i.UP]
	#Act
	var map = create_test_map(paths)
	#Assert
	assert_true(map.has(PavementTilesMap.corner_top_left))
func test_corners_right_up():
	#Arrange
	var paths: Array[Vector2i] = [Vector2i.ZERO,Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN,
	Vector2i.LEFT +Vector2i.DOWN,
	Vector2i.RIGHT+ Vector2i.DOWN,
	Vector2i.LEFT + Vector2i.UP]
	#Act
	var map = create_test_map(paths)
	#Assert
	assert_true(map.has(PavementTilesMap.corner_top_right))
