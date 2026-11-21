class_name CampRaids
extends Node
## Night raids on the camp (DESIGN.md 11.5). The host runs everything; every
## machine gets the status (for the HUD) and the messages.
##
## A raid: at dusk, a claimed, lit camp with a player nearby may be raided. A
## band of ordinary enemies appears 70-90 m out and marches to the camp. While
## raiders stand near the hearth the camp's strength drains. Kill them all
## before it hits 0 and before dawn to win a chest of spoils.

signal message(text: String)

const MARAUDER := preload("res://game/enemies/marauder.tscn")
const ZEALOT := preload("res://game/enemies/zealot.tscn")
const HOUND := preload("res://game/enemies/hound.tscn")
const LOOT := preload("res://data/loot/loot_raid.tres")

## Raiders within this distance of the hearth drain the camp.
const DRAIN_RADIUS := 12.0
## Strength lost per raider per second (percent), before the palisade helps.
const DRAIN_PER_RAIDER := 1.6
## Chance of a raid on a night after the first.
const CHANCE := 0.6
## A raid needs a player this close to the camp.
const PLAYER_RANGE := 120.0
const SPAWN_DISTANCE := Vector2(70.0, 90.0)
const MAX_RAIDERS := 14
const COMPASS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]

var camp: Camp
var active := false
## Camp strength, 100 down to 0.
var strength := 100.0
var raiders: Array[Enemy] = []
var total := 0
## The compass bearing raiders come from (degrees, 0 = east; math angle in the x/z plane).
var bearing := 0.0
## Optional: where raiders are placed under (tests set this).
var enemies_root: Node3D

var _was_night := false
var _rng := RandomNumberGenerator.new()
var _sync_timer := 0.0
var _counter := 0


func _ready() -> void:
	_rng.randomize()
	_was_night = DayNight.night > 0.5
	multiplayer.peer_connected.connect(func(id: int) -> void:
		if multiplayer.is_server() and active:
			_net_status.rpc_id(id, active, strength, raiders.size(), total, bearing))


func _process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	var night := DayNight.night > 0.5
	if night and not _was_night:
		_dusk()
	elif not night and _was_night and active:
		end_raid(&"fled")
	_was_night = night
	if not active:
		return
	_tick(delta)


# --- Starting ----------------------------------------------------------------------------

func _dusk() -> void:
	if active or camp == null or not camp.is_active():
		return
	if not _player_near():
		return
	var first_done := bool(WorldState.get_flag(Camp.FLAG_FIRST_RAID, false))
	if first_done and _rng.randf() >= CHANCE:
		return
	start_raid()


func _player_near() -> bool:
	for n in get_tree().get_nodes_in_group(&"player"):
		if (n as Node3D).global_position.distance_to(camp.global_position) <= PLAYER_RANGE:
			return true
	return false


## How many raiders a raid has right now.
func raid_size() -> int:
	var players := maxi(get_tree().get_nodes_in_group(&"player").size(), 1)
	return clampi(3 + camp.total_level() / 3 + 2 * (players - 1), 3, MAX_RAIDERS)


## Begin a raid now (dusk calls this; tests and debugging can too). Host only.
func start_raid(count := -1) -> void:
	if not multiplayer.is_server() or active:
		return
	var n := raid_size() if count < 0 else clampi(count, 1, MAX_RAIDERS)
	bearing = _rng.randf() * 360.0
	var root := _root()
	if root == null:
		return
	var players := maxi(get_tree().get_nodes_in_group(&"player").size(), 1)
	raiders.clear()
	for i in n:
		var scene: PackedScene = _pick_scene()
		var e := scene.instantiate() as Enemy
		_counter += 1
		e.name = "Raider_%d_%d" % [_counter, Time.get_ticks_msec() % 100000]
		var p := _find_spot()
		e.position = p
		# Walk to the camp and pace around it until someone shows up.
		var toward := (camp.global_position - p)
		toward.y = 0.0
		toward = toward.normalized()
		e.patrol_points = PackedVector3Array([
				camp.global_position + toward * -3.0 + Vector3.UP * 0.1,
				camp.global_position + toward * 3.0 + Vector3.UP * 0.1])
		e.rotation.y = atan2(-toward.x, -toward.z)
		root.add_child(e, true)
		e.remove_from_group(&"respawn_on_rest")  # resting must not undo a raid
		e.add_to_group(&"raiders")
		e.set_party_size(players)
		e.sight_scale = camp.raider_sight_mult()
		e._spawn = Transform3D(e.global_basis, camp.global_position)  # "home" is the camp
		raiders.append(e)
	total = raiders.size()
	strength = 100.0
	active = true
	var text := "Raiders approach the camp!"
	if camp.level(&"watch") >= 1:
		text += "\nThey come from the %s." % compass_name()
	_say(text)
	_horn.rpc()
	_send_status()


