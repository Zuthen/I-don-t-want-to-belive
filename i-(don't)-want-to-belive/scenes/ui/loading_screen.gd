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
		# ZABEZPIECZENIE: Jeśli gra już została wpięta do roota, ignorujemy pętlę process
		if get_tree().root.has_node("Game"):
			return

		var game_scene: PackedScene = ResourceLoader.load_threaded_get(game_path)
		var game = game_scene.instantiate()

		# Gra ładuje się na pełnych obrotach w tle (brak wyłączania visible),
		# dzięki czemu silnik sieciowy i rysowanie mapy działają bezawaryjnie!
		get_tree().root.add_child(game)
