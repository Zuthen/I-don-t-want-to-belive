extends Player

class_name Robert

@onready var player_input_synchronizer: PlayerInputSynchronizer = $PlayerInputSynchronizer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera = $Camera2D
@onready var animated_wheel = $AnimatedWheel
@onready var voicer = $Voicer
@onready var voicer_shape = $Voicer/VoicerShape
@onready var voicer_shape_radius = voicer_shape.shape.radius

signal near_wreck_changed(near: bool, _crashed_ufo_peer_id: int)
signal robert_reparing(time: float)
signal robert_speaking

const speed = 100.0
var animation_sprite_idx: int = 0
var steering_wheel_collected = false
var repair_tool_collected = false
var near_wreck_id: int
var can_speach = false
var speaking = false
var speach_timeout: float = 20.0
var belivers: Array[int]
var speach_active: bool = false
var show_speach_range: bool = false

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
	voicer_shape_radius = voicer_shape.shape.radius
	near_wreck_changed.connect(_on_near_wreck)
	voicer.area_entered.connect(_talk_active)
	robert_speaking.connect(_speach)


func _show_range():
	show_speach_range = true
	queue_redraw()


func _hide_range():
	show_speach_range = false
	queue_redraw()


func _speach():
	speaking = true
	const voicer_max_radius: float = 150.0
	const voicer_min_radius: float = 50.0
	_show_range()
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_method(
		_update_speach_radius,
		voicer_min_radius,
		voicer_max_radius,
		speach_timeout / 3.0,
	)
	if not voicer.area_entered.is_connected(_on_speach_succeed):
		voicer.area_entered.connect(_on_speach_succeed.bind(tween))
	tween.finished.connect(_on_speach_end.bind(tween))


func _update_speach_radius(new_radius: float):
	if is_instance_valid(voicer_shape) and voicer_shape.shape is CircleShape2D:
		voicer_shape.shape.radius = new_radius
		queue_redraw()


func _draw():
	if not show_speach_range:
		return

	if is_instance_valid(voicer_shape) and voicer_shape.shape is CircleShape2D:
		var speach_area_color: Color = Color("e3577533")
		var speach_border_color: Color = Color("e35775ff")
		var current_radius = voicer_shape.shape.radius
		draw_circle(Vector2.ZERO, current_radius, speach_area_color, true, -1.0, true)
		draw_circle(Vector2.ZERO, current_radius, speach_border_color, false, 2.0, true)


func _on_speach_end(tween: Tween):
	_hide_range()
	voicer_shape.shape.radius = voicer_shape_radius
	speaking = false
	if voicer.area_entered.is_connected(_on_speach_succeed):
		voicer.area_entered.disconnect(_on_speach_succeed)


func _talk_active(area):
	var parent = area.get_parent()
	if parent != null and parent is Skeptic and not belivers.has(parent.id) and not speaking:
		start_timer(1.5, _speach)


func _on_speach_succeed(area, tween: Tween):
	if not multiplayer.is_server():
		return

	var parent = area.get_parent()

	if not (parent is Skeptic) or belivers.has(parent.id):
		return

	belivers.append(parent.id)

	if voicer.area_entered.is_connected(_on_speach_succeed):
		voicer.area_entered.disconnect(_on_speach_succeed)

	if is_instance_valid(tween) and tween.is_running():
		tween.kill()

	_on_speach_end(tween)

	rpc_change_skeptic_faith.rpc(parent.id)


@rpc("any_peer", "call_local", "reliable")
func rpc_change_skeptic_faith(skeptic_id: int):
	var game_node = get_node_or_null("/root/Game")
	if game_node:
		var target_skeptic = game_node.get_node_or_null(str(skeptic_id))
		target_skeptic.belive_points_changed.emit(1)


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
			wreck_to_repair.network_repair.rpc()
			network_play_repair_animation.rpc()

			var animation_time = animation_player.get_animation("repair ufo").length
			movement_blocked = true
			start_timer(animation_time, func(): movement_blocked = false)

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
