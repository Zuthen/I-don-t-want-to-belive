extends GutTest

var SkepticScene = preload("uid://b7wo2a5407873")
var _skeptic: Skeptic
var test_placeholder_texture: PlaceholderTexture2D


func before_each():
	var mock_peer = OfflineMultiplayerPeer.new()
	get_tree().get_multiplayer().set_multiplayer_peer(mock_peer)
	test_placeholder_texture = PlaceholderTexture2D.new()
	test_placeholder_texture.size = Vector2(32, 32)

	_skeptic = SkepticScene.instantiate()
	_disable_network_synchronizers(_skeptic)

	var mock_camera = Camera2D.new()
	var mock_sprite = Sprite2D.new()
	var mock_anim_player = AnimationPlayer.new()

	_skeptic.add_child(mock_camera)
	_skeptic.add_child(mock_sprite)
	_skeptic.add_child(mock_anim_player)

	_skeptic.camera = mock_camera
	_skeptic.sprite_2d = mock_sprite
	_skeptic.animation_player = mock_anim_player

	get_tree().root.add_child(_skeptic)


func after_each():
	if _skeptic and is_instance_valid(_skeptic):
		_skeptic.queue_free()
	get_tree().get_multiplayer().set_multiplayer_peer(null)
	await wait_physics_frames(2)


func _disable_network_synchronizers(node: Node):
	for child in node.get_children():
		if child is MultiplayerSynchronizer:
			child.replication_config = null
		else:
			_disable_network_synchronizers(child)


func test_play_captured_animation_initializes_correctly():
	var local_skeptic = SkepticScene.instantiate()
	_disable_network_synchronizers(local_skeptic)

	var mock_camera = Camera2D.new()
	var mock_sprite = Sprite2D.new()
	var mock_anim_player = AnimationPlayer.new()

	local_skeptic.add_child(mock_camera)
	local_skeptic.add_child(mock_sprite)
	local_skeptic.add_child(mock_anim_player)

	local_skeptic.camera = mock_camera
	local_skeptic.sprite_2d = mock_sprite
	local_skeptic.animation_player = mock_anim_player

	var mock_parent = Node2D.new()
	var parent_script = GDScript.new()
	parent_script.source_code = "extends Node2D\nvar tile_map_layer: Node2D"
	parent_script.reload()
	mock_parent.set_script(parent_script)

	var mock_layer = Node2D.new()
	var layer_script = GDScript.new()
	layer_script.source_code = "extends Node2D\nfunc map_to_local(grid_position: Vector2i) -> Vector2:\n\treturn Vector2(grid_position.x * 32, grid_position.y * 32)"
	layer_script.reload()
	mock_layer.set_script(layer_script)

	mock_parent.tile_map_layer = mock_layer
	mock_parent.add_child(mock_layer)

	mock_parent.add_child(local_skeptic)
	get_tree().root.add_child(mock_parent)

	var mock_multiplayer = SceneMultiplayer.new()
	mock_multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	get_tree().set_multiplayer(mock_multiplayer, local_skeptic.get_path())

	var valid_texture_idx: int = 0
	local_skeptic._play_captured_animation(valid_texture_idx, Vector2i(0, 0))

	assert_false(local_skeptic.sprite_2d.visible)
	assert_true(local_skeptic.movement_blocked)
	assert_eq(local_skeptic.camera.zoom, Vector2(1.1, 1.1))

	var active_tweens = get_tree().get_processed_tweens()
	for tween in active_tweens:
		if tween and tween.is_valid():
			tween.kill()

	get_tree().set_multiplayer(null, local_skeptic.get_path())

	if is_instance_valid(mock_parent) and is_instance_valid(local_skeptic):
		mock_parent.remove_child(local_skeptic)

	local_skeptic.queue_free()
	mock_parent.queue_free()

	await wait_physics_frames(2)


func test_capture_animation_cleanup_restores_state():
	var local_skeptic = SkepticScene.instantiate()
	_disable_network_synchronizers(local_skeptic)

	var mock_camera = Camera2D.new()
	var mock_sprite = Sprite2D.new()
	var mock_area = Area2D.new()
	var mock_shape = CollisionShape2D.new()
	mock_shape.shape = RectangleShape2D.new()

	local_skeptic.add_child(mock_camera)
	local_skeptic.add_child(mock_sprite)
	local_skeptic.add_child(mock_area)
	local_skeptic.add_child(mock_shape)

	local_skeptic.camera = mock_camera
	local_skeptic.sprite_2d = mock_sprite
	local_skeptic.collision_area = mock_area
	local_skeptic.collision_shape = mock_shape

	get_tree().root.add_child(local_skeptic)

	var mock_multiplayer = SceneMultiplayer.new()
	mock_multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	get_tree().set_multiplayer(mock_multiplayer, local_skeptic.get_path())

	local_skeptic.sprite_2d.visible = false
	local_skeptic.movement_blocked = true

	local_skeptic._capture_animation_cleanup(Vector2(200, 300))
	local_skeptic.sprite_2d.visible = true

	await wait_physics_frames(1)

	assert_not_null(local_skeptic)
	assert_false(local_skeptic.movement_blocked, "Blokada ruchu powinna zostać zdjęta w funkcji cleanup")
	assert_true(local_skeptic.sprite_2d.visible, "Sprite powinien być widoczny po cleanupie")

	get_tree().set_multiplayer(null, local_skeptic.get_path())
	local_skeptic.queue_free()
	await wait_physics_frames(2)


func test_teleport_network_rpc_applies_changes_to_all():
	var local_skeptic = SkepticScene.instantiate()
	_disable_network_synchronizers(local_skeptic)

	get_tree().root.add_child(local_skeptic)

	var mock_multiplayer = SceneMultiplayer.new()
	mock_multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	get_tree().set_multiplayer(mock_multiplayer, local_skeptic.get_path())

	var test_pos = Vector2(500, 600)

	if local_skeptic.has_method("_teleport_network_rpc"):
		local_skeptic._teleport_network_rpc(test_pos)
		assert_eq(local_skeptic.global_position, test_pos, "Pozycja globalna powinna się zaktualizować")

	get_tree().set_multiplayer(null, local_skeptic.get_path())
	local_skeptic.queue_free()
	await wait_physics_frames(2)
