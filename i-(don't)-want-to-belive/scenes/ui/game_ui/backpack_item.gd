extends PanelContainer

class_name BackpackItem

@onready var texture_rect = $TextureRect

var texture: Texture2D
var item_name: String
var description: String
var color: Color


func _ready():
	texture_rect.texture = texture
	_set_background_color(color)
	_set_tooltip()


func _set_background_color(color: Color):
	var stylebox = get_theme_stylebox("panel")
	if stylebox:
		var new_style = stylebox.duplicate() as StyleBoxTexture
		new_style.modulate_color = color
		add_theme_stylebox_override("panel", new_style)


func _set_tooltip():
	tooltip_text = description
	var base_theme = theme if theme else find_valid_theme()
	if base_theme:
		var unique_theme = base_theme.duplicate()
		var tooltip_style = StyleBoxFlat.new()
		tooltip_style.bg_color = color
		tooltip_style.set_content_margin_all(8)
		tooltip_style.set_border_width_all(0)
		tooltip_style.shadow_size = 0
		unique_theme.set_stylebox("panel", "TooltipPanel", tooltip_style)
		theme = unique_theme


func find_valid_theme() -> Theme:
	var current_node = self
	while current_node:
		if current_node.theme:
			return current_node.theme
		current_node = current_node.get_parent()
	return null
