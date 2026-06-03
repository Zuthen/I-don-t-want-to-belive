class_name Ufo
extends Player

@onready var camera = $Camera2D
@onready var ship = $Ship
@onready var player_input_synchronizer = $PlayerInputSynchronizer
@onready var capture_area = $CaptureArea
@onready var animation_player = $AnimationPlayer
@onready var capture_area_collision = $CaptureArea/CaptureArea
@onready var captured_label = $CapturedLabel

var laser_scene = preload("uid://dnsiqidfpctrc")
var ufo_sprites: UfosTextures.UfoTextures

var laser_shoot_blocked := false
var movement_blocked := false
var capture_blocked := false
var game: Node2D
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
		if has_node("PlayerInputSynchronizer"):
			$PlayerInputSynchronizer.set_multiplayer_authority(value)


func _ready():
	game = get_parent() as Node2D
	capture_area_collision.disabled = true
	capture_area.area_entered.connect(_on_capture)
	if input_multiplayer_authority != 0:
		set_multiplayer_authority(input_multiplayer_authority)
		if has_node("PlayerInputSynchronizer"):
			$PlayerInputSynchronizer.set_multiplayer_authority(input_multiplayer_authority)

	if is_multiplayer_authority() and has_node("Camera2D"):
		set_camera(camera)

	await get_tree().process_frame
	ufo_sprites = UfosTextures.ufo_textures[0]
	ship.texture = ufo_sprites.ship

	var my_own_hero = null
	for node in get_tree().get_nodes_in_group("skeptics") + get_tree().get_nodes_in_group("ufos"):
		if node.is_multiplayer_authority():
			my_own_hero = node
			my_own_hero.player_role_assigned.emit()
			break

	if my_own_hero and my_own_hero.is_in_group("skeptics"):
		visible = false


func _process(_delta):
	if not is_multiplayer_authority():
		return


func _physics_process(_delta):
	var sync_direction: Vector2 = player_input_synchronizer.movement_vector

	if is_multiplayer_authority():
		if !movement_blocked:
			velocity = speed * sync_direction
			move_and_slide()
		if Input.is_action_just_pressed("laser_point") && !laser_shoot_blocked:
			fire_laser()
		if Input.is_action_just_pressed("capture") && !capture_blocked:
			_capture()


func _capture():
	var animation_time = animation_player.get_animation("capture").length
	animation_player.play("capture")
	captured.emit(capture_timeout_seconds)
	start_cooldown_timer(animation_time, func(): movement_blocked = !movement_blocked)
	start_cooldown_timer(
		animation_time,
		func():
			capture_area_collision.set_deferred("disabled", !capture_area_collision.disabled)
	)
	start_cooldown_timer(capture_timeout_seconds, func(): capture_blocked = false)
	captured.emit(capture_timeout_seconds)


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
		start_cooldown_timer(capture_label_time, func(): captured_label.visible = !captured_label.visible)
		var skeptic_path = player.get_path()
		var new_skeptic_position = _get_new_captured_skeptic_position()
		server_request_capture.rpc(skeptic_path, new_skeptic_position)


@rpc("any_peer", "call_local", "reliable")
func server_request_capture(node_path: NodePath, position: Vector2i):
	if not multiplayer.is_server():
		return
	var player = get_node_or_null(node_path)
	if player and player is Skeptic:
		var ufo_index: int = 0
		player.trigger_captured_effects_network.rpc(ufo_index, position)


@rpc("any_peer", "call_local", "reliable")
func server_spawn_laser(position: Vector2):
	if multiplayer.is_server():
		var laser = laser_scene.instantiate()
		get_parent().add_child(laser)
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
