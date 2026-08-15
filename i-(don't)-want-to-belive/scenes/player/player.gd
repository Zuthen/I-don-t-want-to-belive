extends CharacterBody2D

class_name Player
@onready var tile_map_layer = get_node_or_null("/root/Game/BuildingsAndPaths")
var tile: Vector2
enum Role { UFO, SKEPTIC, ALIEN, BOSS, GROUND }

@warning_ignore_start("unused_signal")
signal somebody_wins

var id: int = 0
var movement_blocked: = false
var role: Role
var is_gameplay_ready: bool = false
var can_collect = true
var actions: Array[Callable] = [Callable(), Callable(), Callable()]


func _ready():
	if not is_inside_tree():
		await tree_entered
	_set_fsx_volume()
	ItemsManager.item_type_removed.connect(_clear_action)

	await get_tree().process_frame
	await get_tree().process_frame
	is_gameplay_ready = true


func _get_action_by_item_name(item_name: String, player: Player) -> Callable:
	if player.role == Role.SKEPTIC:
		match item_name:
			"sanity_pills":
				return player.take_sanity_pill
			"signal_jammer":
				return player.add_signal_jammer
	elif player.role == Role.ALIEN:
		match item_name:
			"repair_tool":
				return player.repair_ufo
	elif player.role == Role.BOSS:
		match item_name:
			"steering_wheel":
				return player.insert_steering_wheel

	return Callable()


func get_actions() -> Array[Callable]:
	return actions


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
	var sector_y_idx = floori(float(y) / MapSettings.sector_tile_size)

	sector_x_idx = clampi(sector_x_idx, 0, 9)
	var row_number = clampi(sector_y_idx, 0, 9) + 1

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


func start_timer(time: float, callback: Callable):
	var timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(callback)
	timer.timeout.connect(timer.queue_free)
	timer.start(time)


func _set_fsx_volume():
	var sound_node = get_node_or_null("Sound") as AudioStreamPlayer
	if sound_node:
		var volume = ConfigManager.get_setting("audio_sfx", 0.5)
		if volume <= 0.0:
			sound_node.volume_db = -80.0
		else:
			sound_node.volume_db = linear_to_db(volume)


func update_synchronizer_visibility_by_role():
	if is_in_group("ufos") and not is_in_group("aliens"):
		visible = true


func get_backpack() -> Backpack:
	var ui = _get_ui()
	return ui.backpack


func _get_ui() -> UserInterface:
	if MultiplayerFeatures.local_ui != null:
		return MultiplayerFeatures.local_ui

	if is_inside_tree():
		var ui = get_parent().get_node_or_null("UserInterface")
		if ui is UserInterface:
			return ui
	return null


func _assign_item_action(item_name: String, _player_role: int):
	if self.role == Role.ALIEN and check_usable(item_name, Role.ALIEN):
		_assign_alien_actions(item_name)

	elif self.role == Role.SKEPTIC and check_usable(item_name, Role.SKEPTIC):
		_assign_skeptic_actions(item_name)

	elif self.role == Role.BOSS and check_usable(item_name, Role.BOSS):
		_assign_robert_actions(item_name)


func check_usable(item_name: String, player_role: Player.Role) -> bool:
	var roles_can_use: Array[Role]
	match item_name:
		"repair_tool":
			roles_can_use = [Role.ALIEN, Role.BOSS]
		"sanity_pills":
			roles_can_use = [Role.SKEPTIC]
		"signal_jammer":
			roles_can_use = [Role.SKEPTIC, Role.ALIEN]
		"steering_wheel":
			roles_can_use = [Role.BOSS]
	return roles_can_use.has(player_role)


func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("action 1"):
		_use_action(0)
	elif event.is_action_pressed("action 2"):
		_use_action(1)
	elif event.is_action_pressed("action 3"):
		_use_action(2)


func _use_action(i: int):
	var action = actions[i]
	if not action.is_null():
		action.call()


func _assign_alien_actions(item_name: String):
	var alien = get_node("Alien") as Alien

	match item_name:
		"repair_tool":
			_assign_action(alien.repair_ufo, false, item_name)
		"signal_jammer":
			_assign_action(alien.jammered_walkie_talkie_message, true, item_name)
		_:
			return


func _clear_action(item_name: String, player: Player):
	var action = _get_action_by_item_name(item_name, player)
	if _check_action_available(action):
		for i in range(GameManager.backpack_capacity):
			if actions[i] == action:
				actions[i] = Callable()
				ItemsManager.action_removed.emit(item_name)


func _check_action_available(action: Callable) -> bool:
	for a in actions:
		if a == action:
			return true
	return false


func _assign_action(action: Callable, enabled_on_collect: bool, item_name: String):
	if _check_action_available(action):
		return
	for i in range(GameManager.backpack_capacity):
		if actions[i].is_null():
			actions[i] = action
			ItemsManager.input_action_assigned.emit(enabled_on_collect, item_name)
			print("input_action_assigned: ", action)
			return


func _assign_skeptic_actions(item_name):
	var skeptic = self as Skeptic
	match item_name:
		"sanity_pills":
			_assign_action(skeptic.take_sanity_pill, skeptic.belive_points > 0, item_name)
		"signal_jammer":
			_assign_action(skeptic.add_signal_jammer, skeptic.can_send_coordinates, item_name)
		_:
			return


func _assign_robert_actions(item_name):
	print("assign robert actions", item_name)
	match item_name:
		"steering_wheel":
			_assign_action(self.insert_steering_wheel, self.near_wreck, item_name)
		"repair_tool":
			_assign_action(self.repair_ufo, self.near_wreck, item_name)


func animate(direction: Vector2, animation_player, animation_sprite_idx):
	var direction_sprite := "down"
	if not is_inside_tree() or animation_player == null:
		return
	var directions = {
		"down": Vector2.DOWN,
		"up": Vector2.UP,
		"left": Vector2.LEFT,
		"right": Vector2.RIGHT,
	}
	var norm_dir = direction.normalized()

	if norm_dir.is_equal_approx(directions["down"]):
		animation_player.play("move down " + str(animation_sprite_idx))
		direction_sprite = "down"
	elif norm_dir.is_equal_approx(directions["up"]):
		animation_player.play("move up " + str(animation_sprite_idx))
		direction_sprite = "up"
	elif norm_dir.is_equal_approx(directions["left"]):
		animation_player.play("move left " + str(animation_sprite_idx))
		direction_sprite = "left"
	elif norm_dir.is_equal_approx(directions["right"]):
		animation_player.play("move right " + str(animation_sprite_idx))
		direction_sprite = "right"
	elif norm_dir == Vector2.ZERO:
		animation_player.play("idle " + direction_sprite + " " + str(animation_sprite_idx))
