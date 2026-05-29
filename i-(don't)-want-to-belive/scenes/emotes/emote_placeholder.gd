class_name IconPlaceholder
extends Node2D

@onready var sprite_2d = $Sprite2D
@export var texture: Texture2D = load("uid://cblgq5okooy2")
var accepts_role: MultiplayerFeatures.Role


func _ready():
	var role = MultiplayerFeatures.get_role()
	setup(role, texture)


func setup(role: MultiplayerFeatures.Role, texture: Texture = texture):
	sprite_2d.texture = texture
	if role != accepts_role:
		sprite_2d.visible = false
