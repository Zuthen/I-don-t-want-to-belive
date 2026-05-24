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
		icon.global_position = center
		get_tree().current_scene.add_child(icon)
		area.timer.timeout.connect(func(): _hide_icon(icon))


func _hide_icon(icon: Node):
	icon.queue_free()
