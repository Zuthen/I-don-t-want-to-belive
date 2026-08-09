extends HFlowContainer

@onready var district_spin_box = $DistrictSpinBox
@onready var narrow_select = $NarrowSelect
@onready var robert_checkbox = $RobertCheckbox

signal with_robert_changed(with_robert: bool)


func _ready():
	district_spin_box.value = GameManager.map_tiles_size
	narrow_select.selected = GameManager.map_config
	_recalculate_map_parameters()
	district_spin_box.value_changed.connect(_on_district_size_changed)
	narrow_select.item_selected.connect(_on_narrowness_changed)
	robert_checkbox.toggled.connect(_on_robert_checkbox_changed)


func _on_robert_checkbox_changed(play_with_robert: bool):
	GameManager.with_robert = play_with_robert
	with_robert_changed.emit(play_with_robert)


func _on_district_size_changed(value: float):
	GameManager.map_tiles_size = int(value)
	_recalculate_map_parameters()


func _on_narrowness_changed(index: int):
	GameManager.map_config = index as GameManager.MapConfig
	_recalculate_map_parameters()


func _recalculate_map_parameters():
	GameManager.map_paths_tiles = GameManager.get_map_paths_tiles()
