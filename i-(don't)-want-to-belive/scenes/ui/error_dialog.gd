extends AcceptDialog

func _ready():
	hide()
	title = "Niepowodzenie"
	dialog_text = "Pokój jest już pełen! Spróbuj gry losowej."
	NakamaNetworkManager.private_room_full.connect(_show)
	confirmed.connect(func(): NakamaNetworkManager.reconnect_after_error_dismissed())
	close_requested.connect(func(): NakamaNetworkManager.reconnect_after_error_dismissed())


func _show():
	print("[UI Error Popup] Displaying full room message after hard redirect...")
	hide()
	popup_centered()
