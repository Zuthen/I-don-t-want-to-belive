extends Control

class_name UserInterface

@onready var q_label = $QLabel
@onready var win_label = $WinLabel
@onready var belive_points_counter_background = $Belive_Points_Counter_Background
@onready var belive_points_counter = $Belive_Points_Counter

var ufos_sprites
var hit_points: int = 0

const UFO_WINS := "Prawda 
	nas jeszcze 
	zadziwi..."

const SKEPTICS_WIN := "Od dawna 
takie latają!"


func _ready():
	ufos_sprites = belive_points_counter.get_children()
	win_label.visible = false

	var player: Player = null
	for i in range(20):
		player = MultiplayerFeatures.get_local_player()
		if player != null:
			break
		await get_tree().create_timer(0.05).timeout

	if player != null:
		player.player_role_assigned.connect(_on_player_role_assigned)
		player.ufo_wins.connect(_on_ufo_wins)
		player.skeptics_win.connect(_on_skeptic_win)

		var role = MultiplayerFeatures.get_role()
		if role == MultiplayerFeatures.Role.SKEPTIC:
			player.belive_points_changed.connect(_on_belive_points_changed)
		_setup_ui(role)
	else:
		printerr("[UI] Błąd sieciowy: Klient o ID ", multiplayer.get_unique_id(), " nie doczekał się swojej postaci!")


func _on_player_role_assigned():
	var role = MultiplayerFeatures.get_role()
	_setup_ui(role)


func _setup_ui(role: MultiplayerFeatures.Role):
	for ufo in ufos_sprites:
		ufo.visible = false
	match role:
		MultiplayerFeatures.Role.UFO:
			q_label.text = "Wystrzel 
			laser"
			belive_points_counter_background.visible = false
			belive_points_counter.visible = false
		MultiplayerFeatures.Role.SKEPTIC:
			q_label.text = "Zawołaj"


func _on_ufo_wins():
	show_ufo_victory_screen.rpc_id(0)


func _on_skeptic_win():
	show_skeptics_victory_screen.rpc_id(0)


@rpc("any_peer", "call_local", "reliable")
func show_ufo_victory_screen():
	win_label.text = UFO_WINS
	win_label.visible = true


@rpc("any_peer", "call_local", "reliable")
func show_skeptics_victory_screen():
	win_label.text = SKEPTICS_WIN
	win_label.visible = true


func _on_belive_points_changed(amount):
	ufos_sprites[hit_points].visible = true
	hit_points += amount
