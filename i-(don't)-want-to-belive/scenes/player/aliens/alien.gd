class_name Alien
extends Player

@onready var animation_player = $AnimationPlayer
@onready var dialog_timer = $DialogTimer
@onready var dialog_placements = $DialogPlacements
@onready var sprite_2d = $Sprite2D
@onready var coordinates = $Coordinates
@onready var collision_area = $CollisionArea

var icon_placeholder_scene: PackedScene = preload("uid://d03xota05sdvx")
var voice_emitter_scene: PackedScene = preload("uid://qt86w2aja6bs")
var movement_blocked := false
var voice_emitter_active := false
const speed = 105.0
var direction_sprite := "down"
var peer_id: int
var textures: AliensTextures

var current_skin: AliensTextures.AlienTextures = null

var input_multiplayer_authority: int:
	set(value):
		input_multiplayer_authority = value
		set_multiplayer_authority(value, true)

var ufo_idx: int = 0:
	set(value):
		ufo_idx = value
		_apply_skin_textures()


func _ready():
	collision_area.area_entered.connect(on_skeptic_seen_alien)
	_apply_skin_textures()

	if is_multiplayer_authority():
		peer_id = get_multiplayer_authority()
		get_tree().call_group("skeptics", "_update_visibility_for_local_player")


func _physics_process(_delta):
	var sync_direction: Vector2 = Vector2.ZERO
	var parent_node = get_parent()

	if parent_node and parent_node.has_node("PlayerInputSynchronizer"):
		sync_direction = parent_node.get_node("PlayerInputSynchronizer").movement_vector

	if is_multiplayer_authority() && !movement_blocked and parent_node:
		parent_node.velocity = speed * sync_direction
		parent_node.move_and_slide()

	animate(sync_direction)


@rpc("any_peer", "call_local", "reliable")
func _sync_alien_skin_across_network(assigned_idx: int):
	ufo_idx = assigned_idx
	_apply_skin_textures()


func _apply_skin_textures():
	var alien_skins_idx = map_alien_color(ufo_idx)
	if alien_skins_idx != -1 and alien_skins_idx < AliensTextures.alien_textures.size():
		current_skin = AliensTextures.alien_textures[alien_skins_idx]

		if is_inside_tree() and animation_player and sprite_2d:
			set_animations(current_skin)
			sprite_2d.texture = current_skin.front


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


func on_skeptic_seen_alien(area: Area2D):
	var object = area.get_parent()
	if object is Skeptic:
		object.alien_seen.emit(peer_id)


func set_animations(animations_sprites: AliensTextures.AlienTextures):
	var track_path = "Sprite2D:texture"

	var anim_down = animation_player.get_animation("move down")
	var track_down = anim_down.find_track(track_path, Animation.TYPE_VALUE)
	if track_down != -1:
		anim_down.track_set_key_value(track_down, 0, animations_sprites.front)
		anim_down.track_set_key_value(track_down, 1, animations_sprites.jump)
		anim_down.track_set_key_value(track_down, 2, animations_sprites.duck)
		anim_down.track_set_key_value(track_down, 3, animations_sprites.front)
		anim_down.track_set_key_value(track_down, 4, animations_sprites.jump)
		anim_down.track_set_key_value(track_down, 5, animations_sprites.duck)

	var anim_up = animation_player.get_animation("move up")
	var track_up = anim_up.find_track(track_path, Animation.TYPE_VALUE)
	if track_up != -1:
		anim_up.track_set_key_value(track_up, 0, animations_sprites.climb_a)
		anim_up.track_set_key_value(track_up, 1, animations_sprites.climb_b)

	var anim_left = animation_player.get_animation("move left")
	var track_left = anim_left.find_track(track_path, Animation.TYPE_VALUE)
	if track_left != -1:
		anim_left.track_set_key_value(track_left, 0, animations_sprites.walk_a)
		anim_left.track_set_key_value(track_left, 1, animations_sprites.front)
		anim_left.track_set_key_value(track_left, 2, animations_sprites.walk_b)
		anim_left.track_set_key_value(track_left, 3, animations_sprites.front)

	var anim_right = animation_player.get_animation("move right")
	var track_right = anim_right.find_track(track_path, Animation.TYPE_VALUE)
	if track_right != -1:
		anim_right.track_set_key_value(track_right, 0, animations_sprites.walk_a)
		anim_right.track_set_key_value(track_right, 1, animations_sprites.front)
		anim_right.track_set_key_value(track_right, 2, animations_sprites.walk_b)
		anim_right.track_set_key_value(track_right, 3, animations_sprites.front)

	var anim_idle = animation_player.get_animation("idle down")
	var track_idle = anim_idle.find_track(track_path, Animation.TYPE_VALUE)
	if track_idle != -1:
		anim_idle.track_set_key_value(track_idle, 0, animations_sprites.idle)
		anim_idle.track_set_key_value(track_idle, 1, animations_sprites.front)
		anim_idle.track_set_key_value(track_idle, 2, animations_sprites.idle)
		anim_idle.track_set_key_value(track_idle, 3, animations_sprites.front)


func animate(direction: Vector2):
	var directions = {
		"down": Vector2.DOWN,
		"up": Vector2.UP,
		"left": Vector2.LEFT,
		"right": Vector2.RIGHT,
	}
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
		animation_player.play("idle down")


func map_alien_color(idx: int) -> int:
	if idx < 0 or idx >= UfosTextures.ufo_textures.size():
		return 0
	if UfosTextures.ufo_textures[idx].color == "Blue":
		return AliensTextures.alien_textures.find_custom(func(texture): return texture.color == "purple")
	return AliensTextures.alien_textures.find_custom(func(texture): return texture.color == UfosTextures.ufo_textures[idx].color.to_lower())
