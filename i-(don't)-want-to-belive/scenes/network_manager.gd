extends Node

const DEFAULT_PORT = 7777
const MAX_PLAYERS = 4

var peer: ENetMultiplayerPeer


func create_host_game():
	peer = ENetMultiplayerPeer.new()

	var error = peer.create_server(0, MAX_PLAYERS)
	if error != OK:
		return

	var assigned_port = peer.get_host().get_local_port()
	setup_upnp(assigned_port)

	multiplayer.multiplayer_peer = peer


func join_client_game(ip_address: String):
	peer = ENetMultiplayerPeer.new()

	if ip_address.is_empty():
		ip_address = "127.0.0.1"

	var error = peer.create_client(ip_address, DEFAULT_PORT)
	if error != OK:
		return

	multiplayer.multiplayer_peer = peer


func setup_upnp(port: int):
	var upnp = UPNP.new()
	var discover_result = upnp.discover()

	if discover_result != UPNP.UPNP_RESULT_SUCCESS:
		return
	if not upnp.get_gateway() or not upnp.get_gateway().is_valid_gateway():
		return

	var map_udp = upnp.add_port_mapping(port, port, "Godot Game UDP", "UDP")
	var map_tcp = upnp.add_port_mapping(port, port, "Godot Game TCP", "TCP")

	if map_udp == UPNP.UPNP_RESULT_SUCCESS and map_tcp == UPNP.UPNP_RESULT_SUCCESS:
		var public_ip = upnp.query_external_address()
