class_name Ufo
extends Player

@onready var ship = $Ship
@onready var capture_area = $CaptureArea
@onready var animation_player = $AnimationPlayer
@onready var capture_area_collision = $CaptureArea/CaptureArea
@onready var captured_label = $CapturedLabel
@onready var coordinates = $Coordinates

var laser_scene = preload("uid://dnsiqidfpctrc")
var ufo_sprites: UfosTextures.UfoTextures
var capture_hit_target := false
var laser_shoot_blocked := false
var movement_blocked := false
var capture_blocked := false
var capture_processing := false
var game: Node2D
var ufo_idx: int = 3
const speed = 150.0
const laser_shoot_timeout_seconds: float = 5.0
const capture_timeout_seconds: float = 1.0
const capture_label_time: float = 1.5

signal laser_shoot(time: float)
signal captured(time: float)

var ufo_laser_shoot_animation_time: float

var input_multiplayer_authority: int:
	set(value):
		input_multiplayer_authority = value
		set_multiplayer_authority(value)


func _ready():
	var parent_core = get_parent()
	if parent_core:
		game = parent_core.get_parent()

	capture_area_collision.disabled = true
	capture_area.area_entered.connect(_on_capture)

	if input_multiplayer_authority != 0:
		set_multiplayer_authority(input_multiplayer_authority)

	if is_multiplayer_authority():
		get_tree().call_group("skeptics", "_update_visibility_for_local_player")

	await get_tree().process_frame
	if UfosTextures.ufo_textures.size() > ufo_idx:
		ufo_sprites = UfosTextures.ufo_textures[ufo_idx]
		ship.texture = ufo_sprites.ship


# Czyste przechwytywanie klawiszy akcji – bez fizyki ruchu
func _process(_delta):
	if not is_multiplayer_authority():
		return

	if Input.is_action_just_pressed("laser_point") and not laser_shoot_blocked:
		fire_laser()

	if Input.is_action_just_pressed("capture") and not capture_blocked:
		_capture()


func _capture():
	capture_blocked = true
	capture_hit_target = false
	capture_processing = true
	movement_blocked = true

	var animation_time = animation_player.get_animation("capture").length
	animation_player.play("capture")
	captured.emit(capture_timeout_seconds)
	capture_area_collision.disabled = false

	var capture_tween = create_tween()
	capture_tween.tween_interval(animation_time)
	capture_tween.tween_callback(
		func():
			capture_area_collision.disabled = true
			_check_capture_result()
			movement_blocked = false
	)

	var cooldown_tween = create_tween()
	cooldown_tween.tween_interval(capture_timeout_seconds)
	cooldown_tween.tween_callback(func(): capture_blocked = false)


func _check_capture_result():
	if not capture_processing:
		return
	capture_processing = false

	if capture_hit_target:
		return

	var tile_map = game.tile_map_layer
	var my_position = tile_map.local_to_map(global_position)

	if game.paths.has(my_position):
		var pixel_position = tile_map.map_to_local(my_position)
		_on_capture_failed.rpc(ufo_idx, pixel_position)
	else:
		var nearest_tile = find_nearest_path(global_position)
		var nearest_pixel_path = tile_map.map_to_local(nearest_tile)
		_on_capture_failed.rpc(ufo_idx, nearest_pixel_path)


func find_nearest_path(pos_pixels: Vector2) -> Vector2i:
	var possible_paths = []
	var search_radius_tiles = 1
	while possible_paths.size() == 0 and search_radius_tiles < 50:
		possible_paths = find_paths_in_radius(pos_pixels, search_radius_tiles)
		search_radius_tiles += 1

	if possible_paths.is_empty():
		return game.tile_map_layer.local_to_map(pos_pixels)

	return Vector2i(possible_paths.pick_random())


