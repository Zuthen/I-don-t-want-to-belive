extends Node

class_name MapGenerator

var random: RandomNumberGenerator
var paths: Array[Vector2i] = []
var map_layer: TileMapLayer
var region_math: RegionMath

var _generated_building_rects: Array[Rect2i] = []


func _init():
	region_math = RegionMath.new()


class DrawData:
	var paths: Array[Vector2i]
	var obstacle_rects: Array[Rect2i]


	func _init(p: Array[Vector2i], o: Array[Rect2i]):
		paths = p
		obstacle_rects = o


func set_tile_map_layer(new_map_layer: TileMapLayer):
	map_layer = new_map_layer


func create_map(paths_data: Array[Vector2i]) -> DrawData:
	var obstacle_rects: Array[Rect2i] = []
	for rect in _generated_building_rects:
		obstacle_rects.append(rect)
	return DrawData.new(paths_data, obstacle_rects)


func generate_map(map_seed: int = 0) -> Array[Vector2i]:
	random = RandomNumberGenerator.new()
	random.seed = map_seed
	paths.clear()
	_generated_building_rects.clear()

	var min_x = MapSettings.min_position.x
	var max_x = MapSettings.max_position.x
	var min_y = MapSettings.min_position.y
	var max_y = MapSettings.max_position.y

	# Parametry z menu
	var sector_max = GameManager.map_tiles_size
	var target_paths_count = GameManager.map_paths_tiles

	# KROK 1: Wypełniamy całą mapę ścieżkami na start
	var grid_tiles := { }
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			grid_tiles[Vector2i(x, y)] = "path"

	var current_paths_count = grid_tiles.size()
	var safety_counter = 0
	var max_iterations = 5000

	# KROK 2: Upychamy budynki dopóki nie osiągniemy celu z suwaka
	while current_paths_count > target_paths_count and safety_counter < max_iterations:
		safety_counter += 1

		# POPRAWKA: Wywołujemy poprawną, ultraszybką funkcję skanującą luki
		var largest_empty_rect = _find_fast_empty_rect(min_x, max_x, min_y, max_y, grid_tiles)

		# Jeśli wolna przestrzeń skurczyła się do zera, kończymy
		if largest_empty_rect.size.x < 1 or largest_empty_rect.size.y < 1:
			break

		# GWARANCJA GĘSTOŚCI: Rezerwujemy dokładnie 1 kafelek drogi na dole i po prawej
		var reserve_right = 1 if largest_empty_rect.end.x <= max_x else 0
		var reserve_bottom = 1 if largest_empty_rect.end.y <= max_y else 0

		# Realna przestrzeń na budynek po odliczeniu korytarza drogi
		var available_w = largest_empty_rect.size.x - reserve_right
		var available_h = largest_empty_rect.size.y - reserve_bottom

		if available_w < 1 or available_h < 1:
			grid_tiles[largest_empty_rect.position] = "road_reserved"
			continue

		# Rozmiar budynku (nie większy niż sektor i nie większy niż dostępna luka)
		var max_w = min(sector_max, available_w)
		var max_h = min(sector_max, available_h)

		# LIKWIDACJA PUSTYCH PLACÓW:
		# Zmuszamy budynek do zajęcia co najmniej 70% wyznaczonego obszaru,
		# co drastycznie ściska ulice i eliminuje puste, otwarte rynki.
		var min_w = max(1, int(max_w * 0.70))
		var min_h = max(1, int(max_h * 0.70))

		# Losujemy w pełni asymetryczne wymiary w ciasnym, gęstym przedziale
		var b_w = random.randi_range(min_w, max_w)
		var b_h = random.randi_range(min_h, max_h)

		# Stawiamy budynek w rogu wolnej luki
		var b_x = largest_empty_rect.position.x
		var b_y = largest_empty_rect.position.y

		# Minimalne losowe przesunięcie (maksymalnie o 1 kafelek), jeśli jest spory luz
		if available_w - b_w > 2:
			b_x += random.randi_range(0, 1)
		if available_h - b_h > 2:
			b_y += random.randi_range(0, 1)

		# Budujemy!
		var new_building = Rect2i(b_x, b_y, b_w, b_h)
		_generated_building_rects.append(new_building)

		# Wypalamy budynek na mapie i aktualizujemy licznik dróg
		for y in range(new_building.position.y, new_building.end.y):
			for x in range(new_building.position.x, new_building.end.x):
				var tile = Vector2i(x, y)
				if grid_tiles.get(tile) == "path" or grid_tiles.get(tile) == "road_reserved":
					grid_tiles[tile] = "building"
					current_paths_count -= 1

	# KROK 3: Wszystko, co ocalało, to idealna, gęsta sieć korytarzy (paths)
	for tile in grid_tiles:
		if grid_tiles[tile] == "path" or grid_tiles[tile] == "road_reserved":
			paths.append(tile)

	return paths


func _find_fast_empty_rect(min_x: int, max_x: int, min_y: int, max_y: int, grid: Dictionary) -> Rect2i:
	var best_rect = Rect2i(0, 0, 0, 0)
	var max_area = 0

	# ZMIANA: Zwiększamy liczbę prób (np. do 250).
	# To zmusi algorytm do precyzyjnego przeczesania mapy i zapełnienia ostatnich wolnych placów!
	var sample_attempts = 250

	for attempt in range(sample_attempts):
		var sx = random.randi_range(min_x, max_x)
		var sy = random.randi_range(min_y, max_y)
		var start_tile = Vector2i(sx, sy)

		if grid.get(start_tile) != "path":
			continue

		var width = 0
		while sx + width <= max_x and grid.get(Vector2i(sx + width, sy)) == "path":
			width += 1

		var height = 0
		var can_expand = true
		while sy + height <= max_y and can_expand:
			for x in range(width):
				if grid.get(Vector2i(sx + x, sy + height)) != "path":
					can_expand = false
					break
			if can_expand:
				height += 1

		var area = width * height
		if area > max_area:
			max_area = area
			best_rect = Rect2i(sx, sy, width, height)

	return best_rect


func generate_map_borders():
	var edges = MapSettings.get_map_limits()
	var map_width_px = edges.right - edges.left - 1
	var map_height_px = edges.bottom - edges.top - 1
	var wall_thickness = 64.0
	var left_right_size = Vector2(wall_thickness, map_height_px)
	var top_bottom_size = Vector2(map_width_px, wall_thickness)

	var left_position = Vector2(edges.left - (wall_thickness / 2.0), edges.top + (map_height_px / 2.0))
	var right_position = Vector2(edges.right + (wall_thickness / 2.0), edges.top + (map_height_px / 2.0))
	var top_position = Vector2(edges.left + (map_width_px / 2.0), edges.top - (wall_thickness / 2.0))
	var bottom_position = Vector2(edges.left + (map_width_px / 2.0), edges.bottom + (wall_thickness / 2.0))

	_generate_collider(left_right_size, left_position)
	_generate_collider(left_right_size, right_position)
	_generate_collider(top_bottom_size, top_position)
	_generate_collider(top_bottom_size, bottom_position)


func _generate_collider(size: Vector2, position: Vector2):
	var collider_shape = RectangleShape2D.new()
	collider_shape.size = size

	var border = StaticBody2D.new()
	border.position = position
	border.set_collision_layer_value(5, true)
	border.set_collision_layer_value(6, true)

	var border_collider = CollisionShape2D.new()
	border_collider.shape = collider_shape

	border.add_child(border_collider)
	map_layer.add_child(border)
