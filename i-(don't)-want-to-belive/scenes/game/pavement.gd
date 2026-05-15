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

static func is_cross_road(borders:PavementBorders):
	return !borders.top && !borders.bottom && !borders.right && !borders.left

static func get_tile(borders: PavementBorders) -> Vector2i:
	if is_cross_road(borders):
		if !borders.top_left && !borders.top_right && borders.bottom_left && borders.bottom_right :
			return PavementTilesMap.corners_bottom
		if !borders.bottom_left && !borders.bottom_right && borders.top_left && borders.top_right:
			return PavementTilesMap.corners_top
		if  borders.top_left && borders.bottom_left && !borders.top_right && !borders.bottom_right:
			return PavementTilesMap.corners_left
		if  borders.top_right && borders.bottom_right && !borders.top_left && !borders.bottom_left:
			return PavementTilesMap.corners_right
		if  borders.top_left && borders.bottom_right && !borders.top_right && !borders.bottom_left:
			return PavementTilesMap.diagonal_left_top
		if  !borders.top_left && !borders.bottom_right && borders.top_right && borders.bottom_left:
			return PavementTilesMap.diagonal_right_top
		if  borders.top_left && borders.top_right && !borders.bottom_left && borders.bottom_right:
			return PavementTilesMap.corners_left_bottom_open
		if  borders.top_left && borders.top_right && borders.bottom_left && !borders.bottom_right:
			return PavementTilesMap.corners_right_bottom_open
		if  borders.top_left && !borders.top_right && borders.bottom_left && borders.bottom_right:
			return PavementTilesMap.corners_right_top_open
		if  !borders.top_left && borders.top_right && borders.bottom_left && borders.bottom_right:
			return PavementTilesMap.corners_left_top_open
		if  borders.top_left && borders.top_right && borders.bottom_left && borders.bottom_right:
			return PavementTilesMap.thin_cross_road
	if borders.top && borders.bottom && !borders.left && !borders.right: # ok
		return PavementTilesMap.left_right
	if borders.left && borders.right && !borders.top && !borders.bottom: #ok
		return PavementTilesMap.top_bottom
	if borders.left && !borders.right && !borders.bottom && !borders.top:
		return PavementTilesMap.wide_left
	if borders.right && !borders.left && !borders.bottom && !borders.top:
		return PavementTilesMap.wide_right
	if !borders.right && !borders.bottom && borders.bottom_right && borders.top &&borders.left:
		return PavementTilesMap.top_left	
	if borders.top && !borders.bottom && !borders.left && !borders.right:
		return PavementTilesMap.wide_top
	if borders.bottom && !borders.top && !borders.left && !borders.right:
		return PavementTilesMap.wide_bottom
	if !borders.left && !borders.bottom && borders.bottom_left && borders.top:
		return PavementTilesMap.top_right
	if !borders.left && !borders.top && borders.top_left && borders.bottom:
		return PavementTilesMap.bottom_right
	if !borders.right && !borders.top && borders.top_right && borders.bottom:
		return PavementTilesMap.bottom_left
	if borders.left && borders.top && borders.bottom && !borders.right:
		return PavementTilesMap.left_end
	if borders.top && borders.left && !borders.bottom && !borders.right:
		return PavementTilesMap.wide_top_left
	if borders.left && borders.right && borders.top:
		return PavementTilesMap.top_end
	if borders.top && borders.bottom && borders.right:
		return PavementTilesMap.right_end
	if borders.left && borders.right && borders.bottom:
		return PavementTilesMap.bottom_end
	if borders.top && borders.right && !borders.bottom:
		return PavementTilesMap.wide_top_right
	if borders.bottom && borders.right && !borders.top:
		return PavementTilesMap.wide_bottom_right
	if borders.bottom && borders.left && !borders.top:
		return PavementTilesMap.wide_bottom_left
	if borders.top_right && !borders.top && !borders.right:
		return PavementTilesMap.corner_top_right
	if borders.top_left && !borders.top && !borders.left:
		return PavementTilesMap.corner_top_left
	if borders.bottom_left && !borders.bottom && !borders.left:
		return PavementTilesMap.corner_bottom_left
	if borders.bottom_right && !borders.bottom && !borders.right:
		return PavementTilesMap.corner_bottom_right
	return PavementTilesMap.wide_center
