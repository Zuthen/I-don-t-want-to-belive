extends Area2D

class_name Collectable
@onready var collision_shape_2d = $CollisionShape2D
@onready var sprite_2d = $Sprite2D
@onready var collectable = $"."

var texture: Texture2D
var item_name: String
var faction: Player.Role

var skeptic_color = Color("e35775ff")
var alien_color = Color("57e357ff")
var both_color = Color("5796e3ff")


func _ready():
	sprite_2d.texture = texture
	collectable.area_entered.connect(_collect)


func set_faction(item_name):
	match item_name:
		"sanity_pills":
			faction = Player.Role.SKEPTIC
		"repair_tool":
			faction = Player.Role.ALIEN
		_:
			faction = Player.Role.BOTH


func _collect(other):
	var current_node = other
	var player: Player = null

	while current_node != null and current_node != get_tree().root:
		if "id" in current_node and current_node.id != 0:
			player = current_node as Player
			break
		current_node = current_node.get_parent() as Player

	var peer_id = player.id
	var my_id = multiplayer.get_unique_id()
	if peer_id == my_id:
		var backpack = player.get_backpack()
		player.can_collect = backpack.can_collect()
		if player.can_collect:
			Events.item_collected.emit(texture, item_name, faction)
			_request_server_removal.rpc_id(1)


func _draw():
	var radius = collision_shape_2d.shape.radius
	var color: Color
	match faction:
		Player.Role.ALIEN:
			color = alien_color
		Player.Role.SKEPTIC:
			color = skeptic_color
		Player.Role.BOTH:
			color = both_color
		_:
			color = both_color

	var stroke_thickness: float = 0.6
	var outer_radius: float = radius + stroke_thickness
	var stroke_color: Color = color.darkened(0.25)
	draw_circle(Vector2.ZERO, outer_radius, stroke_color, true, -1.0, true)
	draw_circle(Vector2.ZERO, radius, color, true, -1.0, true)


@rpc("any_peer", "call_local", "reliable")
func _request_server_removal():
	if multiplayer.is_server():
		queue_free()
