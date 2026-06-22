extends Node2D

@onready var create_game = $CanvasLayer/Buttons/CreateGame
@onready var join = $CanvasLayer/Buttons/Join
@onready var room_popup = $CanvasLayer/RoomPopup
@onready var quick_game = $CanvasLayer/Buttons/QuickGame
@onready var buttons = $CanvasLayer/Buttons
@onready var quit_button = $CanvasLayer/HBoxContainer2/QuitButton
@onready var version_label = $CanvasLayer/VersionLabel
@onready var settings_button = $CanvasLayer/HBoxContainer2/SettingsButton
@onready var canvas_layer = $CanvasLayer


func _ready():
	version_label.text = "v" + VersionManager.get_version()
	_connect_buttons()
	_set_music_setting()
	NakamaNetworkManager.connection_established.connect(_on_connect)

	if NakamaNetworkManager.is_connected_to_server:
		_on_connect()
	else:
		buttons.visible = false


func _set_music_setting():
	var music_volume = ConfigManager.get_setting("audio_music", 0.5)
	if music_volume <= 0.0:
		BackgroundMusic.volume_db = -80.0
	else:
		BackgroundMusic.volume_db = linear_to_db(music_volume)
	BackgroundMusic.play()


func _connect_buttons():
	create_game.pressed.connect(_create_game_and_go_to_lobby)
	join.pressed.connect(_show_popup)
	quick_game.pressed.connect(_join_existing_game)
	quit_button.pressed.connect(_quit)
	settings_button.pressed.connect(_show_settings)


func _show_settings():
	for child in get_tree().root.get_children():
		if child is Settings:
			return
	var settings_scene: PackedScene = load("uid://dsg5768ufuf6v")
	var settings = settings_scene.instantiate()
	canvas_layer.add_child(settings)


func _on_connect():
	buttons.visible = true


func _quit():
	get_tree().quit()


func _show_popup():
	room_popup.popup_centered()


func _create_game_and_go_to_lobby():
	NakamaNetworkManager.host_create_match()


func _join_existing_game():
	quick_game.disabled = true
	await NakamaNetworkManager.join_existing_game()


func _go_to_lobby():
	var lobby_scene = load("uid://dg7q16m0w6dnx") as PackedScene
	get_tree().change_scene_to_packed(lobby_scene)
