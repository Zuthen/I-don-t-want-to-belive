extends Node

@warning_ignore_start("unused_signal")
signal item_collected(texture: Texture2D, item_name: String, player_role: int, color: Color)
signal backpack_updated(item_name: String, player_role: int)
signal input_action_assigned(enabled: bool, item_name: String)
signal item_used(item_name: String, player: Player)
signal item_type_removed(item_name: String, player: Player)
signal action_removed(item_name: String)
