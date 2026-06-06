extends Node2D

class_name CrashedUfo

@onready var sprite_2d = $Sprite2D
@onready var vision = $Vision
@onready var collision_shape = $Vision/CollisionShape2D
@onready var explosion = $Explosion
@onready var particle = $Particle

var peer_id: int
var ufo_texture_idx:
	set(value):
		ufo_texture_idx = value
		if is_inside_tree() and sprite_2d and value != null:
			if UfosTextures.ufo_textures.size() > value:
				sprite_2d.texture = UfosTextures.ufo_textures[value].ship_crashed
				print("[WRAK] Tekstura nałożona pomyślnie dla indeksu: ", value)

signal crashed_ufo_seen(peer_id: int)


func _ready():
	collision_shape_setup()
	var explosion_time = explosion.get_animation("crash").length
	var explosion_timer = Timer.new()
	explosion_timer.one_shot = true
	explosion_timer.timeout.connect(func(): particle.visible = false)
	add_child(explosion_timer)
	explosion_timer.start(explosion_time)
	explosion.play("crash")
	if ufo_texture_idx != null and UfosTextures.ufo_textures.size() > ufo_texture_idx:
		sprite_2d.texture = UfosTextures.ufo_textures[ufo_texture_idx].ship_crashed

	vision.area_entered.connect(_on_crashed_ufo_seen)


func _on_crashed_ufo_seen(other):
	var player = other.get_parent()
	if player is Skeptic:
		if not crashed_ufo_seen.is_connected(player._on_crashed_ufo_discovered):
			crashed_ufo_seen.connect(player._on_crashed_ufo_discovered, CONNECT_ONE_SHOT)
		crashed_ufo_seen.emit(peer_id)


func collision_shape_setup():
	collision_shape.shape = collision_shape.shape.duplicate()
	var box_shape = collision_shape.shape as RectangleShape2D
	if box_shape:
		box_shape.size = Vector2(MapSettings.tile_size * 10, MapSettings.tile_size * 10)
