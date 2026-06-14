extends AcceptDialog

func _ready():
	hide()
	get_viewport().canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	title = "Niepowodzenie"
	dialog_text = "Pokój jest już pełen! Spróbuj gry losowej."
	NakamaNetworkManager.private_room_full.connect(_show)
	confirmed.connect(func(): NakamaNetworkManager.reconnect_after_error_dismissed())
	close_requested.connect(func(): NakamaNetworkManager.reconnect_after_error_dismissed())
	var custom_font: FontFile = load("res://assets/fonts/Audiowide-Regular.ttf")
	var ok_button = get_ok_button()
	ok_button.add_theme_font_override("font", custom_font)
	ok_button.add_theme_font_size_override("font_size", 20)
	for child in get_children():
		if child is Label or child is RichTextLabel:
			child.add_theme_font_override("font", custom_font)


func _show():
	print("[UI Error Popup] Displaying full room message after hard redirect...")
	hide()
	popup_centered()
