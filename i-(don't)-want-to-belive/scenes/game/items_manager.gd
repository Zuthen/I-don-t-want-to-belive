extends Node

@warning_ignore_start("unused_signal")
signal item_collected(texture: Texture2D, item_name: String, item_faction: Player.Role, player_role: Player.Role)
signal backpack_updated(item_name: String, for_role: Player.Role, player_role: Player.Role)
signal input_action_assigned(enabled: bool, item_name: String, player_role: Player.Role)
signal item_used(item_name: String, player: Player)
signal item_type_removed(item_name: String, player: Player)
signal action_removed(item_name: String)
