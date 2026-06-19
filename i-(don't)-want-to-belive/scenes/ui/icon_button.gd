extends Button

@onready var icon_placeholder = $HBoxContainer/MarginContainer/Icon
@onready var label = $HBoxContainer/Label

@export var texture: Texture2D
@export var label_text: String


func _ready():
	icon_placeholder.texture = texture
	label.text = label_text
