extends Player

class_name Robert

@onready var player_input_synchronizer: PlayerInputSynchronizer = $PlayerInputSynchronizer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera = $Camera2D
@onready var animated_wheel = $AnimatedWheel

signal near_wreck_changed(near: bool, _crashed_ufo_peer_id: int)
signal robert_reparing(time: float)

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
	animated_wheel.visible = false
	near_wreck_changed.connect(_on_near_wreck)


func _physics_process(_delta):
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return
	var sync_direction = move(speed, player_input_synchronizer)
	animate(sync_direction, animation_player, animation_sprite_idx)


func _on_near_wreck(near: bool, peer_id: int):
	near_wreck_id = peer_id if near else -1


func insert_steering_wheel():
	if steering_wheel_collected and near_wreck and near_wreck_id != -1:
		steering_wheel_collected = false
		var wreck = _get_wreck_by_id(near_wreck_id)
		wreck.steering_wheel_mounted = true
		wreck.animator.play("insert wheel")
		var animation_time = wreck.animator.get_animation("insert wheel").length
		start_cooldown_timer(animation_time, func(): movement_blocked = !movement_blocked)
		ItemsManager.item_used.emit("steering_wheel", self)
		start_timer(animation_time + 2.0, func(): _check_can_win(near_wreck_id))


func _check_can_win(wreck_id: int):
	movement_blocked = true
	var wreck = _get_wreck_by_id(wreck_id)
	if wreck.fixed and wreck.steering_wheel_mounted:
		wreck.animator.play("robert fixed")
		somebody_wins.emit("robert")
	movement_blocked = false


func repair_ufo():
	if near_wreck_id != -1:
		var wreck_to_repair = _get_wreck_by_id(near_wreck_id)
		if not wreck_to_repair.fixed:
			wreck_to_repair.network_repair()
			network_play_repair_animation()
			var animation_time = animation_player.get_animation("repair ufo").length
			start_cooldown_timer(animation_time, func(): movement_blocked = !movement_blocked)
			robert_reparing.emit(animation_time)
			ItemsManager.item_used.emit("repair_tool", self)
			_check_can_win(near_wreck_id)


func _get_wreck_by_id(wreck_id: int) -> Wreck:
	var wrecks = get_tree().get_nodes_in_group("wrecks") as Array[Wreck]
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


@rpc("any_peer", "call_local", "reliable")
func network_play_repair_animation():
	animation_player.play("repair ufo")
