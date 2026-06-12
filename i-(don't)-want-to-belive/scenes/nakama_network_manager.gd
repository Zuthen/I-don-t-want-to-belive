extends Node

var client: NakamaClient
var session: NakamaSession
var socket: NakamaSocket
var multiplayer_bridge: NakamaMultiplayerBridge

var match_name: String
var actual_match_id: String
var is_host: bool = false

signal match_joined_successfully(server_match_id: String)


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


func connect_to_named_room(room_name: String):
	if not socket or not multiplayer_bridge:
		print("[Nakama] Błąd: Brak otwartego mostu sieciowego!")
		return

	match_name = room_name
	print("[Nakama] Łączenie z nazwanym pokojem: ", room_name)

	if not multiplayer_bridge.match_joined.is_connected(_on_bridge_match_joined):
		multiplayer_bridge.match_joined.connect(_on_bridge_match_joined)

	multiplayer_bridge.join_named_match(room_name)


func host_create_match() -> String:
	is_host = true
	var generated_code = create_match_name()
	connect_to_named_room(generated_code)
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

	match_joined_successfully.emit(actual_match_id)


func create_match_name():
	var characters = "ABCDEFGHIJKLMNOPRSTQUVWXYZ"
	var result: String = ""
	for i in range(6):
		var random_index = randi() % characters.length()
		result += characters[random_index]
	return result
