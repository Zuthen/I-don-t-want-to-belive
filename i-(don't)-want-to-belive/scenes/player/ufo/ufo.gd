class_name Ufo
extends Player

@onready var camera = $Camera2D
@onready var ship = $Ship
@onready var player_input_synchronizer = $PlayerInputSynchronizer

var laser_scene = preload("uid://dnsiqidfpctrc")
var ufo_sprites: UfosTextures.UfoTextures

var laser_shoot_blocked := false
var movement_blocked: = false

const speed = 150.0
const laser_shoot_timeout_seconds: float = 5.0
signal laser_shoot(time: float)
var ufo_laser_shoot_animation_time: float
var input_multiplayer_authority: int:
	set(value):
		input_multiplayer_authority = value
		set_multiplayer_authority(value)
		if has_node("PlayerInputSynchronizer"):
			$PlayerInputSynchronizer.set_multiplayer_authority(value)


func _ready():
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
	else:
		pass


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
	movement_blocked = true
	laser_shoot_blocked = true

	start_cooldown_timer(laser_shoot_timeout_seconds, func(): laser_shoot_blocked = false)
	start_cooldown_timer(ufo_laser_shoot_animation_time, func(): movement_blocked = false)


func _get_animation_time():
	var temp_laser = laser_scene.instantiate()
	get_tree().root.add_child(temp_laser)
	var time = temp_laser.get_animation_time()
	temp_laser.queue_free()
	return time
