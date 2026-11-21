class_name HighcrownArt
extends Node3D
## Dresses the Highcrown backdrop (wall, towers, keep) with detail: stone texture,
## battlements, a gatehouse with a dark arch, hanging White Knight banners, lit
## windows and a few torches. Backdrop only (you cannot enter yet), so no collision.
## The wall runs along x at z = 0 and faces south (+z), where the road arrives.

const STONE := preload("res://levels/common/materials/stone.tres")
const CLOTH := preload("res://levels/common/materials/cloth_white.tres")
const IRON := preload("res://levels/common/materials/iron.tres")
const DARK_WOOD := preload("res://levels/common/materials/dark_wood.tres")

const WALL_HALF := 70.0
const WALL_H := 18.0
const FRONT_Z := 3.0


func _ready() -> void:
	# Use the textured shared stone on the existing big shapes.
	for c in get_children():
		if c is MeshInstance3D:
			c.material_override = STONE
	_battlements(-WALL_HALF, WALL_HALF, WALL_H, FRONT_Z - 0.4)
	_battlements(-WALL_HALF, WALL_HALF, WALL_H, -FRONT_Z + 0.4)
	_gatehouse()
	_banners()
	_windows()
	_torches()
	_town()
	_beacons()
	_exempt_from_fog()


func _mat_emit(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m


func _add_box(pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi


func _battlements(x0: float, x1: float, y: float, z: float) -> void:
	var step := 3.2
	var count := int((x1 - x0) / step)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var bm := BoxMesh.new()
	bm.size = Vector3(1.6, 1.8, 1.0)
	mm.mesh = bm
	mm.instance_count = count
	for i in count:
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(x0 + (i + 0.5) * step, y + 0.9, z)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = STONE
	add_child(mmi)


func _gatehouse() -> void:
	# Two flanking blocks and a lintel make a gate; the arch itself is a dark recess.
	for sx in [-1.0, 1.0]:
		_add_box(Vector3(sx * 11.0, 13.0, FRONT_Z + 3.0), Vector3(9, 26, 8), STONE)
		_battlements_block(sx * 11.0, 26.0, FRONT_Z + 6.6)
	_add_box(Vector3(0, 22.0, FRONT_Z + 3.0), Vector3(14, 8, 8), STONE)
	# The opening: a black hollow, with a raised portcullis and iron bars.
	var hollow := StandardMaterial3D.new()
	hollow.albedo_color = Color(0.015, 0.012, 0.01)
	hollow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_add_box(Vector3(0, 7.0, FRONT_Z + 7.05), Vector3(10, 14, 0.2), hollow)
	for i in range(-4, 5):
		_add_box(Vector3(i * 1.1, 11.0, FRONT_Z + 7.2), Vector3(0.14, 6.0, 0.14), IRON)
	_add_box(Vector3(0, 8.1, FRONT_Z + 7.2), Vector3(10, 0.2, 0.2), IRON)
	_add_box(Vector3(0, 11.0, FRONT_Z + 7.2), Vector3(10, 0.2, 0.2), IRON)


func _battlements_block(x: float, y: float, z: float) -> void:
	for i in range(-3, 4, 2):
		_add_box(Vector3(x + i * 1.2, y + 0.9, z), Vector3(1.2, 1.8, 0.8), STONE)


func _banners() -> void:
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.55, 0.43, 0.2)
	gold.metallic = 0.6
	gold.roughness = 0.5
	var xs := [-60.0, -48.0, -36.0, -26.0, 26.0, 36.0, 48.0, 60.0]
	for x in xs:
		_add_box(Vector3(x, 12.0, FRONT_Z + 0.05), Vector3(2.4, 8.0, 0.1), CLOTH)
		_add_box(Vector3(x, 12.5, FRONT_Z + 0.12), Vector3(0.35, 5.0, 0.05), gold)
		_add_box(Vector3(x, 13.5, FRONT_Z + 0.12), Vector3(1.6, 0.35, 0.05), gold)
	# Two long banners down the gatehouse flanks.
	for sx in [-1.0, 1.0]:
		_add_box(Vector3(sx * 11.0, 16.0, FRONT_Z + 7.05), Vector3(3.0, 12.0, 0.1), CLOTH)
		_add_box(Vector3(sx * 11.0, 17.0, FRONT_Z + 7.12), Vector3(0.45, 8.0, 0.05), gold)
		_add_box(Vector3(sx * 11.0, 19.0, FRONT_Z + 7.12), Vector3(2.0, 0.45, 0.05), gold)


func _windows() -> void:
	# Warm lit windows on the keep's south face (keep centre z -25, depth 22 -> face z -14).
	var glow := _mat_emit(Color(1.0, 0.62, 0.26), 2.2)
	for row in 4:
		for col in range(-4, 5):
			if (row + col) % 3 == 0:
				continue
			_add_box(Vector3(col * 3.2, 14.0 + row * 8.0, -13.9), Vector3(0.9, 2.2, 0.15), glow)
	# A few on the towers too.
	for t in [-60.0, -20.0, 25.0, 65.0]:
		_add_box(Vector3(t, 30.0, 6.4), Vector3(0.8, 2.0, 0.15), glow)


func _torches() -> void:
	var flame := _mat_emit(Color(1.0, 0.55, 0.2), 4.0)
	for sx in [-1.0, 1.0]:
		_add_box(Vector3(sx * 5.8, 3.4, FRONT_Z + 7.0), Vector3(0.12, 1.2, 0.12), DARK_WOOD)
		_add_box(Vector3(sx * 5.8, 4.2, FRONT_Z + 7.0), Vector3(0.3, 0.4, 0.3), flame)
		var l := OmniLight3D.new()
		l.position = Vector3(sx * 5.8, 4.8, FRONT_Z + 8.0)
		l.light_color = Color(1.0, 0.6, 0.3)
		l.light_energy = 2.2
		l.omni_range = 18.0
		add_child(l)


# --- the town behind the wall -------------------------------------------------
# A hillside of crowded gabled houses climbing toward the keep, inside side and back
# walls, so from the road Highcrown reads as a small walled stronghold town.

const PLASTER := preload("res://levels/common/materials/plaster.tres")
const THATCH := preload("res://levels/common/materials/thatch.tres")
const WOOD := preload("res://levels/common/materials/wood.tres")

var _rng := RandomNumberGenerator.new()


func _slope_y(z: float) -> float:
	return maxf(0.0, -z) * 0.24


func _town() -> void:
	_rng.seed = 4242
	# Side and back curtain walls with a tower at each back corner.
	for sx in [-1.0, 1.0]:
		_add_box(Vector3(sx * WALL_HALF, 12.0, -36.0), Vector3(5, 24, 78), STONE)
	_add_box(Vector3(0, 20.0, -75.0), Vector3(145, 40, 5), STONE)
	for p in [Vector2(-WALL_HALF, -74.0), Vector2(WALL_HALF, -74.0)]:
		var t := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 5.5
		cm.bottom_radius = 6.2
		cm.height = 46.0
		cm.radial_segments = 10
		t.mesh = cm
		t.material_override = STONE
		t.position = Vector3(p.x, 23.0, p.y)
		add_child(t)
	# Terraced ground so the houses show over the front wall.
	for i in 8:
		var tz := -4.0 - i * 8.5
		_add_box(Vector3(0, _slope_y(tz) * 0.5, tz), Vector3(136, maxf(_slope_y(tz), 0.4), 8.6), STONE)
	# Houses on a loose grid, skipping the keep footprint and the main street.
	var z := -6.0
	while z > -70.0:
		var x := -62.0
		while x < 62.0:
			var w := _rng.randf_range(5.0, 8.5)
			var d := _rng.randf_range(5.0, 7.5)
			var in_keep := absf(x) < 20.0 and z < -10.0 and z > -40.0
			var in_street := absf(x) < 4.0
			if not in_keep and not in_street and _rng.randf() < 0.85:
				_house(Vector3(x + w * 0.5, _slope_y(z), z), w, d)
			x += w + _rng.randf_range(1.2, 2.5)
		z -= 9.0
	# Market square in front of the keep: stalls with cloth awnings.
	for i in 5:
		_stall(Vector3(-12.0 + i * 6.0, _slope_y(-9.0), -8.5))
	# A chapel-like hall with a tower, east side.
	var cy := _slope_y(-30.0)
	_add_box(Vector3(38.0, cy + 8.0, -30.0), Vector3(10, 16, 18), PLASTER)
	_roof(Vector3(38.0, cy + 16.0, -30.0), Vector3(11.5, 7.0, 19.5))
	_add_box(Vector3(38.0, cy + 14.0, -40.0), Vector3(5, 28, 5), STONE)
	_roof(Vector3(38.0, cy + 28.0, -40.0), Vector3(6.5, 8.0, 6.5))


func _house(pos: Vector3, w: float, d: float) -> void:
	var h := _rng.randf_range(4.5, 7.5)
	_add_box(pos + Vector3(0, h * 0.5, 0), Vector3(w, h, d), PLASTER)
	_add_box(pos + Vector3(0, h * 0.5, d * 0.5 + 0.03), Vector3(0.3, h, 0.1), WOOD)
	_add_box(pos + Vector3(0, h * 0.55, d * 0.5 + 0.03), Vector3(w, 0.3, 0.1), WOOD)
	_roof(pos + Vector3(0, h, 0), Vector3(w + 0.8, _rng.randf_range(3.0, 4.6), d + 0.8))
	if _rng.randf() < 0.6:
		_add_box(pos + Vector3(w * 0.28, h + 3.2, -d * 0.2), Vector3(0.8, 2.4, 0.8), STONE)
	if _rng.randf() < 0.5:
		_add_box(pos + Vector3(-w * 0.2, h * 0.55, d * 0.5 + 0.06),
				Vector3(0.9, 1.0, 0.1), _mat_emit(Color(1.0, 0.6, 0.25), 1.8))


func _roof(base: Vector3, size: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = size
	mi.mesh = pm
	mi.material_override = THATCH
	mi.position = base + Vector3(0, size.y * 0.5, 0)
	add_child(mi)


func _stall(pos: Vector3) -> void:
	for sx in [-1.2, 1.2]:
		_add_box(pos + Vector3(sx, 1.2, 0), Vector3(0.14, 2.4, 0.14), WOOD)
	_add_box(pos + Vector3(0, 0.55, 0.3), Vector3(2.8, 0.2, 1.0), WOOD)
	var awning := _add_box(pos + Vector3(0, 2.5, 0), Vector3(3.2, 0.12, 2.0), CLOTH)
	awning.rotation_degrees = Vector3(-10, 0, 0)


# --- visible from afar ----------------------------------------------------------
# Highcrown is 350 m from the start altar, far beyond where the zone fog hides things.
# It is exempt from distance fog (a dark, cold silhouette with warm lights), so the
# stronghold can be seen from the first shrine.

func _beacons() -> void:
	var flame := _mat_emit(Color(1.0, 0.55, 0.2), 6.0)
	flame.disable_fog = true
	for t in [Vector2(-WALL_HALF, -74.0), Vector2(WALL_HALF, -74.0), Vector2(-60, 0), Vector2(65, 1), Vector2(-20, 2), Vector2(25, 0)]:
		_add_box(Vector3(t.x, 46.0 if t.y < -50.0 else 38.0, t.y), Vector3(2.4, 1.4, 2.4), flame)
	_add_box(Vector3(6, 82.0, -28), Vector3(1.6, 2.4, 1.6), flame)


func _exempt_from_fog() -> void:
	var cache := {}
	for c in get_children():
		var mi := c as GeometryInstance3D
		if mi != null:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if mi == null or mi.material_override == null:
			continue
		var src := mi.material_override as BaseMaterial3D
		if src == null:
			continue
		if not cache.has(src):
			var m := src.duplicate() as BaseMaterial3D
			m.disable_fog = true
			if not m.emission_enabled:
				m.albedo_color = m.albedo_color * Color(0.62, 0.66, 0.74, 1.0)
			cache[src] = m
		mi.material_override = cache[src]
