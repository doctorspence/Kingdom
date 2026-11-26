class_name SpawnPoint
extends Marker3D
## A place where enemies appear. Each reset (start of the world, and whenever
## someone rests) rolls its table. Put several around a zone (DESIGN.md 8.3).

@export var table: SpawnTable
## Enemies are placed within this radius around the point.
@export var radius := 3.0
## Optional patrol route, relative to the point (they walk it in a loop).
@export var patrol := PackedVector3Array()
## Only spawn when at least this many players are in the world (3+ / 6+ extras).
@export var min_players := 1
## A named rare that sometimes replaces the normal roll.
@export var named_scene: PackedScene
@export_range(0.0, 1.0) var named_chance := 0.05

## Underground spawns keep their own height instead of snapping to the terrain.
@export var snap_to_terrain := true
## Don't reroll while a player is this close (meters). -1 = the director's default.
@export var reset_distance := -1.0

## What its enemies do before a fight (ENEMY_LIFE_PLAN.md). "auto": groups stand
## together facing each other (lookouts keep watch, patrols walk). "watch": keep
## watch the way the point faces (its -Z, the blue arrow's back), scanning left and
## right, and see farther in that direction.
@export_enum("auto", "watch") var post := "auto"
## Watchers lean on a rail or palisade in front of them.
@export var watch_rail := false
## Its enemies stand on a tower, wall top or ledge and never move from it (they turn, shoot
## and fight from there). Turn off snap_to_terrain too, so they keep the point's height.
@export var perch := false

## Host only: the enemies this point made, still in the world.
var spawned: Array[Node] = []


func _ready() -> void:
	add_to_group(&"spawn_points")
