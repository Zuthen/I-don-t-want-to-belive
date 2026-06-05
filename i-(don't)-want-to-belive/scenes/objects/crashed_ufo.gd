extends Node2D

class_name CrashedUfo

@onready var sprite_2d = $Sprite2D
@onready var vision = $Vision
@onready var collision_shape = $Vision/CollisionShape2D

var peer_id: int

signal crashed_ufo_seen(peer_id: int)

var texture: Texture2D:
	set(value):
		texture = value
		if sprite_2d:
			sprite_2d.texture = value


func _ready():
	collision_shape_setup()
	if texture and sprite_2d:
		sprite_2d.texture = texture
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
