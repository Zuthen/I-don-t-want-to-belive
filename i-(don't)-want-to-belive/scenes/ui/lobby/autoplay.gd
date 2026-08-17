extends VBoxContainer

@onready var check_box = $Option/CheckBox
@onready var option = $Option
@onready var description = $Description

var autoplay: bool = true
var host: bool


func _ready():
	check_box.toggled.connect(_on_checkbox_toggled)


func _on_checkbox_toggled(button_pressed: bool):
	if host:
		_set_autoplay.rpc(button_pressed)


func setup(is_host: bool):
	host = is_host
	if host:
		option.visible = true
		check_box.disabled = false
	else:
		option.visible = false
		check_box.disabled = true


func get_autoplay_setting():
	return autoplay


@rpc("any_peer", "call_local", "reliable")
func _set_autoplay(checked):
	autoplay = checked

	if checked:
		description.text = tr("AUTOPLAY_ON")
	else:
		if host:
			description.text = tr("AUTOPLAY_OFF_HOST")
		else:
			description.text = tr("AUTOPLAY_OFF_PLAYERS")
