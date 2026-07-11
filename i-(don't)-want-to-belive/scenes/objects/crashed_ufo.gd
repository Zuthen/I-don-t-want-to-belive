extends Node2D

class_name CrashedUfo

@onready var sprite_2d = $Sprite2D
@onready var vision = $Vision
@onready var collision_shape = $Vision/CollisionShape2D
@onready var animator = $Animator
@onready var particle = $Particle
@onready var repair_area = $RepairArea

var peer_id: int
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


func _connect_signals():
	repair_area.area_entered.connect(_enable_ufo_repair)
	repair_area.area_exited.connect(_disable_ufo_repair)
	vision.area_entered.connect(_on_crashed_ufo_seen)
	Events.alien_fixed_ufo.connect(_on_fixed)


func _enable_ufo_repair(body):
	var my_id = multiplayer.get_unique_id()
	var ufo_with_alien = _find_ufo_with_alien_node(body)
	if ufo_with_alien is UfoWithAlien and ufo_with_alien.id == my_id:
		var alien = ufo_with_alien.get_node("Alien") as Alien
		alien.near_wreck = true
		if alien.can_repair_ufo:
			alien.can_repair.emit()


func _find_ufo_with_alien_node(body) -> Node:
	var current_node = body
	var main_player_root: Node = null
	while current_node != null and current_node != get_tree().root:
		if "id" in current_node and current_node.id != 0:
			main_player_root = current_node
			break
		current_node = current_node.get_parent()
	return main_player_root


func _disable_ufo_repair(body):
	var my_id = multiplayer.get_unique_id()
	var ufo_with_alien = _find_ufo_with_alien_node(body)
	if ufo_with_alien is UfoWithAlien and ufo_with_alien.id == my_id:
		var alien = ufo_with_alien.get_node("Alien")
		alien.near_wreck = false
		alien.cannot_repair.emit()


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
	var track_path = "Sprite2D:texture"
	var fixed_animation = animator.get_animation("fixed")
	var track = fixed_animation.find_track(track_path, Animation.TYPE_VALUE)
	if track != -1:
		fixed_animation.track_set_key_value(track, 0, UfosTextures.ufo_textures[ufo_texture_idx].ship)


func _on_fixed_animation_complete():
	_request_server_to_destroy.rpc_id(1)


@rpc("any_peer", "call_local", "reliable")
func _request_server_to_destroy():
	if multiplayer.is_server():
		visible = false
		queue_free()
