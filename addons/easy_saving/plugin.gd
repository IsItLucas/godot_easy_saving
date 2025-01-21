@tool extends EditorPlugin


# Added constants to make the creation of new "Godot Easy ..." plugins easier.
const AUTOLOAD_NAME := "Saving"
const FOLDER_NAME := "easy_saving"
const SETTINGS_NAME := "saving"

# All custom project settings created by the addon should be in here for an easy clean up and addition.
const CUSTOM_SETTINGS: Array[Array] = [
	["debug_log", true],
	["auto_repair", true],
	["encrypt", false],
]


func _enter_tree() -> void:
	# Add GES autoload.
	#add_autoload_singleton(AUTOLOAD_NAME, "res://addons/" + FOLDER_NAME + "/autoload.gd")
	
	# Add GES settings with compatibility for other "Godot Easy ..." plugins.
	for pair: Array in CUSTOM_SETTINGS:
		var setting_name: String = pair[0]
		var setting_value: Variant = pair[1]
		add_setting(setting_name, setting_value)


func _exit_tree() -> void:
	# Remove GES autoload.
	#remove_autoload_singleton(AUTOLOAD_NAME)
	
	# Remove custom settings.
	for pair: Array in CUSTOM_SETTINGS:
		var setting_name: String = pair[0]
		add_setting(setting_name, null)


func add_setting(setting_name: String, setting_value: Variant) -> void:
	ProjectSettings.set_setting("godot_easy/" + SETTINGS_NAME + "/" + setting_name, setting_value)
