extends TileMapLayer

@export var buildings_layer: TileMapLayer
@export var vision_radius: int = 1

var black_tile_coords: Vector2i = Vector2i(9, 1)

const ATLAS_SOURCE_ID: int = 2

const TILE_DEEP_NIGHT = 3
const TILE_HALF_SHADOW = 7
const TILE_NEAR_LIGHT = 8

var last_player_tile := Vector2i(-999, -999)


func _ready():
	if not buildings_layer:
		push_error("Set buildings layer")
		return

	await get_tree().process_frame
	initialize_fog()


func initialize_fog():
	var cells_pck: Array[Vector2i] = []

	for x in range(MapSettings.min_position.x - 15, MapSettings.max_position.x + 15):
		for y in range(MapSettings.min_position.y - 15, MapSettings.max_position.y + 15):
			cells_pck.append(Vector2i(x, y))

	for cell in cells_pck:
		set_cell(cell, ATLAS_SOURCE_ID, black_tile_coords, TILE_DEEP_NIGHT)


func _process(_delta):
	var local_player = get_local_player()
	if not local_player:
		return

	# 1. LOGIKA DLA UFO
	if local_player.is_in_group("ufos") and not local_player.is_in_group("aliens"):
		if last_player_tile == Vector2i(-999, -999):
			last_player_tile = Vector2i(0, 0)
			setup_ufo_view()
		update_players_visibility(local_player)
		return

	# 2. LOGIKA DLA RAS NAZIEMNYCH (Skeptic / Alien)
	if last_player_tile == Vector2i(0, 0) or (last_player_tile == Vector2i(-999, -999) and (local_player.is_in_group("aliens") or local_player.is_in_group("skeptics"))):
		last_player_tile = buildings_layer.local_to_map(local_player.global_position)
		initialize_fog()
		apply_new_fog(last_player_tile)

	var current_tile = buildings_layer.local_to_map(local_player.global_position)

	if current_tile != last_player_tile:
		if last_player_tile != Vector2i(-999, -999):
			reset_old_fog(last_player_tile)

		last_player_tile = current_tile
		apply_new_fog(current_tile)

	# Uruchamiamy filtrowanie widoczności graczy w każdej klatce
	update_players_visibility(local_player)


func update_players_visibility(local_player: Node2D):
	var my_network_id = multiplayer.get_unique_id()

	# A. Reguła dla ekranu UFO: widzi tylko inne UFO, ukrywa ludzi i obcych na ziemi
	if local_player.is_in_group("ufos") and not local_player.is_in_group("aliens"):
		var ground_players = get_tree().get_nodes_in_group("skeptics") + get_tree().get_nodes_in_group("aliens")
		for player in ground_players:
			player.visible = false

		var ufo_players = get_tree().get_nodes_in_group("ufos")
		for ufo in ufo_players:
			ufo.visible = true
		return

	# B. Reguła dla ekranu naziemnego (Skeptic / Alien): wzajemna widoczność tylko w polu widzenia
	var all_ground_players = get_tree().get_nodes_in_group("skeptics") + get_tree().get_nodes_in_group("aliens")
	var local_tile = buildings_layer.local_to_map(local_player.global_position)

	for player in all_ground_players:
		# Pancerne sprawdzenie autorytetu: Siebie samego na swoim ekranie zawsze muszę widzieć
		if player.get_multiplayer_authority() == my_network_id:
			player.visible = true
			continue

		# Pobieramy pozycję kafelka przeciwnika i liczymy czysty dystans kafelkowy
		var player_tile = buildings_layer.local_to_map(player.global_position)
		var distance_in_tiles = local_tile.distance_to(player_tile)

		# Dodatkowo sprawdzamy stan kafelka bezpośrednio pod przeciwnikiem na naszym lokalnym ekranie
		var fog_tile_alternative = get_cell_alternative_tile(player_tile)

		# REGUŁA: Jeśli wróg nie stoi w głębokim mroku ORAZ jest matematycznie w promieniu wzroku -> ujawnij go
		if fog_tile_alternative != TILE_DEEP_NIGHT and distance_in_tiles <= vision_radius:
			player.visible = true
		else:
			player.visible = false


func setup_ufo_view():
	var cells_pck: Array[Vector2i] = []

	for x in range(MapSettings.min_position.x - 15, MapSettings.max_position.x + 15):
		for y in range(MapSettings.min_position.y - 15, MapSettings.max_position.y + 15):
			cells_pck.append(Vector2i(x, y))

	for cell in cells_pck:
		set_cell(cell, ATLAS_SOURCE_ID, black_tile_coords, TILE_HALF_SHADOW)


func reset_old_fog(center_tile: Vector2i):
	for x in range(-vision_radius, vision_radius + 1):
		for y in range(-vision_radius, vision_radius + 1):
			var target_tile = center_tile + Vector2i(x, y)

			if vision_radius == 1 or center_tile.distance_to(target_tile) <= vision_radius:
				set_cell(target_tile, ATLAS_SOURCE_ID, black_tile_coords, TILE_DEEP_NIGHT)


func apply_new_fog(center_tile: Vector2i):
	for x in range(-vision_radius, vision_radius + 1):
		for y in range(-vision_radius, vision_radius + 1):
			var target_tile = center_tile + Vector2i(x, y)

			if vision_radius == 1 or center_tile.distance_to(target_tile) <= vision_radius:
				set_cell(target_tile, ATLAS_SOURCE_ID, black_tile_coords, TILE_NEAR_LIGHT)


func get_local_player() -> Node2D:
	var my_id = multiplayer.get_unique_id()
	var all_nodes = get_tree().get_nodes_in_group("skeptics") + get_tree().get_nodes_in_group("ufos") + get_tree().get_nodes_in_group("aliens")

	for node in all_nodes:
		# Szukamy po ID autorytetu sieciowego maszyny, radzi sobie z kontenerami rodzic-dziecko
		if node.get_multiplayer_authority() == my_id:
			return node
		if node.get_parent() and node.get_parent().get_multiplayer_authority() == my_id:
			return node.get_parent() as Node2D

	return null
