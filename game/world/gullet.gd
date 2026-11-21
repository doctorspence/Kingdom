class_name Gullet
extends Node3D
## The Gullet: a cave dungeon under the quarry (DESIGN.md 11.2), built from a
## solid block of rock with rooms and corridors carved out of it.
## Coordinates are local meters: x east, z south, the floor is y = 0.
##
##   A  entrance hall (the way up)      B  bone gallery      C  cistern
##   D  shrine alcove                   E  Brother Tallow's chapel (behind the fog gate)
##   A long corridor from E back to A opens after the first boss kill.

## [center x, center z, width, depth, height]
const CARVES := [
	[0, 40, 18, 14, 7],         # A entrance hall
	[0, 26, 5, 14.4, 5],        # A -> B
	[0, 8, 24, 22, 8],          # B bone gallery
	[0, -8.5, 5, 11.4, 5],      # B -> C
	[0, -24, 26, 20, 8],        # C cistern
	[-18.5, -24, 11.4, 5, 5],   # C -> D
	[-30, -24, 12, 12, 7],      # D shrine alcove
	[-30, -39, 5, 18.4, 5],     # D -> fog gate -> E
	[-30, -62, 26, 28, 12],     # E chapel
	[1, -62, 36.4, 5, 5],       # E -> east (the shortcut)
	[19, -11, 5, 102.4, 5],     # the long way back south
	[14, 40, 12.4, 5, 5],       # into A
]
## Rock around everything: [center x, y, z, width, height, depth].
const ROCK := [-9.0, 5.5, -14.0, 78.0, 17.0, 132.0]
## Candle lights: [x, z, brightness]
const CANDLES := [
	[-6, 42, 0.8], [6, 42, 0.8], [0, 30, 0.5], [-8, 14, 0.7], [8, 14, 0.7], [-8, 2, 0.7], [8, 2, 0.7],
	[0, -8, 0.5], [-9, -20, 0.8], [9, -20, 0.8], [-9, -29, 0.8], [9, -29, 0.8], [-18, -24, 0.5],
	[-30, -39, 0.5], [-40, -52, 1.0], [-20, -52, 1.0], [-40, -72, 1.0], [-20, -72, 1.0], [-30, -62, 1.2],
	[-8, -62, 0.5], [19, -30, 0.4], [19, 10, 0.4],
]


func _ready() -> void:
	var combiner := CSGCombiner3D.new()
	combiner.use_collision = true
	var mat: Material = load("res://levels/common/materials/dark_stone.tres")
	var rock := CSGBox3D.new()
	rock.position = Vector3(ROCK[0], ROCK[1], ROCK[2])
	rock.size = Vector3(ROCK[3], ROCK[4], ROCK[5])
	rock.material = mat
	combiner.add_child(rock)
	for c in CARVES:
		var box := CSGBox3D.new()
		box.operation = CSGShape3D.OPERATION_SUBTRACTION
		box.position = Vector3(c[0], c[4] * 0.5, c[1])
		box.size = Vector3(c[2], c[4], c[3])
		box.material = mat
		combiner.add_child(box)
	# Pillars in the chapel and the bone gallery.
	for p in [Vector2(-40, -54), Vector2(-20, -54), Vector2(-40, -70), Vector2(-20, -70), Vector2(-8, 4), Vector2(8, 4), Vector2(-8, 13), Vector2(8, 13)]:
		var pillar := CSGBox3D.new()
		pillar.position = Vector3(p.x, 3.5, p.y)
		pillar.size = Vector3(1.6, 7.0 if p.y < -50 else 6.0, 1.6)
		pillar.material = load("res://levels/common/materials/stone.tres")
		combiner.add_child(pillar)
	add_child(combiner)
	for c in CANDLES:
		var l := OmniLight3D.new()
		l.position = Vector3(c[0], 2.2, c[1])
		l.light_color = Color(1.0, 0.7, 0.4)
		l.light_energy = c[2] * 3.0
		l.omni_range = 15.0
		l.omni_attenuation = 1.4
		add_child(l)
