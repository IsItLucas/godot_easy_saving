extends Node


## Emitted when [member data] changes in any way.
## [b]Note:[/b] If you want to know exactly what changed, use [signal key_changed] instead.
signal data_changed(new_data: Dictionary)

## Emitted when one of [member data]'s values change in any way.
## [b]Note:[/b] If you don't need to know the exact key and value that changed,
## use [signal data_changed] instead.
signal key_changed(full_key: String, real_key: String, new_value: Variant)

## Emitted when a file is saved.
signal file_saved(file_slot: int)

## Emitted when a save file is loaded.
signal file_loaded(file_slot: int, loaded_data: Dictionary)


## The FOLDER where all save files are going to be stored.
##
## You can add as many subfolders as you want, but make sure to user the
## [code]user://[/code] directory instead of the [code]res://[/code] directory.
##
## Also, do not put the file name in here. The file is named automatically
## by the addon in the right moment.
##
## Lastly, make sure to add an [code]/[/code] at the end of the string.
const SAVE_DIRECTORY: String = "user://save/"

## The default data. When no save files are found or no values are found in the save
## file, this dictionary will be used instead.
const DEFAULT_DATA: Dictionary = {
	"example_scene": {
		"value_a": 0,
		"value_b": 0,
		"value_c": 0,
	}
}

## Defines which debug messages should be printed.
## 0 - Errors Only,
## 1 - Errors and Important Messages,
## 2 - Errors and All Messages,
const DEBUG_LEVEL: int = 1

## Determines whether [member data] will be saved automatically when the
## application is closed or not.
const SAVE_ON_QUIT: bool = true


## Defines the interval between autosaves in seconds.
## If this value is smaller or equal to 0, autosaving will be disabled.
var autosave_interval := 1

## The current section's data.
## This dictionary is used in basically all save operations.
var data: Dictionary = DEFAULT_DATA.duplicate(true)

## The currently selected save slot.
## This variable is automatically updated when a save file is loaded.
var slot: int = -1


## The autosave timer reference.
var timer: Timer


func _ready() -> void:
	# Create a timer responsible for automatically saving the data.
	_create_autosave_timer()


func _notification(what: int) -> void:
	# Only listen to close requests.
	if what != NOTIFICATION_WM_CLOSE_REQUEST:
		return
	
	# Make sure auto accept quit is disabled.
	assert(not ProjectSettings.get_setting("application/config/auto_accept_quit", true) or not SAVE_ON_QUIT,
		"Save on quit functionality is only available if project setting \"application/config/auto_accept_quit\" is disabled"
	)
	
	# Automatically save the file.
	if SAVE_ON_QUIT:
		save()
	
	# Debug log.
	if DEBUG_LEVEL >= 1:
		print("Quitting and saving")


#region Utils - Do not use these.
## Creates a timer responsible for automatically saving the data.
func _create_autosave_timer() -> void:
	# Create the autosave timer.
	timer = Timer.new()
	add_child(timer)
	
	if autosave_interval > 0:
		timer.start(autosave_interval)
	else:
		timer.start(60)
	
	timer.one_shot = true
	
	timer.timeout.connect(func _on_autosave_timer_timeout() -> void:
		# Autosave.
		if autosave_interval > 0:
			save()
		
		# Restart timer.
		# The timer has to be manually restarted so the autosave interval
		# can be updated during runtime.
		if autosave_interval > 0:
			timer.start(autosave_interval)
		else:
			timer.start(60)
	)


## Creates all folders present in [member SAVE_DIRECTORY] in the user's file system.
func _create_directory() -> void:
	# Divide the path into different folders.
	var path: String = SAVE_DIRECTORY.replace("user://", "")
	var folders: PackedStringArray = path.split("/")
	
	# Store the path that the code is currently at.
	var current_path: String = "user://"
	for folder: String in folders:
		# Check if the folder is valid.
		if folder == "":
			continue
		
		# Check whether the directory exists or not.
		var exists: bool = DirAccess.dir_exists_absolute(current_path + folder)
		
		# If it doesn't exist, make a new folder.
		if not exists:
			DirAccess.make_dir_absolute(current_path + folder)
		
		# Update the current path.
		current_path += folder + "/"


## Validates the currently selected [member slot] by updating it to [param target_slot] when possible.
## However, if that's not possible, updates [member slot] to the first available slot: 0.
func _validate_slot(target_slot: int) -> void:
	# Check if the user wants to use the currently selected slot.
	if target_slot < 0:
		# Check if the currently selected slot is valid.
		if slot < 0:
			# Use the first available slot if not.
			slot = 0
	else:
		# Update currently selected slot.
		slot = target_slot


