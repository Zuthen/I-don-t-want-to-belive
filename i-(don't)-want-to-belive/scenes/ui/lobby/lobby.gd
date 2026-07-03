extends Control

@onready var faction_warning = $MarginContainer/HBoxContainer/VBoxContainer/FactionWarning
@onready var factions = $MarginContainer/HBoxContainer/VBoxContainer/Factions
@onready var about_role = $MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/TextBackground/AboutRole
@onready var match_id_label = $MarginContainer/MatchId
@onready var room_name_label = $MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/RoomName
@onready var players_label = $MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/Players
@onready var confirm_button = $MarginContainer/HBoxContainer/VBoxContainer/Confirm
@onready var ready_players_label = $MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/ReadyPlayers
@onready var host_label = $MarginContainer/HBoxContainer/VBoxContainer/HostLabel
@onready var copy_button = $MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/CopyButton
@onready var tooltip = $MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/CopyButton/Tooltip
@onready var ufo_skin_slider = $MarginContainer/HBoxContainer/VBoxContainer/UfoSkinSlider
@onready var skeptic_skin_slider = $MarginContainer/HBoxContainer/VBoxContainer/SkepticSkinSlider
@onready var autoplay = $MarginContainer/HBoxContainer/VBoxContainer/Autoplay
@onready var game_map_settings = $MarginContainer/HBoxContainer/VBoxContainer/GameMapSettings

var ufo_skin_index: int = 0
var skeptic_skin_index: int = 0
var role_idx = 1
var players: = 0
var players_requests: Array[GameManager.Preferences] = []
var ready_players_counter: int = 0
var skeptic_skins: Array[Texture2D] = [
	preload("uid://dhsp46crp15wo"),
	preload("uid://difqg4xp0cai7"),
	preload("uid://cpngrw26iagtq"),
	preload("uid://m0lvo0ynihlo"),
	preload("uid://bonb0l27pbhxn"),
	preload("uid://dia4fsapfv33w"),
]
var skeptic_skin_count = skeptic_skins.size()
var ufo_skins_count = UfosTextures.ufo_textures.size()

signal all_players_ready


func _ready():
	if not is_inside_tree():
		return
	if multiplayer.multiplayer_peer == null:
		await get_tree().process_frame
	_set_sliders()
	_adjust_skins_visibility(role_idx)
	tooltip.set_deferred("visible", false)
	_set_host_section()
	_set_players_ready(ready_players_counter)
	_update_players_counter()
	_set_game_data()
	await _connect()
	about_role.add_theme_constant_override("line_separation", 10)
	await get_tree().process_frame

	_set_warning_text(role_idx)
	_set_role_info()
	_connect_signals()


func _set_sliders():
	ufo_skin_slider.init_slider(_ufo_skins(), ufo_skin_index)
	skeptic_skin_slider.init_slider(skeptic_skins, skeptic_skin_index)


func _connect_signals():
	all_players_ready.connect(_on_all_players_ready)
	confirm_button.pressed.connect(_on_preferences_set)
	copy_button.pressed.connect(_copy_room_name_to_clipboard)
	factions.item_selected.connect(_set_warning_text)
	ufo_skin_slider.skin_index_changed.connect(func(index): ufo_skin_index = index)
	skeptic_skin_slider.skin_index_changed.connect(func(index): skeptic_skin_index = index)

	var main_loop = Engine.get_main_loop() as SceneTree
	if main_loop and main_loop.get_multiplayer():
		var net = main_loop.get_multiplayer()
		if not net.peer_connected.is_connected(_on_player_count_changed):
			net.peer_connected.connect(_on_player_count_changed)
		if not net.peer_disconnected.is_connected(_on_player_count_changed):
			net.peer_disconnected.connect(_on_player_count_changed)


func _update_players_counter():
	var main_loop = Engine.get_main_loop() as SceneTree
	if main_loop and main_loop.get_multiplayer():
		var net = main_loop.get_multiplayer()
		var total_players = net.get_peers().size() + 1
		if total_players >= 5:
			total_players = 4
		players_label.text = str(total_players) + "/4 graczy"
	else:
		players_label.text = "1/4 graczy"


func _connect():
	var main_loop = Engine.get_main_loop() as SceneTree
	if main_loop and main_loop.get_multiplayer():
		var net = main_loop.get_multiplayer()

		if net.multiplayer_peer != null:
			var my_id = net.get_unique_id()
			var host_id = get_multiplayer_authority()
			var host = my_id == host_id
			if !host:
				_request_current_ready_count.rpc_id(host_id)
			autoplay.setup(host)


func _set_game_data():
	if NakamaNetworkManager.multiplayer_bridge:
		var net_match_id = NakamaNetworkManager.actual_match_id
		if net_match_id == "":
			net_match_id = NakamaNetworkManager.multiplayer_bridge.match_id

		match_id_label.text = "ID meczu: " + str(net_match_id)

		var room_name = NakamaNetworkManager.match_name
		room_name_label.text = "Kod pokoju: " + str(room_name)


func _set_host_section():
	if is_multiplayer_authority():
		host_label.text = "Jesteś hostem"
		game_map_settings.visible = true
		game_map_settings.district_spin_box.editable = true
		game_map_settings.narrow_select.disabled = false
	else:
		host_label.set_deferred("visible", false)
		game_map_settings.district_spin_box.editable = false
		game_map_settings.narrow_select.disabled = true


func _set_warning_text(index: int = 0):
	role_idx = index
	if index == 0:
		faction_warning.text = "Uwaga! Jeśli więcej niż 2 graczy wybierzę tę opcję, może się zdarzyć, że zagrasz ufokiem"
	elif index == 1:
		faction_warning.text = "Uwaga! Jeśli więcej niż 2 graczy wybierzę tę opcję, może się zdarzyć, że zagrasz sceptykiem"
	_adjust_skins_visibility(index)
	_set_role_info()


func _adjust_skins_visibility(value):
	if value == 1:
		ufo_skin_slider.set_deferred("visible", true)
		skeptic_skin_slider.set_deferred("visible", false)
	elif value == 0:
		skeptic_skin_slider.set_deferred("visible", true)
		ufo_skin_slider.set_deferred("visible", false)


func _on_player_count_changed(_id: int):
	_update_players_counter()


func _on_preferences_set():
	confirm_button.set_deferred("visible", false)
	var sender_id = multiplayer.get_unique_id()
	var type: String = ""

	ufo_skin_slider.visible = false
	skeptic_skin_slider.visible = false

	if role_idx == 0:
		type = "skeptic"
		_server_request_preferences.rpc_id(1, sender_id, type, skeptic_skin_index)
	elif role_idx == 1:
		type = "ufo"
		_server_request_preferences.rpc_id(1, sender_id, type, ufo_skin_index)


@rpc("any_peer", "call_local", "reliable")
func _server_request_preferences(sender_id: int, type: String, skin_idx: int):
	var preferences = GameManager.Preferences.new()
	preferences.peer_id = sender_id
	preferences.type = type
	preferences.skin_idx = skin_idx
	players_requests.append(preferences)

	ready_players_counter += 1
	if not is_inside_tree():
		return
	_set_players_ready.rpc(ready_players_counter)
	if ready_players_counter == 4:
		all_players_ready.emit()


@rpc("any_peer", "call_local", "reliable")
func _set_players_ready(count: int):
	ready_players_counter = count
	ready_players_label.text = "gotowi gracze: " + str(count) + "/4"


@rpc("any_peer", "call_remote", "reliable")
func _request_current_ready_count():
	var sender_id = multiplayer.get_remote_sender_id()
	_set_players_ready.rpc_id(sender_id, ready_players_counter)


func _on_all_players_ready():
	if is_multiplayer_authority():
		if autoplay.autoplay:
			_on_start_game()
		else:
			confirm_button.update_label("Rozpocznij grę")
			confirm_button.set_deferred("visible", true)
			confirm_button.pressed.disconnect(_on_preferences_set)
			confirm_button.pressed.connect(_on_start_game)
		GameManager.players_selections = players_requests


func _on_start_game():
	_start_game.rpc()


@rpc("authority", "call_local", "reliable")
func _start_game():
	var loading_screen: PackedScene = load("uid://c7m7gjtuwjrst")
	get_tree().change_scene_to_packed(loading_screen)


func _copy_room_name_to_clipboard():
	if room_name_label and room_name_label.text != "":
		var room_name = room_name_label.text
		var clean_text = room_name.replace("Kod pokoju: ", "").strip_edges()
		DisplayServer.clipboard_set(clean_text)
		tooltip.set_deferred("visible", true)
		var tooltip_timer = Timer.new()
		tooltip_timer.one_shot = true
		add_child(tooltip_timer)
		tooltip_timer.timeout.connect(func(): tooltip.set_deferred("visible", false))
		tooltip_timer.start(1)


func _ufo_skins():
	var ufo_skins: Array[Texture2D] = []
	for i in range(ufo_skins_count):
		ufo_skins.append(UfosTextures.ufo_textures[i].ship)
	return ufo_skins


func _set_role_info():
	if role_idx == 1:
		about_role.text = "[b]Cel:[/b] przekonać sceptyków do wiary w UFO
[b]Zdolności: [/b]
	[b] Wystrzelenie lasera: [/b] Jeśli laser trafi w sceptyka, sceptyk zdobędzie 1 punkt wiary a ty zobaczysz jego skwaszoną minę.
	[b] Pochwycenie: [/b] Pikujesz w dół i pobierasz sceptyka, dodajesz mu 3 punkty wiary i wywozisz go w inne miejsce mapy. Nawet nie wiesz gdzie.
		[b]Uwaga! [/b] Jeżeli nie trafisz w sceptyka, twój statek się rozbije. Musisz wtedy wyjść ze statku i sprawić by sceptyk zobaczył ciebie i twoje ufo (każda z tych akcji dodaje mu jednorazowo 1 punkt wiary).
	[b] Wołanie sceptyka (jako kosmita):[/b] Możesz zawołać sceptyka. Jeśli się to powiedzie może uznać, że jesteś drugim sceptykiem. Ale nie wiesz czy się zorientuje."
	elif role_idx == 0:
		about_role.text = "[b]Cel:[/b] Znaleźć drugiego sceptyka i współnie utwierdzić się w przekonaniu, że UFO nie istnieje.
[b]Zdolności: [/b]
	[b] Zawołanie: [/b] Jeśli drugi sceptyk is w zasięgu twojego głosu, będziesz wiedzieć, w którą stronę iść.
		[b] Uwaga! [/b] Kosmici po rozbiciu statku mogą podszywać się pod sceptyków.
	[b] Walkie-Talkie: [/b] Wysyłasz swoją lokalizację drugiemu sceptykowi. Będzie to litera i/lub liczba (losowo).
		[b]Uwaga! [/b] Statki UFO (ale nie kosmici) zawsze przechwytują tę informację."
