extends Node

const GAME_VERSION: String = "1.1.0"


func get_version() -> String:
	var path = "res://version.txt"

	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var version_text = file.get_line().strip_edges()
		if version_text != "":
			return version_text

	return GAME_VERSION
