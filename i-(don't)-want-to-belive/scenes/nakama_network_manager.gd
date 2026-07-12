extends Node

var client: NakamaClient
var session: NakamaSession
var socket: NakamaSocket
var multiplayer_bridge: NakamaMultiplayerBridge
var public_chat_channel = null
var match_name: String
var actual_match_id: String
var is_host: bool = false
var private: bool = false
var max_other_players: int = 3
var is_connected_to_server: bool = false
var main_menu_scene = load("uid://8hnv34c0paf") as PackedScene
signal match_joined_successfully(room_code: String, server_match_id: String)
signal private_room_full()
signal connection_established()


func _init():
	Engine.get_main_loop().node_added.connect(_on_scene_tree_node_added)


func _ready():
	OS.set_restart_on_exit(false)
	if OS.is_debug_build():
		ProjectSettings.set_setting("debug/settings/stdout/ignore_warnings", true)

	await get_tree().process_frame
	_connect_to_nakama_server()


func _connect_to_nakama_server():
	var server_key = "defaultkey"
	var server_host = "nie-chc-uwierzy.fly.dev"

	var port = 443
	var scheme = "https"

	client = Nakama.create_client(server_key, server_host, port, scheme, 10, true)

	var unique_id = OS.get_unique_id() + str(randi() % 10000)
	var vars = { "game_version": VersionManager.get_version() }

	session = await client.authenticate_device_async(unique_id, "", true, vars)

	if session.is_exception():
		return

	socket = Nakama.create_socket_from(client)

	await socket.connect_async(session)

	is_connected_to_server = true
	connection_established.emit()

	multiplayer_bridge = NakamaMultiplayerBridge.new(socket)
	get_tree().get_multiplayer().set_multiplayer_peer(multiplayer_bridge.multiplayer_peer)

	if not multiplayer.peer_connected.is_connected(_verify_room_limit):
		multiplayer.peer_connected.connect(_verify_room_limit)


func _on_bridge_match_joined(_p_match = null):
	var other_players = []
	if get_tree().get_multiplayer().multiplayer_peer != null:
		other_players = multiplayer.get_peers()

	if is_host and other_players.size() > 0:
		await get_tree().create_timer(0.1).timeout
		host_create_match()
		return

	actual_match_id = multiplayer_bridge.match_id
	match_joined_successfully.emit(match_name, actual_match_id)


func _on_scene_tree_node_added(node: Node):
	if not is_instance_valid(node):
		return
	if node.name == "Control" or (node.get_script() and node.get_script().get_path().ends_with("lobby.gd")):
		await get_tree().process_frame

		if not is_instance_valid(node):
			return

		if get_tree().get_multiplayer().multiplayer_peer == null:
			return

		var peers_list = multiplayer.get_peers()
		var total_players = peers_list.size() + 1

		if not is_host and total_players >= 5:
			node.queue_free()
			get_tree().get_multiplayer().multiplayer_peer = null

			if private:
				is_connected_to_server = true

				if main_menu_scene:
					Engine.get_main_loop().change_scene_to_packed(main_menu_scene)

				await get_tree().process_frame
				await get_tree().process_frame

				private_room_full.emit()
				return
			else:
				await get_tree().create_timer(0.2).timeout
				multiplayer_bridge = NakamaMultiplayerBridge.new(socket)
				get_tree().get_multiplayer().set_multiplayer_peer(multiplayer_bridge.multiplayer_peer)
				_escape_full_room_and_host_new()


func _verify_room_limit(_id: int):
	var peers_list = multiplayer.get_peers()
	var total_players = peers_list.size() + 1

	if not is_host and total_players >= 5:
		var my_id = multiplayer.get_unique_id()

		var max_id = 0
		for peer in peers_list:
			if peer > max_id:
				max_id = peer

		if my_id == max_id:
			get_tree().get_multiplayer().multiplayer_peer = null

			multiplayer_bridge = NakamaMultiplayerBridge.new(socket)
			get_tree().get_multiplayer().set_multiplayer_peer(multiplayer_bridge.multiplayer_peer)

			if private:
				private_room_full.emit()
			else:
				_escape_full_room_and_host_new()


func host_create_match() -> String:
	is_host = true
	private = true
	var generated_code = _create_match_name()
	await connect_to_named_room(generated_code)
	return generated_code


func _create_match_name() -> String:
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var new_code = ""

	randomize()

	for i in range(6):
		var rand_index = randi() % chars.length()
		new_code += chars[rand_index]
	return new_code


func join_existing_game():
	if not socket:
		return

	if multiplayer_bridge == null:
		multiplayer_bridge = NakamaMultiplayerBridge.new(socket)
		get_tree().get_multiplayer().set_multiplayer_peer(multiplayer_bridge.multiplayer_peer)

	is_host = false
	private = false
	actual_match_id = ""
	match_name = ""

	var random_delay = randf_range(0.05, 0.5)
	await get_tree().create_timer(random_delay).timeout

	if not multiplayer_bridge.match_joined.is_connected(_on_bridge_match_joined):
		multiplayer_bridge.match_joined.connect(_on_bridge_match_joined)

	public_chat_channel = await socket.join_chat_async("global_matchmaking_room", 1, true, false)

	if public_chat_channel.is_exception():
		return

	var target_room_code = await _find_active_room()

	if target_room_code == "":
		is_host = true
		private = false
		var generated_code = _create_match_name()

		var msg_content = {
			"room_code": generated_code,
			"player_count": 1,
			"version": VersionManager.get_version(),
		}
		await socket.write_chat_message_async(public_chat_channel.id, msg_content)
		await connect_to_named_room(generated_code)
	else:
		is_host = false
		private = false
		await connect_to_named_room(target_room_code)


func _find_active_room() -> String:
	if not socket or not public_chat_channel:
		return ""

	var history_result = await client.list_channel_messages_async(session, public_chat_channel.id, 50, false)

	if history_result.is_exception() or not history_result.messages or history_result.messages.size() < 1:
		return ""

	var time = Time.get_unix_time_from_system()

	var messages_chronological = history_result.messages
	messages_chronological.reverse()

	for msg in messages_chronological:
		var content = JSON.parse_string(msg.content)
		if content and content.has("room_code"):
			var room_version = content.get("version", VersionManager.get_version())
			if room_version != VersionManager.get_version():
				continue

			var msg_time = Time.get_unix_time_from_datetime_string(msg.create_time)

			if time - msg_time < 300:
				var waiting_players = content.get("player_count", 1)

				if waiting_players <= 0:
					continue

				if waiting_players >= 4:
					continue

				var found_code = content["room_code"]
				return found_code

	return ""


func connect_to_named_room(room_name: String):
	if not socket or not multiplayer_bridge:
		return

	match_name = room_name

	if not multiplayer_bridge.match_joined.is_connected(_on_bridge_match_joined):
		multiplayer_bridge.match_joined.connect(_on_bridge_match_joined)

	multiplayer_bridge.join_named_match(room_name)


func _escape_full_room_and_host_new():
	get_tree().get_multiplayer().multiplayer_peer = null
	await get_tree().create_timer(0.2).timeout

	multiplayer_bridge = NakamaMultiplayerBridge.new(socket)
	get_tree().get_multiplayer().set_multiplayer_peer(multiplayer_bridge.multiplayer_peer)

	is_host = true
	private = false

	var generated_code = _create_match_name()

	if public_chat_channel:
		var msg_content = { "room_code": generated_code, "version": VersionManager.get_version(), "player_count": 1 }
		await socket.write_chat_message_async(public_chat_channel.id, msg_content)

	connect_to_named_room(generated_code)

	await get_tree().process_frame

	var lobby_scene = load("uid://dg7q16m0w6dnx") as PackedScene
	get_tree().change_scene_to_packed(lobby_scene)


func reconnect_after_error_dismissed():
	if multiplayer_bridge and multiplayer_bridge.match_joined.is_connected(_on_bridge_match_joined):
		multiplayer_bridge.match_joined.disconnect(_on_bridge_match_joined)

	multiplayer_bridge = NakamaMultiplayerBridge.new(socket)
	get_tree().get_multiplayer().set_multiplayer_peer(multiplayer_bridge.multiplayer_peer)

	is_connected_to_server = true
	connection_established.emit()


func leave_room():
	if is_instance_valid(multiplayer_bridge):
		if multiplayer_bridge.has_method("leave"):
			multiplayer_bridge.leave()
		elif multiplayer_bridge.has_method("leave_match"):
			multiplayer_bridge.leave_match()

	get_tree().get_multiplayer().set_multiplayer_peer(null)
	multiplayer_bridge = null

	actual_match_id = ""
	match_name = ""
	is_host = false
	private = false
