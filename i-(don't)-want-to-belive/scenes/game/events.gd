extends Node

signal item_collected(texture: Texture2D, name: String)
signal alien_fixed_ufo(peer_id: int)
signal ufo_fixed(new_position: Vector2)
signal request_crashed_ufo_despawn
