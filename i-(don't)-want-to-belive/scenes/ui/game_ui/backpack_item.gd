extends PanelContainer

class_name BackpackItem

@onready var texture_rect = $TextureRect

var texture: Texture2D
var item_name: String
var description: String
var color: Color


func _ready():
	texture_rect.texture = texture
	_set_background_color(color)
	_set_tooltip()


func _set_background_color(color: Color):
	var stylebox = get_theme_stylebox("panel")
	var new_style = stylebox.duplicate() as StyleBoxTexture
	new_style.modulate_color = color
	add_theme_stylebox_override("panel", new_style)


func _set_tooltip():
	tooltip_text = description
