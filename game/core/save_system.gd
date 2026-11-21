class_name SaveSystem
extends RefCounted
## Characters are saved on your own PC as readable JSON files in
## %APPDATA%\Godot\app_userdata\Kingdom\characters\ (one file per character).
## Each file has a version number so old saves can be upgraded later.

const DIR := "user://characters"
const VERSION := 1


static func file_for(character_name: String) -> String:
	var safe := ""
	for c in character_name.to_lower():
		safe += c if (c >= "a" and c <= "z") or (c >= "0" and c <= "9") else "_"
	return DIR.path_join((safe if safe != "" else "wanderer") + ".json")


static func save_character(data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(DIR)
	data["version"] = VERSION
	data["saved_at"] = Time.get_datetime_string_from_system()
	var path := file_for(data.get("name", "Wanderer"))
	# Write to a temporary file first, then swap, so a crash can't half-write a save.
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	return DirAccess.rename_absolute(tmp, path) == OK


static func load_character(character_name: String) -> Dictionary:
	var path := file_for(character_name)
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Saved characters: [{name, class, level}], newest first.
static func list_characters() -> Array:
	var out := []
	var dir := DirAccess.open(DIR)
	if dir == null:
		return out
	for f in dir.get_files():
		if not f.ends_with(".json"):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIR.path_join(f)))
		if parsed is Dictionary:
			out.append(parsed)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("saved_at", "")) > str(b.get("saved_at", "")))
	return out


static func exists(character_name: String) -> bool:
	return FileAccess.file_exists(file_for(character_name))
