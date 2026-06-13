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


func _on_scene_tree_node_added(node: Node):
	if node.name == "Control" or (node.get_script() and node.get_script().get_path().ends_with("lobby.gd")):
		await get_tree().process_frame

		var peers_list = multiplayer.get_peers()
		var total_players = peers_list.size() + 1

		if not is_host and total_players >= 5:
			print("[CRITICAL SECURITY] Room full (5/4) in Lobby. Kicking player...")

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
				escape_full_room_and_host_new()


func _ready():
	OS.set_restart_on_exit(false)
	if OS.is_debug_build():
		ProjectSettings.set_setting("debug/settings/stdout/ignore_warnings", true)

	await get_tree().process_frame
	connect_to_nakama_server()


func connect_to_nakama_server():
	var server_key = "defaultkey"
	var server_host = "127.0.0.1"
	var port = 7350
	var scheme = "http"

	client = Nakama.create_client(server_key, server_host, port, scheme)
	var unique_id = OS.get_unique_id() + str(randi() % 10000)

	print("[Nakama] Próba autentykacji urządzenia...")
	session = await client.authenticate_device_async(unique_id)

	if session.is_exception():
		print("[Nakama] Błąd logowania: ", session.get_exception().message)
		return

	print("[Nakama] Zalogowano! ID użytkownika na serwerze: ", session.user_id)

	socket = Nakama.create_socket_from(client)
	await socket.connect_async(session)
	print("[Nakama] Połączenie Socket otwarte i gotowe do gry!")
	is_connected_to_server = true
	connection_established.emit()
	multiplayer_bridge = NakamaMultiplayerBridge.new(socket)
	get_tree().get_multiplayer().set_multiplayer_peer(multiplayer_bridge.multiplayer_peer)

	if not multiplayer.peer_connected.is_connected(_verify_room_limit):
		multiplayer.peer_connected.connect(_verify_room_limit)


func _on_bridge_match_joined(_p_match = null):
	var other_players = multiplayer.get_peers()

	if is_host and other_players.size() > 0:
		print("[Nakama] Pech! Kod %s jest już zajęty. Losuję nowy..." % match_name)
		get_tree().get_multiplayer().multiplayer_peer = null
		await get_tree().create_timer(0.2).timeout
		host_create_match()
		return

	actual_match_id = multiplayer_bridge.match_id
	print("[Nakama] Most sieciowy zestawiony pomyślnie. Kod pokoju: ", match_name)

	match_joined_successfully.emit(match_name, actual_match_id)


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
			print("[Nakama Manager] STOP! Pokój %s osiągnął limit (4/4). Rozłączam..." % match_name)

			get_tree().get_multiplayer().multiplayer_peer = null

			multiplayer_bridge = NakamaMultiplayerBridge.new(socket)
			get_tree().get_multiplayer().set_multiplayer_peer(multiplayer_bridge.multiplayer_peer)

			if private:
				private_room_full.emit()
			else:
				escape_full_room_and_host_new()


func host_create_match() -> String:
	is_host = true
	private = true
	var generated_code = create_match_name()
	await connect_to_named_room(generated_code)
	return generated_code


@rpc("authority", "call_remote", "reliable")
func _host_response(accepted: bool, private: bool):
	if accepted:
		print("[Nakama Client] Zgoda przyznana! Przechodzę do lobby.")
		match_joined_successfully.emit(match_name, actual_match_id)

	else:
		print("[Nakama Client] Brak miejsc na serwerze! Uruchamiam procedurę odrzucenia...")
		get_tree().get_multiplayer().multiplayer_peer = null
		await get_tree().create_timer(0.2).timeout

		multiplayer_bridge = NakamaMultiplayerBridge.new(socket)
		get_tree().get_multiplayer().set_multiplayer_peer(multiplayer_bridge.multiplayer_peer)

		if private:
			print("[Nakama Client] Pokój był prywatny. Aktywuję błąd w popupie.")
			private_room_full.emit()
		else:
			print("[Nakama Client] Szybka gra była pełna. Tworzę nowe publiczne lobby...")
			escape_full_room_and_host_new()


