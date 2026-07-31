extends PanelContainer

class_name Settings

@onready var icon_button = $MarginContainer/VBoxContainer/IconButton
@onready var music_slider = $MarginContainer/VBoxContainer/MusicSlider
@onready var fsx_slider = $MarginContainer/VBoxContainer/FSXSlider
@onready var about_button = $IconButton

var about_scene = preload("uid://up7ssvvcvcwp")


func _ready():
	icon_button.pressed.connect(_quit)
	about_button.pressed.connect(_show_credits)
	music_slider.value = ConfigManager.get_setting("audio_music", 0.5)
	music_slider.value_changed.connect(_on_music_changed)

	fsx_slider.value = ConfigManager.get_setting("audio_sfx", 0.5)
	fsx_slider.value_changed.connect(_on_sfx_changed)


func _show_credits():
	var about = about_scene.instantiate()
	add_child(about)


func _on_music_changed(new_value: float):
	ConfigManager.set_setting("audio_music", new_value)
	if new_value <= 0.0:
		BackgroundMusic.volume_db = -80.0
	else:
		BackgroundMusic.volume_db = linear_to_db(new_value)


func _on_sfx_changed(new_value: float):
	ConfigManager.set_setting("audio_sfx", new_value)


func _quit():
	ConfigManager.save_settings()
	queue_free()
