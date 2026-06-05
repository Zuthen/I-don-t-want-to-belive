class_name Alien
extends Player

@onready var camera = $Camera2D
@onready var animation_player = $AnimationPlayer
@onready var player_input_synchronizer = $PlayerInputSynchronizer
@onready var dialog_timer = $DialogTimer
@onready var dialog_placements = $DialogPlacements
@onready var collision_area = $CollisionArea
@onready var sprite_2d = $Sprite2D
@onready var collision_shape = $CollisionShape2D

var icon_placeholder_scene: PackedScene = preload("uid://d03xota05sdvx")
var voice_emitter_scene: PackedScene = preload("uid://qt86w2aja6bs")
var movement_blocked := false
var voice_emitter_active := false
const speed = 120.0
var direction_sprite := "down"

var input_multiplayer_authority: int:
	set(value):
		input_multiplayer_authority = value
		set_multiplayer_authority(value, true)

var ufo_idx: int = 0:
	set(value):
		ufo_idx = value
		if is_inside_tree() and animation_player:
			if AliensTextures.alien_textures.size() > ufo_idx:
				var my_skin = AliensTextures.alien_textures[ufo_idx]
				set_animations(my_skin)


func _ready():
	collision_area.area_entered.connect(_on_alien_find_skeptic)

	if AliensTextures.alien_textures.size() > ufo_idx:
		set_animations(AliensTextures.alien_textures[ufo_idx])

	if input_multiplayer_authority == 0 and name.is_valid_int():
		input_multiplayer_authority = name.to_int()

	if has_node("PlayerInputSynchronizer"):
		player_input_synchronizer.set_multiplayer_authority(input_multiplayer_authority)
		player_input_synchronizer.set_process(is_multiplayer_authority())
		player_input_synchronizer.set_physics_process(is_multiplayer_authority())

	if is_multiplayer_authority() and has_node("Camera2D"):
		set_camera(camera, 6.0)

	for node in get_tree().get_nodes_in_group("skeptics") + get_tree().get_nodes_in_group("ufos") + get_tree().get_nodes_in_group("aliens"):
		if node.is_multiplayer_authority():
			if node.name.begins_with("To_Delete_"):
				continue
			break


func callable_initialize_visibility():
	if is_multiplayer_authority():
		get_tree().call_group("ufos", "set_visible", true)
		get_tree().call_group("skeptics", "set_visible", true)
		get_tree().call_group("aliens", "set_visible", true)


func _process(_delta):
	if not is_multiplayer_authority():
		return

	if Input.is_action_just_pressed("call_other_skeptic") and not voice_emitter_active:
		call_other_skeptic_network.rpc()


func _physics_process(_delta):
	var sync_direction: Vector2 = Vector2.ZERO

	if has_node("PlayerInputSynchronizer"):
		sync_direction = $PlayerInputSynchronizer.movement_vector

	if is_multiplayer_authority() && !movement_blocked:
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


func _on_dialog_timer_timeout(node: Node2D):
	if node != null:
		node.queue_free()


func _on_alien_find_skeptic(area: Area2D):
	var object = area.get_parent()
	if object is Skeptic:
		object.belive_points_changed.emit(1)


func set_animations(animations_sprites: AliensTextures.AlienTextures):
	var animation_down: Animation = animation_player.get_animation("move down")
	var animation_down_track_idx = animation_down.find_track("Sprite2D:texture", Animation.TYPE_VALUE)

	var tex_idle = animations_sprites.front
	var tex_jump = animations_sprites.jump
	var tex_duck = animations_sprites.duck

	animation_down.track_set_key_value(animation_down_track_idx, 0, tex_idle)
	animation_down.track_set_key_value(animation_down_track_idx, 1, tex_jump)
	animation_down.track_set_key_value(animation_down_track_idx, 2, tex_duck)
	animation_down.track_set_key_value(animation_down_track_idx, 3, tex_idle)
	animation_down.track_set_key_value(animation_down_track_idx, 4, tex_jump)
	animation_down.track_set_key_value(animation_down_track_idx, 5, tex_duck)

	var animation_up: Animation = animation_player.get_animation("move up")
	var animation_up_track_idx = animation_up.find_track("Sprite2D:texture", Animation.TYPE_VALUE)

	animation_up.track_set_key_value(animation_up_track_idx, 0, animations_sprites.climb_a)
	animation_up.track_set_key_value(animation_up_track_idx, 1, animations_sprites.climb_b)

	var animation_left: Animation = animation_player.get_animation("move left")
	var animation_left_track_idx = animation_left.find_track("Sprite2D:texture", Animation.TYPE_VALUE)

	animation_left.track_set_key_value(animation_left_track_idx, 0, animations_sprites.walk_a)
	animation_left.track_set_key_value(animation_left_track_idx, 1, tex_idle)
	animation_left.track_set_key_value(animation_left_track_idx, 2, animations_sprites.walk_b)
	animation_left.track_set_key_value(animation_left_track_idx, 3, tex_idle)

	var animation_right: Animation = animation_player.get_animation("move right")
	var animation_right_track_idx = animation_right.find_track("Sprite2D:texture", Animation.TYPE_VALUE)

	animation_right.track_set_key_value(animation_right_track_idx, 0, animations_sprites.walk_a)
	animation_right.track_set_key_value(animation_right_track_idx, 1, tex_idle)
	animation_right.track_set_key_value(animation_right_track_idx, 2, animations_sprites.walk_b)
	animation_right.track_set_key_value(animation_right_track_idx, 3, tex_idle)

	var animation_idle: Animation = animation_player.get_animation("idle down")
	var animation_idle_track_idx = animation_idle.find_track("Sprite2D:texture", Animation.TYPE_VALUE)

	animation_idle.track_set_key_value(animation_idle_track_idx, 0, tex_idle)


func animate(direction: Vector2):
	var directions = {
		"down": Vector2.DOWN,
		"up": Vector2.UP,
		"left": Vector2.LEFT,
		"right": Vector2.RIGHT,
	}
	var norm_dir = direction.normalized()
	var animation_sprite_name_suffix = ""
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
		animation_player.play("idle down" + animation_sprite_name_suffix)
