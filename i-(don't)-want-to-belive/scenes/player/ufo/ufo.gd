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
		if has_node("PlayerInputSynchronizer"):
			$PlayerInputSynchronizer.set_multiplayer_authority(value)


func _ready():
	if typeof(sprites) == TYPE_ARRAY and not sprites.is_empty() and has_node("Sprite2D"):
		sprite_2d.texture = sprites.pick_random()

	if input_multiplayer_authority != 0:
		set_multiplayer_authority(input_multiplayer_authority)
		if has_node("PlayerInputSynchronizer"):
			$PlayerInputSynchronizer.set_multiplayer_authority(input_multiplayer_authority)

	if is_multiplayer_authority() and has_node("Camera2D"):
		camera.enabled = true
		camera.make_current()

	await get_tree().process_frame

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
	else:
		pass
