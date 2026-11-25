extends CharacterModel
## The White Knight character: the mannequin's skeleton and every animation in the game, wearing
## the White Knight (WK_white_knight.scn, built from the owner's sheet by white_knight.gd). The
## mannequin's own body is hidden; the outfit covers all of it.

const OUTFIT := preload("res://assets/characters/white_knight/WK_white_knight.scn")


func _ready() -> void:
	super._ready()
	for m in find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).visible = false
	set_armor("white_knight", OUTFIT)
