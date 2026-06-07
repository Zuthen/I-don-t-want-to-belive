extends GutTest

class PureLogicUfoMock extends Node2D:
	var capture_processing: bool = false
	var capture_hit_target: bool = false
	var capture_blocked: bool = false
	var movement_blocked: bool = false
	var ufo_idx: int = 0
	var game: Node = null
	var tile_map_layer: Node = null

	var mock_crash_count: int = 0


	func _check_capture_result():
		if not capture_processing:
			return

		capture_processing = false

		if capture_hit_target:
			pass
		else:
			_on_capture_failed(ufo_idx, global_position)


	func _on_capture_failed(_ufo_index: int, _target_global_position: Vector2):
		mock_crash_count += 1


var fake_game: Node2D
var mock_ufo: Node2D


func before_each():
	fake_game = Node2D.new()
	fake_game.name = "FakeGame"

	var game_mock_script = GDScript.new()
	game_mock_script.source_code = "
extends Node2D
var paths: Array[Vector2i] = []
var tile_map_layer: Node2D
var multiplayer_spawner: Node

func local_to_map(local_position: Vector2) -> Vector2i:
	return Vector2i(10, 10)

func map_to_local(map_position: Vector2i) -> Vector2:
	return Vector2(168.0, 328.0)
"
	game_mock_script.reload()
	game_mock_script.resource_path = "res://tests/mocks/fake_game_script_mock.gd"
	fake_game.set_script(game_mock_script)

	fake_game.paths = [Vector2i(10, 10)] as Array[Vector2i]
	fake_game.tile_map_layer = fake_game

	fake_game.multiplayer_spawner = Node.new()
	fake_game.multiplayer_spawner.name = "FakeMultiplayerSpawner"
	fake_game.add_child(fake_game.multiplayer_spawner)

	add_child_autofree(fake_game)


func test_check_capture_result_executes_only_once_due_to_processing_gate():
	# Arrange
	mock_ufo = PureLogicUfoMock.new()
	mock_ufo.name = "MockUfo"

	mock_ufo.game = fake_game
	mock_ufo.tile_map_layer = fake_game
	fake_game.add_child(mock_ufo)

	mock_ufo.capture_hit_target = false
	mock_ufo.capture_processing = true
	mock_ufo.ufo_idx = 0
	mock_ufo.global_position = Vector2(160, 160)

	# Act
	mock_ufo._check_capture_result()
	mock_ufo._check_capture_result()
	mock_ufo._check_capture_result()

	# Assert
	assert_not_null(mock_ufo)
	assert_false(mock_ufo.capture_processing)
	assert_eq(mock_ufo.mock_crash_count, 1)


func test_check_capture_result_does_not_crash_ufo_if_target_hit():
	# Arrange
	mock_ufo = PureLogicUfoMock.new()
	mock_ufo.name = "MockUfo"

	mock_ufo.game = fake_game
	mock_ufo.tile_map_layer = fake_game
	fake_game.add_child(mock_ufo)

	mock_ufo.global_position = Vector2(160, 160)
	mock_ufo.capture_blocked = true
	mock_ufo.capture_hit_target = true
	mock_ufo.capture_processing = true
	mock_ufo.movement_blocked = true

	# Act
	mock_ufo._check_capture_result()

	# Assert
	assert_not_null(mock_ufo)
	assert_false(mock_ufo.capture_processing)
	assert_eq(mock_ufo.mock_crash_count, 0)


func test_alien_spawns_at_correct_tilemap_position_after_ufo_crash():
	# Arrange
	mock_ufo = PureLogicUfoMock.new()
	mock_ufo.name = "MockUfoForCrash"
	mock_ufo.game = fake_game
	mock_ufo.tile_map_layer = fake_game
	fake_game.add_child(mock_ufo)

	mock_ufo.global_position = Vector2(160, 160)
	mock_ufo.capture_processing = true
	mock_ufo.capture_hit_target = false

	# Act
	mock_ufo._check_capture_result()
	await wait_frames(2)

	# Assert
	assert_eq(mock_ufo.mock_crash_count, 1)
