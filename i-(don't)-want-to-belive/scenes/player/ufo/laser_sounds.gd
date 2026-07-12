extends Node

var laser_sounds: Array[AudioStream] = []
var explosion_sounds: Array[AudioStream] = []
var capture_sounds: Array[AudioStream] = []
const SOUNDS_PATH = "res://assets/sounds/"


func _ready():
	_get_all_laser_sounds()


func _get_all_laser_sounds():
	if not DirAccess.dir_exists_absolute(SOUNDS_PATH):
		return

	var sounds_directory = DirAccess.open(SOUNDS_PATH)
	if sounds_directory:
		sounds_directory.list_dir_begin()

		var file_name = sounds_directory.get_next()

		while file_name != "":
			if not sounds_directory.current_is_dir():
				if file_name.begins_with("laser") and (file_name.ends_with(".ogg") or file_name.ends_with(".ogg.import")):
					var clean_name = file_name.replace(".import", "")
					var full_path = SOUNDS_PATH + clean_name
					var sound_resource = load(full_path)
					if sound_resource:
						laser_sounds.append(sound_resource)
				elif file_name.begins_with("explosion") and (file_name.ends_with(".ogg") or file_name.ends_with(".ogg.import")):
					var clean_name = file_name.replace(".import", "")
					var full_path = SOUNDS_PATH + clean_name
					var sound_resource = load(full_path)
					if sound_resource:
						explosion_sounds.append(sound_resource)
				elif file_name.begins_with("spaceEngine") and (file_name.ends_with(".ogg") or file_name.ends_with(".ogg.import")):
					var clean_name = file_name.replace(".import", "")
					var full_path = SOUNDS_PATH + clean_name
					var sound_resource = load(full_path)
					if sound_resource:
						capture_sounds.append(sound_resource)
			file_name = sounds_directory.get_next()

		sounds_directory.list_dir_end()
