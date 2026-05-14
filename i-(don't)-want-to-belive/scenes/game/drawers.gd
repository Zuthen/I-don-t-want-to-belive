extends Node
class_name Drawer
var tile_map_layer:TileMapLayer
var details: TileMapLayer
var city_atlas_source_id: = 2
var details_source_id: = 0

func draw_map(obstacles:Array[Rect2i]):		
	for rect in obstacles:
		if(rect.size.y ==1):
			draw_horizontal_flat_obstacle(rect)
		else:
			draw_obstacle(rect)

func set_city_atlas_cell( position:Vector2i, cell:Vector2i):
	tile_map_layer.set_cell(position, city_atlas_source_id, cell)

func set_building_details_cell( position:Vector2i, cell:Vector2i):
	details.set_cell(position, details_source_id, cell)

func draw_horizontal_flat_obstacle(rectangle: Rect2i):
	if rectangle.size==Vector2i(1,1):
		var random_single = ["fontain", "lawn"]
		var obstacle_type= 	random_single.pick_random()
		if obstacle_type == "fontain":
			var cell = Vector2i(14,8)
			set_city_atlas_cell(rectangle.position, cell)
		elif obstacle_type == "lawn":
			var cell = Vector2i(6,2)
			set_city_atlas_cell(rectangle.position, cell)
	else:
		var random_obstacles = ["fence", "metal sheet"]
		var obstacle_type = random_obstacles.pick_random()
		var left: Vector2i
		var middle: Vector2i
		var right: Vector2i
		
		if obstacle_type == "fence":
			left = Vector2i(4,13)
			middle = Vector2i(5,13)
			right = Vector2i(6,13)
		if obstacle_type == "metal sheet":
			left = Vector2i(4,14)
			middle = Vector2i(5,14)
			right = Vector2i(6,14)
			
		tile_map_layer.set_cell(rectangle.position, city_atlas_source_id,left)
		for i in range(1,rectangle.size.x -1):
			var position = rectangle.position + Vector2i(i,0)
			tile_map_layer.set_cell(position, city_atlas_source_id, middle)
		tile_map_layer.set_cell(rectangle.position + Vector2i(rectangle.size.x -1,0), city_atlas_source_id, right)

func draw_obstacle(rectangle: Rect2i):

	var rows = rectangle.size.y
	var width = rectangle.size.x

	var random_roofs=["yellow","grey"]
	var roof_color = random_roofs.pick_random()
	var roof = Roof.create_by_color(roof_color)
	var facade= Facade.create_by_roof_color(roof_color)
	var water = Water.new()
	if rows ==1:
		if width == 1:
			tile_map_layer.set_cell(rectangle.position, city_atlas_source_id, roof.single)
		else:
			draw_single_row(rectangle,roof.single_row)
	elif rows ==2:
		if width == 1:
			draw_single_column(rectangle,water.thin)
		elif width == 2:
			draw_water_fountain(rectangle, water)
		else:
			draw_single_row( rectangle, water.top)
			draw_single_row( rectangle,water.bottom, 1)
	elif rows == 3:
		if width == 1:
			set_city_atlas_cell(rectangle.position, roof.single)
			draw_single_column(rectangle,facade.thin,1)
		else:
			draw_single_row(rectangle,roof.single_row)
			draw_single_row( rectangle,facade.top, 1)
			var next_window_row = draw_top_windows(rectangle,1,roof_color)
			draw_single_row( rectangle, facade.bottom, 2)
			if roof_color == "yellow" && width==3:
				var awnings = Awnings.new()
				set_building_details_cell(rectangle.position + Vector2i(1,2),awnings.double)
				var placed_door = place_door(rectangle,2,roof_color)
				if placed_door.start_position != Vector2i.ZERO:
					place_windows_on_door_level(rectangle,roof_color,placed_door)
			elif roof_color == "grey" && width>3:
				draw_awnings_row(rectangle,2)
				draw_windows(rectangle,1,roof_color)
	elif rows == 4:
		if width == 1:
			set_city_atlas_cell(rectangle.position, roof.thin.start)
			set_city_atlas_cell(rectangle.position + Vector2i(0,1), roof.thin.end)
			set_city_atlas_cell(rectangle.position + Vector2i(0,2), facade.thin.top)
			
			var placed_door = place_door(rectangle,2,roof_color)
			if placed_door.start_position != Vector2i.ZERO:
					place_windows_on_door_level(rectangle,roof_color,placed_door)
			set_city_atlas_cell(rectangle.position + Vector2i(0,3), facade.thin.bottom)
		else:
			draw_single_row( rectangle,roof.top)
			draw_single_row( rectangle,roof.bottom, 1)
			draw_single_row( rectangle, facade.top, 2)
			draw_single_row( rectangle, facade.bottom,3)
			var placed_door = place_door(rectangle,3, roof_color)
			if placed_door.start_position != Vector2i.ZERO:
					place_windows_on_door_level(rectangle,roof_color,placed_door)
	else:
		if width == 1:
			set_city_atlas_cell(rectangle.position, roof.thin.start)
			set_city_atlas_cell(rectangle.position + Vector2i(0,1), roof.thin.end)
			draw_single_column(rectangle,facade.thin, 2)
		else:
			draw_single_row(rectangle,roof.top)
			draw_single_row(rectangle, roof.bottom, 1)
			draw_single_row(rectangle,facade.top,2)
			var next_window_row = draw_top_windows(rectangle,2,roof_color)
			draw_windows(rectangle, next_window_row,roof_color)
			draw_multiple_rows(rectangle, facade.middle,rectangle.size.y-1, 3)
			draw_single_row(rectangle,facade.bottom, rectangle.size.y-1)
			var placed_door = place_door(rectangle,rectangle.size.y-1, roof_color)
			if placed_door.start_position != Vector2i.ZERO:
					place_windows_on_door_level(rectangle,roof_color,placed_door)

func draw_single_row(rectangle:Rect2i, tiles_row:TilesRow, start: int=0):
	var width = rectangle.size.x
	set_city_atlas_cell(rectangle.position + +Vector2i(0,start), tiles_row.start)
	for i in range(1, width -1):
		set_city_atlas_cell(rectangle.position + Vector2i(i,start), tiles_row.middle)
	set_city_atlas_cell(rectangle.position+Vector2i(width-1,start),tiles_row.end)

func draw_awnings_row( rectangle:Rect2i, start: int=0):
	var width = rectangle.size.x
	var sprite_width = 3
	var max_x = width - sprite_width
	var random_position = Vector2i(randi_range(0,max_x), start)
	var awnings = Awnings.new()
	
	set_building_details_cell(rectangle.position + random_position, awnings.long.start )
	set_building_details_cell(rectangle.position + random_position+ Vector2i(1,0), awnings.long.middle)
	set_building_details_cell(rectangle.position + random_position+ Vector2i(2,0),awnings.long.end)

func draw_single_column(rectangle, tiles, start:int = 0):
	set_city_atlas_cell(rectangle.position +Vector2i(0,start), tiles.top)
	for i in range(1,rectangle.size.y-start -1):
		if tiles is TilesColumn:
			set_city_atlas_cell(rectangle.position + Vector2i(0,start +i), tiles.middle.pick_random())
		elif tiles is TilesRow:
			set_city_atlas_cell(rectangle.position + Vector2i(0,start+i), tiles.middle)
	set_city_atlas_cell(rectangle.position +Vector2i(0, rectangle.size.y-1), tiles.bottom)

func draw_multiple_rows(rectangle: Rect2i, tiles_row: TilesRow, end: int, start:int = 1):
	var width = rectangle.size.x
	for y in range(start,end):
		set_city_atlas_cell(rectangle.position + Vector2i(0,y),  tiles_row.start)
		for x in range(1,width-1):
			set_city_atlas_cell(rectangle.position + Vector2i(x,y),  tiles_row.middle)
		set_city_atlas_cell(rectangle.position +Vector2i(width-1,y),  tiles_row.end)
		
func draw_water_fountain(rectangle:Rect2i, water):
	set_city_atlas_cell(rectangle.position,water.circle.top_left)
	set_city_atlas_cell(rectangle.position +Vector2i(1,0), water.circle.top_right)
	set_city_atlas_cell(rectangle.position + Vector2i(0,1), water.circle.bottom_left)
	set_city_atlas_cell(rectangle.position + Vector2i(1,1), water.circle.bottom_right)
	

func draw_top_windows(rectangle, row, color) -> int:
	var window = BuildingWindow.create_by_roof_color(color)
	var width = rectangle.size.x
	for i in range(1, width, 2):
		set_building_details_cell(rectangle.position + Vector2i(i,row),window.top.top_sprite)
		set_building_details_cell(rectangle.position + Vector2i(i,row +1),window.top.bottom_sprite)
	return row+2

func draw_windows(rectangle, row, color):
	var window = BuildingWindow.create_by_roof_color(color)
	var width = rectangle.size.x

	var sprite = window.middle.pick_random()
	var start_y = row
	var max_y = rectangle.size.y - 2
	for y in range(start_y, max_y+1, 2):
		for x in range(1, width,2):
			set_building_details_cell(
				rectangle.position + Vector2i(x, y),
				sprite
			)

func place_door(rectangle, row, color) -> Door.PlacedDoor:
	var width = rectangle.size.x
	var door_width = 0
	var random_position_last = -2
	if color == "yellow" && width >1 :
		var door = Door.create()
		random_position_last = randi() %width
		if width == 2:
			var possible_x = [0, 1]
			var start_x = possible_x.pick_random()
			var sprite = door.single.pick_random()
			set_building_details_cell(
				rectangle.position + Vector2i(start_x, row),
				sprite
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
				sprites.left_sprite
			)
			set_building_details_cell(
				rectangle.position + Vector2i(start_x + 1, row),
				sprites.right_sprite
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
				sprites.left_sprite
			)
			set_building_details_cell(
				rectangle.position + Vector2i(start_x + 1, row),
				sprites.middle_sprite
			)
			set_building_details_cell(
				rectangle.position + Vector2i(start_x + 2, row),
				sprites.right_sprite
			)
			return Door.PlacedDoor.new(Vector2i(start_x, row), 3)
	return Door.PlacedDoor.new(Vector2i.ZERO, door_width)
	
	
func place_windows_on_door_level(rectangle, color, placed_door):
	var width = rectangle.size.x
	var blocked_positions = []

	for i in range(placed_door.length):
		blocked_positions.append(
			placed_door.start_position.x + i)
	var window = BuildingWindow.create_by_roof_color(color).bottom

	for x in range(1, width, 2):
		if blocked_positions.has(x):
			continue
		set_building_details_cell(rectangle.position + Vector2i(x, rectangle.size.y-1),window)

func draw_pavement(paths):
	var pavement: Pavement = Pavement.new()
	var rows_range := split_to_rows(paths)
	#pierwszy kafelek:
	var first_path_position = paths[0]
	draw_first_pavement(first_path_position,rows_range, pavement)
	
	
	#for path in paths:
		#set_city_atlas_cell(path,pavement.wide.middle)

func draw_first_pavement(position: Vector2i, rows_range:RowsRange, pavement: Pavement):
	var neighbors = get_neighbors(position, rows_range)
	var wide = neighbors.right && neighbors.bottom && neighbors.diagonal
	if wide:
		set_city_atlas_cell(position, pavement.wide.corners.top_left)
	elif neighbors.right && neighbors.bottom:
		set_city_atlas_cell(position, pavement.thin.corners.top_left)
	elif neighbors.right:
		set_city_atlas_cell(position, pavement.thin.path_ends.left)
	elif neighbors.bottom:
		set_city_atlas_cell(position, pavement.thin.path_ends.top)
		# zrwacamy wide i sąsiadów (chyba)
class RowsRange:
	var rows: Array
	var min: int
	var max: int
	
	func _init(rows, min, max):
		self.rows = rows
		self.min= min
		self.max=max

		
func split_to_rows(paths: Array[Vector2i]) -> RowsRange:
	var y = paths.map(func(path): return path.y)
	var min_y = y.min()
	var max_y = y.max()
	var rows= []
	for i in range (min_y, max_y):
		var row: Array[Vector2i] = []
		row.append_array(paths.filter(func(vector: Vector2i): return vector.y == i))
		rows.append(row)
	var rows_range :=  RowsRange.new(rows, min_y, max_y)
	return rows_range

class Neighbors:
	var right: bool = false
	var bottom: bool = false
	var diagonal: bool = false

func get_neighbors(place: Vector2i, rows_range: RowsRange) -> Neighbors:
	var neighbors: Neighbors = Neighbors.new()
	var x = place.x
	var y = place.y
	
	var row_index = y - rows_range.min
	var row = rows_range.rows[row_index]
	
	var right_neighbor = Vector2i(x+1, y)
	if row.has(right_neighbor):
		neighbors.right = true
		
	if row_index + 1 < rows_range.rows.size():
		var next_row = rows_range.rows[row_index+1]
		var bottom_neighbor = Vector2i(x, y+1)
		if next_row.has(bottom_neighbor):
			neighbors.bottom = true
		var diagonal_neighbor = Vector2i(x+1, y+1)
		if next_row.has(diagonal_neighbor):
			neighbors.diagonal = true
	return neighbors