## A place for one raider: 70-90 m from the camp toward the raid's bearing, but
## inside the zone's walls and on dry land. It tries a few nearby bearings and,
## if everything is water or out of bounds, uses the last one it tried.
func _find_spot() -> Vector3:
	var p := camp.global_position
	for attempt in 14:
		var wobble := _rng.randf_range(-20.0, 20.0) + attempt * 14.0 * (1.0 if attempt % 2 == 0 else -1.0)
		var angle := deg_to_rad(bearing + wobble)
		var dist := _rng.randf_range(SPAWN_DISTANCE.x, SPAWN_DISTANCE.y)
		p = camp.global_position + Vector3(cos(angle), 0.0, sin(angle)) * dist
		if camp._terrain:
			var half := camp._terrain.size * 0.5 - 14.0  # keep clear of the edge walls
			p.x = clampf(p.x, -half, half)
			p.z = clampf(p.z, -half, half)
		var ground := camp._ground(p.x, p.z)
		var dry := camp._terrain == null or ground > camp._terrain.water_level_at(p.x, p.z) + 0.4
		if dry and p.distance_to(camp.global_position) >= SPAWN_DISTANCE.x * 0.6:
			p.y = ground + 0.1
			return p
	p.y = camp._ground(p.x, p.z) + 0.1
	return p


func _pick_scene() -> PackedScene:
	var r := _rng.randf()
	if r < 0.5:
		return MARAUDER
	if r < 0.8:
		return ZEALOT
	return HOUND


func compass_name() -> String:
	var i := int(round(fposmod(-bearing, 360.0) / 45.0)) % 8  # (z grows southward on screen)
	return COMPASS[i]


func _root() -> Node3D:
	if enemies_root and is_instance_valid(enemies_root):
		return enemies_root
	for n in get_tree().get_nodes_in_group(&"spawn_directors"):
		var r := (n as SpawnDirector).enemies_root
		if r:
			return r
	# Beside the camp's own parent, or wherever the other enemies live.
	var up := camp.get_parent()
	var holder := up.get_parent() if up else null
	var e := holder.get_node_or_null("Enemies") if holder else null
	if e == null:
		for n in get_tree().get_nodes_in_group(&"enemies"):
			if n.get_parent() is Node3D:
				return n.get_parent() as Node3D
	return e as Node3D if e else holder as Node3D


# --- During the raid -------------------------------------------------------------------------

func _tick(delta: float) -> void:
	var alive: Array[Enemy] = []
	var inside := 0
	for e in raiders:
		if not is_instance_valid(e) or e.is_queued_for_deletion() or e.state == Enemy.State.DEAD:
			continue
		alive.append(e)
		var flat := e.global_position - camp.global_position
		flat.y = 0.0
		if flat.length() <= DRAIN_RADIUS:
			inside += 1
	raiders = alive
	var slow := 1.0 - 0.25 * camp.level(&"palisade")
	strength = maxf(0.0, strength - inside * DRAIN_PER_RAIDER * slow * delta)
	if raiders.is_empty():
		end_raid(&"won")
		return
	if strength <= 0.0:
		end_raid(&"overrun")
		return
	_sync_timer -= delta
	if _sync_timer <= 0.0:
		_sync_timer = 0.5
		_send_status()


## Finish the raid: &"won", &"overrun" or &"fled" (dawn). Host only.
func end_raid(result: StringName) -> void:
	if not multiplayer.is_server() or not active:
		return
	active = false
	WorldState.set_flag(Camp.FLAG_FIRST_RAID, true)
	match result:
		&"won":
			strength = 100.0
			WorldState.set_flag(Camp.FLAG_WINS, camp.wins() + 1)
			_give_reward()
			_say("The raid is repelled!\nA chest of spoils lies by the hearth.", &"pile_recover")
		&"overrun":
			_clear_raiders()
			WorldState.set_flag(Camp.FLAG_COLD, true)
			_say("The camp is overrun!\nThe hearth has gone cold.", &"death_sting")
		_:
			_clear_raiders()
			_say("Dawn comes. The raiders slink off.")
	_send_status()


func _clear_raiders() -> void:
	for e in raiders:
		if is_instance_valid(e):
			e.queue_free()
	raiders.clear()


## The raid chest: ordinary drops, thrown down at the hearth (everyone nearby
## shares the coins, souls and XP, and rolls for the items). The Stores upgrade
## makes it better.
func _give_reward() -> void:
	var table := LOOT.duplicate() as LootTable
	var stores := camp.level(&"stores")
	table.item_count = Vector2i(1 + stores, 1 + stores)
	table.guaranteed_min_rarity = [1, 1, 2, 2][stores]
	table.rarity_weights = PackedFloat32Array([40.0, 32.0, 18.0 + 4.0 * stores, 8.0 + 2.0 * stores, 1.0 + stores])
	table.coins = table.coins * (1 + stores)
	table.souls = table.souls * (1 + stores)
	Loot.enemy_died(camp, table, 120 + 60 * camp.total_level())


# --- Telling everyone ------------------------------------------------------------------------

func _say(text: String, cue := &"") -> void:
	_net_message.rpc(text, cue)


@rpc("authority", "call_local", "reliable")
func _net_message(text: String, cue := &"") -> void:
	if cue != &"":
		Audio.sfx(cue)
	message.emit(text)


@rpc("authority", "call_local", "reliable")
func _horn() -> void:
	Audio.sfx(&"horn", camp.global_position + Vector3.UP * 2.0)


func _send_status() -> void:
	_net_status.rpc(active, strength, raiders.size(), total, bearing)


## What the HUD shows (copied on every machine).
@rpc("authority", "call_local", "reliable")
func _net_status(is_active: bool, s: float, left: int, of: int, bear: float) -> void:
	active = is_active
	strength = s
	total = of
	bearing = bear
	_left = left


## Raiders left, as everyone sees it.
var _left := 0


func raiders_left() -> int:
	return raiders.size() if multiplayer.is_server() else _left
