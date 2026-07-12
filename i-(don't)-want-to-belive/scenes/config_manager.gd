extends Node

const SAVE_PATH = "user://settings.cfg"

var settings = {
	"audio_music": 0.5,
	"audio_sfx": 0.5,
}


func _ready():
	_load_settings()


func set_setting(key: String, value: float):
	if settings.has(key):
		settings[key] = value


func get_setting(key: String, default_value: float) -> float:
	return settings.get(key, default_value)


func save_settings():
	var config = ConfigFile.new()
	config.set_value("Audio", "music_volume", settings["audio_music"])
	config.set_value("Audio", "sfx_volume", settings["audio_sfx"])
	config.save(SAVE_PATH)


func _load_settings():
	var config = ConfigFile.new()
	var error = config.load(SAVE_PATH)

	if error != OK:
		_apply_initial_music_volume(settings["audio_music"])
		return

	settings["audio_music"] = config.get_value("Audio", "music_volume", settings["audio_music"])
	settings["audio_sfx"] = config.get_value("Audio", "sfx_volume", settings["audio_sfx"])

	_apply_initial_music_volume(settings["audio_music"])


func _apply_initial_music_volume(volume: float):
	if has_node("/root/BackgroundMusic"):
		var bg_music = get_node("/root/BackgroundMusic") as AudioStreamPlayer
		if volume <= 0.0:
			bg_music.volume_db = -80.0
		else:
			bg_music.volume_db = linear_to_db(volume)