func create_match_name():
	var rng = RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_usec() + OS.get_process_id()

	var characters = "ABCDEFGHIJKLMNOPRSTQUVWXYZ"
	var result: String = ""

	for i in range(6):
		var random_index = rng.randi() % characters.length()
		result += characters[random_index]

	print("[DEBUG] Wygenerowano całkowicie unikalny kod pokoju: ", result)
	return result


func join_existing_game():
	if not socket or not multiplayer_bridge:
		print("[Nakama] Błąd: Brak otwartego mostu sieciowego!")
		return

	var random_delay = randf_range(0.05, 0.5)
	print("[Nakama] Opóźniam start wyszukiwania o %f sek. ..." % random_delay)
	await get_tree().create_timer(random_delay).timeout

	if not multiplayer_bridge.match_joined.is_connected(_on_bridge_match_joined):
		multiplayer_bridge.match_joined.connect(_on_bridge_match_joined)

	public_chat_channel = await socket.join_chat_async("global_matchmaking_room", 1, true, false)

	if public_chat_channel.is_exception():
		print("[Nakama] Błąd czatu matchmakingu: ", public_chat_channel.get_exception().message)
		return

	var target_room_code = await find_active_room()

	if target_room_code == "":
		print("[Nakama] Brak gier lub wszystkie są pełne. Tworzę mecz jako HOST...")
		is_host = true
		private = false
		var generated_code = create_match_name()

		var msg_content = { "room_code": generated_code, "player_count": 1 }
		await socket.write_chat_message_async(public_chat_channel.id, msg_content)
		connect_to_named_room(generated_code)

	else:
		print("[Nakama] Dołączam jako Klient do pokoju: ", target_room_code)
		is_host = false
		private = false
		connect_to_named_room(target_room_code)


func find_active_room() -> String:
	if not socket or not public_chat_channel:
		return ""

	print("[Nakama] Pobieram historię wiadomości z kanału parowania...")
	var history_result = await client.list_channel_messages_async(session, public_chat_channel.id, 10, false)

	if history_result.is_exception() or not history_result.messages or history_result.messages.size() < 1:
		return ""

	var time = Time.get_unix_time_from_system()

	for msg in history_result.messages:
		var content = JSON.parse_string(msg.content)
		if content and content.has("room_code"):
			var msg_time = Time.get_unix_time_from_datetime_string(msg.create_time)

			if time - msg_time < 300:
				var graczy_w_srodku = content.get("player_count", 1)
				if graczy_w_srodku >= 4:
					print("[Nakama] Omijam pokój %s, ponieważ na czacie oznaczono go jako PEŁNY (4/4)." % content["room_code"])
					continue

				var found_code = content["room_code"]
				return found_code

	return ""


func connect_to_named_room(room_name: String):
	if not socket or not multiplayer_bridge:
		print("[Nakama] Błąd: Brak otwartego mostu sieciowego!")
		return

	match_name = room_name
	print("[Nakama] Łączenie z nazwanym pokojem: ", room_name)

	if not multiplayer_bridge.match_joined.is_connected(_on_bridge_match_joined):
		multiplayer_bridge.match_joined.connect(_on_bridge_match_joined)

	multiplayer_bridge.join_named_match(room_name)


func escape_full_room_and_host_new():
	print("[Nakama] Opuszczam przepełniony pokój: ", match_name)

	get_tree().get_multiplayer().multiplayer_peer = null
	await get_tree().create_timer(0.2).timeout

	multiplayer_bridge = NakamaMultiplayerBridge.new(socket)
	get_tree().get_multiplayer().set_multiplayer_peer(multiplayer_bridge.multiplayer_peer)

	is_host = true
	private = false

	var generated_code = create_match_name()

	if public_chat_channel:
		var msg_content = { "room_code": generated_code }
		await socket.write_chat_message_async(public_chat_channel.id, msg_content)

	print("[Nakama] Nowy pokój publiczny wygenerowany: ", generated_code)

	connect_to_named_room(generated_code)

	await get_tree().process_frame

	var lobby_scene = load("uid://dg7q16m0w6dnx") as PackedScene
	get_tree().change_scene_to_packed(lobby_scene)


