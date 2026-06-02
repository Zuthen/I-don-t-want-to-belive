extends Control

@onready var timer = $Timer
@onready var coordinates = $VBoxContainer/Coordinates
@onready var text = $VBoxContainer/Text

var coordinates_text: String
var message: String = "Sceptyk nadał wiadomość"


func _ready():
	set_text()
	timer.timeout.connect(_quit)


func set_text():
	coordinates.text = coordinates_text
	text.text = message


func _quit():
	queue_free()
