extends CanvasLayer


## This script showcases all functionalities of the GES - Godot Easy Saving addon.
## Feel free to play around with the example script and scene to get to understand
## the addon ;)
##
## _ IsItLucas?


@onready var Spinboxes: Array[SpinBox] = [
	%ValueA,
	%ValueB,
	%ValueC,
]


func _ready() -> void:
	# Stabilish connections.
	Save.file_loaded.connect(_on_file_loaded)
	
	for spinbox: SpinBox in Spinboxes:
		spinbox.value_changed.connect(func _on_value_changed(new_value: float) -> void:
			Save.push("example_scene/" + spinbox.name.to_snake_case(), int(new_value))
		)


## Called when a save file is loaded.
func _on_file_loaded(_file_slot: int, loaded_data: Dictionary) -> void:
	# Update the value of all spin boxes.
	for spinbox: SpinBox in Spinboxes:
		spinbox.value = loaded_data["example_scene"][spinbox.name.to_snake_case()]


func _on_save_button_pressed() -> void:
	# Save data.
	Save.save()


func _on_load_button_pressed() -> void:
	# Load data.
	Save.load()


func _on_slot_spin_box_value_changed(value: float) -> void:
	# Update selected save slot.
	Save.slot = int(value)
