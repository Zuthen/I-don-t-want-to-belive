extends Node2D

@onready var bushes = $Bushes
@onready var camera = $Camera2D

var bush : PackedScene = preload("uid://bstnhs77ge8vn")
var random_generator: RandomNumberGenerator = RandomNumberGenerator.new()
var paths: Array[Vector2i]=[]
func _ready():
	genereate_map()
	fit_map()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func genereate_map():
	var start: Vector2i = Vector2i(random_generator.randi_range(0, 19), random_generator.randi_range(-10,9))
	create_bush(start)
	var next:Array[Vector2i] = find_next_path(start,Vector2i.ZERO)
	create_bushes(next)
	
	for i in range(110):
		var way = find_next_path(next[0], next[1])
		create_bushes(way)
		next=way

func create_bush(position: Vector2i):
	var new_bush = bush.instantiate()
	new_bush.position = bushes.map_to_local(position)
	bushes.add_child(new_bush)
	paths.push_back(position)

func create_bushes(positions: Array[Vector2i]):
	for position in positions:
		var new_bush = bush.instantiate()
		new_bush.position = bushes.map_to_local(position)
		bushes.add_child(new_bush)
		paths.push_back(position)


func empty() -> bool:
	var is_empty := [true, false]
	return is_empty.pick_random()

func map_rows(row_number:int) -> int :
	return row_number -11

func find_next_path(position: Vector2i, previous:Vector2i)-> Array[Vector2i]:
	var min_position:= Vector2i(0, -10)
	var max_position:= Vector2i(19, 9)

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
	return [position + valid_dirs[key], position + valid_ways[key]]

func directions(step: int) -> Dictionary:
	return{
		"up": Vector2i(0, -step),
		"down": Vector2i(0, step),
		"left": Vector2i(-step, 0),
		"right":Vector2i(step, 0)
	}

func fit_map():
	var size = Vector2(2560, 2560)
	var screen = get_viewport_rect().size
	camera.zoom = screen / size
	
	
# 1. Losowe miejsce, losowy kierunek, następne miejsce, To jest nasz start, na początek węzły dam zamiast ścieżki a potem zamienię!!!
