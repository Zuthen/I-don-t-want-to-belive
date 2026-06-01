extends CharacterBody2D

class_name Player

@warning_ignore_start("unused_signal")
signal player_role_assigned
signal ufo_wins
signal skeptics_win
var id: int = 0


func set_camera(camera: Camera2D):
	var camera_limits = MapSettings.get_map_limits()
	camera.enabled = true
	camera.limit_top = camera_limits.top
	camera.limit_bottom = camera_limits.bottom
	camera.limit_left = camera_limits.left

	var current_zoom = camera.zoom.x
	var ui_width_in_world = 128.0 / current_zoom
	camera.limit_right = camera_limits.right + int(ui_width_in_world)
	camera.make_current()
