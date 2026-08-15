extends Node

class_name AnimationSetup

static func setup_textures(animation: Animation, textures: Array[Texture2D]):
	var track_path = "Sprite2D:texture"
	var track = animation.find_track(track_path, Animation.TYPE_VALUE)
	if track != -1:
		for i in range(textures.size()):
			animation.track_set_key_value(track, i, textures[i])
