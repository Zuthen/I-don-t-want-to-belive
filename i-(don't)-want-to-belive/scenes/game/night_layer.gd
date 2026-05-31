extends ColorRect

@export var sceptic_inner_radius: float = 0.02
@export var sceptic_outer_radius: float = 0.1
@export var sceptic_alpha: float = 0.96
@export var ufo_alpha: float = 0.9


func _process(_delta):
	var local_player = get_local_player()
	if not local_player:
		visible = false
		return

	visible = true

	if local_player.is_in_group("skeptics"):
		self.color.a = sceptic_alpha
		material.set_shader_parameter("inner_radius", sceptic_inner_radius)
		material.set_shader_parameter("outer_radius", sceptic_outer_radius)
		material.set_shader_parameter("min_alpha", 0.60)

		var canvas_pos = local_player.get_global_transform_with_canvas().origin
		var screen_size = get_viewport_rect().size
		var player_screen_uv = canvas_pos / screen_size
		material.set_shader_parameter("player_screen_pos", player_screen_uv)

	elif local_player.is_in_group("ufos"):
		self.color.a = ufo_alpha

		material.set_shader_parameter("min_alpha", 1.0)
		material.set_shader_parameter("inner_radius", 0.0)
		material.set_shader_parameter("outer_radius", 0.0)
		material.set_shader_parameter("player_screen_pos", Vector2(-1.0, -1.0))


func get_local_player() -> Node2D:
	for group in ["skeptics", "ufos"]:
		for node in get_tree().get_nodes_in_group(group):
			if node.is_multiplayer_authority():
				return node
	return null
