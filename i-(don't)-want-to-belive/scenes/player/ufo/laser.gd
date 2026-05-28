extends Node2D

class_name UfoLaser

@onready var animation_player = $AnimationPlayer
@onready var laser_top = $LaserTop
@onready var laser_middle = $LaserMiddle
@onready var laser_pointer = $LaserPointer
@onready var collision_shape_2d = $LaserRange/CollisionShape2D

var textures: UfosTextures.UfoTextures = UfosTextures.ufo_textures[0]


func _ready():
	set_textures(textures)
	animation_player.play("laser pointing")


func set_textures(textures: UfosTextures.UfoTextures):
	laser_top.texture = textures.laser1
	laser_middle.texture = textures.laser2
	laser_pointer.texture = textures.laser_pointing
	collision_shape_2d.disabled = false
