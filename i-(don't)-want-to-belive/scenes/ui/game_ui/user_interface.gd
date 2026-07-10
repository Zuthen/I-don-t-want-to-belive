extends CanvasLayer

class_name UserInterface

@onready var q = $SkillsPanel/Q
@onready var e = $SkillsPanel/E
@onready var win_info = $WinInfo
@onready var win_label = $WinInfo/WinLabel
@onready var faction_label = $WinInfo/FactionLabel
@onready var belive_points_counter_background = $Belive_Points_Counter_Background
@onready var belive_points_counter = $Belive_Points_Counter
@onready var walkie_talkie_message = $WalkieTalkieMessage
@onready var main_menu_button = $WinInfo/MainMenuButton

var ufos_sprites
var hit_points: int = 0
var crashed_ufos: Array[int] = []
var max_ufos_count: int = 2
var player: Player

const UFO_WINS := "Prawda 
	nas jeszcze 
	zadziwi..."

const SKEPTICS_WIN := "Od dawna 
takie latają!"


func _ready():
	MultiplayerFeatures.local_ui = self
	ufos_sprites = belive_points_counter.get_children()
	setup_win_section()
	main_menu_button.pressed.connect(_go_to_main_menu)
	if is_instance_valid(q):
		q.set_icon_text("")
	if is_instance_valid(e):
		e.set_icon_text("")

	player = get_parent()
	for i in range(60):
		player = MultiplayerFeatures.get_local_player()
		if player != null:
			break
		await get_tree().create_timer(0.05).timeout

	if player != null:
		_connect_signals(player)
		setup_ui(player.role)

		await get_tree().create_timer(0.15).timeout
		for child in get_tree().root.get_children():
			if child.name == "LoadingScreen" or (child.get_script() and child.get_script().get_path().ends_with("loading_screen.gd")):
				child.queue_free()
	Events.ufo_fixed.connect(func(_position): _connect_signals(player))


func _connect_signals(player: Player):
	_disconnect_skill_signals(player)
	if not player.player_role_assigned.is_connected(_on_player_role_assigned):
		player.player_role_assigned.connect(_on_player_role_assigned)
	if not player.ufo_wins.is_connected(_on_ufo_wins):
		player.ufo_wins.connect(_on_ufo_wins)
	if not player.skeptics_win.is_connected(_on_skeptic_win):
		player.skeptics_win.connect(_on_skeptic_win)
	if player.role == Player.Role.SKEPTIC:
		player.belive_points_changed.connect(_on_belive_points_changed)
		player.walkie_talkie_message_sent.connect(_on_e_skill_fired)
	elif player.role == Player.Role.UFO:
		player.ufo_crashed.connect(_on_ufo_crashed)
		var ufo = player.get_node_or_null("Ufo")
		if ufo:
			ufo.laser_shoot.connect(_on_q_skill_fired)
			ufo.captured.connect(_on_e_skill_fired)
	elif player.role == Player.Role.ALIEN:
		var alien = player.get_node_or_null("Alien")
		if alien:
			if not alien.can_repair.is_connected(_on_alien_can_repair):
				alien.can_repair.connect(_on_alien_can_repair)
			if not alien.cannot_repair.is_connected(_on_alien_cannot_repair):
				alien.cannot_repair.connect(_on_alien_cannot_repair)
			if not alien.repairing.is_connected(_on_e_skill_fired):
				alien.repairing.connect(_on_e_skill_fired)


func _disconnect_skill_signals(player: Player):
	var ufo = player.get_node_or_null("Ufo")
	if ufo:
		if ufo.laser_shoot.is_connected(_on_q_skill_fired):
			ufo.laser_shoot.disconnect(_on_q_skill_fired)
		if ufo.captured.is_connected(_on_e_skill_fired):
			ufo.captured.disconnect(_on_e_skill_fired)

	var alien = player.get_node_or_null("Alien")
	if alien:
		if alien.repairing.is_connected(_on_e_skill_fired):
			alien.repairing.disconnect(_on_e_skill_fired)


func _on_alien_can_repair():
	print("Napraw")
	e.set_icon_text("Napraw")
	e.visible = true


func _on_alien_cannot_repair():
	e.visible = false


func _on_ufo_crashed(peer_id):
	e.reset_cooldown()
	setup_ui(Player.Role.ALIEN)
	_connect_signals(player)
	_report_ufo_crash_to_server.rpc_id(1, peer_id)


@rpc("any_peer", "call_local", "reliable")
func _report_ufo_crash_to_server(dropped_peer_id: int):
	if not crashed_ufos.has(dropped_peer_id):
		crashed_ufos.append(dropped_peer_id)

	if crashed_ufos.size() >= max_ufos_count:
		var ufo_can_win: bool = false
		var skeptics = get_tree().get_nodes_in_group("skeptics")

		for skeptic in skeptics:
			var available_belive_points = 2 * max_ufos_count - skeptic.seen_ufos.size() - skeptic.seen_aliens.size()
			if skeptic.belive_points + available_belive_points >= 5:
				ufo_can_win = true
				break

		if !ufo_can_win:
			_on_skeptic_win()


func _check_ufo_can_win(peer_id: int):
	crashed_ufos.append(peer_id)
	var ufo_can_win: bool = false
	if crashed_ufos.size() == max_ufos_count:
		var skeptics = get_tree().get_nodes_in_group("skeptics")
		for skeptic in skeptics:
			if skeptic.belive_points >= 3:
				ufo_can_win = true
	if !ufo_can_win:
		_on_skeptic_win()


func setup_win_section():
	win_info.visible = false
	main_menu_button.disabled = true


func _go_to_main_menu():
	visible = false
	main_menu_button.disabled = true
	_request_game_over_from_server.rpc_id(1)


@rpc("any_peer", "call_local", "reliable")
func _request_game_over_from_server():
	if multiplayer.is_server():
		_network_broadcast_game_over.rpc_id(0)


@rpc("any_peer", "call_local", "reliable")
func _network_broadcast_game_over():
	visible = false
	main_menu_button.disabled = true
	if is_instance_valid(MultiplayerFeatures) and MultiplayerFeatures.local_ui == self:
		MultiplayerFeatures.local_ui = null

	var cleanup_screen = load("uid://cl8gmmdjy0oxx")
	if cleanup_screen:
		get_tree().change_scene_to_packed(cleanup_screen)


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
	main_menu_button.disabled = false


@rpc("any_peer", "call_local", "reliable")
func show_skeptics_victory_screen():
	win_label.text = SKEPTICS_WIN
	faction_label.text = "Wygrywają sceptycy"
	win_info.visible = true
	main_menu_button.disabled = false


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
