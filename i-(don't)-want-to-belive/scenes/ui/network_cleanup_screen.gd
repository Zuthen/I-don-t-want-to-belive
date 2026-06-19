extends Control

func _ready():
	print("[CLEANUP] Bezpieczna strefa załadowana. Czyszczenie śmieci z root...")

	var game_node = get_tree().root.get_node_or_null("Game")
	if is_instance_valid(game_node):
		game_node.free()

	if is_instance_valid(NakamaNetworkManager) and NakamaNetworkManager.has_method("leave_room"):
		NakamaNetworkManager.leave_room()

	await get_tree().process_frame
	await get_tree().process_frame

	var main_menu_scene = load("uid://8hnv34c0paf")
	if main_menu_scene:
		get_tree().change_scene_to_packed(main_menu_scene)
