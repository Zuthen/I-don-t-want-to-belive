class_name Ufo
extends CharacterBody2D

@onready var camera = $Camera2D
@onready var ship = $Ship
@onready var player_input_synchronizer = $PlayerInputSynchronizer

var laser_scene = preload("uid://dnsiqidfpctrc")
var ufo_sprites: UfosTextures.UfoTextures
const speed = 150.0

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
		camera.enabled = true
		camera.make_current()

	await get_tree().process_frame
	ufo_sprites = UfosTextures.ufo_textures[0]
	ship.texture = ufo_sprites.ship

	var my_own_hero = null
	for node in get_tree().get_nodes_in_group("skeptics") + get_tree().get_nodes_in_group("ufos"):
		if node.is_multiplayer_authority():
			my_own_hero = node
			break

	if my_own_hero and my_own_hero.is_in_group("skeptics"):
		visible = false


func _process(_delta):
	if not is_multiplayer_authority():
		return


func _physics_process(_delta):
	var sync_direction: Vector2 = player_input_synchronizer.movement_vector

	if is_multiplayer_authority():
		velocity = speed * sync_direction
		move_and_slide()
		if Input.is_action_just_pressed("laser_point"):
			server_spawn_laser.rpc(global_position)
	else:
		pass


@rpc("any_peer", "call_local", "reliable")
func server_spawn_laser(position: Vector2):
	if multiplayer.is_server():
		var laser = laser_scene.instantiate()
		laser.global_position = position
		get_parent().add_child(laser)


func spawn_laser(position: Vector2):
	server_spawn_laser(position)
