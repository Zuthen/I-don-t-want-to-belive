class_name VoiceReceiver
extends Area2D

@export var icons_count: int = 3
@onready var collision_shape_2d = $CollisionShape2D
@onready var emote_placeholder = $EmotePlaceholder


func _ready():
	emote_placeholder.visible = false
	area_entered.connect(_listen)


func _listen(area: Area2D):
	if not area is VoiceEmitter:
		return

	var player = area.get_parent()
	var my_player = get_parent()

	if player == my_player or player == my_player.get_parent():
		return

	var current_role = Player.Role.ALIEN if player is Alien else player.role

	var center = global_position + (area.global_position - global_position) * 0.5

	emote_placeholder.global_position = center

	var accepted_roles = [Player.Role.SKEPTIC, Player.Role.ALIEN] as Array[Player.Role]
	emote_placeholder.setup(current_role, accepted_roles)
	emote_placeholder.visible = true
	if is_instance_valid(area) and area.timer:
		area.timer.timeout.connect(
			func(): _hide_icon(emote_placeholder),
			CONNECT_ONE_SHOT,
		)


func _hide_icon(icon: Node):
	if icon != null:
		icon.visible = false
