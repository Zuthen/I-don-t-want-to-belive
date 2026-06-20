extends Node

const GAME_VERSION: String = "0.1.0"


func _ready() -> void:
	print("[VERSION] Uruchomiono grę w wersji: ", GAME_VERSION)


func get_version() -> String:
	return GAME_VERSION
