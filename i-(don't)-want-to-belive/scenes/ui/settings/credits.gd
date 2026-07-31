extends PanelContainer

@onready var quit_button = $IconButton


func _ready():
	quit_button.pressed.connect(queue_free)
