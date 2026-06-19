extends Control

func _ready():
	print("[CLEANUP] Bezpieczna strefa załadowana. Zaczynam wygaszanie sieci...")

	# 1. Odpinamy i uciszamy potok sieciowy Godota
	if get_tree() and get_tree().get_multiplayer():
		get_tree().get_multiplayer().set_multiplayer_peer(null)
		print("[CLEANUP] Kabel sieciowy Godota odcięty.")

	# 2. Informujemy mostek Nakamy, że opuszczamy pokój
	if is_instance_valid(NakamaNetworkManager):
		if NakamaNetworkManager.has_method("leave_room"):
			NakamaNetworkManager.leave_room()
		elif "multiplayer_bridge" in NakamaNetworkManager and NakamaNetworkManager.multiplayer_bridge:
			if NakamaNetworkManager.multiplayer_bridge.has_method("leave"):
				NakamaNetworkManager.multiplayer_bridge.leave()
		print("[CLEANUP] Mostek Nakamy zresetowany.")

	# 3. Dajemy silnikowi dwie klatki na ugaszenie wszystkich procesów C++
	await get_tree().process_frame
	await get_tree().process_frame

	# 4. Ładujemy w pełnej sieciowej ciszy menu główne
	var main_menu_scene: PackedScene = load("uid://8hnv34c0paf")
	if main_menu_scene:
		get_tree().change_scene_to_packed(main_menu_scene)
