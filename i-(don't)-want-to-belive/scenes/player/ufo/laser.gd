extends Node2D

class_name UfoLaser

@onready var animation_player = $AnimationPlayer
@onready var laser_top = $LaserTop
@onready var laser_middle = $LaserMiddle
@onready var laser_pointer = $LaserPointer
@onready var collision_shape_2d = $LaserRange/CollisionShape2D
@onready var laser_range = $LaserRange

var laser_hit_points := 1
var pointing_animation: Animation
var color_idx: int = 0
var textures: UfosTextures.UfoTextures
var peer_id: int = 0


# Wewnątrz laser.gd
func _physics_process(_delta):
	# Loguje pozycję lasera raz na 60 klatek, żeby zobaczyć czy w ogóle leci w stronę gracza
	if Engine.get_frames_drawn() % 60 == 0:
		print("[LOG FIZYKI LASERA] Żyję w świecie! Moja globalna pozycja to: ", global_position)


func _ready():
	textures = UfosTextures.ufo_textures[color_idx]
	var original_anim = animation_player.get_animation("laser pointing")
	pointing_animation = original_anim.duplicate()
	animation_player.get_animation_library("").add_animation("laser pointing", pointing_animation)
	animation_player.animation_finished.connect(_on_pointing_finished)
	laser_range.area_entered.connect(_on_skeptic_see_laser)
	set_textures(textures)
	if animation_player:
		animation_player.play("laser pointing")


func set_textures(textures: UfosTextures.UfoTextures):
	laser_top.texture = textures.laser1
	laser_middle.texture = textures.laser2
	laser_pointer.texture = textures.laser_pointing

	var track_pointer = pointing_animation.find_track("Laser/LaserPointer:texture", Animation.TYPE_VALUE)
	var track_top = pointing_animation.find_track("Laser/LaserTop:texture", Animation.TYPE_VALUE)
	var track_middle = pointing_animation.find_track("Laser/LaserMiddle:texture", Animation.TYPE_VALUE)

	if track_pointer != -1:
		pointing_animation.track_set_key_value(track_pointer, 0, textures.laser_pointing)

	if track_top != -1:
		pointing_animation.track_set_key_value(track_top, 0, textures.laser1)

	if track_middle != -1:
		pointing_animation.track_set_key_value(track_middle, 0, textures.laser2)

	collision_shape_2d.disabled = false


func _on_skeptic_see_laser(other):
	var player = other.get_parent()
	if player is Skeptic:
		_set_animation_hit()
		player.belive_points_changed.emit(laser_hit_points)
		player.laser_seen.emit(peer_id)


func _set_animation_hit():
	if textures == null:
		return
	var current_time = animation_player.current_animation_position
	var track_pointer = pointing_animation.find_track("Laser/LaserPointer:texture", Animation.TYPE_VALUE)
	if track_pointer != -1:
		pointing_animation.track_set_key_value(track_pointer, 0, textures.laser_burst)

	animation_player.stop()
	animation_player.play("laser pointing")
	animation_player.seek(current_time, true)


func get_animation_time() -> float:
	return animation_player.get_animation("laser pointing").length


func _on_pointing_finished(anim_name: StringName) -> void:
	if anim_name == "laser pointing":
		if multiplayer.is_server():
			queue_free()
