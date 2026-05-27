class_name Ufo
extends CharacterBody2D

@onready var camera = $Camera2D
@onready var sprite_2d = $Sprite2D
@onready var player_input_synchronizer = $PlayerInputSynchronizer

@export var sprites: Array[Texture]

const speed = 150.0

var input_multiplayer_authority: int:
	set(value):
		input_multiplayer_authority = value
		set_multiplayer_authority(value)


func _ready():
	sprite_2d.texture = sprites.pick_random()
	if has_node("PlayerInput"):
		player_input_synchronizer.set_multiplayer_authority(input_multiplayer_authority)
	var local_player = get_tree().get_first_node_in_group("local_player")
	if local_player and local_player.is_in_group("skeptics"):
		visible = false
	if is_multiplayer_authority():
		get_tree().call_group("skeptics", "set_visible", false)
	if is_multiplayer_authority() and has_node("Camera2D"):
		camera.enabled = true
		camera.make_current()


func _process(_delta):
	if not is_multiplayer_authority():
		return


func _physics_process(_delta):
	var sync_direction: Vector2 = player_input_synchronizer.movement_vector

	if is_multiplayer_authority():
		velocity = speed * sync_direction
		move_and_slide()
	else:
		pass
