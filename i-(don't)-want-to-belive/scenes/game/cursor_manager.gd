extends Node

var texture: Texture2D = preload("uid://bucvfw8qc1fi3")


func _ready() -> void:
	Input.set_custom_mouse_cursor(texture, Input.CURSOR_POINTING_HAND, Vector2(0, 0))
	_apply_cursor_shape_globally()
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _apply_cursor_shape_globally() -> void:
	var all_nodes = get_tree().root.get_children()
	for node in all_nodes:
		_find_and_set_buttons(node)


func _find_and_set_buttons(current_node: Node) -> void:
	if current_node is BaseButton:
		current_node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for child in current_node.get_children():
		_find_and_set_buttons(child)
