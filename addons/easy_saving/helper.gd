class_name SaveHelper extends Node


## This class only serves as a helper class.
## It only contains some utils and / or quality of life features.
## This is mainly used by GES - Godot Easy Saving, but feel free to use it if you want.


## The project settings related to the addon prefix.
const SETTINGS_NAME := "save"

## The save file name.
const FILE_NAME := "save_%s.cfg"

## The encryption file name.
const ENCRYPTION_NAME := "enc_%s"

## The save files and encryption files path.
const FOLDER_PATH := "user://save/"


## Returns [code]true[/code] if the given slot corresponds to an encrypted file. Returns [code]false[/code] otherwise.
static func is_slot_encrypted(slot: int) -> bool:
	return FileAccess.file_exists(get_encryption_file_path(slot))


## Sets a given GES setting to the given value.
static func set_setting(setting: String, value: Variant) -> void:
	ProjectSettings.set_setting("godot_easy/" + SETTINGS_NAME + "/" + setting, value)


## Returns the current value of a GES project setting.
static func get_setting(setting: String, default: Variant = null) -> Variant:
	return ProjectSettings.get_setting("godot_easy/" + SETTINGS_NAME + "/" + setting, default)


## Returns the full path that points to the save file corresponding to the given slot.
static func get_save_file_path(slot: int) -> String:
	return (FOLDER_PATH + FILE_NAME) % str(slot)


## Returns the full path that points to the file that says if a save file is encrypted or not.
static func get_encryption_file_path(slot: int) -> String:
	return (FOLDER_PATH + ENCRYPTION_NAME) % str(slot)
