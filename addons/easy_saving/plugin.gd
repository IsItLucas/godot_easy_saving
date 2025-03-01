@tool extends EditorPlugin


## This script is responsible for setting up the plugin and its autoload.


## The name of the autoload that is going to be added by this plugin.
const AUTOLOAD_NAME := "Save"

## Where the autoload script / scene is located.
const FOLDER_NAME := "easy_saving"

## The autoload file name and extension.
const FILE_NAME := "save.gd"


func _enter_tree() -> void:
	# Add autoload.
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/" + FOLDER_NAME + "/" + FILE_NAME)


func _exit_tree() -> void:
	# Remove autoload.
	remove_autoload_singleton(AUTOLOAD_NAME)
