extends NinePatchRect

@onready var header_label = $Header/MarginContainer/HBoxContainer/Label
@onready var close_button = $Header/MarginContainer/HBoxContainer/CloseButton
@onready var button_label = $VBoxContainer/ConnectButton/Label
@onready var connect_button = $VBoxContainer/ConnectButton
@onready var line_edit = $VBoxContainer/LineEdit

enum NetworkRole { HOST, CLIENT }

var network_role: NetworkRole:
	set(value):
		network_role = value
		if is_inside_tree():
			_set_popup(value)


func _ready():
	_set_popup(network_role)
	line_edit.text_changed.connect(cast_to_upper_case)
	close_button.pressed.connect(func(): set_deferred("visible", false))
	connect_button.pressed.connect(_on_connect_pressed)
	NakamaNetworkManager.match_joined_successfully.connect(_on_network_match_joined)


func cast_to_upper_case(text: String):
	var caret = line_edit.caret_column
	line_edit.text = text.to_upper()
	line_edit.caret_column = caret


func _set_popup(role: NetworkRole):
	header_label.text = "Podaj nazwę pokoju"
	if role == NetworkRole.HOST:
		button_label.text = "Utwórz"
	elif role == NetworkRole.CLIENT:
		button_label.text = "Dołącz"


func _on_connect_pressed():
	var room_name = line_edit.text.strip_edges()
	if room_name == "":
		print("Nazwa pokoju nie może być pusta!")
		return
	set_deferred("visible", false)
	NakamaNetworkManager.connect_to_named_room(room_name)


func _on_network_match_joined(_match_name: String, _match_id: String):
	var lobby_scene = load("uid://dg7q16m0w6dnx") as PackedScene
	if NakamaNetworkManager.is_inside_tree():
		NakamaNetworkManager.get_tree().change_scene_to_packed(lobby_scene)
	else:
		Engine.get_main_loop().change_scene_to_packed(lobby_scene)
