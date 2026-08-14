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
var near_wreck_id: int

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
	near_wreck_changed.connect(_on_near_wreck)


func _physics_process(_delta):
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return
	var sync_direction = move(speed, player_input_synchronizer)
	animate(sync_direction, animation_player, animation_sprite_idx)


func _on_near_wreck(near: bool, peer_id: int):
	near_wreck_id = peer_id if near else -1


func insert_steering_wheel():
	print("wheel inserted")
	if steering_wheel_collected and near_wreck:
		steering_wheel_collected = false
		ItemsManager.item_used.emit("steering_wheel")
		Events.steering_wheel_inserted.emit()


func repair_ufo():
	if near_wreck_id != -1:
		var wreck_to_repair = _get_wreck_by_id(near_wreck_id)
		wreck_to_repair.network_repair()


func _get_wreck_by_id(wreck_id: int) -> CrashedUfo:
	var wrecks = get_tree().get_nodes_in_group("wrecks") as Array[CrashedUfo]
	var wreck_idx = wrecks.find_custom(func(wreck): return wreck.peer_id == wreck_id)
	return wrecks[wreck_idx]


func _update_visibility_for_local_player():
	if not is_inside_tree():
		return

	var my_unique_id = multiplayer.get_unique_id()

	if id == my_unique_id or is_multiplayer_authority():
		visible = true
		return

	var my_role = MultiplayerFeatures.get_local_player_role()

	if my_role == Player.Role.UFO:
		visible = false
	if my_role == Player.Role.ALIEN:
		visible = true
