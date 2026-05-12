extends Node
class_name  Facade

var top: TilesRow
var middle: TilesRow
var bottom: TilesRow
var thin: TilesColumn

static func create_by_roof_color(color: String):
	var facade = Facade.new()
	if color == "grey":
		facade.top = TilesRow.new(Vector2i(17,0), Vector2i(18,0), Vector2i(19,0))
		facade.middle = TilesRow.new(Vector2i(17,2), Vector2i(18,2),Vector2i(19,2))
		facade.bottom = TilesRow.new(Vector2i(17,3), Vector2i(18,3), Vector2i(19,3) )
		facade.thin = TilesColumn.new(Vector2i(16,0),[Vector2i(16,1), Vector2i(16,2)], Vector2i(16,3) )
	elif color == "yellow":
		facade.top = TilesRow.new(Vector2i(17,4), Vector2i(18,4), Vector2i(19,4))
		facade.middle=TilesRow.new(Vector2i(17,6), Vector2i(18,6), Vector2i(19,6))
		facade.bottom = TilesRow.new(Vector2i(17,7), Vector2i(18,7), Vector2i(19,7))
		facade.thin = TilesColumn.new(Vector2i(16,4), [Vector2i(16,5), Vector2i(16,6)], Vector2i(16,7))
	return facade
