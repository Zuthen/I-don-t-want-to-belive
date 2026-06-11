extends NinePatchRect

@onready var header_label = $Header/MarginContainer/HBoxContainer/Label
@onready var close_button = $Header/MarginContainer/HBoxContainer/CloseButton
@onready var button_label = $VBoxContainer/Button/Label

enum NetworkRole { HOST, CLIENT }

var network_role: NetworkRole:
	set(value):
		network_role = value
		if is_inside_tree():
			_set_popup(value)


func _ready():
	_set_popup(network_role)
	close_button.pressed.connect(func(): set_deferred("visible", false))


func _set_popup(role: NetworkRole):
	header_label.text = "Podaj nazwę pokoju"
	if role == NetworkRole.HOST:
		button_label.text = "Utwórz"
	elif role == NetworkRole.CLIENT:
		button_label.text = "Dołącz"
