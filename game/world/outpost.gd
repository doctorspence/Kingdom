extends Node3D
## Places the White Knights Outpost in the zone from levels/tithelands/outpost_layout.gd: every
## asset (baked scenes in assets/outpost/) stands on the terrain under it. Also builds the moat's
## water in front of Highcrown and the lowered drawbridge to its gate. Everyone sees the same
## layout (no randomness). Loaded with preload, no class_name.

const Layout := preload("res://levels/tithelands/outpost_layout.gd")
const HK := preload("res://assets/hideout/Materials/kit.gd")
const K := preload("res://assets/outpost/materials/outpost_kit.gd")
const WATER := preload("res://levels/common/materials/water.tres")

@export var terrain: ZoneTerrain

var placed := 0


func _ready() -> void:
	if terrain == null:
		terrain = get_node_or_null("../Terrain") as ZoneTerrain
	var cache := {}
	for g: Array in Layout.GROUPS:
		var centre := Vector2(g[0], g[1])
		var turn := deg_to_rad(float(g[2]))
		var group := Node3D.new()
		group.name = "Group%d" % get_child_count()
		add_child(group)
		for it: Array in g[3]:
			var path := "res://assets/outpost/%s.scn" % it[0]
			if not cache.has(path):
				cache[path] = load(path)
			var ps := cache[path] as PackedScene
			if ps == null:
				push_warning("Outpost: missing %s" % path)
				continue
			var local := Vector2(it[1], it[2])
			var off := Vector2(local.x * cos(turn) + local.y * sin(turn), -local.x * sin(turn) + local.y * cos(turn))
			var p := centre + off
			var n := ps.instantiate() as Node3D
			n.position = Vector3(p.x, _ground(p.x, p.y) + float(it[4]), p.y)
			n.rotation.y = turn + deg_to_rad(float(it[3]))
			group.add_child(n)
			placed += 1
	_moat_and_bridge()


func _ground(x: float, z: float) -> float:
	return terrain.height_at(x, z) if terrain else 0.0


## The moat's water (beyond the north edge, so only seen) and the drawbridge lowered across it.
func _moat_and_bridge() -> void:
	var m: Dictionary = Layout.MOAT
	var mid := (float(m.z0) + float(m.z1)) * 0.5
	var level := _ground(0.0, float(m.z0) - 1.0) - float(m.depth) + float(m.water)
	var water := MeshInstance3D.new()
	water.name = "MoatWater"
	var pm := PlaneMesh.new()
	pm.size = Vector2(float(m.hx) * 2.0, absf(float(m.z1) - float(m.z0)) + 2.0)
	water.mesh = pm
	water.material_override = WATER
	water.position = Vector3(0, level, mid)
	add_child(water)
	# The drawbridge: an oak deck 12 m wide from the near bank to the gate, iron-bound, on chains.
	var b := HK.MB.new(1300)
	var oak := K.oak()
	var near := float(m.z0) + 1.5
	var far := Layout.HIGHCROWN.z + 10.0
	var y0 := _ground(0.0, near) + 0.1
	var y1 := Layout.HIGHCROWN.y + 0.15
	var len_ := absf(far - near)
	var bas := Basis(Vector3(1, 0, 0), atan2(y1 - y0, len_))
	var c := Vector3(0, (y0 + y1) * 0.5, (near + far) * 0.5)
	b.box(oak, c, Vector3(12.0, 0.35, len_ + 0.4), bas, 0.01)
	for i in 7:
		var x := -5.4 + i * 1.8
		b.box(K.iron(), c + bas * Vector3(x, 0.19, 0), Vector3(0.12, 0.04, len_ + 0.3), bas)
	for s in [-1.0, 1.0]:
		var a := Vector3(s * 5.8, y1 + 0.2, far + 0.3)
		var top := Vector3(s * 6.5, Layout.HIGHCROWN.y + 12.5, Layout.HIGHCROWN.z + 9.5)
		for j in 12:
			var p := a.lerp(top, float(j) / 11.0)
			K.ring(b, K.iron(), p, Vector3(1, 0, 0) if j % 2 else Vector3(0, 0, 1), 0.09, 0.025, 6, 4)
	var bridge := K.asset("Drawbridge", b, [["box", c, Vector3(12.0, 0.35, len_), bas]])
	add_child(bridge)
