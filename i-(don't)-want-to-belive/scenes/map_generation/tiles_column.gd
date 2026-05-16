extends Node
class_name  TilesColumn

var top: Vector2i
var middle: Array[Vector2i]
var bottom: Vector2i

func _init(top: Vector2i, middle: Array[Vector2i], bottom:Vector2i):
	self.top = top
	self.middle = middle
	self.bottom =bottom
