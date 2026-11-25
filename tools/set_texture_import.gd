extends SceneTree
## Switches the painted armor textures (assets/equipment/Textures) to VRAM-compressed with mip-maps, then run
## --import again so Godot re-imports them. Safe to run repeatedly.
##   Godot_console.exe --headless --path . --script res://tools/set_texture_import.gd

const DIR := "res://assets/equipment/Textures/"


func _initialize() -> void:
	var changed := 0
	for f in DirAccess.get_files_at(DIR):
		if not f.ends_with(".png.import"):
			continue
		var cf := ConfigFile.new()
		if cf.load(DIR + f) != OK:
			continue
		if int(cf.get_value("params", "compress/mode", 0)) == 2 and bool(cf.get_value("params", "mipmaps/generate", false)):
			continue
		cf.set_value("params", "compress/mode", 2)
		cf.set_value("params", "mipmaps/generate", true)
		cf.save(DIR + f)
		changed += 1
	print("texture imports updated: ", changed)
	quit()
