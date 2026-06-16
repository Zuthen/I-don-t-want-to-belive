class_name VoiceReceiver
extends Area2D

@export var icons_count: int = 3
@onready var collision_shape_2d = $CollisionShape2D


func _ready():
	area_entered.connect(_listen)


func _listen(area: Area2D):
	if not area is VoiceEmitter:
		return

	var player = area.get_parent()
	var my_player = get_parent()

	if player == my_player or player == my_player.get_parent():
		return

	var center = global_position + (area.global_position - global_position) * 0.5

	var skeptic_player = get_parent() as Skeptic
	if skeptic_player and skeptic_player.has_method("request_icon_spawn_on_server"):
		var my_id = multiplayer.get_unique_id()
		var sender_id = player.id if "id" in player else player.get_multiplayer_authority()
		skeptic_player.request_icon_spawn_on_server.rpc(center, sender_id, my_id, "call")


func _hide_icon(icon: Node):
	if icon != null:
		icon.visible = false
