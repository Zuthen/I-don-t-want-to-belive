extends Node

class_name BackpackItemsDictionary

static func get_item_description(role: Player.Role, item_name: String) -> String:
	if role == Player.Role.ALIEN:
		match item_name:
			"repair_tool":
				return "Wichajster:
					 Użyj do naprawy swojego UFO"
			"signal_jammer":
				return "Zakłócacz:
					Wyślij swoją pozycję przez
					walkie talkie, tak jak
					sceptyk"
	elif role == Player.Role.SKEPTIC:
		match item_name:
			"sanity_pills":
				return "Medi-Sinet: 
					Użyj aby stracić punkt wiary"
			"signal_jammer":
				return "Zakłócacz:
					Po użyciu na walkie-talkie
					ufo nie zobaczy nadanej
					przez ciebie pozycji"

	return "Nie możesz użyć tego przedmiotu"
