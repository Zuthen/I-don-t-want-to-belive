extends GutTest

const GAME_SCENE = preload("uid://c4twc836ak4bd")

var _game_instance: Node
var _tile_map: TileMapLayer
var _spawner: MultiplayerSpawner


func before_each():
	_game_instance = GAME_SCENE.instantiate()
	add_child_autofree(_game_instance)

	_tile_map = _game_instance.tile_map_layer
	_spawner = _game_instance.multiplayer_spawner

	MultiplayerFeatures.spawn_player(_spawner, _tile_map)


func test_alien_spawns_at_correct_tilemap_position_after_ufo_crash():
	var test_peer_id = 1
	var ufo_index = 2

	var target_global_pos = Vector2(160, 320)
	var grid_position = _tile_map.local_to_map(_tile_map.to_local(target_global_pos))
	var expected_local_pos = _tile_map.map_to_local(grid_position)

	var fake_ufo = Node2D.new()
	fake_ufo.name = str(test_peer_id)
	fake_ufo.global_position = target_global_pos
	_game_instance.add_child(fake_ufo)

	var ufo_node = _game_instance.get_node(str(test_peer_id))
	ufo_node._on_capture_failed(ufo_index, target_global_pos)

	await wait_seconds(0.1)

	var old_ufo_still_exists = _game_instance.has_node(str(test_peer_id))
	assert_false(old_ufo_still_exists)

	var alien_node = _game_instance.get_node_or_null(str(test_peer_id)) as Alien
	assert_not_null(alien_node)

	if alien_node:
		assert_eq(alien_node.position, expected_local_pos)
		assert_eq(alien_node.ufo_idx, ufo_index)
		assert_eq(alien_node.id, test_peer_id)
