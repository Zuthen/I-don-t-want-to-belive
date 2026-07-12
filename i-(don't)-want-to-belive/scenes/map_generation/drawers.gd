extends Node

class_name Drawer
var city_atlas_source_id: = 2
var details_source_id: = 0


func draw(map_layer: TileMapLayer, details_layer: TileMapLayer, obstacles: Array[Rect2i], paths: Array[Vector2i]):
	draw_map(obstacles, map_layer, details_layer)
	draw_pavement(paths, map_layer)


func draw_map(obstacles: Array[Rect2i], map_layer: TileMapLayer, details: TileMapLayer):
	for rect in obstacles:
		if (rect.size.y == 1):
			draw_horizontal_flat_obstacle(rect, map_layer)
		else:
			draw_obstacle(rect, map_layer, details)


func set_city_atlas_cell(position: Vector2i, cell: Vector2i, map_layer: TileMapLayer):
	map_layer.set_cell(position, city_atlas_source_id, cell)


func set_building_details_cell(position: Vector2i, cell: Vector2i, details: TileMapLayer):
	details.set_cell(position, details_source_id, cell)


func draw_horizontal_flat_obstacle(rectangle: Rect2i, map_layer: TileMapLayer):
	if rectangle.size == Vector2i(1, 1):
		var random_single = ["fontain", "lawn"]
		var obstacle_type = random_single.pick_random()
		if obstacle_type == "fontain":
			var cell = Vector2i(14, 8)
			set_city_atlas_cell(rectangle.position, cell, map_layer)
		elif obstacle_type == "lawn":
			var cell = Vector2i(6, 2)
			set_city_atlas_cell(rectangle.position, cell, map_layer)
	else:
		var random_obstacles = ["fence", "metal sheet"]
		var obstacle_type = random_obstacles.pick_random()
		var left: Vector2i
		var middle: Vector2i
		var right: Vector2i

		if obstacle_type == "fence":
			left = Vector2i(4, 13)
			middle = Vector2i(5, 13)
			right = Vector2i(6, 13)
		if obstacle_type == "metal sheet":
			left = Vector2i(4, 14)
			middle = Vector2i(5, 14)
			right = Vector2i(6, 14)

		map_layer.set_cell(rectangle.position, city_atlas_source_id, left)
		for i in range(1, rectangle.size.x - 1):
			var position = rectangle.position + Vector2i(i, 0)
			map_layer.set_cell(position, city_atlas_source_id, middle)
		map_layer.set_cell(rectangle.position + Vector2i(rectangle.size.x - 1, 0), city_atlas_source_id, right)


func draw_obstacle(rectangle: Rect2i, map_layer: TileMapLayer, details: TileMapLayer):
	var rows = rectangle.size.y
	var width = rectangle.size.x

	var random_roofs = ["yellow", "grey"]
	var roof_color = random_roofs.pick_random()
	var roof = Roof.create_by_color(roof_color)
	var facade = Facade.create_by_roof_color(roof_color)
	var water = Water.new()
	if rows == 1:
		if width == 1:
			map_layer.set_cell(rectangle.position, city_atlas_source_id, roof.single)
		else:
			draw_single_row(rectangle, roof.single_row, map_layer)
	elif rows == 2:
		if width == 1:
			draw_single_column(rectangle, water.thin, map_layer)
		elif width == 2:
			draw_water_fountain(rectangle, water, map_layer)
		else:
			draw_single_row(rectangle, water.top, map_layer)
			draw_single_row(rectangle, water.bottom, map_layer, 1)
	elif rows == 3:
		if width == 1:
			set_city_atlas_cell(rectangle.position, roof.single, map_layer)
			draw_single_column(rectangle, facade.thin, map_layer, 1)
		else:
			draw_single_row(rectangle, roof.single_row, map_layer)
			draw_single_row(rectangle, facade.top, map_layer, 1)
			draw_top_windows(rectangle, 1, roof_color, details)
			draw_single_row(rectangle, facade.bottom, map_layer, 2)
			if roof_color == "yellow" && width == 3:
				var awnings = Awnings.new()
				set_building_details_cell(rectangle.position + Vector2i(1, 2), awnings.double, details)
				var placed_door = place_door(rectangle, 2, roof_color, details)
				if placed_door.start_position != Vector2i.ZERO:
					place_windows_on_door_level(rectangle, roof_color, placed_door, details)
			elif roof_color == "grey" && width > 3:
				draw_awnings_row(rectangle, details, 2)
				draw_windows(rectangle, 1, roof_color, details)
	elif rows == 4:
		if width == 1:
			set_city_atlas_cell(rectangle.position, roof.thin.start, map_layer)
			set_city_atlas_cell(rectangle.position + Vector2i(0, 1), roof.thin.end, map_layer)
			set_city_atlas_cell(rectangle.position + Vector2i(0, 2), facade.thin.top, map_layer)

			var placed_door = place_door(rectangle, 2, roof_color, details)
			if placed_door.start_position != Vector2i.ZERO:
				place_windows_on_door_level(rectangle, roof_color, placed_door, details)
			set_city_atlas_cell(rectangle.position + Vector2i(0, 3), facade.thin.bottom, map_layer)
		else:
			draw_single_row(rectangle, roof.top, map_layer)
			draw_single_row(rectangle, roof.bottom, map_layer, 1)
			draw_single_row(rectangle, facade.top, map_layer, 2)
			draw_single_row(rectangle, facade.bottom, map_layer, 3)
			var placed_door = place_door(rectangle, 3, roof_color, details)
			if placed_door.start_position != Vector2i.ZERO:
				place_windows_on_door_level(rectangle, roof_color, placed_door, details)
	else:
		if width == 1:
			set_city_atlas_cell(rectangle.position, roof.thin.start, map_layer)
			set_city_atlas_cell(rectangle.position + Vector2i(0, 1), roof.thin.end, map_layer)
			draw_single_column(rectangle, facade.thin, map_layer, 2)
		else:
			draw_single_row(rectangle, roof.top, map_layer)
			draw_single_row(rectangle, roof.bottom, map_layer, 1)
			draw_single_row(rectangle, facade.top, map_layer, 2)
			var next_window_row = draw_top_windows(rectangle, 2, roof_color, details)
			draw_windows(rectangle, next_window_row, roof_color, details)
			draw_multiple_rows(rectangle, facade.middle, rectangle.size.y - 1, map_layer, 3)
			draw_single_row(rectangle, facade.bottom, map_layer, rectangle.size.y - 1)
			var placed_door = place_door(rectangle, rectangle.size.y - 1, roof_color, details)
			if placed_door.start_position != Vector2i.ZERO:
				place_windows_on_door_level(rectangle, roof_color, placed_door, details)


func draw_single_row(rectangle: Rect2i, tiles_row: TilesRow, map_layer: TileMapLayer, start: int = 0):
	var width = rectangle.size.x
	set_city_atlas_cell(rectangle.position + +Vector2i(0, start), tiles_row.start, map_layer)
	for i in range(1, width - 1):
		set_city_atlas_cell(rectangle.position + Vector2i(i, start), tiles_row.middle, map_layer)
	set_city_atlas_cell(rectangle.position + Vector2i(width - 1, start), tiles_row.end, map_layer)


func draw_awnings_row(rectangle: Rect2i, details: TileMapLayer, start: int = 0):
	var width = rectangle.size.x
	var sprite_width = 3
	var max_x = width - sprite_width
	var random_position = Vector2i(randi_range(0, max_x), start)
	var awnings = Awnings.new()

	set_building_details_cell(rectangle.position + random_position, awnings.long.start, details)
	set_building_details_cell(rectangle.position + random_position + Vector2i(1, 0), awnings.long.middle, details)
	set_building_details_cell(rectangle.position + random_position + Vector2i(2, 0), awnings.long.end, details)


func draw_single_column(rectangle, tiles, map_layer: TileMapLayer, start: int = 0):
	set_city_atlas_cell(rectangle.position + Vector2i(0, start), tiles.top, map_layer)
	for i in range(1, rectangle.size.y - start - 1):
		if tiles is TilesColumn:
			set_city_atlas_cell(rectangle.position + Vector2i(0, start + i), tiles.middle.pick_random(), map_layer)
		elif tiles is TilesRow:
			set_city_atlas_cell(rectangle.position + Vector2i(0, start + i), tiles.middle, map_layer)
	set_city_atlas_cell(rectangle.position + Vector2i(0, rectangle.size.y - 1), tiles.bottom, map_layer)


func draw_multiple_rows(rectangle: Rect2i, tiles_row: TilesRow, end: int, map_layer: TileMapLayer, start: int = 1):
	var width = rectangle.size.x
	for y in range(start, end):
		set_city_atlas_cell(rectangle.position + Vector2i(0, y), tiles_row.start, map_layer)
		for x in range(1, width - 1):
			set_city_atlas_cell(rectangle.position + Vector2i(x, y), tiles_row.middle, map_layer)
		set_city_atlas_cell(rectangle.position + Vector2i(width - 1, y), tiles_row.end, map_layer)


func draw_water_fountain(rectangle: Rect2i, water, map_layer: TileMapLayer):
	set_city_atlas_cell(rectangle.position, water.circle.top_left, map_layer)
	set_city_atlas_cell(rectangle.position + Vector2i(1, 0), water.circle.top_right, map_layer)
	set_city_atlas_cell(rectangle.position + Vector2i(0, 1), water.circle.bottom_left, map_layer)
	set_city_atlas_cell(rectangle.position + Vector2i(1, 1), water.circle.bottom_right, map_layer)


func draw_top_windows(rectangle, row, color, details: TileMapLayer) -> int:
	var window = BuildingWindow.create_by_roof_color(color)
	var width = rectangle.size.x
	for i in range(1, width, 2):
		set_building_details_cell(rectangle.position + Vector2i(i, row), window.top.top_sprite, details)
		set_building_details_cell(rectangle.position + Vector2i(i, row + 1), window.top.bottom_sprite, details)
	return row + 2


func draw_windows(rectangle, row, color, details: TileMapLayer):
	var window = BuildingWindow.create_by_roof_color(color)
	var width = rectangle.size.x

	var sprite = window.middle.pick_random()
	var start_y = row
	var max_y = rectangle.size.y - 2
	for y in range(start_y, max_y + 1, 2):
		for x in range(1, width, 2):
			set_building_details_cell(
				rectangle.position + Vector2i(x, y),
				sprite,
				details,
			)


func place_door(rectangle, row, color, details: TileMapLayer) -> Door.PlacedDoor:
	var width = rectangle.size.x
	var door_width = 0
	if color == "yellow" && width > 1:
		var door = Door.create()
		if width == 2:
			var possible_x = [0, 1]
			var start_x = possible_x.pick_random()
			var sprite = door.single.pick_random()
			set_building_details_cell(
				rectangle.position + Vector2i(start_x, row),
				sprite,
				details,
			)
			return Door.PlacedDoor.new(Vector2i(start_x, row), 1)
		elif width < 5:
			var possible_x = []
			for x in range(0, width - 1, 2):
				possible_x.append(x)
			var start_x = possible_x.pick_random()
			var sprites = door.double.pick_random()
			set_building_details_cell(
				rectangle.position + Vector2i(start_x, row),
				sprites.left_sprite,
				details,
			)
			set_building_details_cell(
				rectangle.position + Vector2i(start_x + 1, row),
				sprites.right_sprite,
				details,
			)
			return Door.PlacedDoor.new(Vector2i(start_x, row), 2)
		elif width >= 5:
			var possible_x = []
			for x in range(0, width - 2, 2):
				possible_x.append(x)
			var start_x = possible_x.pick_random()
			var sprites = door.triple.pick_random()
			set_building_details_cell(
				rectangle.position + Vector2i(start_x, row),
				sprites.left_sprite,
				details,
			)
			set_building_details_cell(
				rectangle.position + Vector2i(start_x + 1, row),
				sprites.middle_sprite,
				details,
			)
			set_building_details_cell(
				rectangle.position + Vector2i(start_x + 2, row),
				sprites.right_sprite,
				details,
			)
			return Door.PlacedDoor.new(Vector2i(start_x, row), 3)
	return Door.PlacedDoor.new(Vector2i.ZERO, door_width)


func place_windows_on_door_level(rectangle, color, placed_door, details: TileMapLayer):
	var width = rectangle.size.x
	var blocked_positions = []

	for i in range(placed_door.length):
		blocked_positions.append(
			placed_door.start_position.x + i,
		)
	var window = BuildingWindow.create_by_roof_color(color).bottom

	for x in range(1, width, 2):
		if blocked_positions.has(x):
			continue
		set_building_details_cell(rectangle.position + Vector2i(x, rectangle.size.y - 1), window, details)


func draw_pavement(paths, map_layer: TileMapLayer):
	for tile in paths:
		var borders = Pavement.get_neighbors(tile, paths)
		var pavement_tile = Pavement.get_tile(borders)
		set_city_atlas_cell(tile, pavement_tile, map_layer)
