extends Control

func _ready():
	var game_node = get_tree().root.get_node_or_null("Game")
	if is_instance_valid(game_node):
		game_node.free()

	if is_instance_valid(GameManager):
		GameManager.players_selections.clear()
		GameManager.is_local_fog_ready = false

	if is_instance_valid(NakamaNetworkManager) and NakamaNetworkManager.has_method("leave_room"):
		NakamaNetworkManager.leave_room()

	for i in range(5):
		await get_tree().process_frame

	var main_menu_scene = load("uid://8hnv34c0paf")
	if main_menu_scene:
		get_tree().change_scene_to_packed(main_menu_scene)
