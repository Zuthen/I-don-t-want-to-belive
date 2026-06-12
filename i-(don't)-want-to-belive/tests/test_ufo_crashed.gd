extends GutTest

const GAME_SCENE = preload("uid://c4twc836ak4bd")
const UFO_WITH_ALIEN_SCENE = preload("uid://m52fuwcrlo2k")

var _game_instance: Node
var _tile_map: TileMapLayer
var _spawner: MultiplayerSpawner


func before_each():
	var mock_peer = OfflineMultiplayerPeer.new()
	get_tree().get_multiplayer().set_multiplayer_peer(mock_peer)
	_game_instance = GAME_SCENE.instantiate()
	add_child_autofree(_game_instance)

	_tile_map = _game_instance.tile_map_layer
	_spawner = _game_instance.multiplayer_spawner

	MultiplayerFeatures.spawn(_spawner, _tile_map)


func after_each():
	var mock_peer = OfflineMultiplayerPeer.new()
	get_tree().get_multiplayer().set_multiplayer_peer(mock_peer)


func test_alien_spawns_at_correct_tilemap_position_after_ufo_crash():
	var test_peer_id = 99
	var ufo_index = 2

	var target_global_pos = Vector2(160, 320)
	var grid_position = _tile_map.local_to_map(_tile_map.to_local(target_global_pos))
	var expected_local_pos = _tile_map.map_to_local(grid_position)

	var player_core = UFO_WITH_ALIEN_SCENE.instantiate() as UfoWithAlien
	player_core.name = str(test_peer_id)
	_game_instance.add_child(player_core)

	player_core.global_position = target_global_pos
	player_core.ufo_index_sync = ufo_index

	if "paths" in _game_instance:
		_game_instance.paths.append(grid_position)

	await get_tree().process_frame

	# Act
	player_core.change_state(UfoWithAlien.State.ALIEN, ufo_index)

	player_core.set_physics_process(false)
	if player_core.has_node("Alien"):
		player_core.get_node("Alien").set_physics_process(false)

	await wait_seconds(0.1)

	# Assert
	assert_eq(player_core.current_state, UfoWithAlien.State.ALIEN)

	var alien_node = player_core.get_node_or_null("Alien") as Alien
	assert_not_null(alien_node)

	if alien_node:
		assert_eq(player_core.global_position, expected_local_pos)
		assert_eq(alien_node.ufo_idx, ufo_index)
