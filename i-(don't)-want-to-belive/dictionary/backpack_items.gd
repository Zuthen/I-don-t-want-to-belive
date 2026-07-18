extends Node

class_name BackpackItemsDictionary

static func get_item_description(role: Player.Role, item_name: String) -> String:
	if role == Player.Role.ALIEN:
		match item_name:
			"repair_tool":
				return "Użyj do naprawy swojego UFO"
	elif role == Player.Role.SKEPTIC:
		match item_name:
			"sanity_pills":
				return "Użyj aby stracić punkt wiary"
	return "Nie możesz użyć tego przedmiotu"
