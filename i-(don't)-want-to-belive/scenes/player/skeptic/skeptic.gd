class_name Skeptic
extends Player

@onready var camera = $Camera2D
@onready var animation_player = $AnimationPlayer
@onready var player_input_synchronizer = $PlayerInputSynchronizer

var is_male
var input_multiplayer_authority: int:
	set(value):
		input_multiplayer_authority = value
		set_multiplayer_authority(value)
		if has_node("PlayerInputSynchronizer"):
			$PlayerInputSynchronizer.set_multiplayer_authority(value)
var voice_emitter_scene: PackedScene = preload("uid://qt86w2aja6bs")
var voice_emitter_active := false
const speed = 100.0
var direction_sprite := "down"


func _ready():
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

	if my_own_hero and my_own_hero.is_in_group("ufos"):
		visible = false


func callable_initialize_visibility():
	var local_player = get_tree().get_first_node_in_group("local_player")
	if local_player and local_player.is_in_group("ufos"):
		local_player.player_role_assigned.emit()
		visible = false

	if is_multiplayer_authority():
		get_tree().call_group("ufos", "set_visible", false)


func _process(_delta):
	if not is_multiplayer_authority():
		return

	if Input.is_action_just_pressed("call_other_skeptic") and not voice_emitter_active:
		call_other_skeptic_network.rpc()


func _physics_process(_delta):
	var sync_direction: Vector2 = Vector2.ZERO

	if has_node("PlayerInputSynchronizer"):
		sync_direction = $PlayerInputSynchronizer.movement_vector

	if is_multiplayer_authority():
		velocity = speed * sync_direction
		move_and_slide()

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
	call_other_skeptic_network()


func animate(direction: Vector2):
	var directions = {
		"down": Vector2.DOWN,
		"up": Vector2.UP,
		"left": Vector2.LEFT,
		"right": Vector2.RIGHT,
	}
	var norm_dir = direction.normalized()
	var animation_sprite_name_suffix = "_boy" if is_male else ""
	if norm_dir.is_equal_approx(directions["down"]):
		animation_player.play("move down" + animation_sprite_name_suffix)
		direction_sprite = "down"
	elif norm_dir.is_equal_approx(directions["up"]):
		animation_player.play("move up" + animation_sprite_name_suffix)
		direction_sprite = "up"
	elif norm_dir.is_equal_approx(directions["left"]):
		animation_player.play("move left" + animation_sprite_name_suffix)
		direction_sprite = "left"
	elif norm_dir.is_equal_approx(directions["right"]):
		animation_player.play("move right" + animation_sprite_name_suffix)
		direction_sprite = "right"
	elif norm_dir == Vector2.ZERO:
		animation_player.play("idle " + direction_sprite + animation_sprite_name_suffix)
