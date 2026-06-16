extends Control

@onready var progress_bar = $HSlider

var game_path = "uid://c4twc836ak4bd"


func _ready():
	ResourceLoader.load_threaded_request(game_path)


func _process(_delta):
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(game_path, progress)

	# POPRAWKA: Sprawdzamy czy tablica ma elementy i mnożymy tylko pierwszy indeks [0]
	if progress.size() > 0:
		progress_bar.value = progress[0] * 100

	if status == ResourceLoader.THREAD_LOAD_LOADED:
		if get_tree().root.has_node("Game"):
			return

		var game_scene: PackedScene = ResourceLoader.load_threaded_get(game_path)
		var game = game_scene.instantiate()

		get_tree().root.add_child(game)
		# queue_free() zostało stąd wycięte zgodnie z planem, aby gra sama zamknęła ekran po narysowaniu mapy!
