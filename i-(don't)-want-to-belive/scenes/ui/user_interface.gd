extends Control

class_name UserInterface

@onready var q = $SkillsPanel/Q
@onready var e = $SkillsPanel/E
@onready var win_info = $WinInfo
@onready var win_label = $WinInfo/WinLabel
@onready var faction_label = $WinInfo/FactionLabel
@onready var belive_points_counter_background = $Belive_Points_Counter_Background
@onready var belive_points_counter = $Belive_Points_Counter
@onready var walkie_talkie_message = $WalkieTalkieMessage

var ufos_sprites
var hit_points: int = 0

const UFO_WINS := "Prawda 
	nas jeszcze 
	zadziwi..."

const SKEPTICS_WIN := "Od dawna 
takie latają!"


func _ready():
	print("--- [UI LOG] Start funkcji _ready() w interfejsie użytkownika ---")
	MultiplayerFeatures.local_ui = self
	ufos_sprites = belive_points_counter.get_children()
	win_info.visible = false

	# Czyszczenie tekstów zastępczych z edytora na starcie
	if is_instance_valid(q):
		q.set_icon_text("")
	if is_instance_valid(e):
		e.set_icon_text("")

	var player: Player = null
	print("[UI LOG] Rozpoczynam pętlę szukania lokalnego gracza (20 prób)...")

	for i in range(60):
		player = MultiplayerFeatures.get_local_player()
		if player != null:
			print("[UI LOG] SUKCES! Znaleziono postać gracza w próbie nr: ", i)
			break
		await get_tree().create_timer(0.05).timeout

	if player != null:
		player.player_role_assigned.connect(_on_player_role_assigned)
		player.ufo_wins.connect(_on_ufo_wins)
		player.skeptics_win.connect(_on_skeptic_win)
		if player.role == Player.Role.SKEPTIC:
			player.belive_points_changed.connect(_on_belive_points_changed)
			player.walkie_talkie_message_sent.connect(_on_e_skill_fired)
		elif player.role == Player.Role.UFO:
			var ufo = player.get_node_or_null("Ufo")
			if ufo:
				ufo.laser_shoot.connect(_on_q_skill_fired)
				ufo.captured.connect(_on_e_skill_fired)
			var ufo_with_alien = ufo.get_parent() as UfoWithAlien if ufo else null
			if ufo_with_alien:
				ufo_with_alien.ufo_crashed.connect(func(): setup_ui(Player.Role.ALIEN))

		print("[UI LOG] Gracz ma rolę: ", player.role, ". Odpalam setup_ui().")
		setup_ui(player.role)

		# KLUCZOWE ROZWIĄZANIE: Dajemy silnikowi sieciowemu i graficznemu
		# mały bufor czasowy (0.15s) na zrenderowanie spritów postaci i ułożenie kamery!
		await get_tree().create_timer(0.15).timeout

		# Dopiero gdy cały świat i postacie stoją gotowe, gasimy ekran ładowania
		for child in get_tree().root.get_children():
			if child.name == "LoadingScreen" or (child.get_script() and child.get_script().get_path().ends_with("loading_screen.gd")):
				child.queue_free()
	else:
		printerr("[UI LOG ERROR] Klient o ID ", multiplayer.get_unique_id(), " ostatecznie NIE doczekał się swojej postaci!")

		printerr("[UI LOG ERROR] Klient o ID ", multiplayer.get_unique_id(), " ostatecznie NIE doczekał się swojej postaci!")


func _on_player_role_assigned():
	var player = get_parent() as Player
	setup_ui(player.role)


func setup_ui(role: Player.Role):
	for ufo in ufos_sprites:
		ufo.visible = false
	match role:
		Player.Role.UFO:
			q.set_icon_text("Wystrzel laser")
			e.set_icon_text("Pochwyć")
			belive_points_counter_background.visible = false
			belive_points_counter.visible = false
		Player.Role.SKEPTIC:
			e.set_icon_text("Wyślij swoją pozycję")
			q.set_icon_text("Zawołaj")
		Player.Role.ALIEN:
			q.set_icon_text("Zawołaj")
			e.visible = false
			belive_points_counter_background.visible = false
			belive_points_counter.visible = false


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


@rpc("any_peer", "call_local", "reliable")
func receive_walkie_talkie_message(msg_content: String):
	if not is_instance_valid(walkie_talkie_message):
		return

	var sender_id = multiplayer.get_remote_sender_id()
	var my_id = multiplayer.get_unique_id()

	var label_type = ""
	if sender_id == my_id:
		label_type = "Nadana wiadomość:"
	else:
		label_type = "Odebrana wiadomość:"

	walkie_talkie_message.setup(label_type, msg_content)
