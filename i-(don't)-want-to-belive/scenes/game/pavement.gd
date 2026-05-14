extends Node
class_name Pavement

var thin: Thin
var wide: Wide

func _init():
	thin = Thin.new()
	wide = Wide.new()

	thin.path_ends = PathEnds.new()
	thin.connectors = Directions.new()
	thin.corners = ThinCorners.new()

	wide.corners = Corners.new()
	wide.connectors = Connectors.new()
class Thin:
	var path_ends: PathEnds
	var connectors : Directions
	var corners: ThinCorners
		
class PathEnds:
	var top: = Vector2i(15,0)
	var bottom:  = Vector2i(15,2)
	var left: = Vector2i(11,2)
	var right: = Vector2i(13,2)
	
class Directions:
	var left_right: = Vector2i(12,2)
	var up_down: =Vector2i(15,1)
	
class Wide:
	var corners: Corners 
	var connectors: Connectors 
	var middle:= Vector2i(9,1)
	
class Corners:
	var top_left: = Vector2i(8,0)
	var top_right:= Vector2i(10,0)
	var bottom_left:= Vector2i(8,2)
	var bottom_right: =Vector2i(10,2)

class ThinCorners:
	var top_left: = Vector2i(11,0)
	var top_right:= Vector2i(12,0)
	var bottom_left:= Vector2i(11,1)
	var bottom_right: =Vector2i(12,1)

class Connectors:
	var top: = Vector2i(9,0)
	var bottom: = Vector2i(9,2)
	var left:= Vector2i(8,1)
	var right:= Vector2i(10,1)
	
