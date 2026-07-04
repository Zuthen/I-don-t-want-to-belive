extends PanelContainer

@onready var texture_rect = $TextureRect

var texture: Texture2D


func _ready():
	texture_rect.texture = texture
