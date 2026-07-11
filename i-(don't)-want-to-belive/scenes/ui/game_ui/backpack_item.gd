extends PanelContainer

class_name BackpackItem

@onready var texture_rect = $TextureRect

var texture: Texture2D
var item_name: String


func _ready():
	texture_rect.texture = texture
