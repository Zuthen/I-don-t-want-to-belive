extends Node

const FOLDER_PATH = "res://assets/characters/aliens/"

var dir = DirAccess.open(FOLDER_PATH)
var sprites: Array[String]
var textures: Array[AlienTextures]
var alien_textures: Array[AlienTextures] = []


func _ready():
	sprites = get_all_aliens_sprites()
	map_to_alien_texture(sprites)


class AlienTextures:
	var climb_a: Texture2D
	var climb_b: Texture2D
	var duck: Texture2D
	var front: Texture2D
	var hit: Texture2D
	var idle: Texture2D
	var jump: Texture2D
	var walk_a: Texture2D
	var walk_b: Texture2D


func get_all_aliens_sprites() -> Array[String]:
	var result_paths: Array[String] = []

	if dir:
		for file_name in dir.get_files():
			if file_name.ends_with(".import"):
				continue
			var clean_file_name = file_name
			if clean_file_name.ends_with(".remap"):
				clean_file_name = clean_file_name.replace(".remap", "")

			var full_path = FOLDER_PATH + clean_file_name
			result_paths.append(full_path)

	return result_paths


func map_to_alien_texture(files_list: Array[String]):
	var colors: Array[String] = []
	for path in files_list:
		var file_name = path.get_file()
		if file_name.begins_with("character_") and file_name.ends_with("_duck.png"):
			var color = file_name.replace("character_", "").replace("_duck.png", "")
			if not colors.has(color):
				colors.append(color)

	for color in colors:
		var alien_sprites: AlienTextures = AlienTextures.new()
		var name_start = FOLDER_PATH + "character_" + color
		alien_sprites.climb_a = load(name_start + "_climb_a.png")
		alien_sprites.climb_b = load(name_start + "_climb_b.png")
		alien_sprites.duck = load(name_start + "_duck.png")
		alien_sprites.front = load(name_start + "_front.png")
		alien_sprites.hit = load(name_start + "_hit.png")
		alien_sprites.idle = load(name_start + "_idle.png")
		alien_sprites.jump = load(name_start + "_jump.png")
		alien_sprites.walk_a = load(name_start + "_walk_a.png")
		alien_sprites.walk_b = load(name_start + "_walk_b.png")

		alien_textures.append(alien_sprites)
