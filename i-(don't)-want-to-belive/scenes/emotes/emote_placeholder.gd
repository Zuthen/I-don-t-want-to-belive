class_name IconPlaceholder
extends Node2D

@onready var sprite_2d = $Sprite2D
@export var texture: Texture2D = load("uid://cblgq5okooy2")


func _ready():
	setup(texture)


func setup(texture: Texture = texture):
	sprite_2d.texture = texture
