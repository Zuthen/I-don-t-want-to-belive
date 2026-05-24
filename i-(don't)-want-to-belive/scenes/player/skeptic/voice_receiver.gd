class_name VoiceReceiver
extends Area2D

@export var icons_count: int = 3
var icon_scene: PackedScene = preload("uid://d03xota05sdvx")
@onready var collision_shape_2d = $CollisionShape2D


func _ready():
	area_entered.connect(_listen)


func _listen(area: Area2D):
	if area is VoiceEmitter:
		var parent = get_parent()
		var area_parent = area.get_parent()
		if parent == area_parent:
			return
		var distance = global_position.distance_to(area.global_position)
		var icon: Node = icon_scene.instantiate()
		var center = global_position + (area.global_position - global_position) * 0.5
		if icon.get_parent() == null:
			if is_instance_valid(parent) and parent.get_parent():
				parent.get_parent().add_child(icon)
			else:
				add_child(icon)
		icon.global_position = center
		if is_instance_valid(area) and area.timer:
			area.timer.timeout.connect(
				func(): _hide_icon(icon),
				CONNECT_ONE_SHOT,
			)


func _hide_icon(icon: Node):
	icon.queue_free()
