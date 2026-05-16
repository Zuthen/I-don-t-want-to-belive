extends Node
class_name Roof

var single: Vector2i
var top: TilesRow
var middle: TilesRow
var bottom: TilesRow
var single_row: TilesRow
var thin : TilesRow

	

static func create_by_color(color: String) -> Object:
	var roof := Roof.new()
	if color == "yellow":
		roof.single= Vector2i(6,5)
		roof.top = TilesRow.new(Vector2i(0,3),Vector2i(1,3),Vector2i(2,3))
		roof.middle=TilesRow.new(Vector2i(0,4),Vector2i(1,4), Vector2i(2,4))
		roof.bottom = TilesRow.new(Vector2i(0,5), Vector2i(1,5),Vector2i(2,5))
		roof.single_row = TilesRow.new(Vector2i(3,5),Vector2i(4,5),Vector2i(5,5))
		roof.thin = TilesRow.new(Vector2i(7,3),Vector2i(7,4),Vector2i(7,5) )

	elif color == "grey":
		roof.single= Vector2i(14,5)
		roof.top = TilesRow.new(Vector2i(8,3), Vector2i(9,3), Vector2i(10,3))
		roof.middle = TilesRow.new(Vector2i(8,4),Vector2i(9,4), Vector2i(10,4))
		roof.bottom = TilesRow.new(Vector2i(8,5),Vector2i(9,5),Vector2i(10,5))
		roof.single_row = TilesRow.new(Vector2i(11,5), Vector2i(12,5), Vector2i(13,5))
		roof.thin = TilesRow.new(Vector2i(15,3),Vector2i(15,4),Vector2i(15,5))
	return roof
