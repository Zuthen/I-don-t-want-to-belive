extends Node2D

class_name UfoLaser

@onready var animation_player = $AnimationPlayer
@onready var laser_top = $LaserTop
@onready var laser_middle = $LaserMiddle
@onready var laser_pointer = $LaserPointer
@onready var collision_shape_2d = $LaserRange/CollisionShape2D
@onready var laser_range = $LaserRange

var textures: UfosTextures.UfoTextures = UfosTextures.ufo_textures[0]
var laser_hit_points := 1
var pointing_animation: Animation


func _ready():
	pointing_animation = animation_player.get_animation("laser pointing")
	set_textures(textures)
	animation_player.play("laser pointing")
	laser_range.area_entered.connect(_on_skeptic_see_laser)


func set_textures(textures: UfosTextures.UfoTextures):
	laser_top.texture = textures.laser1
	laser_middle.texture = textures.laser2
	laser_pointer.texture = textures.laser_pointing
	pointing_animation.track_set_key_value(4, 0, textures.laser_ground_burst)
	collision_shape_2d.disabled = false


func _on_skeptic_see_laser(other):
	var player = other.get_parent()
	if player is Skeptic:
		_set_animation()
		player.belive_points_changed.emit(laser_hit_points)
		player.laser_seen.emit()


func _set_animation():
	var current_time = animation_player.current_animation_position
	pointing_animation.track_set_key_value(4, 0, textures.laser_burst)
	animation_player.stop()
	animation_player.play("laser pointing")
	animation_player.seek(current_time, true)


func get_animation_time() -> float:
	return animation_player.get_animation("laser pointing").length
