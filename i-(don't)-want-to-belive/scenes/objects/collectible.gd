extends Area2D

class_name Collectible
@onready var collision_shape_2d = $CollisionShape2D
@onready var sprite_2d = $Sprite2D
@onready var collectible = $"."

var texture: Texture2D
var on_collect: Callable

signal collected(texture: Texture2D)


func _ready():
	sprite_2d.texture = texture
	collectible.area_entered.connect(_collect)


func _collect(other):
	var player = other.get_parent()
	var my_id = multiplayer.get_unique_id()
	if player.id == my_id:
		Events.item_collected.emit(texture)
	if is_multiplayer_authority():
		queue_free()


func _draw():
	var radius = collision_shape_2d.shape.radius
	var color = Color(0.89, 0.34, 0.46, 1)
	var stroke_thickness: float = 0.6
	var outer_radius: float = radius + stroke_thickness
	var stroke_color: Color = color.darkened(0.25)
	draw_circle(Vector2.ZERO, outer_radius, stroke_color, true, -1.0, true)
	draw_circle(Vector2.ZERO, radius, color, true, -1.0, true)
