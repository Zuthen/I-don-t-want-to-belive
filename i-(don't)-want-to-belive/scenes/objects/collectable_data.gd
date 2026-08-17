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


func get_skill_label(role: Player.Role, skill_name: String) -> String:
	match skill_name:
		"repair_tool":
			return tr("BACKPACK_SKILL_ACTION_REPAIR_TOOL")
		"sanity_pills":
			return tr("BACKPACK_SKILL_ACTION_SANITY_PILLS")
		"signal_jammer":
			if role == Player.Role.SKEPTIC:
				return tr("BACKPACK_SKILL_ACTION_SIGNAL_JAMMER_SKEPTIC")
			if role == Player.Role.ALIEN:
				return tr("BACKPACK_SKILL_ACTION_SIGNAL_JAMMER_ALIEN")
			return ""
		"steering_wheel":
			return tr("BACKPACK_SKILL_ACTION_STEERING_WHEEL")
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
