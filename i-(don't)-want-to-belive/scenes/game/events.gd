extends Node

@warning_ignore_start("unused_signal")
signal aliens_ufo_is_fixed(peer_id: int)
signal ufo_fixed(new_position: Vector2)
signal steering_wheel_inserted(wreck_id: int)
signal somebody_wins_network(winner: String)


@rpc("any_peer", "call_local", "reliable")
func rpc_global_announce_win(winner: String):
	somebody_wins_network.emit(winner)
