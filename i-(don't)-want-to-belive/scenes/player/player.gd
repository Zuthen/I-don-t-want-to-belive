extends CharacterBody2D
class_name Player

@onready var animation_player = $AnimationPlayer

const speed = 100.0

var direction_sprite := "down" 

func _physics_process(_delta):
	var horizontal_direction := Input.get_axis("walk_left","walk_right")
	var vertical_direction := Input.get_axis("walk_up","walk_down")
	
	var direction := Vector2(horizontal_direction,vertical_direction).normalized()
	velocity = speed * direction
	move_and_slide()
	animate(direction)

func animate(direction: Vector2):
	var directions = {
	"down": Vector2.DOWN,
	"up" : Vector2.UP,
	"left": Vector2.LEFT,
	"right": Vector2.RIGHT
}
	if direction == directions["down"]:
		animation_player.play("move down")
		direction_sprite = "down"
	elif direction == directions["up"]:
		animation_player.play("move up")
		direction_sprite = "up"
	elif direction == directions["left"]:
		animation_player.play("move left")
		direction_sprite = "left"
	elif direction == directions["right"]:
		animation_player.play("move right")
		direction_sprite = "right"
	elif direction == Vector2.ZERO:
		animation_player.play("idle "+ direction_sprite)
