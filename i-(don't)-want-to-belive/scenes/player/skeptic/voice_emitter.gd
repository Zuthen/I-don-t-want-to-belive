class_name VoiceEmitter
extends Area2D

@onready var timer = $Timer


func _ready():
	timer.timeout.connect(_stop_calling)


func _stop_calling():
	queue_free()
