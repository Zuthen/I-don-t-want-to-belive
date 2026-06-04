extends GutTest

var SkepticScene = preload("uid://b7wo2a5407873")
var _skeptic: Skeptic


func beforeEach():
	_skeptic = SkepticScene.instantiate()

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


func afterEach():
	if _skeptic and is_instance_valid(_skeptic):
		_skeptic.queue_free()


func test_play_captured_animation_initializes_correctly():
	var local_skeptic = SkepticScene.instantiate()
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

	var mock_texture = Texture2D.new()

	stub(local_skeptic, "rpc").to_do_nothing()

	local_skeptic._play_captured_animation(mock_texture, Vector2i(0, 0))

	assert_false(local_skeptic.sprite_2d.visible)
	assert_true(local_skeptic.movement_blocked)
	assert_eq(local_skeptic.camera.zoom, Vector2(1.5, 1.5))

	mock_parent.queue_free()


func test_capture_animation_cleanup_restores_state():
	var local_skeptic = SkepticScene.instantiate()

	var mock_camera = Camera2D.new()
	var mock_sprite = Sprite2D.new()

	local_skeptic.add_child(mock_camera)
	local_skeptic.add_child(mock_sprite)

	local_skeptic.camera = mock_camera
	local_skeptic.sprite_2d = mock_sprite

	get_tree().root.add_child(local_skeptic)

	local_skeptic.movement_blocked = true
	stub(local_skeptic, "rpc").to_do_nothing()

	var target_pixel_pos = Vector2(200, 300)
	local_skeptic._capture_animation_cleanup(target_pixel_pos)

	assert_not_null(local_skeptic)
	assert_false(local_skeptic.movement_blocked)

	local_skeptic.queue_free()


func test_teleport_network_rpc_applies_changes_to_all():
	var local_skeptic = SkepticScene.instantiate()

	var mock_sprite = Sprite2D.new()
	var mock_camera = Camera2D.new()
	local_skeptic.add_child(mock_sprite)
	local_skeptic.add_child(mock_camera)
	local_skeptic.sprite_2d = mock_sprite
	local_skeptic.camera = mock_camera
	local_skeptic.camera_zoom = Vector2(1.0, 1.0)

	local_skeptic.input_multiplayer_authority = multiplayer.get_unique_id()
	local_skeptic.add_to_group("skeptics")

	get_tree().root.add_child(local_skeptic)

	var teleport_pos = Vector2(500, 600)
	local_skeptic._teleport_network_rpc(teleport_pos)

	assert_not_null(local_skeptic)
	assert_eq(local_skeptic.global_position, teleport_pos)
	assert_true(local_skeptic.visible)
	assert_true(local_skeptic.sprite_2d.visible)

	local_skeptic.queue_free()
