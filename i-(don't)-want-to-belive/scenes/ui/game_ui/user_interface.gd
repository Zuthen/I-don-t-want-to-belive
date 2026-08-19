extends CanvasLayer

class_name UserInterface

@onready var q = $SkillsPanel/Q
@onready var e = $SkillsPanel/E
@onready var r = $SkillsPanel/R
@onready var backpack_skills = $SkillsPanel/BackpackSkills
@onready var win_info = $WinInfo
@onready var win_label = $WinInfo/WinLabel
@onready var win_info_faction_label = $WinInfo/FactionLabel
@onready var belive_points_counter_background = $Belive_Points_Counter_Background
@onready var belive_points_counter = $Belive_Points_Counter
@onready var walkie_talkie_message = $WalkieTalkieMessage
@onready var main_menu_button = $WinInfo/MainMenuButton
@onready var backpack = $SkillsPanel/Backpack
@onready var faction_label = $SkillsPanel/FactionLabel

var ufos_sprites
var hit_points: int = 0
var crashed_ufos: Array[int] = []
var max_ufos_count: int = 2
var player: Player
var additional_skills: Dictionary[Skill, bool] = { }
var jammer_ready = true


func _ready():
	MultiplayerFeatures.local_ui = self
	ufos_sprites = belive_points_counter.get_children()
	_setup_win_section()
	_setup_backpack_skills()
	if is_instance_valid(q):
		q.set_icon_text("")
	if is_instance_valid(e):
		e.set_icon_text("")
	if is_instance_valid(r):
		r.set_icon_text(tr("SKILL_FLY_AWAY"))
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


func _assign_backpack_skill(enabled_on_collect: bool, item_name: String):
	var skill_slots = additional_skills.keys()
	var free_slot_idx = skill_slots.find_custom(
		func(skill): return additional_skills[skill] == false
	)

	if free_slot_idx != -1:
		var free_skill = skill_slots[free_slot_idx]
		additional_skills[free_skill] = true
		free_skill.skill_name = item_name
		free_skill.visible = true
		var skill_labels = Findings.new()
		free_skill.set_icon_text(skill_labels.get_skill_label(player.role, item_name))
		free_skill.set_disabled()
		if enabled_on_collect:
			free_skill.set_enabled()


func _clear_backpack_skill(skill_name: String):
	var skills_list = additional_skills.keys()
	var skill = _find_skill_by_name(skill_name)
	if skill == null:
		return
	if skill.idx != -1:
		var taken_slot = skills_list[skill.idx]
		additional_skills[taken_slot] = false
		taken_slot.visible = false
		taken_slot.set_icon_text("")
		taken_slot.skill_name = ""


func _connect_signals(player: Player):
	_connect_signal_if_not_connected(ItemsManager.input_action_assigned, _assign_backpack_skill)
	_connect_signal_if_not_connected(ItemsManager.action_removed, _clear_backpack_skill)
	_connect_signal_if_not_connected(main_menu_button.pressed, _go_to_main_menu)
	_connect_signal_if_not_connected(player.somebody_wins, _on_somebody_win)
	_connect_signal_if_not_connected(ItemsManager.item_type_removed, _on_item_type_removed)
	if player.role == Player.Role.SKEPTIC:
		_connect_signal_if_not_connected(player.belive_points_changed, _on_belive_points_changed)
		_connect_signal_if_not_connected(player.walkie_talkie_message_sent, _on_skill_fired.bind(e))
		_connect_signal_if_not_connected(player.can_take_sanity_pill, _set_sanity_pill_skill)
		_connect_signal_if_not_connected(player.jammer_activated, _on_jammer_activated.bind(player as Skeptic))
		_connect_signal_if_not_connected(player.can_send_coordinates_changed, _on_jammer_ready)

	elif player.role == Player.Role.UFO:
		_assign_ufo_signals()
	elif player.role == Player.Role.BOSS:
		_connect_signal_if_not_connected(player.near_wreck_changed, _on_robert_near_wreck)
		_connect_signal_if_not_connected(player.robert_reparing, _on_robert_reparing)
	elif player.role == Player.Role.ALIEN:
		var alien = player.get_node_or_null("Alien") as Alien
		if alien:
			_connect_signal_if_not_connected(alien.near_wreck_changed, _on_alien_can_repair)
			_connect_signal_if_not_connected(alien.fly_away_activated, _on_fly_away_changed)


func _on_fly_away_changed(active: bool):
	r.visible = active


func _on_item_type_removed(item_name: String, _player: Player):
	var skill_data = _find_skill_by_name(item_name)

	if skill_data == null:
		return
	_clear_backpack_skill(item_name)


func _on_jammer_activated(player: Skeptic):
	var jammer_idx = _find_skill_by_name("signal_jammer").idx
	var skills_list = additional_skills.keys()
	if not player.can_send_coordinates:
		skills_list[jammer_idx].set_disabled()
	ItemsManager.item_used.emit("signal_jammer", player)


func _on_jammer_ready(ready: bool):
	var jammer_idx = _find_skill_by_name("signal_jammer").idx
	var skills_list = additional_skills.keys()
	if ready:
		skills_list[jammer_idx].set_enabled()
	else:
		skills_list[jammer_idx].set_disabled()


func _set_sanity_pill_skill(enabled: bool):
	if not is_multiplayer_authority():
		return

	var skill_data = _find_skill_by_name("sanity_pills")

	if skill_data == null:
		return

	var sanity_pills_idx = skill_data.idx

	if sanity_pills_idx == -1:
		return

	var skill = additional_skills.keys()[sanity_pills_idx]

	if enabled:
		skill.set_enabled()
	else:
		skill.set_disabled()


func _assign_ufo_signals():
	_connect_signal_if_not_connected(player.ufo_crashed, _on_ufo_crashed)
	var ufo = player.get_node_or_null("Ufo")
	if ufo:
		_connect_signal_if_not_connected(ufo.laser_shoot, _on_skill_fired.bind(q))
		_connect_signal_if_not_connected(ufo.captured, _on_skill_fired.bind(e))


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


func _connect_signal_if_not_connected(signal_to_connect: Signal, callable: Callable):
	if not signal_to_connect.is_connected(callable):
		signal_to_connect.connect(callable)


func _on_robert_near_wreck(near_wreck: bool, wreck_peer_id):
	if not is_instance_valid(player) or player.role != Player.Role.BOSS:
		return

	var steering_wheel_skill_data = _find_skill_by_name("steering_wheel")

	if steering_wheel_skill_data != null and steering_wheel_skill_data.idx != -1:
		var insert_steering_wheel_skill = steering_wheel_skill_data.skill

		if near_wreck:
			insert_steering_wheel_skill.set_enabled()
		else:
			insert_steering_wheel_skill.set_disabled()

	var repair_skill_data = _find_skill_by_name("repair_tool")
	var wreck = _get_wreck_by_id(wreck_peer_id)
	if repair_skill_data != null and repair_skill_data.idx != -1:
		if near_wreck and not wreck.fixed:
			repair_skill_data.skill.set_enabled()
		else:
			repair_skill_data.skill.set_disabled()


func _get_wreck_by_id(wreck_id: int) -> Wreck:
	var wrecks = get_tree().get_nodes_in_group("wrecks") as Array[Wreck]
	var wreck_idx = wrecks.find_custom(func(wreck): return wreck.peer_id == wreck_id)
	return wrecks[wreck_idx]


func _on_robert_reparing(time: float):
	var repair_skill_data = _find_skill_by_name("repair_tool")
	if repair_skill_data != null and repair_skill_data.idx != -1:
		repair_skill_data.skill.start_cooldown(time)


func _is_steering_wheel_mounted_on_wreck(wreck_peer_id: int):
	var wrecks = get_tree().get_nodes_in_group("wrecks")
	for wreck in wrecks:
		if wreck.peer_id == wreck_peer_id:
			return true
	return false


class SkillData:
	var skill: Skill
	var idx: int


func _find_skill_by_name(skill_name: String):
	var skills = backpack_skills.get_children() as Array[Skill]
	var skill_idx = skills.find_custom(
		func(s): return s.skill_name == skill_name
	)
	if skill_idx == -1:
		return
	var skillData = SkillData.new()
	skillData.skill = skills[skill_idx]
	skillData.idx = skill_idx
	return skillData


func _on_alien_can_repair(near_wreck: bool):
	if player and player.role != Player.Role.ALIEN:
		return

	var alien = player.get_node("Alien") as Alien
	var skill_data = _find_skill_by_name("repair_tool")
	if skill_data == null:
		return
	var repair_skill_idx = skill_data.idx

	if repair_skill_idx == -1:
		return

	var repair_skill = skill_data.skill
	if near_wreck:
		repair_skill.set_enabled()
	else:
		repair_skill.set_disabled()

	_connect_signal_if_not_connected(alien.repairing, repair_skill.start_cooldown)


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
			faction_label.text = tr("FACTION_LABEL_UFO")
			q.set_icon_text(tr("SKILL_LASER_SHOOT"))
			e.set_icon_text(tr("SKILL_CAPTURE"))
			e.visible = true
			r.visible = false
			belive_points_counter_background.visible = false
			belive_points_counter.visible = false
		Player.Role.SKEPTIC:
			faction_label.text = tr("FACTION_LABEL_SKEPTIC")
			e.set_icon_text(tr("SKILL_SEND_POSITION_SKEPTIC"))
			q.set_icon_text(tr("SKILL_CALL_SKEPTIC"))
			r.visible = false
		Player.Role.ALIEN:
			q.visible = false
			e.visible = false
			belive_points_counter_background.visible = false
			belive_points_counter.visible = false
			r.visible = false
			r.set_icon_text(tr("SKILL_FLY_AWAY"))
		Player.Role.BOSS:
			faction_label.text = tr("FACTION_LABEL_ROBERT")
			q.visible = false
			e.visible = false
			belive_points_counter_background.visible = false
			belive_points_counter.visible = false
			r.visible = false


func _on_somebody_win(winner: String):
	match winner:
		"ufo":
			_show_ufo_victory_screen()
		"skeptic":
			_show_skeptics_victory_screen()
		"robert":
			_show_robert_victory_screen()


func _on_skeptic_win():
	_show_skeptics_victory_screen.rpc_id(0)


func _on_skill_fired(time: float, skill: Skill):
	skill.start_cooldown(time)


@rpc("any_peer", "call_local", "reliable")
func _show_ufo_victory_screen():
	win_label.text = tr("UFO_WIN_LABEL")
	win_info_faction_label.text = tr("UFO_WIN_SUBTITLE")
	win_info.visible = true
	main_menu_button.disabled = false


@rpc("any_peer", "call_local", "reliable")
func _show_skeptics_victory_screen():
	win_label.text = tr("SKEPTICS_WIN_LABEL")
	win_info_faction_label.text = tr("SKEPTICS_WIN_SUBTITLE")
	win_info.visible = true
	main_menu_button.disabled = false


@rpc("any_peer", "call_local", "reliable")
func _show_robert_victory_screen():
	win_label.text = tr("ROBERT_WIN_LABEL")
	win_info_faction_label.text = tr("ROBERT_WIN_SUBTITLE")
	win_info.visible = true
	main_menu_button.disabled = false


func _on_belive_points_changed(amount: int):
	hit_points += amount
	if hit_points > ufos_sprites.size():
		hit_points = ufos_sprites.size()

	for i in range(ufos_sprites.size()):
		ufos_sprites[i].visible = (i < hit_points)


func display_walkie_talkie_message(sender_id: int, message_content: String, label_me: String, label_other: String):
	var my_id = multiplayer.get_unique_id()
	var is_me = (sender_id == 0) or (sender_id == my_id)
	var label_type = label_me if is_me else label_other
	walkie_talkie_message.setup(label_type, message_content)
