class_name Skill
extends Control

@export var icon_active_texture = preload("uid://dbjdyoew6bdm1")
@export var icon_not_active_texture = preload("uid://dj1wg20cjxer8")

@onready var cool_down_progress_circle = $Icon/CoolDownProgressCircle
@onready var icon = $Icon
@onready var label = $Label
@onready var time_left_label = $Icon/TimeLeftLabel

var text: String
var cooldown_time: float = 3.0
var time_left: float = 0.0
var is_on_cooldown: bool = false


func _ready():
	set_enabled()
	cool_down_progress_circle.value = 0
	set_process(false)


func set_disabled():
	print("nie mogę tego teraz zrobić")
	icon.texture = icon_not_active_texture


func set_enabled():
	icon.texture = icon_active_texture


func _process(delta: float) -> void:
	if is_on_cooldown:
		time_left -= delta

		cool_down_progress_circle.value = (time_left / cooldown_time) * 100
		if time_left > 1.0:
			time_left_label.text = str(int(ceil(time_left)))
		else:
			time_left_label.text = "%0.1f" % time_left
		if time_left <= 0.0:
			is_on_cooldown = false
			cool_down_progress_circle.value = 0
			icon.texture = icon_active_texture
			time_left_label.text = ""
			set_process(false)


func start_cooldown(time: float = cooldown_time) -> void:
	icon.texture = icon_not_active_texture
	cooldown_time = time
	time_left = time
	is_on_cooldown = true
	cool_down_progress_circle.value = 100
	set_process(true)


func reset_cooldown() -> void:
	time_left_label.text = ""
	is_on_cooldown = false
	time_left = 0.0
	cool_down_progress_circle.value = 0
	set_process(false)
	icon.texture = icon_active_texture


func set_icon_text(text: String):
	label.text = text
