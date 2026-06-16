class_name Skeptic
extends Player

@onready var camera = $Camera2D
@onready var animation_player = $AnimationPlayer
@onready var player_input_synchronizer: PlayerInputSynchronizer = $PlayerInputSynchronizer
@onready var dialog_timer = $DialogTimer
@onready var dialog_placements = $DialogPlacements
@onready var collision_area = $CollisionArea
@onready var sprite_2d = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var warning_label = $WarningLabel
@onready var sound = $Sound
@onready var voice_receiver = $VoiceReceiver

var icon_placeholder_scene: PackedScene = preload("uid://d03xota05sdvx")
var voice_emitter_scene: PackedScene = preload("uid://qt86w2aja6bs")
var captured_animation_scene: PackedScene = preload("uid://68od6wexu11a")
var ufo_type_camera_scene: PackedScene = preload("uid://cba40e72olvj2")

var animation_sprite_idx: int = 0
var can_send_coordinates = true
var voice_emitter_active := false

var seen_ufos: Array[int] = []
var seen_aliens: Array[int] = []

const walkie_talkie_timeout_seconds: float = 120.0
const speed = 100.0
const max_belive_points := 5
const capture_animation_time: float = 4.0

var direction_sprite := "down"
var belive_points: int = 0
var camera_zoom: Vector2
var warning_time: float = 1.5

signal belive_points_changed(amount: int)
signal laser_seen(ufo_sender_id: int)
signal walkie_talkie_message_sent(time: float)
signal alien_seen(peer_id: int)

var input_multiplayer_authority: int:
	set(value):
		input_multiplayer_authority = value
		_deferred_set_network_authority(value)


func _deferred_set_network_authority(value: int):
	if not is_inside_tree():
		await tree_entered
	set_multiplayer_authority(value)
	if has_node("PlayerInputSynchronizer"):
		$PlayerInputSynchronizer.set_multiplayer_authority(value)
	if has_node("MultiplayerSynchronizer"):
		$MultiplayerSynchronizer.set_multiplayer_authority(value)


