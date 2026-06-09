extends Control

@onready var progress_bar = $HSlider

var game_path = "uid://c4twc836ak4bd"


func _ready():
	ResourceLoader.load_threaded_request(game_path)


func _process(_delta):
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(game_path, progress)
	if progress.size() > 0:
		progress_bar.value = progress[0] * 100

	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var game_scene: PackedScene = ResourceLoader.load_threaded_get(game_path)
		var game = game_scene.instantiate()
		get_tree().root.add_child(game)

		queue_free()
