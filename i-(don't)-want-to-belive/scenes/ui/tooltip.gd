extends PanelContainer

@export var font_color: Variant = null
@export var background_color: Variant = null
@onready var tooltip = $"."
@onready var label = $Label


func _ready():
	_setup_background_color()
	_setup_font_color()


func _setup_background_color():
	if background_color != null:
		var current_panel_style: StyleBoxFlat = get_theme_stylebox("panel")
		var style: StyleBoxFlat = current_panel_style.duplicate()
		style.bg_color = background_color
		add_theme_stylebox_override("panel", style)


func _setup_font_color():
	if font_color != null:
		label.label_settings = label.label_settings.duplicate()
		label.label_settings.font_color = font_color
