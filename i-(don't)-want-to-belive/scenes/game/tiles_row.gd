extends Node
class_name TilesRow

var start:Vector2i
var middle: Vector2i
var end:Vector2i

func _init(start: Vector2i, middle: Vector2i, end:Vector2i):
	self.start = start
	self.middle = middle
	self.end =end
