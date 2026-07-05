extends Area2D

class_name Collectable
@onready var collision_shape_2d = $CollisionShape2D
@onready var sprite_2d = $Sprite2D
@onready var collectible = $"."

var texture: Texture2D
var item_name: String


func _ready():
	sprite_2d.texture = texture
	collectible.area_entered.connect(_collect)


func _collect(other):
	var current_node = other
	var main_player_root: Node = null

	while current_node != null and current_node != get_tree().root:
		if "id" in current_node and current_node.id != 0:
			main_player_root = current_node
			break
		current_node = current_node.get_parent()

	var peer_id = main_player_root.id
	var my_id = multiplayer.get_unique_id()

	if peer_id == my_id:
		Events.item_collected.emit(texture, item_name)

	if multiplayer.is_server():
		queue_free()


func _draw():
	var radius = collision_shape_2d.shape.radius
	var color = Color(0.89, 0.34, 0.46, 1)
	var stroke_thickness: float = 0.6
	var outer_radius: float = radius + stroke_thickness
	var stroke_color: Color = color.darkened(0.25)
	draw_circle(Vector2.ZERO, outer_radius, stroke_color, true, -1.0, true)
	draw_circle(Vector2.ZERO, radius, color, true, -1.0, true)
