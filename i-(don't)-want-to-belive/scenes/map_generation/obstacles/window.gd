extends RefCounted
class_name BuildingWindow

var top: VerticalSprite 
var bottom: Vector2i
var middle: Array[Vector2i]

class VerticalSprite:
	var top_sprite: Vector2i
	var bottom_sprite: Vector2i

	func _init():
		top_sprite = Vector2i.ZERO
		bottom_sprite = Vector2i.ZERO


static func create_by_roof_color(color: String):
	var window = BuildingWindow.new()
	window.top = VerticalSprite.new()

	if color == "grey":
		window.top.top_sprite = Vector2i(11,13)
		window.top.bottom_sprite = Vector2i(11,14)

		window.bottom = Vector2i(12,14)

		window.middle = [
			Vector2i(12,13),
			Vector2i(13,13),
			Vector2i(13,14)
		] as Array[Vector2i]

	elif color == "yellow":
		window.top.top_sprite = Vector2i(11,16)
		window.top.bottom_sprite = Vector2i(11,17)

		window.bottom = Vector2i(11,15)

		window.middle = [
			Vector2i(12,16),
			Vector2i(13,16),
			Vector2i(13,17)
		] as Array[Vector2i]

	return window
