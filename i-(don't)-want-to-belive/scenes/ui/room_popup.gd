extends AcceptDialog

@onready var code_input = $CodeInput
var lobby_scene = load("uid://dg7q16m0w6dnx") as PackedScene


func _ready():
	title = "Kod pokoju"
	ok_button_text = "Dołącz"

	code_input.text_changed.connect(cast_to_upper_case)
	confirmed.connect(_on_connect_pressed)

	about_to_popup.connect(_on_about_to_popup)

	NakamaNetworkManager.match_joined_successfully.connect(_on_network_match_joined)


func _on_about_to_popup():
	var connect_btn = get_ok_button()
	if connect_btn:
		connect_btn.disabled = false
		connect_btn.release_focus()

	code_input.text = ""

	if not NakamaNetworkManager.private_room_full.is_connected(_on_room_full):
		NakamaNetworkManager.private_room_full.connect(_on_room_full)


func _on_connect_pressed():
	var room_name = code_input.text.strip_edges()
	if room_name == "":
		print("Nazwa pokoju nie może być pusta!")
		popup_centered()
		return

	get_tree().get_multiplayer().multiplayer_peer = null

	if NakamaNetworkManager.multiplayer_bridge:
		NakamaNetworkManager.multiplayer_bridge.notification(NOTIFICATION_PREDELETE)
		NakamaNetworkManager.multiplayer_bridge = null

	NakamaNetworkManager.multiplayer_bridge = NakamaMultiplayerBridge.new(NakamaNetworkManager.socket)
	get_tree().get_multiplayer().set_multiplayer_peer(NakamaNetworkManager.multiplayer_bridge.multiplayer_peer)

	await get_tree().process_frame

	NakamaNetworkManager.is_host = false
	NakamaNetworkManager.private = true
	NakamaNetworkManager.connect_to_named_room(room_name)


func _on_room_full():
	hide()
	code_input.text = ""

	var connect_btn = get_ok_button()
	if connect_btn:
		connect_btn.disabled = false

	var error_popup = get_parent().get_node("ErrorDialog") as AcceptDialog
	if error_popup:
		if not error_popup.confirmed.is_connected(_on_error_dismissed):
			error_popup.confirmed.connect(_on_error_dismissed)
		if not error_popup.canceled.is_connected(_on_error_dismissed):
			error_popup.canceled.connect(_on_error_dismissed)

		error_popup.popup_centered()


func _on_error_dismissed():
	await get_tree().process_frame
	popup_centered()


func _on_network_match_joined(_match_name: String, _match_id: String):
	hide()

	var main_loop = Engine.get_main_loop() as SceneTree
	if main_loop:
		main_loop.change_scene_to_packed(lobby_scene)


func cast_to_upper_case(text: String):
	var caret = code_input.caret_column
	line_edit_text_all_caps(text, caret)


func line_edit_text_all_caps(text: String, caret: int):
	code_input.text = text.to_upper()
	code_input.caret_column = caret
