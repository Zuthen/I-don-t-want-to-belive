class_name Player
extends CharacterBody2D

@onready var player_input_synchronizer = $PlayerInputSynchronizer

const speed = 100.0
var sync_direction: Vector2

var input_multiplayer_authority: int:
	set(value):
		input_multiplayer_authority = value

		if is_node_ready():
			set_multiplayer_authority(value)


func _ready():
	set_multiplayer_authority(input_multiplayer_authority)

	if is_instance_valid(player_input_synchronizer):
		player_input_synchronizer.set_multiplayer_authority(input_multiplayer_authority)

	if not is_multiplayer_authority():
		set_physics_process(false)


func _physics_process(_delta):
	sync_direction = player_input_synchronizer.movement_vector

	if is_multiplayer_authority():
		velocity = speed * sync_direction
		move_and_slide()
