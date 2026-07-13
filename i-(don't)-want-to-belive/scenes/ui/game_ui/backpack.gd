extends VBoxContainer

class_name Backpack

var backpack_item_scene = preload("uid://dsg7kyngde3tw")
var max_capacity: int
@onready var overflow_label = $OverflowLabel


func _ready():
	max_capacity = get_child_count() + GameManager.backpack_capacity
	overflow_label.visible = false
	Events.item_collected.connect(_item_collected)
	Events.ufo_fixed.connect(_remove_repair_tool)


func can_collect() -> bool:
	return max_capacity - get_child_count() > 0


func _remove_repair_tool(_new_position):
	var all_items = get_children()
	for item in all_items:
		if item is BackpackItem and item.item_name == "repair_tool":
			item.queue_free()
			break


func _remove_sanity_pills():
	var all_items = get_children()
	for item in all_items:
		if item is BackpackItem and item.item_name == "sanity_pills":
			item.queue_free()
			break


func _item_collected(texture: Texture2D, item_name: String, _faction):
	if max_capacity - get_child_count() > 0:
		var backpack_item = backpack_item_scene.instantiate()
		backpack_item.item_name = item_name
		backpack_item.texture = texture
		add_child(backpack_item)

	if get_child_count() == max_capacity:
		overflow_label.visible = true
