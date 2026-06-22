extends Node

const GAME_VERSION: String = "1.0.2-mvp"


func _ready() -> void:
	print("[VERSION] Uruchomiono grę w wersji: ", GAME_VERSION)


func get_version() -> String:
	var path = "res://version.txt"

	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var version_text = file.get_line().strip_edges()
		if version_text != "":
			return version_text

	return "0.1.0-dev"
