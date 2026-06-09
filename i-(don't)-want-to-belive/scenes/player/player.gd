extends CharacterBody2D

class_name Player
@onready var tile_map_layer = get_node_or_null("/root/Game/BuildingsAndPaths")
var tile: Vector2
enum Role { NONE, UFO, SKEPTIC, ALIEN }

@warning_ignore_start("unused_signal")
signal player_role_assigned
signal ufo_wins
signal skeptics_win
var id: int = 0
var movement_blocked: = false
var role: Role


func move(speed: float, player_input_synchronizer: PlayerInputSynchronizer) -> Vector2:
	var sync_direction: Vector2 = Vector2.ZERO
	if is_instance_valid(player_input_synchronizer):
		sync_direction = player_input_synchronizer.movement_vector
	if is_multiplayer_authority() and not movement_blocked:
		velocity = speed * sync_direction
		move_and_slide()
	return sync_direction


func set_camera(camera: Camera2D, desired_zoom: float = 0.0):
	camera.enabled = true
	if desired_zoom > 0.0:
		camera.zoom = Vector2(desired_zoom, desired_zoom)

	var camera_limits = MapSettings.get_map_limits()
	camera.limit_top = camera_limits.top
	camera.limit_bottom = camera_limits.bottom
	camera.limit_left = camera_limits.left

	var current_zoom = camera.zoom.x
	var ui_width_in_world = 128.0 / current_zoom
	camera.limit_right = camera_limits.right + int(ui_width_in_world)
	camera.make_current()


class PlayerPosition:
	var letter: String
	var number: int


func get_coordinates(pos) -> PlayerPosition:
	var tile_position = tile_map_layer.local_to_map(pos)
	var x = clampi(tile_position.x, MapSettings.min_position.x, MapSettings.max_position.x)
	var y = clampi(tile_position.y, MapSettings.min_position.y, MapSettings.max_position.y)
	var sector_x_idx = floori(float(x) / MapSettings.sector_tile_size)
	var shifted_y = y - MapSettings.min_position.y
	var row_number = floori(float(shifted_y) / MapSettings.sector_tile_size) + 1
	var position = PlayerPosition.new()
	position.letter = get_column_name(sector_x_idx)
	position.number = row_number
	return position


func get_column_name(col_idx: int) -> String:
	var name := ""
	var temp = col_idx
	while temp >= 0:
		name = char(65 + (temp % 26)) + name
		temp = int(temp / 26.0) - 1
	return name


func start_cooldown_timer(time: float, callback: Callable):
	callback.call()
	var timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(callback)
	timer.timeout.connect(timer.queue_free)
	timer.start(time)
