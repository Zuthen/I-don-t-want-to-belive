extends Node
class_name Pavement

class PavementBorders:
	var top_left: = true
	var top: = true
	var top_right: = true
	
	var left: = true
	var right := true
	
	var bottom_left:= true
	var bottom:=true
	var bottom_right:=true

static func get_neighbors(position: Vector2i, paths:Array[Vector2i]) -> PavementBorders :
	var borders = PavementBorders.new()
	if paths.has(position+Vector2i.UP +Vector2i.LEFT):
		borders.top_left = false
	if paths.has(position + Vector2i.UP):
		borders.top = false
	if paths.has(position + Vector2i.UP + Vector2i.RIGHT):
		borders.top_right = false
	if paths.has(position + Vector2i.LEFT):
		borders.left = false
	if paths.has(position + Vector2i.RIGHT):
		borders.right = false
	if paths.has(position+Vector2i.DOWN + Vector2i.LEFT):
		borders.bottom_left = false
	if paths.has(position+Vector2i.DOWN):
		borders.bottom = false
	if paths.has(position+Vector2i.DOWN + Vector2i.RIGHT):
		borders.bottom_right = false
	return borders

static func get_tile(borders: PavementBorders) -> Vector2i:
	if borders.top && borders.bottom && !borders.left && !borders.right: # ok
		return Vector2i(12,2)
	if borders.left && borders.right && !borders.top && !borders.bottom: #ok
		return Vector2i(15,1)
	if borders.left && !borders.right && !borders.bottom && !borders.top:
		return Vector2i(8,1)
	if borders.right && !borders.left && !borders.bottom && !borders.top:
		return Vector2i(10,1)
	if borders.top && !borders.bottom && !borders.left && !borders.right:
		return Vector2i(9,0)
	if borders.bottom && !borders.top && !borders.left && !borders.right:
		return Vector2i(9,2)
		# single corners
	if !borders.right && !borders.bottom && borders.bottom_right && borders.top:
		return Vector2i(11,0)
	if !borders.left && !borders.bottom && borders.bottom_left && borders.top:
		return Vector2i(12,0)
	if !borders.left && !borders.top && borders.top_left && borders.bottom:
		return Vector2i(12,1)
	if !borders.right && !borders.top && borders.top_right && borders.bottom:
		return Vector2i(11,1)
	if borders.top && borders.left && !borders.bottom:
		return Vector2i(8,0)
	if borders.top && borders.bottom && borders.right:
		return Vector2i(13,2)
	if borders.left && borders.right && borders.top:
		return Vector2i(15,0)
	if borders.left && borders.right && borders.bottom:
		return Vector2i(15,2)
	if borders.top && borders.right && !borders.bottom:
		return Vector2i(10,0)
	if borders.left && borders.top && borders.bottom && !borders.right:
		return Vector2i(11,2)
	if borders.bottom && borders.right && !borders.top:
		return Vector2i(10,2)
	if borders.bottom && borders.left && !borders.top:
		print("done")
		return Vector2i(8,2)
	return Vector2i(9,1)