## Returns the deepest value of a nested dictionary.
func _get_nested(key: String) -> Dictionary:
	# Look for nesteed dictionaries.
	var nested: PackedStringArray = key.split("/")
	
	# If no nested dictionaries were found, simply set the variable in the main data dictionary.
	if nested.size() <= 0:
		# Stop the code right here as no additional logic has to run in this case.
		return {}
	
	# But if at least one nested dictionary was found, remove the last entry of the split result and store it in another variable.
	# The last element of the nested dictionaries array is ALWAYS the key, that means, not a
	# dictionary, so we don't want to iterate through it.
	var true_key: String = nested[nested.size() - 1]
	nested.remove_at(nested.size() - 1)
	
	# Store the current dictionary.
	var current_dict: Dictionary = data
	
	# Loop through all nested dictionaries.
	for dict: String in nested:
		# Check if the given nested dictionary exists in the main dictionary.
		if not current_dict.has(dict):
			continue
		
		# Update the current dictionary.
		current_dict = current_dict[dict]
	
	# Return.
	return {
		"dict": current_dict,
		"key": true_key
	}


## Returns a [class FileAccess] associated with [member target_slot].
func _access_file(target_slot: int, mode: FileAccess.ModeFlags) -> FileAccess:
	# Create a new file access.
	var file_name: String = "save_%s.cfg" % str(target_slot)
	var file_access: FileAccess = FileAccess.open(SAVE_DIRECTORY + file_name, mode)
	
	# Check if the file access is not valid.
	if not file_access:
		return null
	
	# Check if the file was opened successfully.
	var error: Error = file_access.get_open_error()
	assert(error == OK, "An error occured while trying to open save file: " + error_string(error))
	
	# Return.
	return file_access
#endregion


## Adds a variable to [member data] using [param key] if it doesn't exist yet and changes it to the given [param value].
func push(key: String, value: Variant) -> void:
	# Get the desired dictionary.
	var dict_data: Dictionary = _get_nested(key)
	
	# Update value.
	if dict_data == {}:
		data.set(key, value)
	else:
		dict_data.dict[dict_data.key] = value
	
	# Emit signals.
	data_changed.emit(data)
	key_changed.emit(key, dict_data.key, value)
	
	# Debug log.
	if DEBUG_LEVEL >= 2:
		print("Setting \"%s\" to %s" % [key, str(value)])


## Gets a variable from [member data] and adds it if it doesn't exist yet.
func pull(key: String, default: Variant = null) -> Variant:
	# Get the desired dictionary.
	var dict_data: Dictionary = _get_nested(key)
	
	# Return value.
	if dict_data == {}:
		return data.get_or_add(key, default)
	else:
		return dict_data.dict[dict_data.key]


## Saves [member data] to a file located at [member SAVE_DIRECTORY] using the save slot [param to_slot].
## If [param to_slot] is smaller than 0, the save file will be saved using [member slot].
## However, if [member slot] is also smaller than 0, the first save slot (0) is going to be used.
func save(to_slot: int = -1) -> void:
	# Validate the currently selected slot.
	_validate_slot(to_slot)
	
	# Open the target save file.
	var file_access: FileAccess = _access_file(slot, FileAccess.WRITE)
	
	# Save the data to the file.
	file_access.store_var(data)
	file_access.close()
	
	# Emit a signal.
	file_saved.emit(slot)
	
	# Debug log.
	if DEBUG_LEVEL >= 1:
		print("Saving file to slot %s\nData: %s" % [str(slot), str(data)])


## Loads the save file associated with [param target_slot] and updates [member data].
## If the file doesn't exist, [member DEFAULT_DATA] will be used as [member data] instead.
func load(target_slot: int = -1) -> void:
	# Validate the currently selected slot.
	_validate_slot(target_slot)
	
	# Load data from the save file.
	var file_access: FileAccess = _access_file(slot, FileAccess.READ)
	if file_access == null:
		data = DEFAULT_DATA.duplicate(true)
		
		if DEBUG_LEVEL >= 1:
			print("Creating new file at slot %s\nData: %s" % [str(slot), str(data)])
	else:
		data = file_access.get_var()
		file_access.close()
		
		if DEBUG_LEVEL >= 1:
			print("Loading file from slot %s\nData: %s" % [str(slot), str(data)])
	
	# Emit a signal.
	file_loaded.emit(slot, data)
