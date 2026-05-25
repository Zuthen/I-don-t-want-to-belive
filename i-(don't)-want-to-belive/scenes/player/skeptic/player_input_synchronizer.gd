extends MultiplayerSynchronizer

var movement_vector = Vector2.ZERO


func _process(_delta):
	if is_multiplayer_authority():
		gather_input()


func gather_input():
	movement_vector = Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
