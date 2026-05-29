extends Control

@onready var q_label = $QLabel


func _ready():
	var my_player: Player = null

	for i in range(20):
		my_player = MultiplayerFeatures.get_local_player()
		if my_player != null:
			break
		await get_tree().create_timer(0.05).timeout

	if my_player != null:
		my_player.player_role_assigned.connect(_on_player_role_assigned)
		var role = MultiplayerFeatures.get_role()
		_update_ui_text(role)
	else:
		printerr("[UI] Błąd sieciowy: Klient o ID ", multiplayer.get_unique_id(), " nie doczekał się swojej postaci!")


func _on_player_role_assigned():
	var role = MultiplayerFeatures.get_role()
	_update_ui_text(role)


func _update_ui_text(role: MultiplayerFeatures.Role):
	match role:
		MultiplayerFeatures.Role.UFO:
			q_label.text = "Wystrzel laser"
		MultiplayerFeatures.Role.SKEPTIC:
			q_label.text = "Zawołaj"
