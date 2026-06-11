extends Node

const FOLDER_PATH = "res://assets/characters/ufos/"

var dir: DirAccess
var sprites: Array[String]
var ufo_textures: Array[UfoTextures] = []


func _ready():
	dir = DirAccess.open(FOLDER_PATH)
	sprites = get_all_ufos_sprites()
	map_to_ufo_texture(sprites)


class UfoTextures:
	var color: String
	var ship: Texture2D
	var laser1: Texture2D
	var laser2: Texture2D
	var laser_pointing: Texture2D
	var laser_burst: Texture2D
	var laser_ground_burst: Texture2D
	var ship_crashed: Texture2D


func get_all_ufos_sprites() -> Array[String]:
	var result_paths: Array[String] = []

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(".png.import"):
				var clean_png_path = FOLDER_PATH + file_name.replace(".import", "")
				result_paths.append(clean_png_path)

			file_name = dir.get_next()
		dir.list_dir_end()
	return result_paths


func map_to_ufo_texture(files_list: Array[String]):
	var colors: Array[String] = []

	for path in files_list:
		var file_name = path.get_file()
		if file_name.begins_with("ship") and file_name.ends_with("_manned.png"):
			var color = file_name.replace("ship", "").replace("_manned.png", "")
			if not colors.has(color):
				colors.append(color)

	for color in colors:
		var ufo_sprites: UfoTextures = UfoTextures.new()
		ufo_sprites.color = color
		ufo_sprites.ship = load(FOLDER_PATH + "ship" + color + "_manned.png")
		ufo_sprites.laser1 = load(FOLDER_PATH + "laser" + color + "1.png")
		ufo_sprites.laser2 = load(FOLDER_PATH + "laser" + color + "2.png")
		ufo_sprites.laser_pointing = load(FOLDER_PATH + "laser" + color + "3.png")
		ufo_sprites.laser_burst = load(FOLDER_PATH + "laser" + color + "_burst.png")
		ufo_sprites.laser_ground_burst = load(FOLDER_PATH + "laser" + color + "_groundBurst.png")
		ufo_sprites.ship_crashed = load(FOLDER_PATH + "ship" + color + "_damage2.png")

		ufo_textures.append(ufo_sprites)
