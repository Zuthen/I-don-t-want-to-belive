extends Node
class_name  Water

var top: TilesRow = TilesRow.new(Vector2i(8,6), Vector2i(9,6),Vector2(10,6))
var middle: TilesRow = TilesRow.new(Vector2i(8,7), Vector2i(9,7), Vector2(10,7))
var bottom: TilesRow = TilesRow.new(Vector2i(8,8), Vector2i(9,8),Vector2i(10,8))
var thin: TilesColumn = TilesColumn.new(Vector2i(15,6),[Vector2i(15,7)],Vector2i(15,8))
var circle: Circle = Circle.new()

class Circle:
	var top_left:=Vector2i(11,6)
	var top_right:= Vector2i(12,6)
	var bottom_left:=Vector2i(11,7)
	var bottom_right:= Vector2i(12,7)
