class_name Skeptic
extends CharacterBody2D

@onready var animation_player = $AnimationPlayer
@onready var player_input_synchronizer = $PlayerInputSynchronizer
var input_multiplayer_authority: int
var voice_emitter_scene: PackedScene = preload("uid://qt86w2aja6bs")

var voice_emitter_active: = false
const speed = 100.0
var direction_sprite := "down"


func _ready():
	player_input_synchronizer.set_multiplayer_authority(input_multiplayer_authority)
	#set_process(is_multiplayer_authority())


func _process(_delta):
	if Input.is_action_just_pressed("call_other_skeptic") && !voice_emitter_active:
		call_other_skeptic()


func _physics_process(_delta):
	var horizontal_direction := Input.get_axis("walk_left", "walk_right")
	var vertical_direction := Input.get_axis("walk_up", "walk_down")

	var direction := Vector2(horizontal_direction, vertical_direction).normalized()
	velocity = speed * player_input_synchronizer.movement_vector
	move_and_slide()
	animate(direction)


func _reset_voice_emmitter():
	voice_emitter_active = false


func call_other_skeptic():
	voice_emitter_active = true
	var voice_emitter = voice_emitter_scene.instantiate()
	add_child(voice_emitter)
	voice_emitter.timer.timeout.connect(_reset_voice_emmitter)


func animate(direction: Vector2):
	var directions = {
		"down": Vector2.DOWN,
		"up": Vector2.UP,
		"left": Vector2.LEFT,
		"right": Vector2.RIGHT,
	}
	if direction == directions["down"]:
		animation_player.play("move down")
		direction_sprite = "down"
	elif direction == directions["up"]:
		animation_player.play("move up")
		direction_sprite = "up"
	elif direction == directions["left"]:
		animation_player.play("move left")
		direction_sprite = "left"
	elif direction == directions["right"]:
		animation_player.play("move right")
		direction_sprite = "right"
	elif direction == Vector2.ZERO:
		animation_player.play("idle " + direction_sprite)