func _ready():
	if not is_inside_tree():
		await tree_entered
	warning_label.visible = false
	camera_zoom = camera.zoom

	belive_points_changed.connect(_on_belive_points_changed)
	laser_seen.connect(_on_laser_seen)
	alien_seen.connect(_on_alien_seen)
	collision_area.area_entered.connect(_on_skeptic_find_other_skeptic)

	if input_multiplayer_authority != 0:
		set_multiplayer_authority(input_multiplayer_authority)

	if is_multiplayer_authority() and has_node("Camera2D"):
		set_camera(camera)

	if has_node("MultiplayerSynchronizer"):
		var pos_sync = $MultiplayerSynchronizer

		pos_sync.public_visibility = true
		pos_sync.set_multiplayer_authority(id if id != 0 else get_multiplayer_authority())

		var config = SceneReplicationConfig.new()
		config.add_property(NodePath(".:global_position"))
		config.property_set_replication_mode(NodePath(".:global_position"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
		pos_sync.replication_config = config

	await get_tree().process_frame
	await get_tree().process_frame

	_update_visibility_for_local_player()

	if has_node("MultiplayerSynchronizer") and has_method("update_synchronizer_visibility_by_role"):
		update_synchronizer_visibility_by_role()


func _update_visibility_for_local_player():
	if not is_inside_tree():
		return

	var my_unique_id = multiplayer.get_unique_id()

	if id == my_unique_id or is_multiplayer_authority():
		visible = true
		sprite_2d.visible = true
		return

	var my_role = MultiplayerFeatures.get_local_player_role()

	if my_role == Player.Role.UFO:
		visible = false
		sprite_2d.visible = false
	else:
		visible = true
		sprite_2d.visible = true


func callable_initialize_visibility():
	_update_visibility_for_local_player()
	if has_node("MultiplayerSynchronizer"):
		var synchronizer = $MultiplayerSynchronizer
		synchronizer.set_visibility_for(0, false)
		synchronizer.set_visibility_for(multiplayer.get_unique_id(), true)
		synchronizer.set_visibility_for(1, true)
	if is_multiplayer_authority():
		get_tree().call_group("ufos", "set_visible", false)


func _process(_delta):
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return

	if not is_multiplayer_authority():
		return

	if Input.is_action_just_pressed("call_other_skeptic") and not voice_emitter_active:
		call_other_skeptic_network.rpc()

	if Input.is_action_just_pressed("send_walkie_talkie_message") and can_send_coordinates:
		walkie_talkie_message()
		start_cooldown_timer(walkie_talkie_timeout_seconds, func(): can_send_coordinates = !can_send_coordinates)


func _physics_process(_delta):
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return
	var sync_direction = move(speed, player_input_synchronizer)
	animate(sync_direction)


@rpc("call_local", "any_peer", "reliable")
func call_other_skeptic_network():
	voice_emitter_active = true
	var voice_emitter = voice_emitter_scene.instantiate()
	add_child(voice_emitter)
	voice_emitter.timer.timeout.connect(_reset_voice_emmitter)


func walkie_talkie_message():
	var coordinates = get_coordinates(global_position)
	var message: String = ""

	if randi() % 100 >= 40:
		message = str(coordinates.number)
	else:
		message = coordinates.letter + str(coordinates.number) if randi() % 100 < 40 else coordinates.letter

	walkie_talkie_message_sent.emit(walkie_talkie_timeout_seconds)
	MultiplayerFeatures.broadcast_walkie_talkie.rpc(message)


@rpc("any_peer", "call_local", "reliable")
func send_walkie_talkie_message(message: String):
	var ui = get_node_or_null("UserInterface")
	if not ui:
		ui = get_tree().root.find_child("UserInterface", true, false)

	if is_instance_valid(ui) and ui.has_method("receive_walkie_talkie_message"):
		ui.receive_walkie_talkie_message(message)


func _reset_voice_emmitter():
	voice_emitter_active = false


func call_other_skeptic():
	call_other_skeptic_network()


func _on_belive_points_changed(hit_points: int):
	belive_points += hit_points
	if belive_points >= max_belive_points:
		ufo_wins.emit()


func _on_laser_seen(ufo_sender_id: int):
	if dialog_timer and not dialog_timer.is_stopped():
		return

	if sound != null and is_instance_valid(sound):
		var laser_sound = Sounds.laser_sounds.pick_random()
		sound.stream = laser_sound
		sound.play()

	var dialogs = dialog_placements.get_children()
	if dialogs.is_empty():
		return

	var dialog = dialogs.pick_random() as Marker2D
	var target_position = global_position + dialog.position

	request_icon_spawn_on_server.rpc(target_position, ufo_sender_id, multiplayer.get_unique_id(), "angry")


@rpc("any_peer", "call_local", "reliable")
func request_icon_spawn_on_server(target_position: Vector2, sender_id: int, target_id: int, icon_ref: String):
	if not multiplayer.is_server():
		return

	if MultiplayerFeatures.server_icon_cooldowns.has(target_id):
		return
	MultiplayerFeatures.server_icon_cooldowns.append(target_id)

	var is_laser = true if icon_ref == "angry" else false
	var spawn_data = {
		"type": "icon",
		"global_position": target_position,
		"peer_id": target_id,
		"icon_key": icon_ref,
		"sender_id": sender_id,
		"target_id": target_id,
		"is_laser_type": is_laser,
	}

	var current_root = get_tree().current_scene if get_tree().current_scene else get_tree().root
	var spawner = current_root.find_child("MultiplayerSpawner", true, false)

	if spawner:
		spawner.spawn(spawn_data)

		get_tree().create_timer(3.0).timeout.connect(
			func():
				if MultiplayerFeatures.server_icon_cooldowns.has(target_id):
					MultiplayerFeatures.server_icon_cooldowns.erase(target_id),
			CONNECT_ONE_SHOT,
		)


func _hide_emote():
	if is_instance_valid(voice_receiver) and is_instance_valid(voice_receiver.emote_placeholder):
		voice_receiver.emote_placeholder.visible = false


func _on_skeptic_find_other_skeptic(area: Area2D):
	if area.get_parent() is Skeptic:
		skeptics_win.emit()


func _play_captured_animation(ufo_texture_idx: int, target_position):
	var capture_sound = Sounds.capture_sounds.pick_random()
	sound.stream = capture_sound
	sound.play()
	sprite_2d.visible = false
	collision_area.set_deferred("monitoring", false)
	collision_area.set_deferred("monitorable", false)
	collision_area.set_deferred("disabled", true)

	var pixel_position = get_parent().tile_map_layer.map_to_local(target_position)
	var relative_offset = pixel_position - global_position
	var animation = captured_animation_scene.instantiate()

	movement_blocked = true

	add_child(animation)
	animation.set_as_top_level(true)
	animation.z_index = 20
	animation.global_position = pixel_position

	var ufo_sprite: Sprite2D = null
	var ufo_texture = UfosTextures.ufo_textures[ufo_texture_idx].ship

	if animation.has_node("Sprite2D"):
		ufo_sprite = animation.get_node("Sprite2D")
		ufo_sprite.texture = ufo_texture
	else:
		animation.texture = ufo_texture

	var was_zoom_smoothing: bool = false
	var was_smoothing_enabled: bool = false

	if is_multiplayer_authority() and is_instance_valid(camera):
		was_zoom_smoothing = camera.is_class("Camera2D") and camera.has_method("is_zoom_smoothing_enabled") and camera.zoom_smoothing_enabled
		if "zoom_smoothing_enabled" in camera:
			camera.zoom_smoothing_enabled = false

		camera.zoom = Vector2(1.1, 1.1)
		camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER

		was_smoothing_enabled = camera.position_smoothing_enabled
		camera.position_smoothing_enabled = false

		camera.set_as_top_level(true)
		camera.offset = Vector2.ZERO
		camera.global_position = pixel_position
		camera.reset_smoothing()

	var main_tween = get_tree().create_tween().set_parallel(true)

	animation.scale = Vector2(0.75, 0.75)
	if is_instance_valid(ufo_sprite):
		ufo_sprite.scale = Vector2.ONE

	var target_y = pixel_position.y - 150.0

	main_tween.tween_property(animation, "global_position:y", target_y, capture_animation_time) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	if is_multiplayer_authority() and is_instance_valid(camera):
		main_tween.tween_property(camera, "global_position:y", target_y, capture_animation_time) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	main_tween.set_parallel(false)

	var cleanup_callable = func(was_zoom: bool, was_smooth: bool):
		if is_multiplayer_authority() and is_instance_valid(camera):
			if "zoom_smoothing_enabled" in camera:
				camera.zoom_smoothing_enabled = was_zoom
			camera.position_smoothing_enabled = was_smooth

		if is_instance_valid(animation):
			animation.queue_free()

		_capture_animation_cleanup(pixel_position)

	var bound_cleanup = cleanup_callable.bind(was_zoom_smoothing, was_smoothing_enabled)
	main_tween.tween_callback(bound_cleanup)


func _capture_animation_cleanup(pixel_position: Vector2):
	sprite_2d.visible = true
	movement_blocked = false
	global_position = pixel_position

	if is_multiplayer_authority() and is_instance_valid(camera):
		camera.set_as_top_level(false)
		camera.offset = Vector2.ZERO
		camera.zoom = camera_zoom

		camera.position = Vector2.ZERO
		camera.reset_smoothing()

	rpc("_teleport_network_rpc", pixel_position)


@rpc("authority", "call_local", "reliable")
func _teleport_network_rpc(pixel_position: Vector2):
	if is_instance_valid(player_input_synchronizer):
		player_input_synchronizer.set_process(false)
		player_input_synchronizer.set_physics_process(false)

	global_position = pixel_position

	var local_player = null
	for node in get_tree().get_nodes_in_group("skeptics") + get_tree().get_nodes_in_group("ufos") + get_tree().get_nodes_in_group("aliens"):
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
	if is_multiplayer_authority() and is_instance_valid(camera):
		dynamic_smoothing = camera.position_smoothing_enabled
		camera.position_smoothing_enabled = false

	collision_area.set_deferred("monitoring", true)
	collision_area.set_deferred("monitorable", true)
	collision_shape.set_deferred("disabled", false)

	if is_instance_valid(player_input_synchronizer):
		player_input_synchronizer.set_process(true)
		player_input_synchronizer.set_physics_process(true)

	if is_multiplayer_authority() and is_instance_valid(camera):
		camera.position_smoothing_enabled = dynamic_smoothing


@rpc("any_peer", "call_local", "reliable")
func trigger_captured_effects_network(ufo_index: int, target_pos: Vector2i):
	if is_multiplayer_authority():
		belive_points_changed.emit(3)
		_play_captured_animation(ufo_index, target_pos)


func _on_crashed_ufo_discovered(ufo_peer_id: int):
	if not seen_ufos.has(ufo_peer_id):
		seen_ufos.append(ufo_peer_id)
		belive_points_changed.emit(1)
		warning_label.text = "Widzisz wrak ufo!"
		start_cooldown_timer(warning_time, func(): warning_label.visible = !warning_label.visible)


func _on_alien_seen(alien_peer_id: int):
	if not seen_aliens.has(alien_peer_id):
		seen_aliens.append(alien_peer_id)
		belive_points_changed.emit(1)
		warning_label.text = "Widzisz kosmitę!"
		start_cooldown_timer(warning_time, func(): warning_label.visible = !warning_label.visible)


func animate(direction: Vector2):
	if not is_inside_tree() or animation_player == null:
		return
	var directions = {
		"down": Vector2.DOWN,
		"up": Vector2.UP,
		"left": Vector2.LEFT,
		"right": Vector2.RIGHT,
	}
	var norm_dir = direction.normalized()

	if norm_dir.is_equal_approx(directions["down"]):
		animation_player.play("move down " + str(animation_sprite_idx))
		direction_sprite = "down"
	elif norm_dir.is_equal_approx(directions["up"]):
		animation_player.play("move up " + str(animation_sprite_idx))
		direction_sprite = "up"
	elif norm_dir.is_equal_approx(directions["left"]):
		animation_player.play("move left " + str(animation_sprite_idx))
		direction_sprite = "left"
	elif norm_dir.is_equal_approx(directions["right"]):
		animation_player.play("move right " + str(animation_sprite_idx))
		direction_sprite = "right"
	elif norm_dir == Vector2.ZERO:
		animation_player.play("idle " + direction_sprite + " " + str(animation_sprite_idx))
