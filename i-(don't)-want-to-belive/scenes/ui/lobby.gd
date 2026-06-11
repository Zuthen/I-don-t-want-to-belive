extends Control

@onready var faction_warning = $MarginContainer/HBoxContainer/VBoxContainer/FactionWarning
@onready var factions = $MarginContainer/HBoxContainer/VBoxContainer/Factions
@onready var left_button = $MarginContainer/HBoxContainer/VBoxContainer/UfoSkinSlider/LeftButton
@onready var ufo_preview = $MarginContainer/HBoxContainer/VBoxContainer/UfoSkinSlider/UfoPreview
@onready var right_button = $MarginContainer/HBoxContainer/VBoxContainer/UfoSkinSlider/RightButton
@onready var ufo_skin_slider = $MarginContainer/HBoxContainer/VBoxContainer/UfoSkinSlider
@onready var about_role = $MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/AboutRole
@onready var match_id_label = $MarginContainer/MatchId
@onready var room_name_label = $MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/RoomName
@onready var players_label = $MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/Players

var current_skin_index: int = 0
var skins_count: int
var role_idx = 1
var players: = 0


func _ready():
	_update_players_counter()
	if NakamaNetworkManager.multiplayer_bridge:
		var net_match_id = NakamaNetworkManager.multiplayer_bridge.match_id
		match_id_label.text = "ID meczu: " + str(net_match_id)

		var room_name = NakamaNetworkManager.match_name
		room_name_label.text = "Nazwa pokoju: " + str(room_name)

		print("[Lobby] Moje ID meczu to: ", net_match_id)
	multiplayer.peer_connected.connect(_on_player_count_changed)
	multiplayer.peer_disconnected.connect(_on_player_count_changed)
	await get_tree().process_frame
	skins_count = UfosTextures.ufo_textures.size()
	about_role.add_theme_constant_override("line_separation", 10)
	set_warning_text(role_idx)
	set_ufo_skins()
	_adjust_ufo_skins_visibility(role_idx)
	_set_role_info()
	factions.item_selected.connect(set_warning_text)
	left_button.pressed.connect(_set_previous_skin)
	right_button.pressed.connect(_set_next_skin)


func set_warning_text(index: int = 0):
	role_idx = index
	if index == 0:
		faction_warning.text = "Uwaga! Jeśli więcej niż 2 graczy wybierzę tę opcję, może się zdarzyć, że zagrasz ufokiem"
	elif index == 1:
		faction_warning.text = "Uwaga! Jeśli więcej niż 2 graczy wybierzę tę opcję, może się zdarzyć, że zagrasz sceptykiem"
	_adjust_ufo_skins_visibility(index)
	_set_role_info()


func set_ufo_skins():
	if skins_count > 0:
		var texture = UfosTextures.ufo_textures[current_skin_index].ship
		ufo_preview.texture = texture


func _set_previous_skin():
	current_skin_index -= 1
	if current_skin_index < 0:
		current_skin_index = skins_count - 1
	set_ufo_skins()


func _set_next_skin():
	current_skin_index += 1
	if current_skin_index >= skins_count:
		current_skin_index = 0
	set_ufo_skins()


func _adjust_ufo_skins_visibility(value):
	if value == 1:
		ufo_skin_slider.set_deferred("visible", true)
	else:
		ufo_skin_slider.set_deferred("visible", false)


func _on_player_count_changed(_id: int):
	_update_players_counter()


func _update_players_counter():
	players_label.text = str(multiplayer.get_peers().size() + 1) + "/4 graczy"


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
