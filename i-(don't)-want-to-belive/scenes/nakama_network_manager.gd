extends Node

var client: NakamaClient
var session: NakamaSession
var socket: NakamaSocket
var multiplayer_bridge: NakamaMultiplayerBridge
var match_name: String

signal match_joined(match_id: String)


func _ready():
	OS.set_restart_on_exit(false)
	if OS.is_debug_build():
		ProjectSettings.set_setting("debug/settings/stdout/ignore_warnings", true)

	await get_tree().process_frame
	connect_to_nakama_server()


func connect_to_nakama_server():
	var server_key = "defaultkey"
	var host = "127.0.0.1"
	var port = 7350
	var scheme = "http"

	client = Nakama.create_client(server_key, host, port, scheme)
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


func _on_bridge_match_joined():
	var match_id = multiplayer_bridge.match_id
	print("[Nakama] Sukces! Połączono z pokojem. ID meczu: ", match_id)
	match_joined.emit(match_id)