func find_paths_in_radius(pos_pixels: Vector2, radius: int) -> Array[Vector2i]:
	var tile_position = game.tile_map_layer.local_to_map(pos_pixels)
	var possibilities: Array[Vector2i] = []

	var upper_row_idx = tile_position.y - radius
	for i in range(tile_position.x - radius, tile_position.x + radius + 1):
		var temp_tile = Vector2i(i, upper_row_idx)
		if game.paths.has(temp_tile):
			possibilities.append(temp_tile)

	var bottom_row_idx = tile_position.y + radius
	for i in range(tile_position.x - radius, tile_position.x + radius + 1):
		var temp_tile = Vector2i(i, bottom_row_idx)
		if game.paths.has(temp_tile):
			possibilities.append(temp_tile)

	var left_column_idx = tile_position.x - radius
	for i in range(tile_position.y - radius + 1, tile_position.y + radius):
		var temp_tile = Vector2i(left_column_idx, i)
		if game.paths.has(temp_tile):
			possibilities.append(temp_tile)

	var right_column_idx = tile_position.x + radius
	for i in range(tile_position.y - radius + 1, tile_position.y + radius):
		var temp_tile = Vector2i(right_column_idx, i)
		if game.paths.has(temp_tile):
			possibilities.append(temp_tile)

	return possibilities


func _get_new_captured_skeptic_position() -> Vector2i:
	var all_paths = game.paths
	var start_position = game.tile_map_layer.local_to_map(global_position)
	var new_skeptic_position = game.find_new_skeptic_position(all_paths, start_position)
	return new_skeptic_position


func _change_skeptic_position(player, position: Vector2i):
	player.position = game.tile_map_layer.map_to_local(position)


func _on_capture(other):
	var player = other.get_parent()
	if player is Skeptic:
		capture_hit_target = true
		start_cooldown_timer(capture_label_time, func(): captured_label.visible = !captured_label.visible)
		var skeptic_path = player.get_path()
		var new_skeptic_position = _get_new_captured_skeptic_position()
		server_request_capture.rpc(skeptic_path, new_skeptic_position)


@rpc("any_peer", "call_local", "reliable")
func _on_capture_failed(ufo_index: int, target_global_position: Vector2):
	if not multiplayer.is_server():
		return

	var sender_id = multiplayer.get_remote_sender_id()
	var player_core = game.get_node(str(sender_id)) as UfoWithAlien

	if player_core:
		var tile_map = game.tile_map_layer
		var grid_position = tile_map.local_to_map(target_global_position)
		var exact_pixel_position = tile_map.map_to_local(grid_position)

		player_core.global_position = exact_pixel_position
		player_core.ufo_index_sync = ufo_index
		player_core.change_state.rpc(UfoWithAlien.State.ALIEN, ufo_idx)

	var crashed_ufo_spawn_data = {
		"type": "wreck",
		"ufo_idx": ufo_index,
		"spawn_position": game.tile_map_layer.local_to_map(target_global_position),
		"peer_id": sender_id,
	}
	game.multiplayer_spawner.spawn(crashed_ufo_spawn_data)


@rpc("any_peer", "call_local", "reliable")
func server_request_capture(node_path: NodePath, position: Vector2i):
	if not multiplayer.is_server():
		return
	var player = get_node_or_null(node_path)
	if player and player is Skeptic:
		player.trigger_captured_effects_network.rpc(ufo_idx, position)


@rpc("any_peer", "call_local", "reliable")
func server_spawn_laser(position: Vector2):
	if multiplayer.is_server():
		var laser = laser_scene.instantiate()
		game.add_child(laser)
		laser.global_position = position
	if ufo_laser_shoot_animation_time == 0.0:
		_get_animation_time()


func spawn_laser(position: Vector2):
	server_spawn_laser(position)


func fire_laser():
	laser_shoot.emit(laser_shoot_timeout_seconds)
	server_spawn_laser.rpc(global_position)
	start_cooldown_timer(laser_shoot_timeout_seconds, func(): laser_shoot_blocked = !laser_shoot_blocked)
	start_cooldown_timer(ufo_laser_shoot_animation_time, func(): movement_blocked = !movement_blocked)


func _get_animation_time():
	var temp_laser = laser_scene.instantiate()
	get_tree().root.add_child(temp_laser)
	var time = temp_laser.get_animation_time()
	temp_laser.queue_free()
	return time
