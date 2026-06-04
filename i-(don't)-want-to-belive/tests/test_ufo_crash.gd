extends GutTest

var UfoScene = preload("uid://hc74yy2qdg3f")
var MockGameScript = preload("res://tests/mocks/mock_game_node.gd")


func test_check_capture_result_executes_only_once_due_to_processing_gate():
	var test_script = GDScript.new()
	test_script.source_code = "
extends Ufo

static var crash_call_count : int = 0

# Nadpisujemy oryginalną funkcję, aby zamiast sieci zliczała wywołania
func place_crashed_ufo(ufo_index: int, target_global_position: Vector2):
	crash_call_count += 1
"
	test_script.reload()
	test_script.resource_path = "res://tests/mocks/mock_ufo_test_script.gd"
	var local_ufo = UfoScene.instantiate()
	local_ufo.set_script(test_script)

	test_script.crash_call_count = 0

	var mock_game = Node2D.new()
	mock_game.set_script(MockGameScript)
	mock_game.set("paths", [Vector2i(10, 10)])

	var mock_layer = Node2D.new()
	mock_layer.name = "BuildingsAndPaths"
	mock_game.add_child(mock_layer)
	mock_game.set("tile_map_layer", mock_game)

	get_tree().root.add_child(mock_game)

	mock_game.add_child(local_ufo)

	local_ufo.game = mock_game
	local_ufo.tile_map_layer = mock_game

	local_ufo.capture_hit_target = false
	local_ufo.capture_processing = true
	local_ufo.ufo_idx = 0
	local_ufo.global_position = Vector2(160, 160) # Kafel (10, 10)

	local_ufo._check_capture_result()
	local_ufo._check_capture_result()
	local_ufo._check_capture_result()

	assert_not_null(local_ufo)
	assert_false(local_ufo.capture_processing)

	assert_eq(test_script.crash_call_count, 1)

	mock_game.queue_free()
