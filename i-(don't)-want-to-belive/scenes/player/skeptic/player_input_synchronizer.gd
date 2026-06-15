extends MultiplayerSynchronizer

class_name PlayerInputSynchronizer

var movement_vector = Vector2.ZERO


func _ready():
	public_visibility = false
	set_process(false)

	await get_tree().process_frame
	await get_tree().process_frame

	public_visibility = true
	set_process(true)


func _process(_delta):
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return
	if not public_visibility:
		return

	if is_multiplayer_authority():
		gather_input()


func gather_input():
	movement_vector = Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
