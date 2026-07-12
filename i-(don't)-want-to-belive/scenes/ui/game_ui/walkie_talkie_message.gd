extends Control

class_name WalkieTalkieMessage

@onready var timer = $Timer
@onready var coordinates = $VBoxContainer/Coordinates
@onready var text = $VBoxContainer/Text

var coordinates_text: String
var message: String = "Sceptyk nadał wiadomość"

signal show_message


func _ready():
	show_message.connect(func(): visible = true)
	_set_text()
	timer.timeout.connect(_quit)


func setup(new_message: String, new_coordinates: String):
	message = new_message
	coordinates_text = new_coordinates

	coordinates.text = coordinates_text
	text.text = message

	visible = true
	timer.start()


func _set_text():
	coordinates.text = coordinates_text
	text.text = message


func _quit():
	visible = false
