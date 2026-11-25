extends CharacterModel
## A bandit: the shared UAL1 skeleton and every animation in the game, wearing one of the
## code-built outfits (BD_*.scn, made by tools/build_bandit.gd) in place of the mannequin.
## Everything else (facing, animation, weapons in hands, hit tints, multiplayer mirroring) is
## the normal CharacterModel, so enemy AI and combat work unchanged.

const CrossbowHold := preload("res://assets/characters/bandit/crossbow_hold.gd")
const Gear := preload("res://assets/characters/bandit/bandit_gear.gd")

## Which bandit this is (BD_rough, BD_brute, BD_rogue or BD_marksman).
@export var outfit: PackedScene = preload("res://assets/characters/bandit/BD_rough.scn")
## Hold the right-hand item as a crossbow, in both hands.
@export var holds_crossbow := false

## How far behind the spine a stowed shield hangs (further out over a cloak).
var _shield_back := -0.255


func _ready() -> void:
	super._ready()
	if _skeleton == null:
		return
	_wear()
	if holds_crossbow:
		var hold := CrossbowHold.new()
		hold.name = "CrossbowHold"
		if hold.setup(_skeleton, self):
			_skeleton.add_child(hold)
		else:
			hold.free()


func _wear() -> void:
	# the plain mannequin under the clothes isn't needed
	for m in _meshes:
		m.visible = false
		m.queue_free()
	_meshes.clear()
	var inst: Node = outfit.instantiate()
	_shield_back = inst.get_meta(&"shield_back", _shield_back)
	for src in inst.find_children("*", "MeshInstance3D", true, false):
		var n := MeshInstance3D.new()
		n.name = src.name
		n.mesh = (src as MeshInstance3D).mesh
		n.skin = (src as MeshInstance3D).skin
		_skeleton.add_child(n)
		n.skeleton = NodePath("..")
		if _overlay_kind != "":
			n.material_overlay = _overlay
		_meshes.append(n)
	inst.free()


## Where a calm bandit's gear hangs. The base model's places suit most of it; the round shield
## goes flat on the back, and the crossbow hangs nose-down at the left hip (the quiver has the back).
func _stow_holder(side: String) -> BoneAttachment3D:
	if _stow_holders.has(side) and is_instance_valid(_stow_holders[side]):
		return _stow_holders[side]
	# [bone, where the item goes, in the model's rest space]
	var spot: Array
	if holds_crossbow and side == "r":
		spot = [&"pelvis", Transform3D(Basis(Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)), Vector3(0.262, 0.90, -0.01))]
	elif side == "l" and stow_places.get(side, "") == "back":
		var facing := Basis(Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(-1, 0, 0))   # the shield's face looks backward
		# spine_02, not spine_03: it keeps the shield closer to the back when sitting
		spot = [&"spine_02", Transform3D(facing, Vector3(0.0, 1.19, _shield_back) - facing * Gear.SHIELD_CENTRE)]
	else:
		return super._stow_holder(side)
	var bone := _skeleton.find_bone(spot[0])
	var holder := BoneAttachment3D.new()
	holder.bone_name = spot[0]
	_skeleton.add_child(holder)
	_held.append(holder)
	_stow_holders[side] = holder
	var model_from_skel := global_transform.affine_inverse() * _skeleton.global_transform
	var rest := model_from_skel * _skeleton.get_bone_global_rest(bone)
	var local := rest.affine_inverse() * (spot[1] as Transform3D)
	local.basis = local.basis.orthonormalized()
	holder.set_meta(&"stow", local)
	return holder
