extends VBoxContainer

@onready var check_box = $Option/CheckBox
@onready var option = $Option
@onready var description = $Description

var autoplay: bool = true
var host: bool

const CHECKED_LABEL: String = "Gra rozpocznie się automatyczniie, kiedy wszyscy gracze potwierdzą obecność."
const UNCHECKED_LABEL: String = "Gra rozpocznie się, kiedy gospodarz uruchomi grę, kiedy wszyscy gracze będą gotowi"
const UNCHECKED_LABEL_HOST: String = "Uruchomisz grę, kiedy wszyscy gracze będą gotowi"


func _ready():
	check_box.toggled.connect(_on_checkbox_toggled)


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


func _on_checkbox_toggled(button_pressed: bool):
	if host:
		_set_autoplay.rpc(button_pressed)


@rpc("any_peer", "call_local", "reliable")
func _set_autoplay(checked):
	autoplay = checked

	if checked:
		description.text = CHECKED_LABEL
	else:
		if host:
			description.text = UNCHECKED_LABEL_HOST
		else:
			description.text = UNCHECKED_LABEL
