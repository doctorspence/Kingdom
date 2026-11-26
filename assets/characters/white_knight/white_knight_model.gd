extends CharacterModel
## The White Knight character: the mannequin's skeleton and every animation in the game, wearing
## the White Knight (WK_white_knight.scn, built from the owner's sheet by white_knight.gd). The
## mannequin's own body is hidden; the outfit covers all of it.

const OUTFIT := preload("res://assets/characters/white_knight/WK_white_knight.scn")
const CrossbowHold := preload("res://assets/characters/bandit/crossbow_hold.gd")

## Hold the right-hand item as a crossbow, in both hands (the Knights' crossbowmen).
@export var holds_crossbow := false


func _ready() -> void:
	super._ready()
	for m in find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).visible = false
	set_armor("white_knight", OUTFIT)
	if holds_crossbow and _skeleton:
		var hold := CrossbowHold.new()
		hold.name = "CrossbowHold"
		if hold.setup(_skeleton, self):
			_skeleton.add_child(hold)
		else:
			hold.free()
