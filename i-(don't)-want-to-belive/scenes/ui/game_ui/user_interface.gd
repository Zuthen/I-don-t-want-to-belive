extends CanvasLayer

class_name UserInterface

@onready var q = $SkillsPanel/Q
@onready var e = $SkillsPanel/E
@onready var backpack_skills = $SkillsPanel/BackpackSkills
@onready var win_info = $WinInfo
@onready var win_label = $WinInfo/WinLabel
@onready var faction_label = $WinInfo/FactionLabel
@onready var belive_points_counter_background = $Belive_Points_Counter_Background
@onready var belive_points_counter = $Belive_Points_Counter
@onready var walkie_talkie_message = $WalkieTalkieMessage
@onready var main_menu_button = $WinInfo/MainMenuButton
@onready var backpack = $SkillsPanel/Backpack

var ufos_sprites
var hit_points: int = 0
var crashed_ufos: Array[int] = []
var max_ufos_count: int = 2
var player: Player
var additional_skills: Dictionary[Skill, bool] = { }
const UFO_WINS := "Prawda 
	nas jeszcze 
	zadziwi..."

const SKEPTICS_WIN := "Od dawna 
takie latają!"


func _ready():
	MultiplayerFeatures.local_ui = self
	ufos_sprites = belive_points_counter.get_children()
	_setup_win_section()
	_setup_backpack_skills()
	if is_instance_valid(q):
		q.set_icon_text("")
	if is_instance_valid(e):
		e.set_icon_text("")
	for skill in additional_skills:
		if is_instance_valid(skill):
			skill.set_icon_text("")
			skill.visible = false

	player = get_parent()
	for i in range(60):
		player = MultiplayerFeatures.get_local_player()
		if player != null:
			break
		await get_tree().create_timer(0.05).timeout

	if player != null:
		_connect_signals(player)
		_setup_ui(player.role)

		await get_tree().create_timer(0.15).timeout
		for child in get_tree().root.get_children():
			if child.name == "LoadingScreen" or (child.get_script() and child.get_script().get_path().ends_with("loading_screen.gd")):
				child.queue_free()
	Events.ufo_fixed.connect(
		func(_position):
			if player:
				player.role = Player.Role.UFO
			_connect_signals(player)
			_setup_ui(Player.Role.UFO)
	)


func _setup_backpack_skills():
	var skill_nodes = backpack_skills.find_children("Skill*")
	for skill_node in skill_nodes:
		if skill_node is Skill:
			var skill = skill_node as Skill
			additional_skills[skill] = false


func _find_skill_index_by_skill_name(skill_name: String):
	var skills_list = additional_skills.keys()
	return skills_list.find_custom(func(skill): return skill.skill_name == skill_name)


func _assign_backpack_skill(_texture, skill_name: String, faction: Player.Role):
	var role_matches = player.role == faction or player.role == Player.Role.BOTH
	if not role_matches:
		return

	if _find_skill_index_by_skill_name(skill_name) != -1:
		return

	var skills_list = additional_skills.keys()

	var free_slot_idx = skills_list.find_custom(
		func(skill): return additional_skills[skill] == false
	)

	if free_slot_idx != -1:
		var free_skill = skills_list[free_slot_idx]
		additional_skills[free_skill] = true
		free_skill.skill_name = skill_name
		free_skill.visible = true
		free_skill.set_icon_text(Findings.get_skill_label(skill_name))
		if skill_name == "repair_tool" or skill_name == "sanity_pills":
			free_skill.set_disabled()


func _clear_backpack_skill(skill_name: String):
	var skills_list = additional_skills.keys()
	var skill_idx = _find_skill_index_by_skill_name(skill_name)
	if skill_idx != -1:
		var taken_slot = skills_list[skill_idx]
		additional_skills[taken_slot] = false
		taken_slot.visible = false
		taken_slot.set_icon_text("")
		taken_slot.skill_name = ""


func _connect_signals(player: Player):
	_connect_sinal_if_not_connected(Events.item_collected, _assign_backpack_skill)
	_connect_sinal_if_not_connected(main_menu_button.pressed, _go_to_main_menu)
	_connect_sinal_if_not_connected(player.ufo_wins, _on_ufo_wins)
	_connect_sinal_if_not_connected(player.skeptics_win, _on_skeptic_win)
	if player.role == Player.Role.SKEPTIC:
		player.belive_points_changed.connect(_on_belive_points_changed)
		player.walkie_talkie_message_sent.connect(_on_skill_fired.bind(e))
		player.can_take_sanity_pill.connect(_set_sanity_pill_skill)
		player.out_of_pills.connect(_on_out_of_pills)

	elif player.role == Player.Role.UFO:
		_assign_ufo_signals()
	elif player.role == Player.Role.ALIEN:
		var alien = player.get_node_or_null("Alien") as Alien
		if alien:
			_connect_sinal_if_not_connected(alien.can_repair, _on_alien_can_repair)
			_connect_sinal_if_not_connected(alien.cannot_repair, _on_alien_cannot_repair)


func _on_out_of_pills():
	_clear_backpack_skill("sanity_pills")


func _set_sanity_pill_skill(enabled):
	var sanity_pills_idx = _find_skill_index_by_skill_name("sanity_pills")
	var skills_list = additional_skills.keys()

	if enabled:
		skills_list[sanity_pills_idx].set_enabled()
	else:
		skills_list[sanity_pills_idx].set_disabled()


func _assign_ufo_signals():
	_connect_sinal_if_not_connected(player.ufo_crashed, _on_ufo_crashed)
	var ufo = player.get_node_or_null("Ufo")
	if ufo:
		_connect_sinal_if_not_connected(ufo.laser_shoot, _on_skill_fired.bind(q))
		_connect_sinal_if_not_connected(ufo.captured, _on_skill_fired.bind(e))


func _on_alien_near_ufo_wreck():
	if player and player.role != Player.Role.ALIEN:
		return
	var alien = player.get_node("Alien") as Alien
	var repair_action_idx = _get_action_idx(alien.get_actions(), alien.repair_ufo)
	var skills = backpack_skills.get_children()
	skills[repair_action_idx].set_enabled()


func _disconnect_skill_signals(player: Player):
	var ufo = player.get_node_or_null("Ufo")
	if ufo:
		_disconnect_connected_signal(ufo.laser_shoot, _on_skill_fired)
		_disconnect_connected_signal(ufo.captured, _on_skill_fired)

	var alien = player.get_node_or_null("Alien")
	if alien:
		_disconnect_connected_signal(alien.repairing, _on_skill_fired)


func _disconnect_connected_signal(connected_signal: Signal, handler: Callable):
	if connected_signal.is_connected(handler):
		connected_signal.disconnect(handler)


func _connect_sinal_if_not_connected(signal_to_connect: Signal, callable: Callable):
	if not signal_to_connect.is_connected(callable):
		signal_to_connect.connect(callable)


func _on_alien_can_repair():
	if player and player.role != Player.Role.ALIEN:
		return
	var alien = player.get_node("Alien") as Alien
	var repair_action_idx = _get_action_idx(alien.get_actions(), alien.repair_ufo)
	var skills = backpack_skills.get_children() as Array[Skill]
	skills[repair_action_idx].set_enabled()
	skills[repair_action_idx].visible = true
	_connect_sinal_if_not_connected(alien.repairing, skills[repair_action_idx].start_cooldown)
	_connect_sinal_if_not_connected(alien.repairing, func(_time): _clear_backpack_skill("repair_tool"))


func _get_action_idx(actions: Array[Callable], action: Callable) -> int:
	for i in range(actions.size()):
		if actions[i].is_null():
			continue
		if actions[i] == action:
			return i
	return -1


func _on_alien_cannot_repair():
	if player and player.role != Player.Role.ALIEN:
		return
	var alien = player.get_node("Alien") as Alien
	var repair_action_idx = _get_action_idx(alien.get_actions(), alien.repair_ufo)
	var skills = backpack_skills.get_children() as Array[Skill]
	skills[repair_action_idx].set_disabled()


func _on_ufo_crashed(peer_id):
	e.reset_cooldown()
	_setup_ui(Player.Role.ALIEN)
	_connect_signals(player)
	_report_ufo_crash_to_server.rpc_id(1, peer_id)


@rpc("any_peer", "call_local", "reliable")
func _report_ufo_crash_to_server(dropped_peer_id: int):
	if not multiplayer.is_server():
		return

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
			_broadcast_skeptic_win.rpc()


@rpc("authority", "call_local", "reliable")
func _broadcast_skeptic_win():
	_on_skeptic_win()


func _setup_win_section():
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


func _setup_ui(role: Player.Role):
	for ufo in ufos_sprites:
		ufo.visible = false
	match role:
		Player.Role.UFO:
			q.set_icon_text("Wystrzel laser")
			e.set_icon_text("Pochwyć")
			e.visible = true
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
	_show_ufo_victory_screen.rpc_id(0)


func _on_skeptic_win():
	_show_skeptics_victory_screen.rpc_id(0)


func _on_skill_fired(time: float, skill: Skill):
	skill.start_cooldown(time)


@rpc("any_peer", "call_local", "reliable")
func _show_ufo_victory_screen():
	win_label.text = UFO_WINS
	faction_label.text = "Wygrywają ufoki"
	win_info.visible = true
	main_menu_button.disabled = false


@rpc("any_peer", "call_local", "reliable")
func _show_skeptics_victory_screen():
	win_label.text = SKEPTICS_WIN
	faction_label.text = "Wygrywają sceptycy"
	win_info.visible = true
	main_menu_button.disabled = false


func _on_belive_points_changed(amount):
	hit_points += amount
	if hit_points > ufos_sprites.size():
		hit_points = ufos_sprites.size()
	for i in range(ufos_sprites.size()):
		ufos_sprites[i].visible = (i < hit_points)