func _on_client_connected_to_host_successfully():
	var total_players = multiplayer.get_peers().size() + 1
	print("[Nakama Manager] Klient pomyślnie połączony. Liczba osób w sieci: ", total_players)

	if total_players >= 5:
		if private:
			print("[Nakama Manager] Odmowa! Pokój prywatny jest pełny (%d/4). Odłączam..." % total_players)
			get_tree().get_multiplayer().multiplayer_peer = null
			await get_tree().create_timer(0.2).timeout

			multiplayer_bridge = NakamaMultiplayerBridge.new(socket)
			get_tree().get_multiplayer().set_multiplayer_peer(multiplayer_bridge.multiplayer_peer)

			private_room_full.emit()
		else:
			print("[Nakama Manager] Pokój publiczny pełny. Uruchamiam automatyczną ucieczkę...")
			escape_full_room_and_host_new()
		return

	print("[Nakama Manager] Miejsce zabezpieczone. Zmieniam scenę na lobby!")
	match_joined_successfully.emit(match_name, actual_match_id)


@rpc("any_peer", "call_remote", "reliable")
func _check_server_space(client_id: int, is_private_room: bool):
	if not is_host:
		return

	var total_peers = multiplayer.get_peers().size()
	print("[Host Server] Peer %d checking space. Total current peers: %d" % [client_id, total_peers])

	if total_peers > 3:
		print("[Host Server] Room full! Rejecting peer ID: ", client_id)
		_validation_response.rpc_id(client_id, false, is_private_room)
	else:
		print("[Host Server] Space available. Accepting peer ID: ", client_id)
		_validation_response.rpc_id(client_id, true, is_private_room)


@rpc("any_peer", "call_remote", "reliable")
func _validation_response(accepted: bool, is_private_room: bool):
	if accepted:
		print("[Nakama Client] Host accepted connection. Entering lobby.")
		actual_match_id = multiplayer_bridge.match_id
		match_joined_successfully.emit(match_name, actual_match_id)
	else:
		print("[Nakama Client] Host rejected connection. Room is full. Disconnecting...")

		if multiplayer_bridge and multiplayer_bridge.match_joined.is_connected(_on_bridge_match_joined):
			multiplayer_bridge.match_joined.disconnect(_on_bridge_match_joined)

		get_tree().get_multiplayer().multiplayer_peer = null
		await get_tree().create_timer(0.2).timeout

		if multiplayer_bridge:
			get_tree().get_multiplayer().set_multiplayer_peer(multiplayer_bridge.multiplayer_peer)

		is_connected_to_server = true
		connection_established.emit()

		if is_private_room:
			private_room_full.emit()
		else:
			escape_full_room_and_host_new()


func get_nakama_player_count() -> int:
	if get_tree() and get_tree().get_multiplayer() and get_tree().get_multiplayer().multiplayer_peer != null:
		var active_peers = get_tree().get_multiplayer().get_peers()
		return active_peers.size() + 1
	return 1


func reconnect_after_error_dismissed():
	print("[Nakama Manager] User dismissed full room error. Re-initializing network bridge...")

	if multiplayer_bridge and multiplayer_bridge.match_joined.is_connected(_on_bridge_match_joined):
		multiplayer_bridge.match_joined.disconnect(_on_bridge_match_joined)

	multiplayer_bridge = NakamaMultiplayerBridge.new(socket)
	get_tree().get_multiplayer().set_multiplayer_peer(multiplayer_bridge.multiplayer_peer)

	is_connected_to_server = true
	connection_established.emit()
	print("[Nakama Manager] Network pipeline restored cleanly!")
