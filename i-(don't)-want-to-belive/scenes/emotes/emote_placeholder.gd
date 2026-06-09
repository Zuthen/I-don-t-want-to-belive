class_name IconPlaceholder
extends Node2D

@onready var sprite_2d = $Sprite2D
@export var texture: Texture2D = load("uid://cblgq5okooy2")
var accepts_role: Array[Player.Role]
var icon: Texture2D
var role: Player.Role


func setup(player_role: Player.Role, accepted_roles: Array[Player.Role], icon: Texture = texture):
	role = player_role
	accepts_role = accepted_roles
	sprite_2d.texture = icon
	if not accepts_role.has(role):
		sprite_2d.visible = false
