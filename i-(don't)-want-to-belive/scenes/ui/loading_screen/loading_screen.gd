extends Control

@onready var progress_bar = $HSlider

var game_path = "uid://c4twc836ak4bd"
var target_progress: float = 0.0
var current_visual_progress: float = 0.0


func _ready():
	ResourceLoader.load_threaded_request(game_path)


func _process(delta):
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(game_path, progress)

	if progress.size() > 0:
		target_progress = progress[0] * 80.0

	if status == ResourceLoader.THREAD_LOAD_LOADED:
		if get_tree().root.has_node("Game"):
			target_progress = 100.0
			set_process(false)
			return

		var game_scene: PackedScene = ResourceLoader.load_threaded_get(game_path)
		var game = game_scene.instantiate()
		get_tree().root.add_child(game)

	current_visual_progress = lerp(current_visual_progress, target_progress, 10.0 * delta)
	progress_bar.value = current_visual_progress
