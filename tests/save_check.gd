extends Node
## Automated check of character/world saving: backup copy, recovery from a
## crash between steps, and names that clean to the same file name.
##   ... --headless --script res://tests/run.gd -- save_check

var _bad := 0


func _ready() -> void:
	_run.call_deferred()


func _ck(label: String, ok: bool) -> void:
	print(("ok    " if ok else "FAIL  ") + label)
	if not ok:
		_bad += 1


func _run() -> void:
	var a := "ZZ Check Bob!"
	var b := "ZZ Check Bob?"
	_cleanup([a, b])
	_ck("a save succeeds", SaveSystem.save_character({"name": a, "level": 3}))
	_ck("it loads back", SaveSystem.load_character(a).get("level") == 3)
	SaveSystem.save_character({"name": a, "level": 4})
	_ck("second save replaces it", SaveSystem.load_character(a).get("level") == 4)
	_ck("the previous save is kept as .bak", FileAccess.file_exists(SaveSystem.file_for(a) + ".bak"))
	# A crash after the old file was moved away but before the new one moved in.
	var path := SaveSystem.file_for(a)
	DirAccess.rename_absolute(path, path + ".tmp")
	_ck("a lone .tmp still loads", SaveSystem.load_character(a).get("level") == 4)
	DirAccess.remove_absolute(path + ".tmp")
	_ck("a lone .bak still loads", SaveSystem.load_character(a).get("level") == 3)
	SaveSystem.save_character({"name": a, "level": 5})
	# A name that cleans to the same file must not overwrite.
	SaveSystem.save_character({"name": b, "level": 9})
	_ck("similar names keep separate saves", SaveSystem.load_character(a).get("level") == 5 and SaveSystem.load_character(b).get("level") == 9)
	DirAccess.rename_absolute(SaveSystem.file_for(a), SaveSystem.file_for(a) + ".tmp")
	_ck("a character with only a .tmp is still listed", SaveSystem.list_characters().filter(func(d): return d.get("name") == a).size() == 1)
	DirAccess.rename_absolute(SaveSystem.file_for(a) + ".tmp", SaveSystem.file_for(a))
	_ck("both are listed", SaveSystem.list_characters().filter(func(d): return str(d.get("name")).begins_with("ZZ Check")).size() == 2)
	_cleanup([a, b])
	print("PASS: %d problem(s)" % _bad)
	get_tree().quit(1 if _bad else 0)


func _cleanup(names: Array) -> void:
	for n in names:
		var p := SaveSystem.file_for(n)
		for s in ["", ".tmp", ".bak"]:
			if FileAccess.file_exists(p + s):
				DirAccess.remove_absolute(p + s)
