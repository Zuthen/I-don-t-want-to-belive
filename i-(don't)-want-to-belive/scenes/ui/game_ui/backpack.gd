extends VBoxContainer

class_name Backpack

var backpack_item_scene = preload("uid://dsg7kyngde3tw")
var max_capacity: int
@onready var overflow_label = $OverflowLabel

signal remove(item_name: String)


func _ready():
	max_capacity = get_child_count() + GameManager.backpack_capacity
	overflow_label.visible = false
	Events.item_collected.connect(_item_collected)
	remove.connect(_remove_item)


func can_collect() -> bool:
	return max_capacity - get_child_count() > 0


func get_backpack_items_by_name(item_name: String) -> Array[BackpackItem]:
	var items = get_children().filter(
		func(item): return item is BackpackItem and item.item_name == item_name
	)
	var result: Array[BackpackItem] = []
	result.assign(items)
	return result


func _remove_item(item_name: String):
	var found_items = get_backpack_items_by_name(item_name)
	if found_items.size() > 0:
		var item_to_remove = found_items[0]
		item_to_remove.queue_free()
		overflow_label.visible = false


func _item_collected(texture: Texture2D, item_name: String, _faction, _player_faction: Player.Role):
	if max_capacity - get_child_count() > 0:
		var backpack_item = backpack_item_scene.instantiate()
		backpack_item.item_name = item_name
		backpack_item.texture = texture
		backpack_item.description = BackpackItemsDictionary.get_item_description(_player_faction, item_name)
		add_child(backpack_item)

	if get_child_count() == max_capacity:
		overflow_label.visible = true
