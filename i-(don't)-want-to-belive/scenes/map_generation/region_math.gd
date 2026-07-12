extends Node

class_name RegionMath

class ContinousRegions:
	var paths: Array[Vector2i]
	var obstacles: Array[Vector2i]


	func _init(
			paths_vectors: Array[Vector2i],
			obstacles_vectors: Array[Vector2i],
	):
		paths = paths_vectors
		obstacles = obstacles_vectors


class HorizontalSegment:
	var start: Vector2i
	var end: Vector2i


	func _init(s: Vector2i, e: Vector2i):
		start = s
		end = e


func find_areas(paths: Array[Vector2i]) -> ContinousRegions:
	var region_paths: Array[Vector2i] = []
	var region_obstacles: Array[Vector2i] = []

	for j in range(MapSettings.min_position.y, MapSettings.max_position.y + 1):
		for i in range(MapSettings.min_position.x, MapSettings.max_position.x + 1):
			if paths.has(Vector2i(i, j)):
				region_paths.push_back(Vector2i(i, j))
			else:
				region_obstacles.push_back(Vector2i(i, j))
	return ContinousRegions.new(region_paths, region_obstacles)


func find_regions(tiles: Array[Vector2i]) -> Array:
	var tile_lookup := { }
	for t in tiles:
		tile_lookup[t] = true

	var visited := { }
	var regions := []

	for t in tiles:
		if visited.has(t):
			continue

		var stack = [t]
		var region: Array[Vector2i] = []
		while not stack.is_empty():
			var p = stack.pop_back()
			if visited.has(p):
				continue

			visited[p] = true
			region.append(p)

			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var n = p + d
				if tile_lookup.has(n) and not visited.has(n):
					stack.append(n)

		regions.append(region)

	return regions


func map_regions_to_obstacle_rects(obstacle_regions: Array) -> Array[Rect2i]:
	var obstacle_rects: Array[Rect2i] = []
	for region in obstacle_regions:
		var rects = _regions_to_rects(region)
		obstacle_rects.append_array(_merge_small_rectangles(rects))
	return obstacle_rects


func _regions_to_rects(region: Array[Vector2i]) -> Array[Rect2i]:
	var tiles := { }
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
						Vector2i(width, height),
					)

		rects.append(best_rect)

		for y in range(best_rect.size.y):
			for x in range(best_rect.size.x):
				tiles.erase(
					best_rect.position + Vector2i(x, y),
				)

	return rects


func _merge_small_rectangles(rects: Array[Rect2i]) -> Array[Rect2i]:
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
