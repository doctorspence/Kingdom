extends Node3D
## The quarry's workings that tell it was dug by people, built from QuarryKit:
## stacks of squared blocks ready to cart away, blocks half cut out of the
## terrace faces, and a shear-legs crane of oak poles with its rope and hook on
## the high bench. Positions are world x, z; heights come from the terrain.
## Everything stays clear of the path from the lane to the Gullet's door and of
## the enemy spawns on the quarry floor.

@export var terrain: SculptedTerrain

## Stacks of blocks: [x, z, yaw degrees, rows].
const STACKS := [[-137.0, -107.0, 20.0, 3], [-157.5, -104.6, -8.0, 2], [-133.5, -92.5, 70.0, 2]]
## Blocks still half in the face: [x, z, yaw].
const HALF_CUT := [[-160.0, -107.6, 0.0], [-151.5, -107.7, 3.0], [-147.0, -107.5, -4.0], [-169.6, -108.0, 90.0]]
## The shear-legs crane on the high bench, leaning out over the floor: [x, z, yaw].
const CRANE := [-158.0, -114.4, 0.0]


func _ready() -> void:
	_build.call_deferred()


func _build() -> void:
	if terrain == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 5150
	var body := StaticBody3D.new()
	add_child(body)
	for s: Array in STACKS:
		var base := _ground(s[0], s[1])
		var yaw := deg_to_rad(float(s[2]))
		var rows: int = s[3]
		for r in rows:
			var count := rows - r + 1
			for i in count:
				var off := Vector3((i - (count - 1) * 0.5) * 1.75, r * 0.72, rng.randf_range(-0.05, 0.05))
				_block("block", rng.randi() % 4, base + off.rotated(Vector3.UP, yaw), yaw + rng.randf_range(-0.05, 0.05), body)
		_block("block_broken", rng.randi() % 4, base + Vector3(2.6, 0, 1.2).rotated(Vector3.UP, yaw), rng.randf() * TAU, null)
	for h: Array in HALF_CUT:
		# Sits on the floor, its back buried in the terrace face behind it.
		var hx: float = h[0]
		var hz: float = h[1]
		var floor_y := terrain.height_at(hx + sin(deg_to_rad(float(h[2]))) * 1.2, hz + cos(deg_to_rad(float(h[2]))) * 1.2)
		_block("block", rng.randi() % 4, Vector3(hx, floor_y - 0.05, hz), deg_to_rad(float(h[2])), body)
	_crane(rng)


func _ground(x: float, z: float) -> Vector3:
	return Vector3(x, terrain.height_at(x, z), z)


func _block(kind: String, v: int, pos: Vector3, yaw: float, body: StaticBody3D) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = QuarryKit.mesh(kind, v)
	mi.position = pos - global_position
	mi.rotation.y = yaw
	add_child(mi)
	if body:
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		var box := mi.mesh.get_aabb()
		sh.size = box.size * 0.95
		cs.shape = sh
		cs.position = mi.position + (box.get_center()).rotated(Vector3.UP, yaw)
		cs.rotation.y = yaw
		body.add_child(cs)


## Two oak legs spread at the foot, meeting 7 m up and leaning out over the
## terraces; a back stay rope to a stake; a pulley rope with a hook and a block in a sling.
func _crane(rng: RandomNumberGenerator) -> void:
	var base := _ground(CRANE[0], CRANE[1])
	var yaw := deg_to_rad(float(CRANE[2]))
	var apex := base + Vector3(0, 7.0, 3.4).rotated(Vector3.UP, yaw)
	var wood := QuarryKit.timber_material()
	var rope := load("res://assets/hideout/Materials/rope.tres") as Material
	for side: float in [-1.0, 1.0]:
		var foot := base + Vector3(side * 1.8, 0, 0).rotated(Vector3.UP, yaw)
		_pole(foot, apex + Vector3(side * 0.12, 0.3, 0), 0.14, wood)
	_pole(apex, base + Vector3(0, 0, -4.5).rotated(Vector3.UP, yaw), 0.025, rope)
	var hook := apex + Vector3(0, -4.2, 0)
	_pole(apex, hook, 0.025, rope)
	_block("block", 2, hook + Vector3(0, -0.75, 0), yaw + 0.3, null)
	_pole(hook, hook + Vector3(0.7, -0.75, 0), 0.02, rope)
	_pole(hook, hook + Vector3(-0.7, -0.75, 0), 0.02, rope)


func _pole(a: Vector3, b: Vector3, r: float, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r * 0.85
	cm.bottom_radius = r
	cm.height = a.distance_to(b)
	cm.radial_segments = 8
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = mat
	add_child(mi)
	var mid := (a + b) * 0.5
	var up := (b - a).normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
	mi.global_transform = Transform3D(Basis(side, up, side.cross(up)).orthonormalized(), mid)
