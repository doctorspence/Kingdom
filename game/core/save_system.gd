class_name SaveSystem
extends RefCounted
## Characters are saved on your own PC as readable JSON files in
## %APPDATA%\Godot\app_userdata\Kingdom\characters\ (one file per character).
## Each file has a version number so old saves can be upgraded later.

const DIR := "user://characters"
const VERSION := 1


## The file for a name. Letters and digits are kept, anything else becomes "_",
## so "Bob!" and "Bob?" would collide: if a file with that name already holds a
## DIFFERENT character, the new one gets a short hash added to its file name.
static func file_for(character_name: String) -> String:
	return _path_for(DIR, character_name)


static func _path_for(dir: String, character_name: String) -> String:
	var safe := ""
	for c in character_name.to_lower():
		safe += c if (c >= "a" and c <= "z") or (c >= "0" and c <= "9") else "_"
	if safe == "":
		safe = "wanderer"
	var path := dir.path_join(safe + ".json")
	var held := _read(path)
	if not held.is_empty() and str(held.get("name", character_name)) != character_name:
		path = dir.path_join("%s_%08x.json" % [safe, character_name.hash()])
	return path


## Save safely: write a temporary file, keep the old save as .bak, then move the
## new one into place. At every moment at least one complete copy exists.
static func _write(path: String, data: Dictionary) -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.remove_absolute(path + ".bak")
		DirAccess.rename_absolute(path, path + ".bak")
	return DirAccess.rename_absolute(tmp, path) == OK


## Read a save; if the main file is missing or unreadable, fall back to the
## finished temporary copy, then to the backup.
static func _read(path: String) -> Dictionary:
	for p in [path, path + ".tmp", path + ".bak"]:
		if FileAccess.file_exists(p):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
			if parsed is Dictionary and not (parsed as Dictionary).is_empty():
				return parsed
	return {}


static func save_character(data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(DIR)
	data["version"] = VERSION
	data["saved_at"] = Time.get_datetime_string_from_system()
	return _write(file_for(data.get("name", "Wanderer")), data)


static func load_character(character_name: String) -> Dictionary:
	return _read(file_for(character_name))


## Saved characters: [{name, class, level}], newest first.
static func list_characters() -> Array:
	var out := []
	var dir := DirAccess.open(DIR)
	if dir == null:
		return out
	var bases := {}
	for f in dir.get_files():
		# A character whose main file is gone (a crash mid-save) still has a .tmp or .bak.
		for ext in [".json", ".json.tmp", ".json.bak"]:
			if f.ends_with(ext):
				bases[f.trim_suffix(ext.substr(5)) if ext != ".json" else f] = true
	for f in bases:
		var parsed := _read(DIR.path_join(f))
		if not parsed.is_empty():
			out.append(parsed)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("saved_at", "")) > str(b.get("saved_at", "")))
	return out


static func exists(character_name: String) -> bool:
	return not _read(file_for(character_name)).is_empty()


# --- Worlds (saved by the host) -------------------------------------------------------
## Worlds live next to characters, in %APPDATA%\Godot\app_userdata\Kingdom\worlds\.

const WORLD_DIR := "user://worlds"


static func world_file_for(world_name: String) -> String:
	return _path_for(WORLD_DIR, world_name)


static func save_world(data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(WORLD_DIR)
	data["version"] = VERSION
	data["saved_at"] = Time.get_datetime_string_from_system()
	return _write(world_file_for(data.get("name", "World")), data)


static func load_world(world_name: String) -> Dictionary:
	return _read(world_file_for(world_name))


static func delete_world(world_name: String) -> void:
	var path := world_file_for(world_name)
	for p in [path, path + ".tmp", path + ".bak"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
