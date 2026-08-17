extends Node

class_name Findings

class CollectablesData:
	var collectables: Dictionary[String, int]
	var count: int


	func _init(c: Dictionary[String, int]):
		collectables = c
		var all_collectables_count = 0
		for item_name in c:
			all_collectables_count += c[item_name]
		count = all_collectables_count


static func get_skill_label(role: Player.Role, skill_name: String) -> String:
	match skill_name:
		"repair_tool":
			return "Napraw"
		"sanity_pills":
			return "Weź tabletkę"
		"signal_jammer":
			if role == Player.Role.SKEPTIC:
				return "Zaszyfruj sygnał"
			if role == Player.Role.ALIEN:
				return "Wyślij swoją pozycję"
			return ""
		"steering_wheel":
			return "Umieść koło sterowe we wraku"
		_:
			return ""


static func create_collectables() -> CollectablesData:
	var collectables: Dictionary[String, int] = {
		"repair_tool": 3,
		"sanity_pills": 2,
		"signal_jammer": 2,
		"steering_wheel": 1,
	}
	return CollectablesData.new(collectables)
