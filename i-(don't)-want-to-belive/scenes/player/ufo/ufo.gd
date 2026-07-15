class_name Ufo
extends Player

@onready var ship = $Ship
@onready var capture_area = $CaptureArea
@onready var animation_player = $AnimationPlayer
@onready var capture_area_collision = $CaptureArea/CaptureArea
@onready var captured_label = $CapturedLabel
@onready var coordinates = $Coordinates
@onready var sound = $Sound
@onready var camera = $Camera2D

var laser_scene = preload("uid://dnsiqidfpctrc")
var ufo_sprites: UfosTextures.UfoTextures
var capture_hit_target := false
var laser_shoot_blocked := false
var capture_blocked := false
var capture_processing := false
var game: Game
var skin_idx: int = 3
const speed = 150.0
const laser_shoot_timeout_seconds: float = 5.0
const capture_timeout_seconds: float = 60.0
const capture_label_time: float = 1.5

signal laser_shoot(time: float)
signal captured(time: float)

var ufo_laser_shoot_animation_time: float

var input_multiplayer_authority: int:
	set(value):
		input_multiplayer_authority = value
		set_multiplayer_authority(value)


func _ready():
	game = get_tree().root.get_node("Game")
	capture_area_collision.disabled = true
	capture_area.area_entered.connect(_on_capture)

	if input_multiplayer_authority != 0:
		set_multiplayer_authority(input_multiplayer_authority)

	if is_multiplayer_authority():
		get_tree().call_group("skeptics", "_update_visibility_for_local_player")

	await get_tree().process_frame

	if UfosTextures.ufo_textures.size() > skin_idx and skin_idx >= 0:
		ufo_sprites = UfosTextures.ufo_textures[skin_idx]
		if ship and ufo_sprites and "ship" in ufo_sprites:
			ship.texture = ufo_sprites.ship


func _draw() -> void:
	if not is_multiplayer_authority():
		return
	var extents: Vector2 = capture_area_collision.shape.size / 2.0
	var dash_width: float = 8.0
	var dash_height: float = 2.5
	var target_y: float = extents.y + capture_area_collision.position.y - dash_height / 2.0

	var start_point = Vector2(-extents.x, target_y)
	var end_point = Vector2(extents.x, target_y)

	var line_vector: Vector2 = end_point - start_point
	var line_angle: float = line_vector.angle()

	var ufo_laser_texture = UfosTextures.ufo_textures[skin_idx].laser1

	var direction: Vector2 = line_vector.normalized()
	var adjusted_start: Vector2 = start_point + direction * (dash_width / 2.0)
	var adjusted_end: Vector2 = end_point - direction * (dash_width / 2.0)

	var desired_dash_count: int = 5
	var dash_count: int = max(2, desired_dash_count)

	for i in range(dash_count):
		var t: float = float(i) / float(dash_count - 1)
		var current_pos: Vector2 = adjusted_start.lerp(adjusted_end, t)

		var current_angle: float = line_angle + (PI / 2.0)
		draw_set_transform(current_pos, current_angle, Vector2.ONE)

		var dash_rect = Rect2(
			Vector2(-dash_height / 2.0, -dash_width / 2.0),
			Vector2(dash_height, dash_width),
		)

		draw_texture_rect(ufo_laser_texture, dash_rect, false, Color.WHITE)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _process(_delta):
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return

	if not is_multiplayer_authority():
		return

	if Input.is_action_just_pressed("laser_point") and not laser_shoot_blocked:
		_fire_laser()

	if Input.is_action_just_pressed("capture") and not capture_blocked:
		_capture()


func _capture():
	capture_blocked = true
	capture_hit_target = false
	capture_processing = true
	movement_blocked = true
	var animation = animation_player.get_animation("capture")
	var animation_time = animation.length
	animation.track_set_key_value(0, 0, UfosTextures.ufo_textures[skin_idx].laser_pointing)
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

	if game.map_paths.has(my_position):
		var pixel_position = tile_map.map_to_local(my_position)
		_on_capture_failed.rpc(skin_idx, pixel_position)
	else:
		var nearest_tile = find_nearest_path(global_position)
		var nearest_pixel_path = tile_map.map_to_local(nearest_tile)
		_on_capture_failed.rpc(skin_idx, nearest_pixel_path)


func find_nearest_path(pos_pixels: Vector2) -> Vector2i:
	var possible_paths = []
	var search_radius_tiles = 1
	while possible_paths.size() == 0 and search_radius_tiles < 50:
		possible_paths = _find_paths_in_radius(pos_pixels, search_radius_tiles)
		search_radius_tiles += 1

	if possible_paths.is_empty():
		return game.tile_map_layer.local_to_map(pos_pixels)

	return Vector2i(possible_paths.pick_random())


func _find_paths_in_radius(pos_pixels: Vector2, radius: int) -> Array[Vector2i]:
	var tile_position = game.tile_map_layer.local_to_map(pos_pixels)
	var possibilities: Array[Vector2i] = []

	var upper_row_idx = tile_position.y - radius
	for i in range(tile_position.x - radius, tile_position.x + radius + 1):
		var temp_tile = Vector2i(i, upper_row_idx)
		if game.map_paths.has(temp_tile):
			possibilities.append(temp_tile)

	var bottom_row_idx = tile_position.y + radius
	for i in range(tile_position.x - radius, tile_position.x + radius + 1):
		var temp_tile = Vector2i(i, bottom_row_idx)
		if game.map_paths.has(temp_tile):
			possibilities.append(temp_tile)

	var left_column_idx = tile_position.x - radius
	for i in range(tile_position.y - radius + 1, tile_position.y + radius):
		var temp_tile = Vector2i(left_column_idx, i)
		if game.map_paths.has(temp_tile):
			possibilities.append(temp_tile)

	var right_column_idx = tile_position.x + radius
	for i in range(tile_position.y - radius + 1, tile_position.y + radius):
		var temp_tile = Vector2i(right_column_idx, i)
		if game.map_paths.has(temp_tile):
			possibilities.append(temp_tile)

	return possibilities


func _get_new_captured_skeptic_position() -> Vector2i:
	var start_position = game.tile_map_layer.local_to_map(global_position)
	var new_skeptic_position = _find_new_skeptic_position(game.map_paths, start_position)
	return new_skeptic_position


func _find_new_skeptic_position(paths_array: Array[Vector2i], current_position) -> Vector2i:
	var dynamic_min_distance: float = sqrt(MapSettings.paths_tiles) * 0.85
	for i in range(MapSettings.paths_tiles / 2.0):
		var random_index = randi() % paths_array.size()

		if current_position == paths_array[random_index]:
			continue

		var new_position = paths_array[random_index]

		if current_position.distance_to(new_position) >= dynamic_min_distance:
			return new_position

	return paths_array[0]


func _on_capture(other):
	var player = other.get_parent()
	if player is Skeptic:
		capture_hit_target = true
		start_cooldown_timer(capture_label_time, func(): captured_label.visible = !captured_label.visible)
		var skeptic_path = player.get_path()
		var new_skeptic_position = _get_new_captured_skeptic_position()
		_server_request_capture.rpc(skeptic_path, new_skeptic_position)


@rpc("any_peer", "call_local", "reliable")
func _on_capture_failed(ufo_index: int, target_global_position: Vector2):
	if not multiplayer.is_server():
		return

	var explosion_sound = Sounds.explosion_sounds.pick_random()
	sound.stream = explosion_sound
	sound.play()

	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = multiplayer.get_unique_id()

	var player_core = game.get_node_or_null(str(sender_id)) as UfoWithAlien

	var crashed_ufo_spawn_data = {
		"type": "wreck",
		"skin_idx": ufo_index,
		"spawn_position": game.tile_map_layer.local_to_map(target_global_position),
		"peer_id": sender_id,
	}
	game.multiplayer_spawner.spawn(crashed_ufo_spawn_data)

	if player_core:
		var tile_map = game.tile_map_layer
		var grid_position = tile_map.local_to_map(target_global_position)
		var exact_pixel_position = tile_map.map_to_local(grid_position)

		player_core.global_position = exact_pixel_position
		player_core.ufo_index_sync = ufo_index
		player_core.change_state.rpc(UfoWithAlien.State.ALIEN, ufo_index)


@rpc("any_peer", "call_local", "reliable")
func _server_request_capture(node_path: NodePath, position: Vector2i):
	if not multiplayer.is_server():
		return
	var player = get_node_or_null(node_path)
	if player and player is Skeptic:
		player.trigger_captured_effects_network.rpc(skin_idx, position)


func _fire_laser():
	var laser_sound = Sounds.laser_sounds.pick_random()
	sound.stream = laser_sound
	sound.play()
	laser_shoot.emit(laser_shoot_timeout_seconds)
	_server_spawn_laser.rpc(global_position)
	start_cooldown_timer(laser_shoot_timeout_seconds, func(): laser_shoot_blocked = !laser_shoot_blocked)
	start_cooldown_timer(ufo_laser_shoot_animation_time, func(): movement_blocked = !movement_blocked)


@rpc("any_peer", "call_local", "reliable")
func _server_spawn_laser(position: Vector2):
	if multiplayer.is_server():
		var sender_id = multiplayer.get_remote_sender_id()
		if sender_id == 0:
			sender_id = multiplayer.get_unique_id()

		var laser_data = {
			"type": "laser",
			"global_position": position,
			"color_idx": skin_idx,
			"peer_id": sender_id,
		}
		game.multiplayer_spawner.spawn(laser_data)
