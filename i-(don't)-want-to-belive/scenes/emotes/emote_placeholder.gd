class_name IconPlaceholder
extends Node2D

@onready var sprite_2d = $Sprite2D

var net_icon_key: String = ""
var net_sender_id: int = 0
var net_target_id: int = 0
var net_is_laser_type: bool = false
var net_target_pos: Vector2 = Vector2.ZERO

const ICONS_PATHS = {
	angry = "uid://ddjkfec0jsuw",
	call = "uid://cblgq5okooy2",
	alien_warning = "uid://bvj1pjxt7q1du",
}


func _ready():
	z_index = 25
	set_as_top_level(true)

	visible = false
	if is_instance_valid(sprite_2d):
		sprite_2d.visible = false
		sprite_2d.texture = null

	get_tree().create_timer(3.0).timeout.connect(
		func():
			if is_inside_tree() and multiplayer.is_server():
				queue_free()
	)

	await get_tree().create_timer(0.1).timeout
	_configure_icon_state()


func _configure_icon_state():
	if not is_inside_tree():
		return

	var my_id = multiplayer.get_unique_id()
	var local_player = get_local_character()

	if local_player == null:
		return

	var local_role = local_player.role if "role" in local_player else Player.Role.SKEPTIC

	if net_is_laser_type:
		if my_id == net_target_id or my_id == net_sender_id:
			visible = true
			if is_instance_valid(sprite_2d):
				sprite_2d.visible = true
		else:
			visible = false
			if is_instance_valid(sprite_2d):
				sprite_2d.visible = false
			return
	else:
		if local_role == Player.Role.UFO:
			visible = false
			if is_instance_valid(sprite_2d):
				sprite_2d.visible = false
			return
		else:
			visible = true
			if is_instance_valid(sprite_2d):
				sprite_2d.visible = true

	var icon_path = ICONS_PATHS.get(net_icon_key, ICONS_PATHS.call)
	var icon_texture: Texture2D = load(icon_path)

	if local_role == Player.Role.SKEPTIC or local_player.is_in_group("skeptics"):
		var warning = randi() % 100 < 40
		if warning:
			icon_texture = load(ICONS_PATHS.alien_warning) as Texture2D

	if is_instance_valid(sprite_2d):
		sprite_2d.texture = icon_texture


func get_local_character() -> Node:
	var all_nodes = get_tree().get_nodes_in_group("ufos") + get_tree().get_nodes_in_group("skeptics") + get_tree().get_nodes_in_group("aliens")
	var my_id = multiplayer.get_unique_id()
	for node in all_nodes:
		if "id" in node and node.id == my_id:
			return node
	return null
