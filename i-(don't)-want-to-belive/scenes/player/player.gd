extends CharacterBody2D
class_name Player

const speed = 300.0


func _physics_process(delta):
	var horizontal_direction := Input.get_axis("walk_left","walk_right")
	var vertical_direction := Input.get_axis("walk_up","walk_down")
	
	var direction := Vector2(horizontal_direction,vertical_direction).normalized()
	
	velocity = speed * direction
	move_and_slide()
