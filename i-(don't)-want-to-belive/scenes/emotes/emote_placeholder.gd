class_name IconPlaceholder
extends Node2D

@onready var sprite_2d = $Sprite2D
@export var texture: Texture2D = load("uid://cblgq5okooy2")
var accepts_role: Array[MultiplayerFeatures.Role]
var icon: Texture2D


func _ready():
	var role = MultiplayerFeatures.get_role()
	setup(role, texture)


func setup(role: MultiplayerFeatures.Role, icon: Texture = texture):
	sprite_2d.texture = icon
	if not accepts_role.has(role):
		sprite_2d.visible = false
