extends Node

class Preferences:
	var type: String
	var skin_idx: int
	var peer_id: int


var is_local_fog_ready: bool = false
var players_selections: Array[Preferences]
