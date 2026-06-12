extends Player

class_name UfoWithAlien

enum State { UFO, ALIEN }

@onready var ufo = $Ufo
@onready var alien = $Alien
@onready var camera = $Camera2D
@onready var player_input_synchronizer = $PlayerInputSynchronizer
@onready var alien_collider = $AlienCollider
@onready var ufo_collider = $UfoCollider

const UFO_SPEED = 150.0
const ALIEN_SPEED = 105.0
const ufo_camera_zoom = 3.0
const alien_camera_zoom = 6.0

var current_state = State.UFO
var game: Node2D
signal ufo_crashed()

@export var ufo_index_sync: int = 0:
	set(value):
		ufo_index_sync = value
		if alien:
			alien.ufo_idx = value

# POPRAWKA 1: Bezpieczne, odroczone przypisywanie autorytetu i grup lokalnych
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
		get_node("PlayerInputSynchronizer").set_multiplayer_authority(value)

	# Synchronizujemy ogólny synchronizator pozycji, jeśli istnieje na scenie
	if has_node("MultiplayerSynchronizer"):
		$MultiplayerSynchronizer.set_multiplayer_authority(value)

	# KLUCZOWA POPRAWKA SIECIOWA: Jeśli to jest nasze sieciowe ID,
	# dopisujemy się lokalnie do grupy ufos, aby skrypt mgły od razu nas widział!
	if value == multiplayer.get_unique_id():
		if not is_in_group("ufos"):
			add_to_group("ufos")


func _ready():
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

	alien.ufo_idx = ufo_index_sync

	if input_multiplayer_authority != 0:
		_deferred_set_network_authority(input_multiplayer_authority)

	if is_multiplayer_authority():
		set_camera(camera, ufo_camera_zoom)

	_update_visibility_for_start()
	collision_layer = 0
	collision_mask = 16


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
		if not is_blocked and is_multiplayer_authority():
			var sync_direction = move(ALIEN_SPEED, player_input_synchronizer)
			move_and_slide()
			alien.animate(sync_direction)


@rpc("any_peer", "call_local", "reliable")
func change_state(new_state: State, ufo_index: int):
	current_state = new_state
	ufo_index_sync = ufo_index

	if new_state == State.UFO:
		# Powrót do grupy ufos, jeśli to konieczne
		if is_in_group("aliens"):
			remove_from_group("aliens")
		if not is_in_group("ufos"):
			add_to_group("ufos")

		ufo.visible = true
		ufo.set_process(true)

		alien.visible = false
		alien.process_mode = PROCESS_MODE_DISABLED
		alien.set_process(false)

		if "coordinates" in alien and alien.coordinates:
			alien.coordinates.visible = false

		ufo_collider.set_deferred("disabled", false)
		alien_collider.set_deferred("disabled", true)
		collision_layer = 0
		collision_mask = 16

	elif new_state == State.ALIEN:
		ufo_crashed.emit()
		role = Player.Role.ALIEN
		alien.role = Player.Role.ALIEN

		# POPRAWKA 1: Podmiana grup węzła, aby skrypt mgły zauważył zmianę tożsamości
		if is_in_group("ufos"):
			remove_from_group("ufos")
		if not is_in_group("aliens"):
			add_to_group("aliens")

		alien.process_mode = PROCESS_MODE_INHERIT
		alien.visible = true
		alien.set_process(true)

		alien.ufo_idx = ufo_index
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

		var tile_map = game.tile_map_layer
		var current_grid_pos: Vector2i = tile_map.local_to_map(global_position)

		if not game.paths.has(current_grid_pos):
			var safe_tile = ufo.find_nearest_path(global_position)
			global_position = tile_map.map_to_local(safe_tile)
		else:
			global_position = tile_map.map_to_local(current_grid_pos)

		get_tree().call_group("skeptics", "_update_visibility_for_local_player")

		# POPRAWKA 2: Bezpieczne czyszczenie zapamiętanej pozycji mgły
		var fog_layer = game.tile_map_layer
		if fog_layer:
			# Czyścimy bufor, żeby mgła została przeliczona na nowo w klatce _process()
			if "last_player_tile" in fog_layer:
				fog_layer.last_player_tile = Vector2i(-999, -999)
			if "ufo_view_setup" in fog_layer:
				fog_layer.ufo_view_setup = false

		if is_multiplayer_authority() and is_instance_valid(camera):
			var camera_tween = create_tween()
			camera_tween.tween_property(
				camera,
				"zoom",
				Vector2(alien_camera_zoom, alien_camera_zoom),
				0.8,
			).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
