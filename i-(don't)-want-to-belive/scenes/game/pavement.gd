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
static func has_all_bottom_borders(borders:PavementBorders):
	return borders.bottom && borders.bottom_left && borders.bottom_right
static func has_all_top_borders(borders:PavementBorders):
	return borders.top && borders.top_left && borders.top_right
static func has_all_left_borders(borders:PavementBorders):
	return borders.left && borders.bottom_left && borders.top_left
static func has_all_right_borders(borders:PavementBorders):
	return borders.right && borders.top_right && borders.bottom_right
	
static func get_tile(borders: PavementBorders) -> Vector2i:
	if has_all_left_borders(borders) &&  !borders.right && !borders.bottom_right && !borders.top_right  && !borders.top && !borders.bottom && !borders.top_right && !borders.bottom_right:
		return PavementTilesMap.wide_left
	if has_all_right_borders(borders) && !borders.left && !borders.top_left && !borders.bottom_left &&  !borders.top && !borders.bottom && !borders.top_left && !borders.bottom_left:
		return PavementTilesMap.wide_right
	if has_all_bottom_borders(borders) && !borders.top && !borders.top_left && !borders.top_right && !borders.left && !borders.right:
		return PavementTilesMap.wide_bottom
	if has_all_top_borders(borders) && !borders.bottom && !borders.bottom_left && !borders.bottom_right && !borders.left && !borders.right:
		return PavementTilesMap.wide_top
	if borders.right && !borders.left && !borders.top && !borders.bottom && borders.top_left && borders.bottom_left:
		return PavementTilesMap.t_cross_right
	if has_all_left_borders(borders) &&  borders.top_right && borders.bottom_right && !borders.bottom && !borders.top && !borders.right:
		return PavementTilesMap.t_cross_left
	if borders.top && borders.bottom_left && borders.bottom_right && !borders.left && !borders.right && !borders.bottom:
		return PavementTilesMap.t_cross_top
	if borders.bottom && borders.top_left && borders.top_right && !borders.left && !borders.right && !borders.top :
		return PavementTilesMap.t_cross_bottom
	if borders.left && !borders.top && !borders.right && !borders.bottom_right && !borders.bottom:
		return PavementTilesMap.left_border_top_right_corner	
	if borders.left && borders.bottom_right && !borders.top && !borders.right && !borders.top_right && !borders.bottom:
		return PavementTilesMap.left_border_bottom_right_corner
	if borders.right && borders.bottom_left && !borders.top && !borders.top_left && !borders.left && !borders.bottom:
		return PavementTilesMap.right_border_bottom_left_corner
	if borders.right && borders.top_right && !borders.top && !borders.bottom_left && !borders.left && !borders.bottom:
		return PavementTilesMap.right_border_top_left_corner	
	if borders.top && borders.bottom_left && !borders.bottom && !borders.left && !borders.right && !borders.bottom_right:
		return PavementTilesMap.top_border_bottom_left_corner
	if borders.top && borders.bottom_right && !borders.bottom && !borders.left && !borders.right && !borders.bottom_left:
		return PavementTilesMap.top_border_bottom_right_corner
	if borders.bottom && borders.top_right && !borders.top && !borders.left && !borders.right && !borders.top_left:
		return PavementTilesMap.bottom_border_top_right_corner
	if borders.bottom && borders.top_left && !borders.top && !borders.left && !borders.right && !borders.top_right:
		return PavementTilesMap.bottom_border_top_left_corner

		

	if borders.left && borders.right && !borders.top && !borders.bottom:
		return PavementTilesMap.top_bottom
	if has_all_left_borders(borders) && has_all_top_borders(borders) && borders.bottom_right && !borders.right && !borders.bottom:
		return PavementTilesMap.top_left	
	if has_all_top_borders(borders) && has_all_right_borders(borders) && borders.bottom_left && !borders.left && !borders.bottom:
		return PavementTilesMap.top_right
	if has_all_bottom_borders(borders) && has_all_right_borders(borders) && borders.top_left && !borders.top && !borders.left:
		return PavementTilesMap.bottom_right
	if has_all_bottom_borders(borders) && has_all_left_borders(borders) && borders.top_right && !borders.top && !borders.right:
		return PavementTilesMap.bottom_left


	if !borders.right && borders.top && borders.bottom && borders.left:
		return PavementTilesMap.left_end
	if !borders.left && borders.top && borders.bottom && borders.right:
		return PavementTilesMap.right_end


	


	if is_cross_road(borders):	
		if borders.bottom_left && borders.bottom_right && !borders.top_right && !borders.top_left  :
			return PavementTilesMap.corners_bottom
		if borders.top_right && borders.top_left && !borders.bottom_left && !borders.bottom_right :
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


	if borders.top && borders.left && !borders.bottom && !borders.right:
		return PavementTilesMap.wide_top_left
	if borders.left && borders.right && borders.top:
		return PavementTilesMap.top_end
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
		
	if  borders.top && borders.bottom && !borders.left && !borders.right:
		return PavementTilesMap.left_right
	return PavementTilesMap.wide_center
