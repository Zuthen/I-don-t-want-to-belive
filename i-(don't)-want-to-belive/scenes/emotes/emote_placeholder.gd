class_name IconPlaceholder
extends Node2D

@onready var sprite_2d = $Sprite2D
@export var texture: Texture2D = load("uid://cblgq5okooy2")

var accepts_role: Array[Player.Role]
var icon: Texture2D
var role: Player.Role


func setup(player_role: Player.Role, accepted_roles: Array[Player.Role], icon: Texture2D = texture):
	role = player_role
	accepts_role = accepted_roles
	var warning = randi() % 100 < 40

	var icon_path: String = ""
	if is_instance_valid(icon):
		icon_path = icon.resource_path

	display_icon.rpc(icon_path, player_role, warning, accepted_roles)


@rpc("any_peer", "call_local", "reliable")
func display_icon(base_icon_path: String, player_role: Player.Role, warning: bool, net_accepted_roles: Array):
	accepts_role = Array(net_accepted_roles, TYPE_INT, &"", null)
	role = player_role

	var local_player = get_local_character()
	if local_player == null:
		return

	var local_role = local_player.role

	var base_icon: Texture2D = texture
	if base_icon_path != "":
		base_icon = load(base_icon_path) as Texture2D

	sprite_2d.texture = determine_local_texture(local_role, player_role, base_icon, warning)

	if not accepts_role.has(local_role):
		sprite_2d.visible = false
	else:
		sprite_2d.visible = true
		sprite_2d.scale = Vector2(1.5, 1.5)


func determine_local_texture(local_role: Player.Role, target_role: Player.Role, base_icon: Texture2D, warning: bool) -> Texture2D:
	if local_role == Player.Role.SKEPTIC and target_role == Player.Role.ALIEN and warning:
		return load("uid://bvj1pjxt7q1du")
	return base_icon


func get_local_character() -> Node:
	var all_nodes = get_tree().get_nodes_in_group("ufos") + get_tree().get_nodes_in_group("skeptics") + get_tree().get_nodes_in_group("aliens")

	for node in all_nodes:
		if node.get_multiplayer_authority() == multiplayer.get_unique_id():
			if "role" in node:
				return node
			for child in node.get_children():
				if "role" in child:
					return child
	return null
