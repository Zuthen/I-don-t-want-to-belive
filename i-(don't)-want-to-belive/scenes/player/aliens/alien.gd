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
var fly_away_active: = false
const speed = 105.0
var direction_sprite := "down"
var peer_id: int
var near_wreck = false:
	set(value):
		if near_wreck != value:
			near_wreck = value
			near_wreck_changed.emit(value)

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

signal ufo_repaired
signal repairing(time: float)
signal near_wreck_changed(near: bool)
signal fly_away_activated(active: bool)


func _ready():
	collision_area.area_entered.connect(_on_skeptic_seen_alien)
	await get_tree().process_frame
	_apply_skin_textures()

	peer_id = get_multiplayer_authority()
	if is_multiplayer_authority():
		get_tree().call_group("skeptics", "_update_visibility_for_local_player")


func get_ufo_with_alien_container() -> UfoWithAlien:
	var ufo_with_alien = get_parent()
	return ufo_with_alien


func _get_wreck_by_id(wreck_id: int) -> Wreck:
	var wrecks = get_tree().get_nodes_in_group("wrecks") as Array[Wreck]
	var wreck_idx = wrecks.find_custom(func(wreck): return wreck.peer_id == wreck_id)
	return wrecks[wreck_idx]


func fly_away():
	var wreck = _get_wreck_by_id(peer_id) as Wreck
	var animation_time = wreck.animator.get_animation("fixed").length
	if near_wreck and wreck.fixed:
		start_cooldown_timer(animation_time, func(): movement_blocked = !movement_blocked)
		Events.aliens_ufo_is_fixed.emit(peer_id)


func repair_ufo():
	if near_wreck:
		var animation_time = animation_player.get_animation("ufo repair").length
		animation_player.play("ufo repair")
		ItemsManager.item_used.emit("repair_tool", self)
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
					Events.aliens_ufo_is_fixed.emit(peer_id)
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

	if Input.is_action_just_pressed("alien_fly_away") and fly_away_active:
		fly_away()


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
	var anim_down = animation_player.get_animation("move down")
	var anim_up = animation_player.get_animation("move up")
	var anim_repair = animation_player.get_animation("ufo repair")
	var anim_left = animation_player.get_animation("move left")
	var anim_right = animation_player.get_animation("move right")
	var anim_idle = animation_player.get_animation("idle down")

	var down_sprites: Array[Texture2D] = [
		animations_sprites.front,
		animations_sprites.jump,
		animations_sprites.duck,
		animations_sprites.front,
		animations_sprites.jump,
		animations_sprites.duck,
	]

	var track_path = "Sprite2D:texture"
	var track = anim_repair.find_track(track_path, Animation.TYPE_VALUE)
	var keys_size = anim_repair.track_get_key_count(track)
	if track != -1:
		for i in range(0, keys_size - 1, 2):
			anim_repair.track_set_key_value(track, i, animations_sprites.climb_a)
			anim_repair.track_set_key_value(track, i + 1, animations_sprites.climb_b)

	var left_sprites: Array[Texture2D] = [
		animations_sprites.walk_a,
		animations_sprites.front,
		animations_sprites.walk_b,
		animations_sprites.front,
	]

	var idle_sprites: Array[Texture2D] = [
		animations_sprites.idle,
		animations_sprites.front,
		animations_sprites.idle,
		animations_sprites.front,
	]

	AnimationSetup.setup_textures(anim_down, down_sprites)
	AnimationSetup.setup_textures(anim_up, [animations_sprites.climb_a, animations_sprites.climb_b])
	AnimationSetup.setup_textures(anim_left, left_sprites)
	AnimationSetup.setup_textures(anim_right, left_sprites)
	AnimationSetup.setup_textures(anim_idle, idle_sprites)


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


func jammered_walkie_talkie_message():
	var coordinates = get_coordinates(global_position)
	var message: String = ""

	if randi() % 100 >= 40:
		message = str(coordinates.number)
	else:
		message = coordinates.letter + str(coordinates.number) if randi() % 100 < 40 else coordinates.letter
	MultiplayerFeatures.broadcast_walkie_talkie.rpc(message)
	ItemsManager.item_used.emit("signal_jammer", self)
