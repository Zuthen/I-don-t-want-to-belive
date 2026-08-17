extends Node

class_name BackpackItemsDictionary

func get_item_description(role: Player.Role, item_name: String) -> String:
	if role == Player.Role.ALIEN:
		match item_name:
			"repair_tool":
				return tr("TOOLTIP_REPAIR_TOOL_ALIEN")
			"signal_jammer":
				return tr("TOOLTIP_SIGNAL_JAMMER_ALIEN")
	elif role == Player.Role.SKEPTIC:
		match item_name:
			"sanity_pills":
				return tr("TOOLTIP_SANITY_PILLS")
			"signal_jammer":
				return tr("TOOLTIP_SIGNAL_JAMMER_SKEPTIC")
	elif role == Player.Role.BOSS:
		match item_name:
			"steering_wheel":
				return tr("TOOLTIP_STEERING_WHEEL")
			"repair_tool":
				tr("TOOLTIP_REPAIR_TOOL_ROBERT")

	return tr("TOOLTIP_DEFAULT")
