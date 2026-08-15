extends Area2D

class_name Collectable
@onready var collision_shape_2d = $CollisionShape2D
@onready var sprite_2d = $Sprite2D
@onready var collectable = $"."

var texture: Texture2D
var item_name: String
var item_faction: Player.Role
var was_collected: bool = false

var not_usable_color = Color("e35775ff")
var usable_color = Color("57e357ff")
var final_color: Color = Color.WHITE


func _ready():
	sprite_2d.texture = texture
	collectable.area_entered.connect(_collect)
	_update_color_by_local_player_role()


func _update_color_by_local_player_role():
	var local_player: Player = null
	var my_id = multiplayer.get_unique_id()

	var local_players_group = get_tree().get_nodes_in_group("local_player")
	if local_players_group.size() > 0:
		local_player = local_players_group[0] as Player

	if not is_instance_valid(local_player):
		var game_node = get_node_or_null("/root/Game")
		if game_node:
			local_player = game_node.get_node_or_null(str(my_id)) as Player

	if is_instance_valid(local_player):
		var is_usable = local_player.check_usable(item_name, local_player.role)
		if is_usable:
			final_color = usable_color
		else:
			final_color = not_usable_color
	else:
		final_color = not_usable_color
	queue_redraw()


func _collect(other):
	if was_collected:
		return

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
			was_collected = true
			ItemsManager.item_collected.emit(texture, item_name, player.role, final_color, player.id)
			if player.role == Player.Role.BOSS and item_name == "steering_wheel":
				player.steering_wheel_collected = true
			_request_server_removal.rpc_id(1)


func _draw():
	var radius = collision_shape_2d.shape.radius
	var stroke_thickness: float = 0.6
	var outer_radius: float = radius + stroke_thickness
	var stroke_color: Color = final_color.darkened(0.25)

	draw_circle(Vector2.ZERO, outer_radius, stroke_color, true, -1.0, true)
	draw_circle(Vector2.ZERO, radius, final_color, true, -1.0, true)


@rpc("any_peer", "call_local", "reliable")
func _request_server_removal():
	if multiplayer.is_server():
		queue_free()
