extends HBoxContainer

@onready var left_button = $LeftButton
@onready var preview = $UfoPreview
@onready var right_button = $RightButton

var skins_count: int = 0
var current_skin_index: int = 0
var textures: Array[Texture2D] = []

signal skin_index_changed(current_index: int)


func _ready() -> void:
	left_button.pressed.connect(_set_previous_skin)
	right_button.pressed.connect(_set_next_skin)


func init_slider(init_textures: Array[Texture2D], start_index: int = 0) -> void:
	textures = init_textures
	skins_count = textures.size()
	current_skin_index = start_index
	_set_skins(current_skin_index)


func _set_skins(index: int) -> void:
	if skins_count > 0:
		preview.texture = textures[index]


func _set_previous_skin() -> void:
	if skins_count == 0:
		return
	current_skin_index -= 1
	if current_skin_index < 0:
		current_skin_index = skins_count - 1
	skin_index_changed.emit(current_skin_index)
	_set_skins(current_skin_index)


func _set_next_skin() -> void:
	if skins_count == 0:
		return
	current_skin_index += 1
	if current_skin_index >= skins_count:
		current_skin_index = 0
	skin_index_changed.emit(current_skin_index)
	_set_skins(current_skin_index)
