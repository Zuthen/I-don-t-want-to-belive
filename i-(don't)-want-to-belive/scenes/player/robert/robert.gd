extends Player

class_name Robert

@onready var player_input_synchronizer: PlayerInputSynchronizer = $PlayerInputSynchronizer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera = $Camera2D

signal near_wreck_changed(near: bool, _crashed_ufo_peer_id: int)

const speed = 100.0
var animation_sprite_idx: int = 0
var steering_wheel_collected = false
var repair_tool_collected = false

var input_multiplayer_authority: int:
	set(value):
		input_multiplayer_authority = value
		set_multiplayer_authority(value)

var near_wreck = false:
	set(value):
		if near_wreck != value:
			near_wreck = value


func _ready():
	if is_multiplayer_authority() and has_node("Camera2D"):
		set_camera(camera)


func _physics_process(_delta):
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return
	var sync_direction = move(speed, player_input_synchronizer)
	animate(sync_direction, animation_player, animation_sprite_idx)


func insert_steering_wheel():
	if steering_wheel_collected and near_wreck:
		steering_wheel_collected = false
		ItemsManager.item_used.emit("steering_wheel")
		Events.steering_wheel_inserted.emit()


func repair_ufo():
	pass
