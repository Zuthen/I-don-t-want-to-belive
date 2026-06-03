extends Node2D

@onready var sprite_2d = $Sprite2D

var texture: Texture2D
var target_position: Vector2
var time: float


func _ready():
	sprite_2d.texture = texture
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_position, time) \
			.set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT)
	tween.finished.connect(queue_free)
