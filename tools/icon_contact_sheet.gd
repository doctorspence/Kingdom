extends SceneTree
## Lays every equipment icon out on one dark sheet (big and at inventory size) for review:
##   Godot_console.exe --headless --path . --script res://tools/icon_contact_sheet.gd [-- out.png]

const Catalog := preload("res://assets/equipment/eq_catalog.gd")
const Builder := preload("res://tools/build_equipment.gd")


func _initialize() -> void:
	var all: Array = Catalog.entries()
	all.append_array(Catalog.armor_entries())
	var cols := 6
	var cell := 200
	var rows := ceili(all.size() / float(cols))
	var sheet := Image.create(cols * cell, rows * (cell + 20), false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.1, 0.095, 0.09))
	for i in all.size():
		var e: Dictionary = all[i]
		var p := Builder.icon_path(e)
		if not FileAccess.file_exists(p):
			continue
		var img := Image.load_from_file(p)
		img.convert(Image.FORMAT_RGBA8)
		var big := img.duplicate() as Image
		big.resize(150, 150, Image.INTERPOLATE_LANCZOS)
		var small := img.duplicate() as Image
		small.resize(48, 48, Image.INTERPOLATE_LANCZOS)
		var x := (i % cols) * cell
		var y := (i / cols) * (cell + 20)
		sheet.blend_rect(big, Rect2i(0, 0, 150, 150), Vector2i(x + 4, y + 4))
		sheet.blend_rect(small, Rect2i(0, 0, 48, 48), Vector2i(x + 150, y + 4))
		sheet.blend_rect(small, Rect2i(0, 0, 48, 48), Vector2i(x + 150, y + 60))
	var out := "res://assets/equipment/InventoryIcons/_contact_sheet.png"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	sheet.save_png(out)
	print("sheet ", out, " ", all.size(), " icons")
	quit()
