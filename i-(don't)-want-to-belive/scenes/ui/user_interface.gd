extends Control

class_name UserInterface

@onready var q = $SkillsPanel/Q
@onready var e = $SkillsPanel/E
@onready var win_info = $WinInfo
@onready var win_label = $WinInfo/WinLabel
@onready var faction_label = $WinInfo/FactionLabel
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
	win_info.visible = false

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
			player.walkie_talkie_message_sent.connect(_on_e_skill_fired)
		elif role == MultiplayerFeatures.Role.UFO:
			var ufo = player.get_node_or_null("Ufo")
			ufo.laser_shoot.connect(_on_q_skill_fired)
			ufo.captured.connect(_on_e_skill_fired)
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
			q.set_icon_text("Wystrzel laser")
			e.set_icon_text("Pochwyć")
			belive_points_counter_background.visible = false
			belive_points_counter.visible = false
		MultiplayerFeatures.Role.SKEPTIC:
			e.set_icon_text("Wyślij swoją pozycję")
			q.set_icon_text("Zawołaj")
		MultiplayerFeatures.Role.ALIEN:
			q.set_icon_text("Zawołaj")
			e.visible = false


func _on_ufo_wins():
	show_ufo_victory_screen.rpc_id(0)


func _on_skeptic_win():
	show_skeptics_victory_screen.rpc_id(0)


func _on_q_skill_fired(time):
	q.start_cooldown(time)


func _on_e_skill_fired(time):
	e.start_cooldown(time)


@rpc("any_peer", "call_local", "reliable")
func show_ufo_victory_screen():
	win_label.text = UFO_WINS
	faction_label.text = "Wygrywają ufoki"
	win_info.visible = true


@rpc("any_peer", "call_local", "reliable")
func show_skeptics_victory_screen():
	win_label.text = SKEPTICS_WIN
	faction_label.text = "Wygrywają sceptycy"
	win_info.visible = true


func _on_belive_points_changed(amount):
	hit_points += amount
	if hit_points > ufos_sprites.size():
		hit_points = ufos_sprites.size()
	for i in range(hit_points):
		ufos_sprites[i].visible = (i < hit_points)
