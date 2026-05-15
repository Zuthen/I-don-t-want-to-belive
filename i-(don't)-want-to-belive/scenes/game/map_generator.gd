extends Node

var min_position:= Vector2i(0, -10)
var max_position:= Vector2i(19, 9)


class ContinousRegions:
	var paths: Array[Vector2i]
	var obstacles: Array[Vector2i]

	func _init(
		paths_vectors: Array[Vector2i],
		obstacles_vectors: Array[Vector2i]
	):
		paths = paths_vectors
		obstacles = obstacles_vectors

class HorizontalSegment:

	var start: Vector2i
	var end: Vector2i

	func _init(s: Vector2i, e: Vector2i):
		start = s
		end = e
		
func find_areas(paths:Array[Vector2i]) -> ContinousRegions:
	var region_paths: Array[Vector2i] = []
	var region_obstacles: Array[Vector2i]  = []
	for j in range(min_position.y, max_position.y):
		for i in range (min_position.x, max_position.x):
			if paths.has(Vector2i(i, j)):
				region_paths.push_back(Vector2i(i, j))
			else:
				region_obstacles.push_back(Vector2i(i,j))
	return ContinousRegions.new(region_paths, region_obstacles)
	
func rectangles(tiles: Array[Vector2i]) -> Array[Rect2i]:
	var horizontal = build_horizontal_segments(tiles)
	var merged =  merge_vertical(horizontal)
	return resolve_rectangles(merged)

func create_left_borders(area:Rect2i) -> Array[Rect2i]:
	var how_many = randi() % 9 + 1

	var rectangles: Array[Rect2i] = []
	var current_y = area.position.y
	var remaining_height = area.size.y
	var base_height = max(1, area.size.y / how_many)

	for i in range(how_many):
		var position_x = area.position.x + (randi() % 2)
		var size_y = base_height
		if i == how_many - 1:
			size_y = remaining_height
		else:
			size_y = min(base_height, remaining_height)
		var size_x = randi() % 2 + 1

		rectangles.append(
			Rect2i(
				Vector2i(position_x, current_y),
				Vector2i(size_x, size_y)
			)
		)

		current_y += size_y
		remaining_height -= size_y
	return rectangles
			


func build_horizontal_segments(tiles: Array[Vector2i]) -> Array[HorizontalSegment]:
	var segments: Array[HorizontalSegment] = []

	if tiles.is_empty():
		return segments

	var start = tiles[0]
	var end = tiles[0]

	for i in range(tiles.size() - 1):

		var current = tiles[i]
		var next = tiles[i + 1]

		var is_continuous = (
			current.y == next.y
			and current.x + 1 == next.x
		)

		if is_continuous:
			end = next
		else:
			segments.append(HorizontalSegment.new(start, end))
			start = next
			end = next

	segments.append(HorizontalSegment.new(start, end))

	return segments
	
		
func merge_vertical(segments: Array[HorizontalSegment]) -> Array[Rect2i]:

	var result: Array[Rect2i] = []
	var used := {}

	for seg in segments:

		if used.has(seg):
			continue

		var start = seg.start
		var end = seg.end

		var width = end.x - start.x + 1
		var height = 1

		var current_y = start.y

		while true:

			var found = false

			for other in segments:

				if used.has(other):
					continue

				if (
					other.start.x == start.x
					and other.end.x == end.x
					and other.start.y == current_y + 1
				):

					height += 1
					current_y += 1
					used[other] = true
					found = true
					break

			if not found:
				break

		result.append(
			Rect2i(
				start,
				Vector2i(width, height)
			)
		)
	
	return result


func resolve_rectangles(rects: Array[Rect2i]) -> Array[Rect2i]:

	var occupied := {}
	var result: Array[Rect2i] = []

	rects.sort_custom(func(a, b):
		return a.size.x * a.size.y > b.size.x * b.size.y
	)

	for rect in rects:
		var valid_tiles: Array[Vector2i] = []

		for y in range(rect.position.y, rect.position.y + rect.size.y):
			for x in range(rect.position.x, rect.position.x + rect.size.x):

				var p = Vector2i(x, y)

				if !occupied.has(p):
					valid_tiles.append(p)

		if valid_tiles.is_empty():
			continue

		var horizontal = build_horizontal_segments(valid_tiles)
		var merged = merge_vertical(horizontal)

		for r in merged:
			result.append(r)

			for y in range(r.position.y, r.position.y + r.size.y):
				for x in range(r.position.x, r.position.x + r.size.x):
					occupied[Vector2i(x, y)] = true

	return result

func find_regions(tiles: Array[Vector2i]) -> Array:
	var set := {}
	for t in tiles:
		set[t] = true

	var visited := {}
	var regions := []

	for t in tiles:
		if visited.has(t):
			continue

		var stack = [t]
		var region: Array[Vector2i]= []
		while not stack.is_empty():
			var p = stack.pop_back()
			if visited.has(p):
				continue

			visited[p] = true
			region.append(p)

			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var n = p + d
				if set.has(n) and not visited.has(n):
					stack.append(n)

		regions.append(region)

	return regions
	
func merge_small_rectangles(rects: Array[Rect2i]) -> Array[Rect2i]:

	var changed = true

	while changed:

		changed = false

		for i in range(rects.size()):

			var a = rects[i]

			if a.size.x * a.size.y > 2:
				continue

			for j in range(rects.size()):

				if i == j:
					continue

				var b = rects[j]

				# SAME HEIGHT + TOUCHING HORIZONTALLY
				if (
					a.position.y == b.position.y
					and a.size.y == b.size.y
					and (
						a.end.x == b.position.x
						or b.end.x == a.position.x
					)
				):

					var merged = a.merge(b)

					rects.remove_at(max(i, j))
					rects.remove_at(min(i, j))

					rects.append(merged)

					changed = true
					break

			if changed:
				break

	return rects
func get_neighbors(p: Vector2i) -> Array[Vector2i]:
	return [
		p + Vector2i.LEFT,
		p + Vector2i.RIGHT,
		p + Vector2i.UP,
		p + Vector2i.DOWN
	]
func regions_to_rects(region: Array[Vector2i]) -> Array[Rect2i]:

	var tiles := {}
	for t in region:
		tiles[t] = true

	var rects: Array[Rect2i] = []

	while not tiles.is_empty():

		var best_rect: Rect2i
		var best_area := 0

		for start in tiles.keys():

			var max_width := 0

			while tiles.has(start + Vector2i(max_width, 0)):
				max_width += 1

			for width in range(1, max_width + 1):

				var height := 0
				var can_expand := true

				while can_expand:

					for x in range(width):

						var p = start + Vector2i(x, height)

						if not tiles.has(p):
							can_expand = false
							break

					if can_expand:
						height += 1

				var area = width * height

				if area > best_area:

					best_area = area
					best_rect = Rect2i(
						start,
						Vector2i(width, height)
					)

		rects.append(best_rect)

		for y in range(best_rect.size.y):
			for x in range(best_rect.size.x):

				tiles.erase(
					best_rect.position + Vector2i(x, y)
				)

	return rects
