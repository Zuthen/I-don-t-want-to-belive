extends VBoxContainer

var backpack_item_scene = preload("uid://dsg7kyngde3tw")


func _ready():
	Events.item_collected.connect(_item_collected)


func _item_collected(texture: Texture2D, _name):
	var backpack_item = backpack_item_scene.instantiate()
	backpack_item.texture = texture
	add_child(backpack_item)
