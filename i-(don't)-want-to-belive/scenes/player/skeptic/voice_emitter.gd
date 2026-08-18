class_name VoiceEmitter
extends Area2D

@onready var timer = $Timer
@onready var collision_shape_2d = $CollisionShape2D
var icon_placeholder: PackedScene = preload("uid://d03xota05sdvx")


func _ready():
	timer.timeout.connect(_stop_calling)


func _stop_calling():
	queue_free()
