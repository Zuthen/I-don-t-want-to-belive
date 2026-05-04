extends Node2D

@onready var bushes = $Bushes
@onready var camera = $Camera2D

var bush : PackedScene = preload("uid://bstnhs77ge8vn")
var player_scene: PackedScene = preload("uid://b7wo2a5407873")
var random_generator: RandomNumberGenerator = RandomNumberGenerator.new()
var paths: Array[Vector2i]=[]
var min_position:= Vector2i(0, -10)
var max_position:= Vector2i(19, 9)
var spawn_points: Array[Vector2i]=[]
	
func _ready():
	genereate_map()
	var spawn_position = find_spawn_position()
	spawn_player(spawn_position)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func genereate_map():
	var start: Vector2i = Vector2i(random_generator.randi_range(0, 19), random_generator.randi_range(-10,9))
	var next:Array[Vector2i] = find_next_path(start,Vector2i.ZERO)
	
	for i in range(100):
		var way = find_next_path(next[0], next[1])
		next=way
		
	for y in range(min_position.y, max_position.y):
		for x in range(min_position.x, max_position.x):
			var position := Vector2i(x, y)
			if !paths.has(position):
				create_bush(position)
			else:
				spawn_points.append(position)

func create_bush(position: Vector2i):
	var new_bush = bush.instantiate()
	new_bush.position = bushes.map_to_local(position)
	bushes.add_child(new_bush)


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

func directions(step: int) -> Dictionary:
	return{
		"up": Vector2i(0, -step),
		"down": Vector2i(0, step),
		"left": Vector2i(-step, 0),
		"right":Vector2i(step, 0)
	}
func find_spawn_position() -> Vector2i:
	return spawn_points.pick_random()
	
func spawn_player(spawn_position: Vector2i):
	var player = player_scene.instantiate()
	player.position = bushes.map_to_local(spawn_position)
	add_child(player)
#
#func fit_map():
	#var size = Vector2(2560, 2560)
	#var screen = get_viewport_rect().size
	#camera.zoom = screen / size
