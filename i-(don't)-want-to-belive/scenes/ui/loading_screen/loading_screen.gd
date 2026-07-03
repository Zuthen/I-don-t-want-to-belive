extends Control

@onready var progress_bar = $HSlider

var game_path = "uid://c4twc836ak4bd"
var target_progress: float = 0.0
var current_visual_progress: float = 0.0
var _game_instantiated: bool = false
var _safety_buffer_frames: int = 3


func _ready() -> void:
	GameManager.is_local_fog_ready = false
	ResourceLoader.load_threaded_request(game_path)


func _process(delta: float) -> void:
	if not _game_instantiated:
		var progress: Array = []
		var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(game_path, progress)

		if progress.size() > 0:
			target_progress = progress[0] * 70.0

		if status == ResourceLoader.THREAD_LOAD_LOADED:
			if get_tree().root.has_node("Game"):
				_game_instantiated = true
			else:
				var game_scene: PackedScene = ResourceLoader.load_threaded_get(game_path)
				var game: Node = game_scene.instantiate()
				get_tree().root.add_child(game)
				_game_instantiated = true

	else:
		if _is_local_player_ready() and GameManager.is_local_fog_ready:
			if _safety_buffer_frames > 0:
				_safety_buffer_frames -= 1
				target_progress = 95.0
			else:
				target_progress = 100.0
				if current_visual_progress >= 99.5:
					progress_bar.value = 100.0
					set_process(false)
					hide()
					return
		else:
			target_progress = 90.0

	current_visual_progress = lerp(current_visual_progress, target_progress, 12.0 * delta)
	progress_bar.value = current_visual_progress


func _is_local_player_ready() -> bool:
	var local_nodes: Array[Node] = get_tree().get_nodes_in_group("local_player")
	if local_nodes.size() > 0:
		var player = local_nodes[0]
		if "is_gameplay_ready" in player and player.is_gameplay_ready:
			return true
	return false
