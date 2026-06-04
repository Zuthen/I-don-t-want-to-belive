class_name Skeptic
extends Player

@onready var camera = $Camera2D
@onready var animation_player = $AnimationPlayer
@onready var player_input_synchronizer = $PlayerInputSynchronizer
@onready var dialog_timer = $DialogTimer
@onready var dialog_placements = $DialogPlacements
@onready var collision_area = $CollisionArea
@onready var sprite_2d = $Sprite2D
@onready var collision_shape = $CollisionShape2D

var icon_placeholder_scene: PackedScene = preload("uid://d03xota05sdvx")
var voice_emitter_scene: PackedScene = preload("uid://qt86w2aja6bs")
var walkie_talkie_message_scene: PackedScene = preload("uid://tgygvek1j0wa")
var captured_animation_scene: PackedScene = preload("uid://68od6wexu11a")
var ufo_type_camera_scene: PackedScene = preload("uid://cba40e72olvj2")
var is_male
var movement_blocked := false
var can_send_coordinates = true
var voice_emitter_active := false
const walkie_talkie_timeout_seconds: float = 60 * 2
const speed = 100.0
var direction_sprite := "down"
const max_belive_points := 5
var belive_points: int = 0
const capture_animation_time: float = 4.0
signal belive_points_changed(amount: int)
signal laser_seen
signal walkie_talkie_message_sent(time: float)
var camera_zoom: Vector2

var input_multiplayer_authority: int:
	set(value):
		input_multiplayer_authority = value
		set_multiplayer_authority(value)
		if has_node("PlayerInputSynchronizer"):
			$PlayerInputSynchronizer.set_multiplayer_authority(value)


func _ready():
	camera_zoom = camera.zoom
	belive_points_changed.connect(_on_belive_points_changed)
	laser_seen.connect(_on_laser_seen)
	collision_area.area_entered.connect(_on_skeptic_find_other_skeptic)

	if input_multiplayer_authority != 0:
		set_multiplayer_authority(input_multiplayer_authority)
	if has_node("PlayerInputSynchronizer"):
		$PlayerInputSynchronizer.set_multiplayer_authority(input_multiplayer_authority)

	if is_multiplayer_authority() and has_node("Camera2D"):
		set_camera(camera)

	await get_tree().process_frame

	var my_own_hero = null
	for node in get_tree().get_nodes_in_group("skeptics") + get_tree().get_nodes_in_group("ufos"):
		if node.is_multiplayer_authority():
			my_own_hero = node
			break

	if my_own_hero and my_own_hero.is_in_group("ufos"):
		visible = false


func callable_initialize_visibility():
	var local_player = get_tree().get_first_node_in_group("local_player")
	if local_player and local_player.is_in_group("ufos"):
		local_player.player_role_assigned.emit()
		visible = false

	if is_multiplayer_authority():
		get_tree().call_group("ufos", "set_visible", false)


func _process(_delta):
	if not is_multiplayer_authority():
		return

	if Input.is_action_just_pressed("call_other_skeptic") and not voice_emitter_active:
		call_other_skeptic_network.rpc()

	if Input.is_action_just_pressed("send_walkie_talkie_message") and can_send_coordinates:
		walkie_talkie_message()
		start_cooldown_timer(walkie_talkie_timeout_seconds, func(): can_send_coordinates = !can_send_coordinates)


func _physics_process(_delta):
	var sync_direction: Vector2 = Vector2.ZERO

	if has_node("PlayerInputSynchronizer"):
		sync_direction = $PlayerInputSynchronizer.movement_vector

	if is_multiplayer_authority() && !movement_blocked:
		velocity = speed * sync_direction
		move_and_slide()
	animate(sync_direction)


@rpc("call_local", "any_peer", "reliable")
func call_other_skeptic_network():
	voice_emitter_active = true
	var voice_emitter = voice_emitter_scene.instantiate()
	add_child(voice_emitter)
	voice_emitter.timer.timeout.connect(_reset_voice_emmitter)


func walkie_talkie_message():
	var message: String
	var coordinates = get_coordinates(global_position)
	var is_letter_send = randi() % 100 < 40
	if !is_letter_send:
		message = str(coordinates.number)
	else:
		var is_number_send = randi() % 100 < 40
		if is_number_send:
			message = coordinates.letter + str(coordinates.number)
		else:
			message = coordinates.letter
	walkie_talkie_message_sent.emit(walkie_talkie_timeout_seconds)
	send_walkie_talkie_message.rpc(message)


@rpc("any_peer", "call_local", "reliable")
func send_walkie_talkie_message(message: String):
	var ui = get_tree().current_scene.get_node_or_null("CanvasLayer")
	if not ui:
		ui = get_tree().root.find_child("CanvasLayer", true, false)
	var walkie_talkie_message = walkie_talkie_message_scene.instantiate()
	if is_multiplayer_authority():
		walkie_talkie_message.message = "Nadana wiadomość:"
	walkie_talkie_message.coordinates_text = message
	ui.add_child(walkie_talkie_message)


func _reset_voice_emmitter():
	voice_emitter_active = false


func call_other_skeptic():
	call_other_skeptic_network()


