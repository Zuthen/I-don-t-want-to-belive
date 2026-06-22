extends VBoxContainer

signal value_changed(new_value: float)

@export var option_name: String = ""

@export var value: float = 0.5:
	set(val):
		value = val
		if is_node_ready():
			$HSlider.value = val

@onready var label = $Label
@onready var slider = $HSlider


func _ready():
	setup_grabber()
	label.text = option_name

	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.value_changed.connect(_on_internal_slider_changed)


func _on_internal_slider_changed(new_value: float):
	value = new_value
	value_changed.emit(new_value)


func setup_grabber():
	var ufo_sprite: Texture2D = load("uid://3w21pkq8n8b0")
	var texture = ufo_sprite.get_image()
	texture.resize(20, 20, Image.INTERPOLATE_NEAREST)
	var final_texture = ImageTexture.create_from_image(texture)
	slider.add_theme_icon_override("grabber", final_texture)
	slider.add_theme_icon_override("grabber_highlight", final_texture)
	slider.add_theme_icon_override("tick", final_texture)
