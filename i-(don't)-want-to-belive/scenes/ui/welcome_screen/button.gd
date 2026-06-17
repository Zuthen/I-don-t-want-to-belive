extends TextureButton

@onready var label = $Label
@export var label_text: String


func _ready():
	label.text = label_text
