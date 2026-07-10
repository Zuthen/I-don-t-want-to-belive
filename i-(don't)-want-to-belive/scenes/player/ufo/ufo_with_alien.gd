extends Player

class_name UfoWithAlien

enum State { UFO, ALIEN }

@onready var ufo = $Ufo
@onready var alien = $Alien
@onready var player_input_synchronizer = $PlayerInputSynchronizer
@onready var alien_collider = $AlienCollider
@onready var ufo_collider = $UfoCollider

const UFO_SPEED = 150.0
const ALIEN_SPEED = 105.0

var current_state = State.UFO
var game: Node2D
signal ufo_crashed(peer_id: int)

@export var ufo_index_sync: int = 0:
	set(value):
		ufo_index_sync = value
		if alien:
			alien.skin_idx = value

var input_multiplayer_authority: int:
	set(value):
		input_multiplayer_authority = value
		id = value
		_deferred_set_network_authority(value)


func _deferred_set_network_authority(value: int):
	if not is_inside_tree():
		await tree_entered

	set_multiplayer_authority(value)

	if has_node("PlayerInputSynchronizer"):
		var sync_node = get_node("PlayerInputSynchronizer")
		sync_node.public_visibility = false
		sync_node.set_deferred("multiplayer_authority", value)
		get_tree().process_frame.connect(func(): sync_node.public_visibility = true, CONNECT_ONE_SHOT)

	if has_node("MultiplayerSynchronizer"):
		$MultiplayerSynchronizer.set_deferred("multiplayer_authority", value)

	if value == multiplayer.get_unique_id():
		if not is_in_group("ufos"):
			add_to_group("ufos")


func _ready():
	Events.ufo_fixed.connect(_on_ufo_fixed)
	game = get_parent()
	current_state = State.UFO

	ufo.visible = true
	ufo.process_mode = PROCESS_MODE_INHERIT
	ufo_collider.disabled = false

	alien.visible = false
	alien.process_mode = PROCESS_MODE_DISABLED
	alien_collider.disabled = true

	if alien.has_node("Coordinates"):
		alien.get_node("Coordinates").visible = false

	alien.skin_idx = ufo_index_sync

	if input_multiplayer_authority != 0:
		_deferred_set_network_authority(input_multiplayer_authority)

	_update_visibility_for_start()
	collision_layer = 0
	collision_mask = 16
	_set_ufo_state()


func _on_ufo_fixed(new_position: Vector2):
	print("UFO FIXED, I'm ufo again")
	print(new_position)
	global_position = new_position
	change_state.rpc(State.UFO, ufo_index_sync)


func _update_visibility_for_start():
	await get_tree().process_frame

	var my_local_hero: Node = null
	var all_players = get_tree().get_nodes_in_group("ufos") + get_tree().get_nodes_in_group("skeptics")

	for p in all_players:
		if p.is_multiplayer_authority():
			my_local_hero = p
			break

	if my_local_hero and my_local_hero.is_in_group("skeptics"):
		ufo.visible = false
		if ufo.has_node("Ship"):
			ufo.get_node("Ship").visible = false
	else:
		ufo.visible = true
		if ufo.has_node("Ship"):
			ufo.get_node("Ship").visible = true


func _physics_process(_delta):
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return

	if not is_multiplayer_authority():
		return

	if current_state == State.UFO:
		var is_blocked = ufo.movement_blocked if "movement_blocked" in ufo else false
		if not is_blocked:
			move(UFO_SPEED, player_input_synchronizer)

	elif current_state == State.ALIEN:
		var is_blocked = alien.movement_blocked if "movement_blocked" in alien else false
		if not is_blocked:
			move(ALIEN_SPEED, player_input_synchronizer)


func _set_ufo_state():
	alien.visible = false
	if is_in_group("aliens"):
		remove_from_group("aliens")
	if not is_in_group("ufos"):
		add_to_group("ufos")
	ufo.visible = true
	ufo.set_process(true)

	if is_multiplayer_authority():
		if alien.camera:
			alien.camera.enabled = false
		ufo.camera.enabled = true
		ufo.camera.make_current()
		set_camera(ufo.camera)

	alien.visible = false
	alien.process_mode = PROCESS_MODE_DISABLED
	alien.set_process(false)
	alien.collector.set_deferred("disabled", true)

	if "coordinates" in alien and alien.coordinates:
		alien.coordinates.visible = false

	ufo_collider.set_deferred("disabled", false)
	alien_collider.set_deferred("disabled", true)
	collision_layer = 0
	collision_mask = 16
	get_tree().call_group("ufos", "_update_visibility_for_local_player")


func _set_alien_state(ufo_index: int):
	alien.visible = true
	var sender_id = get_multiplayer_authority()

	role = Player.Role.ALIEN
	alien.role = Player.Role.ALIEN
	visible = true

	if is_in_group("ufos"):
		remove_from_group("ufos")
	if not is_in_group("aliens"):
		add_to_group("aliens")

	alien.process_mode = PROCESS_MODE_INHERIT
	alien.collector.set_deferred("disabled", false)
	alien.visible = true
	alien.set_process(true)
	ufo_crashed.emit(sender_id)
	alien.skin_idx = ufo_index
	if alien.has_method("_apply_skin_textures"):
		alien._apply_skin_textures()

	if "coordinates" in alien and alien.coordinates:
		alien.coordinates.visible = true

	ufo.visible = false
	ufo.set_process(false)

	ufo_collider.set_deferred("disabled", true)
	alien_collider.set_deferred("disabled", false)
	collision_layer = 1
	collision_mask = 3

	if is_multiplayer_authority():
		var tile_map = game.tile_map_layer
		var current_grid_pos: Vector2i = tile_map.local_to_map(global_position)

		if not game.paths.has(current_grid_pos):
			var safe_tile = ufo.find_nearest_path(global_position)
			global_position = tile_map.map_to_local(safe_tile)
		else:
			global_position = tile_map.map_to_local(current_grid_pos)

	await get_tree().process_frame

	if is_multiplayer_authority():
		if ufo.camera:
			ufo.camera.enabled = false
		alien.camera.enabled = true
		alien.camera.make_current()
		set_camera(alien.camera)

	get_tree().call_group("aliens", "_update_visibility_for_local_player")
	get_tree().call_group("ufos", "_update_visibility_for_local_player")

	var fog_layer = game.tile_map_layer
	if fog_layer:
		if "last_player_tile" in fog_layer:
			fog_layer.last_player_tile = Vector2i(-999, -999)
		if "ufo_view_setup" in fog_layer:
			fog_layer.ufo_view_setup = false


@rpc("any_peer", "call_local", "reliable")
func change_state(new_state: State, ufo_index: int):
	current_state = new_state
	ufo_index_sync = ufo_index

	if new_state == State.UFO:
		_set_ufo_state()

	elif new_state == State.ALIEN:
		_set_alien_state(ufo_index)


func _update_visibility_for_local_player():
	if not is_inside_tree():
		return

	if is_multiplayer_authority():
		visible = true
		alien.visible = true
		return

	var my_local_role = MultiplayerFeatures.get_local_player_role()

	if current_state == State.UFO:
		if my_local_role == Player.Role.SKEPTIC:
			visible = false
		else:
			visible = true
	elif current_state == State.ALIEN:
		visible = true
		alien.visible = true
