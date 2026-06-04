extends Node2D

class_name CrashedUfo

@onready var sprite_2d = $Sprite2D
@onready var vision = $Vision

var peer_id: int

signal crashed_ufo_seen(peer_id: int)

var texture: Texture2D:
	set(value):
		texture = value
		if sprite_2d:
			sprite_2d.texture = value


func _ready():
	if texture and sprite_2d:
		sprite_2d.texture = texture
	vision.area_entered.connect(_on_crashed_ufo_seen)


func _on_crashed_ufo_seen(other):
	var player = other.get_parent()
	if player is Skeptic:
		crashed_ufo_seen.emit(peer_id)
