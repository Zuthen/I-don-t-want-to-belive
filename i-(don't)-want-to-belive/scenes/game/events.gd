extends Node

@warning_ignore_start("unused_signal")
signal item_collected(texture: Texture2D, name: String, faction: Player.Role, player_faction: Player.Role)
signal alien_fixed_ufo(peer_id: int)
signal ufo_fixed(new_position: Vector2)
