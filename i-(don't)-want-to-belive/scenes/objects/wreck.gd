extends Node2D

class_name Wreck

@onready var sprite_2d = $Sprite2D
@onready var vision = $Vision
@onready var collision_shape = $Vision/CollisionShape2D
@onready var animator = $Animator
@onready var particle = $Particle
@onready var repair_area = $RepairArea
@onready var steering_wheel = $SteeringWheel

var peer_id: int
var steering_wheel_mounted = false
var fixed: bool = false

var ufo_texture_idx:
	set(value):
		ufo_texture_idx = value
		if is_inside_tree() and sprite_2d and value != null:
			if UfosTextures.ufo_textures.size() > value:
				sprite_2d.texture = UfosTextures.ufo_textures[value].ship_crashed

signal crashed_ufo_seen(peer_id: int)


func _ready():
	if ufo_texture_idx != null and UfosTextures.ufo_textures.size() > ufo_texture_idx:
		sprite_2d.texture = UfosTextures.ufo_textures[ufo_texture_idx].ship_crashed
	collision_shape_setup()
	_set_animations()
	_connect_signals()
	animator.play("crash")
	await animator.animation_finished
	animator.play("idle")
	steering_wheel.visible = false


func _connect_signals():
	repair_area.area_entered.connect(_set_near_wreck)
	repair_area.area_exited.connect(_reset_near_wreck)
	vision.area_entered.connect(_on_crashed_ufo_seen)
	Events.aliens_ufo_is_fixed.connect(_on_fixed)


func _set_near_wreck(collector: Area2D):
	var parent_node = collector.get_parent()
	if not is_instance_valid(parent_node) or not ("role" in parent_node):
		return

	var my_id = multiplayer.get_unique_id()
	var collector_role = parent_node.role
	if collector_role == Player.Role.ALIEN:
		var alien = parent_node as Alien
		if is_instance_valid(alien):
			var ufo_with_alien = alien.get_ufo_with_alien_container()
			if is_instance_valid(ufo_with_alien) and ufo_with_alien.id == my_id:
				alien.near_wreck = true
				if fixed:
					alien.fly_away_active = true
					alien.fly_away_activated.emit(true)

	elif collector_role == Player.Role.BOSS:
		var robert = parent_node as Robert
		if is_instance_valid(robert):
			if robert.id == my_id:
				robert.near_wreck = true
				robert.near_wreck_changed.emit(true, peer_id)


func _reset_near_wreck(collector: Area2D):
	var my_id = multiplayer.get_unique_id()
	var collector_role = collector.get_parent().role
	if collector_role == Player.Role.ALIEN:
		var alien = collector.get_parent() as Alien
		var ufo_with_alien = alien.get_ufo_with_alien_container()
		if ufo_with_alien.id == my_id:
			alien.near_wreck = false
			alien.fly_away_active = false
			alien.fly_away_activated.emit(false)
	elif collector_role == Player.Role.BOSS:
		var robert = collector.get_parent() as Robert
		if robert.id == my_id:
			robert.near_wreck = false
			robert.near_wreck_changed.emit(false, peer_id)


func _on_crashed_ufo_seen(other):
	var player = other.get_parent()
	if player is Skeptic:
		if player.is_multiplayer_authority():
			if player.has_method("_on_crashed_ufo_discovered"):
				player._on_crashed_ufo_discovered(peer_id)
		crashed_ufo_seen.emit(peer_id)


func collision_shape_setup():
	collision_shape.shape = collision_shape.shape.duplicate()
	var box_shape = collision_shape.shape as RectangleShape2D
	if box_shape:
		box_shape.size = Vector2(MapSettings.tile_size * 10, MapSettings.tile_size * 10)


func _on_fixed(_alien_peer_id):
	animator.play("fixed")


func send_ufo_fixed_signal():
	var track_path = "Sprite2D:position"
	var fixed_animation = animator.get_animation("fixed")
	var track = fixed_animation.find_track(track_path, Animation.TYPE_VALUE)

	var local_position = fixed_animation.track_get_key_value(track, 1)
	var new_position = sprite_2d.to_global(local_position)
	Events.ufo_fixed.emit(new_position)


func _set_animations():
	var fixed_animation = animator.get_animation("fixed")

	AnimationSetup.setup_textures(fixed_animation, [UfosTextures.ufo_textures[ufo_texture_idx].ship])
	var robert_fixing_animation = animator.get_animation("robert fixing")
	var ufos_sprites: Array[Texture2D] = [
		UfosTextures.ufo_textures[ufo_texture_idx].ship_crashed,
		UfosTextures.ufo_textures[ufo_texture_idx].ship_damage,
		UfosTextures.ufo_textures[ufo_texture_idx].ship_fixed,
	]
	AnimationSetup.setup_textures(robert_fixing_animation, ufos_sprites)


func _on_fixed_animation_complete():
	_request_server_to_destroy.rpc_id(1)


func _get_wreck_by_id(wreck_id: int) -> Wreck:
	var wrecks = get_tree().get_nodes_in_group("wrecks") as Array[Wreck]
	var wreck_idx = wrecks.find_custom(func(wreck): return wreck.peer_id == wreck_id)
	return wrecks[wreck_idx]


@rpc("any_peer", "call_local", "reliable")
func network_repair():
	animator.play("robert fixing")
	fixed = true


@rpc("any_peer", "call_local", "reliable")
func _request_server_to_destroy():
	if multiplayer.is_server():
		visible = false
		queue_free()
