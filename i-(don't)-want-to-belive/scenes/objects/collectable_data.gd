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
				print("jestem sceptem")
				return "Zaszyfruj sygnał"
			if role == Player.Role.ALIEN:
				print("jestem ufokiem")
				return "Wyślij swoją pozycję"
			return ""
		_:
			return ""


static func create_aliens_collectables() -> CollectablesData:
	var collectables: Dictionary[String, int] = {
		"repair_tool": 2,
	}
	return CollectablesData.new(collectables)


static func create_skeptics_collectables() -> CollectablesData:
	var collectables: Dictionary[String, int] = {
		"sanity_pills": 2,
		"signal_jammer": 2,
	}
	return CollectablesData.new(collectables)
