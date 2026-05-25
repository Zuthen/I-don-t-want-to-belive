class_name Skeptic
extends CharacterBody2D

@onready var animation_player = $AnimationPlayer
@onready var player_input_synchronizer = $PlayerInputSynchronizer

var input_multiplayer_authority: int:
	set(value):
		input_multiplayer_authority = value
		set_multiplayer_authority(value)

var voice_emitter_scene: PackedScene = preload("uid://qt86w2aja6bs")
var voice_emitter_active := false
const speed = 100.0
var direction_sprite := "down"


func _ready():
	player_input_synchronizer.set_multiplayer_authority(input_multiplayer_authority)


func _process(_delta):
	if not is_multiplayer_authority():
		return

	if Input.is_action_just_pressed("call_other_skeptic") and not voice_emitter_active:
		call_other_skeptic_network.rpc()


func _physics_process(_delta):
	var sync_direction: Vector2 = player_input_synchronizer.movement_vector

	if is_multiplayer_authority():
		velocity = speed * sync_direction
		move_and_slide()
	else:
		pass

	animate(sync_direction)


@rpc("call_local", "any_peer", "reliable")
func call_other_skeptic_network():
	voice_emitter_active = true
	var voice_emitter = voice_emitter_scene.instantiate()
	add_child(voice_emitter)
	voice_emitter.timer.timeout.connect(_reset_voice_emmitter)


func _reset_voice_emmitter():
	voice_emitter_active = false


func call_other_skeptic():
	# Ta funkcja została zastąpiona bezpiecznym RPC powyżej,
	# ale zostawiamy ją, jeśli Twoje testy jednostkowe GUT bezpośrednio ją wywołują!
	call_other_skeptic_network()


func animate(direction: Vector2):
	var directions = {
		"down": Vector2.DOWN,
		"up": Vector2.UP,
		"left": Vector2.LEFT,
		"right": Vector2.RIGHT,
	}
	# Mała korekta: normalizujemy wektor kierunku do porównania, na wypadek wartości skośnych
	var norm_dir = direction.normalized()

	if norm_dir.is_equal_approx(directions["down"]):
		animation_player.play("move down")
		direction_sprite = "down"
	elif norm_dir.is_equal_approx(directions["up"]):
		animation_player.play("move up")
		direction_sprite = "up"
	elif norm_dir.is_equal_approx(directions["left"]):
		animation_player.play("move left")
		direction_sprite = "left"
	elif norm_dir.is_equal_approx(directions["right"]):
		animation_player.play("move right")
		direction_sprite = "right"
	elif norm_dir == Vector2.ZERO:
		animation_player.play("idle " + direction_sprite)
