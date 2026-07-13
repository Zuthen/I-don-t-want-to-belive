extends Player

class_name Alien

@onready var animation_player = $AnimationPlayer
@onready var dialog_timer = $DialogTimer
@onready var dialog_placements = $DialogPlacements
@onready var sprite_2d = $Sprite2D
@onready var coordinates = $Coordinates
@onready var collision_area = $CollisionArea
@onready var collector = $Collector
@onready var camera = $Camera2D

var icon_placeholder_scene: PackedScene = preload("uid://d03xota05sdvx")
var voice_emitter_scene: PackedScene = preload("uid://qt86w2aja6bs")
var voice_emitter_active := false
const speed = 105.0
var direction_sprite := "down"
var peer_id: int
var can_repair_ufo = false
var near_wreck = false

var current_skin: AliensTextures.AlienTextures = null

var input_multiplayer_authority: int:
	set(value):
		input_multiplayer_authority = value
		set_multiplayer_authority(value)

var skin_idx: int = 0:
	set(value):
		skin_idx = value
		if is_node_ready():
			_apply_skin_textures()

@warning_ignore_start("unused_signal")
signal can_repair
signal cannot_repair
signal ufo_repaired
signal repairing(time: float)


func _ready():
	collision_area.area_entered.connect(_on_skeptic_seen_alien)
	Events.item_collected.connect(_assign_item_action)
	await get_tree().process_frame
	_apply_skin_textures()

	peer_id = get_multiplayer_authority()
	if is_multiplayer_authority():
		get_tree().call_group("skeptics", "_update_visibility_for_local_player")


func _assign_item_action(_texture, item_name, faction):
	assign_item_action(item_name, Role.ALIEN, self, faction)


func _repair_ufo():
	var animation_time = animation_player.get_animation("ufo repair").length
	animation_player.play("ufo repair")
	repairing.emit(animation_time)
	if is_multiplayer_authority():
		movement_blocked = true
		var timer = Timer.new()
		timer.one_shot = true
		add_child(timer)
		timer.timeout.connect(
			func():
				movement_blocked = false
				var synchronizer = get_parent().get_node_or_null("PlayerInputSynchronizer")
				if is_instance_valid(synchronizer):
					_animate(synchronizer.movement_vector)
		)
		timer.timeout.connect(
			func():
				timer.queue_free()
				Events.alien_fixed_ufo.emit(peer_id)
		)
		timer.start(animation_time)


func _apply_skin_textures():
	var alien_skins_idx = _map_alien_color(skin_idx)
	if alien_skins_idx != -1 and alien_skins_idx < AliensTextures.alien_textures.size():
		current_skin = AliensTextures.alien_textures[alien_skins_idx]

		if animation_player and sprite_2d:
			_set_animations(current_skin)
			sprite_2d.texture = current_skin.front


func _process(_delta):
	if not is_multiplayer_authority():
		return

	if Input.is_action_just_pressed("call_other_skeptic") and not voice_emitter_active:
		_call_skeptic_network.rpc()

	if can_repair_ufo and near_wreck and Input.is_action_just_pressed("repair_ufo"):
		_repair_ufo()


@rpc("call_local", "any_peer", "reliable")
func _call_skeptic_network():
	voice_emitter_active = true
	var voice_emitter = voice_emitter_scene.instantiate()
	add_child(voice_emitter)
	voice_emitter.timer.timeout.connect(_reset_voice_emmitter)


func _reset_voice_emmitter():
	voice_emitter_active = false


func _call_skeptic():
	_call_skeptic_network()


func _on_skeptic_seen_alien(area: Area2D):
	var object = area.get_parent()
	if object is Skeptic:
		object.alien_seen.emit(peer_id)


func _set_animations(animations_sprites: AliensTextures.AlienTextures):
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

	var anim_repair = animation_player.get_animation("ufo repair")
	var track = anim_repair.find_track(track_path, Animation.TYPE_VALUE)
	var keys_size = anim_repair.track_get_key_count(track)
	if track != -1:
		for i in range(0, keys_size - 1, 2):
			anim_repair.track_set_key_value(track, i, animations_sprites.climb_a)
			anim_repair.track_set_key_value(track, i + 1, animations_sprites.climb_b)

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


func _animate(direction: Vector2):
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


func _map_alien_color(idx: int) -> int:
	if idx < 0 or idx >= UfosTextures.ufo_textures.size():
		return 0
	if UfosTextures.ufo_textures[idx].color == "Blue":
		return AliensTextures.alien_textures.find_custom(func(texture): return texture.color == "purple")
	return AliensTextures.alien_textures.find_custom(func(texture): return texture.color == UfosTextures.ufo_textures[idx].color.to_lower())
