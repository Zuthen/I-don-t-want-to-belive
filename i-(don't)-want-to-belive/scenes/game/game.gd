extends Node2D

#@onready var camera = $Camera2D
@onready var tile_map_layer = $BuildingsAndPaths
@onready var buildings_details = $BuildingsDetails
var player_scene: PackedScene = preload("uid://b7wo2a5407873")
var min_position:= Vector2i(0, -10)
var max_position:= Vector2i(19, 9)
var random_generator: RandomNumberGenerator = RandomNumberGenerator.new()
var city_atlas_pavement_coords: = Vector2i(9,1)
var city_atlas_obstacles_coords = Vector2i(22,8)
var paths: Array[Vector2i]=[]
var obstacles

func _ready():
	Drawers.tile_map_layer = tile_map_layer
	Drawers.details = buildings_details
	#fit_map()
	var generated_paths = genereate_map()
	var areas = MapCreator.find_areas(generated_paths)
	var obstacle_regions = MapCreator.find_regions(areas.obstacles)
	var obstacle_rects:Array[Rect2i]= []
	var map_borders_obstacle_rects:= MapCreator.create_left_borders(Rect2i(Vector2i(-1,-10),Vector2i(8,19)))
	for region in obstacle_regions:
		var rects = MapCreator.regions_to_rects(region)
		obstacle_rects.append_array(MapCreator.merge_small_rectangles(rects))
#var min_position:= Vector2i(0, -10)
#var max_position:= Vector2i(19, 9)
	var valid_spawns = []

	for pos in areas.paths:
		if not is_inside_obstacle(pos, obstacle_rects):
			valid_spawns.append(pos)

	var spawn_position = valid_spawns.pick_random()
	Drawers.draw_map(obstacle_rects)
	#Drawers.draw_map(map_borders_obstacle_rects)
	
	spawn_player(spawn_position)
	

func genereate_map():
	var start: Vector2i = Vector2i(random_generator.randi_range(0, 19), random_generator.randi_range(-10,9))
	var next:Array[Vector2i] = find_next_path(start,Vector2i.ZERO)

	for i in range(100):
		var way = find_next_path(next[0], next[1])
		next=way
	return paths
			
	
func occupy_rect(rect: Rect2i, occupied: Dictionary):
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			occupied[Vector2i(x, y)] = true
			
	

func directions(step: int) -> Dictionary:
	return{
		"up": Vector2i(0, -step),
		"down": Vector2i(0, step),
		"left": Vector2i(-step, 0),
		"right":Vector2i(step, 0)
	}
	
func spawn_player(spawn_position: Vector2i):
	var player = player_scene.instantiate()
	player.position =  tile_map_layer.map_to_local(spawn_position)
	add_child(player)
	
func find_next_path(position: Vector2i, previous:Vector2i)-> Array[Vector2i]:
	var valid_dirs: Dictionary[String,Vector2i] = {}
	var valid_ways: Dictionary[String,Vector2i] = {}
	var destinations = directions(2)
	var ways_to_destinations = directions(1)

	for key in destinations:
		var dest_vec = destinations[key]

		if not ways_to_destinations.has(key):
			continue

		var way_vec = ways_to_destinations[key]
		var next = position + dest_vec
		if next == previous:
			continue
		if paths.has(next):
			continue
		if next.x < min_position.x or next.x > max_position.x:
			continue
		if next.y < min_position.y or next.y > max_position.y:
			continue

		valid_dirs[key] = dest_vec
		valid_ways[key] = way_vec
	if valid_dirs.is_empty():
		var new_path = paths.pick_random()
		return find_next_path(new_path, previous)
	
	var key = valid_dirs.keys().pick_random()
	var next = position + valid_dirs[key]
	var next_2 = position + valid_ways[key]
	paths.append_array([next, next_2])
	return [position + valid_dirs[key], position + valid_ways[key]]

func is_inside_obstacle(pos: Vector2i, rects: Array[Rect2i]) -> bool:
	for rect in rects:
		if rect.has_point(pos):
			return true
	return false
	
#func fit_map():
	#var size = Vector2(860, 860)
	#var screen = get_viewport_rect().size
	#camera.zoom = screen / size