func _on_belive_points_changed(hit_points: int):
	belive_points += hit_points
	if belive_points >= max_belive_points:
		ufo_wins.emit()


func _on_laser_seen():
	var dialogs = dialog_placements.get_children()
	var dialog = dialogs.pick_random() as Marker2D
	var target_position = dialog.global_position + global_position
	var icon_placeholder = icon_placeholder_scene.instantiate()

	icon_placeholder.accepts_role = [MultiplayerFeatures.Role.UFO, MultiplayerFeatures.Role.SKEPTIC] as Array[MultiplayerFeatures.Role]
	icon_placeholder.icon = preload("uid://ddjkfec0jsuw")

	get_tree().root.add_child(icon_placeholder)

	icon_placeholder.global_position = target_position
	icon_placeholder.scale = Vector2(0.6, 0.6)
	var role = MultiplayerFeatures.get_role()
	icon_placeholder.setup(role, icon_placeholder.icon)
	dialog_timer.timeout.connect(func(): _on_dialog_timer_timeout(icon_placeholder))
	dialog_timer.start()


func _on_dialog_timer_timeout(node: Node2D):
	if node != null:
		node.queue_free()


func _on_skeptic_find_other_skeptic(area: Area2D):
	var object = area.get_parent()
	if object is Skeptic:
		skeptics_win.emit()


func _play_captured_animation(texture: Texture2D, target_position):
	sprite_2d.visible = false
	collision_area.set_deferred("monitoring", false)
	collision_area.set_deferred("monitorable", false)
	collision_shape.set_deferred("disabled", true)
	var pixel_position = get_parent().tile_map_layer.map_to_local(target_position)
	var relative_offset = pixel_position - global_position
	var animation = captured_animation_scene.instantiate()
	movement_blocked = true
	animation.texture = texture
	animation.target_position = pixel_position
	animation.time = capture_animation_time
	animation.position = relative_offset
	camera.zoom = Vector2(1.5, 1.5)
	add_child(animation)
	var camera_tween = create_tween()
	camera_tween.tween_property(camera, "offset", relative_offset, capture_animation_time) \
			.set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT)
	camera_tween.tween_callback(_capture_animation_cleanup.bind(pixel_position))


func _capture_animation_cleanup(pixel_position: Vector2):
	sprite_2d.visible = true
	movement_blocked = false
	rpc("_teleport_network_rpc", pixel_position)
	camera.offset = Vector2.ZERO
	camera.zoom = camera_zoom


@rpc("authority", "call_local", "reliable")
func _teleport_network_rpc(pixel_position: Vector2):
	player_input_synchronizer.set_process(false)
	player_input_synchronizer.set_physics_process(false)
	global_position = pixel_position

	var local_player = null
	for node in get_tree().get_nodes_in_group("skeptics") + get_tree().get_nodes_in_group("ufos"):
		if node.is_multiplayer_authority():
			local_player = node
			break

	if local_player and local_player.is_in_group("skeptics"):
		visible = true
		sprite_2d.visible = true
	else:
		visible = false
		sprite_2d.visible = false

	var dynamic_smoothing = false
	if is_multiplayer_authority():
		dynamic_smoothing = camera.position_smoothing_enabled
		camera.position_smoothing_enabled = false

	collision_area.set_deferred("monitoring", true)
	collision_area.set_deferred("monitorable", true)
	collision_shape.set_deferred("disabled", false)

	if is_multiplayer_authority():
		camera.global_position = pixel_position
		camera.offset = Vector2.ZERO
		camera.zoom = camera_zoom
		camera.position_smoothing_enabled = dynamic_smoothing
		player_input_synchronizer.set_process(true)
		player_input_synchronizer.set_physics_process(false)


@rpc("any_peer", "call_local", "reliable")
func trigger_captured_effects_network(ufo_index: int, target_pos: Vector2i):
	if is_multiplayer_authority():
		var ufo_texture = UfosTextures.ufo_textures[ufo_index].ship
		belive_points_changed.emit(3)
		_play_captured_animation(ufo_texture, target_pos)
	else:
		pass


func animate(direction: Vector2):
	var directions = {
		"down": Vector2.DOWN,
		"up": Vector2.UP,
		"left": Vector2.LEFT,
		"right": Vector2.RIGHT,
	}
	var norm_dir = direction.normalized()
	var animation_sprite_name_suffix = "_boy" if is_male else ""
	if norm_dir.is_equal_approx(directions["down"]):
		animation_player.play("move down" + animation_sprite_name_suffix)
		direction_sprite = "down"
	elif norm_dir.is_equal_approx(directions["up"]):
		animation_player.play("move up" + animation_sprite_name_suffix)
		direction_sprite = "up"
	elif norm_dir.is_equal_approx(directions["left"]):
		animation_player.play("move left" + animation_sprite_name_suffix)
		direction_sprite = "left"
	elif norm_dir.is_equal_approx(directions["right"]):
		animation_player.play("move right" + animation_sprite_name_suffix)
		direction_sprite = "right"
	elif norm_dir == Vector2.ZERO:
		animation_player.play("idle " + direction_sprite + animation_sprite_name_suffix)
