extends Node

var client: NakamaClient
var session: NakamaSession
var socket: NakamaSocket
signal match_joined(match_id: String)
signal match_presence_updated(joins: Array, leaves: Array)
signal network_data_received(op_code: int, data: Dictionary)

var current_match: NakamaRTAPI.Match = null
var my_session_id: String = ""


func _ready():
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
	print("[Nakama] Token sesji: ", session.token)

	socket = Nakama.create_socket_from(client)
	await socket.connect_async(session)
	print("[Nakama] Połączenie Socket otwarte i gotowe do gry!")
