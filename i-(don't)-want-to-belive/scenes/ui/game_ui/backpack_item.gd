extends PanelContainer

class_name BackpackItem

@onready var texture_rect = $TextureRect

var texture: Texture2D
var item_name: String
var description: String


func _ready():
	texture_rect.texture = texture
	_set_tooltip()


func _set_tooltip():
	tooltip_text = description
