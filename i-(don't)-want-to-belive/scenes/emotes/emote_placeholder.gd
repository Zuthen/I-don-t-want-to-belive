class_name IconPlaceholder
extends Node2D

@onready var sprite_2d = $Sprite2D
@export var default_texture: Texture2D = load("uid://cblgq5okooy2")

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
	_hide_icon()

	get_tree().create_timer(3.0).timeout.connect(
		func():
			if is_inside_tree() and get_tree().get_multiplayer().is_server():
				queue_free()
	)

	await get_tree().process_frame
	var my_id = multiplayer.get_unique_id()

	var icon_path = ICONS_PATHS.get(net_icon_key, ICONS_PATHS.call)
	var icon_texture: Texture2D = load(icon_path)

	var local_player = get_local_character()
	var local_role = local_player.role if local_player != null else Player.Role.SKEPTIC

	if net_is_laser_type:
		if my_id == net_target_id or my_id == net_sender_id:
			_show_icon()
		else:
			_hide_icon()
			return
	else:
		if local_role == Player.Role.UFO:
			_hide_icon()
			return
		else:
			_show_icon()

	if local_player != null:
		if sender_id_is_alien(net_sender_id):
			if local_role == Player.Role.SKEPTIC and randi() % 100 < 40:
				icon_texture = load(ICONS_PATHS.alien_warning) as Texture2D

	sprite_2d.texture = icon_texture


func _show_icon():
	visible = true


func _hide_icon():
	visible = false


func get_local_character() -> Node:
	var all_nodes = get_tree().get_nodes_in_group("ufos") + get_tree().get_nodes_in_group("skeptics") + get_tree().get_nodes_in_group("aliens")
	var my_id = multiplayer.get_unique_id()
	for node in all_nodes:
		if "id" in node and node.id == my_id:
			return node
	return null


func sender_id_is_alien(sender_id: int) -> bool:
	var all_nodes = get_tree().get_nodes_in_group("ufos") + get_tree().get_nodes_in_group("skeptics") + get_tree().get_nodes_in_group("aliens")
	for node in all_nodes:
		if "id" in node and node.id == sender_id:
			return node.is_in_group("aliens") or node.role == Player.Role.ALIEN
	return false
