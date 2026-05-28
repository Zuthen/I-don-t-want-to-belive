extends Control

@onready var action_label = $TextureRect/Label
@onready var q_label = $QLabel


func _ready():
	var my_player: Player = null

	for i in range(20):
		my_player = _get_local_player()
		if my_player != null:
			break
		await get_tree().create_timer(0.05).timeout

	if my_player != null:
		my_player.player_role_assigned.connect(_on_player_role_assigned)
		var i_am_ufo = my_player is Ufo

		_update_ui_text(i_am_ufo)
	else:
		printerr("[UI] Błąd sieciowy: Klient o ID ", multiplayer.get_unique_id(), " nie doczekał się swojej postaci!")


func _get_local_player() -> Player:
	var my_id = multiplayer.get_unique_id()
	var all_players = get_tree().get_nodes_in_group("ufos") + get_tree().get_nodes_in_group("skeptics")

	for player in all_players:
		if player is Player and player.id == my_id:
			return player as Player

	return null


func _on_player_role_assigned():
	var my_player = _get_local_player()

	if my_player == null:
		return

	var is_ufo = my_player is Ufo
	_update_ui_text(is_ufo)


func _update_ui_text(is_ufo: bool):
	q_label.text = "Wystrzel laser" if is_ufo else "Zawołaj"
