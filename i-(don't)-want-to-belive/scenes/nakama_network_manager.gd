extends Node

var client: NakamaClient
var session: NakamaSession
var socket: NakamaSocket
var multiplayer_bridge: NakamaMultiplayerBridge

var match_name: String
var actual_match_id: String
var is_host: bool = false
var private: bool = false

signal match_joined_successfully(room_code: String, server_match_id: String)


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

	multiplayer_bridge = NakamaMultiplayerBridge.new(socket)
	get_tree().get_multiplayer().set_multiplayer_peer(multiplayer_bridge.multiplayer_peer)


func host_create_match() -> String:
	is_host = true
	private = true
	var generated_code = create_match_name()
	await connect_to_named_room(generated_code)
	return generated_code


func _on_bridge_match_joined():
	var other_players = multiplayer.get_peers()

	if is_host and other_players.size() > 0:
		print("[Nakama] Pech! Kod %s jest już zajęty przez kogoś innego. Losuję nowy..." % match_name)
		multiplayer_bridge.leave_match()

		await get_tree().create_timer(0.2).timeout
		host_create_match()
		return

	actual_match_id = multiplayer_bridge.match_id

	print("[Nakama] Sukces! Krótki kod: ", match_name, " | ID serwera: ", actual_match_id)
	match_joined_successfully.emit(match_name, actual_match_id)


func create_match_name():
	var characters = "ABCDEFGHIJKLMNOPRSTQUVWXYZ"
	var result: String = ""
	for i in range(6):
		var random_index = randi() % characters.length()
		result += characters[random_index]
	return result


var public_chat_channel = null


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
		print("[Nakama] Brak gier na czacie. Tworzę mecz jako HOST...")
		is_host = true
		private = false
		var generated_code = create_match_name()

		var msg_content = { "room_code": generated_code }
		await socket.write_chat_message_async(public_chat_channel.id, msg_content)
		connect_to_named_room(generated_code)

	else:
		print("[Nakama] Znaleziono wolną grę na czacie! Kod pokoju: %s. Dołączam..." % target_room_code)
		is_host = false
		private = false
		connect_to_named_room(target_room_code)


func find_active_room() -> String:
	if not socket or not public_chat_channel:
		return ""

	print("[Nakama] Pobieram historię wiadomości z kanału parowania...")
	var history_result = await client.list_channel_messages_async(session, public_chat_channel.id, 10, false)

	if history_result.is_exception():
		print("[Nakama] Błąd pobierania historii czatu: ", history_result.get_exception().message)
		return ""

	if not history_result.messages or history_result.messages.size() < 1:
		print("[Nakama] Kanał czatu parowania jest pusty (brak kodów gier).")
		return ""

	for msg in history_result.messages:
		var content = JSON.parse_string(msg.content)
		if content and content.has("room_code"):
			var found_code = content["room_code"]
			print("[Nakama] Znaleziono aktualny kod gry na czacie: ", found_code)
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
