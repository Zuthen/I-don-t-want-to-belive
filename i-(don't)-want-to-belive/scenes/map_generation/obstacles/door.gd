extends RefCounted
class_name Door
var single: Array[Vector2i] =[]
var double : Array[HorizontalSprite2]=[]
var triple: Array[HorizontalSprite3]=[]

class HorizontalSprite2:
	var left_sprite: Vector2i
	var right_sprite: Vector2i
	func _init(left, right):
		left_sprite = left
		right_sprite = right

class HorizontalSprite3:
	var left_sprite: Vector2i
	var middle_sprite: Vector2i
	var right_sprite: Vector2i
	func _init(left, middle, right):
		left_sprite = left
		middle_sprite = middle
		right_sprite = right
	

class PlacedDoor:
	var start_position: Vector2i
	var length: int
	func _init(start, len):
		start_position = start
		length = len

static func create():
	var door = Door.new()
	door.single.assign([
	Vector2i(12,9), Vector2i(13,9), Vector2i(14,9), Vector2i(15,9), 
	Vector2i(11,10), Vector2i(12,10), Vector2i(13,10), Vector2i(14,10), Vector2i(15,10),
	Vector2i(11,11), Vector2i(12,11), Vector2i(13,11), Vector2i(14,11), Vector2i(15,11),
	Vector2i(15,12), Vector2i(15,13)
	])
	door.double.assign([
		HorizontalSprite2.new(Vector2i(7,15), Vector2i(8,15)),
		HorizontalSprite2.new(Vector2i(9,15), Vector2i(10,15))
	])
	door.triple.assign([
		HorizontalSprite3.new(Vector2i(8,13), Vector2i(9,13), Vector2i(10,13)),
		HorizontalSprite3.new(Vector2i(8,14), Vector2i(9,14), Vector2i(10,13))
	])

	return door
