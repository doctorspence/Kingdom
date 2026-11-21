class_name Camp
extends Shrine
## The camp (DESIGN.md 11.5): a cold fire pit anyone can claim, which then
## works as a shrine (the Camp Hearth), can be upgraded, and is raided at
## night. Everything about it is a world flag, so it is shared by everyone and
## saved with the world. Raids are run by CampRaids (a child, host only).
##
## It is a Shrine with a different script, so resting, the bank, travel and the
## map all work for free; it just stays "inactive" while unclaimed or cold.

const CLAIM_COST := 100
const RELIGHT_COST := 50
## Coins for upgrade level 1, 2, 3.
const UPGRADE_COSTS := [150, 400, 900]
const MAX_LEVEL := 3

## The upgrades: id -> [name, what each level does].
const UPGRADES := {
	&"palisade": ["Palisade", "Stakes ring the camp. Raiders drain the camp's strength 25% slower per level."],
	&"watch": ["Watchfires", "Level 1: the horn warns you early and names the direction. Level 2: raiders show on the map. Level 3: raiders see less near the camp."],
	&"stores": ["Stores", "A better chest when you win a raid (more items, better rarity)."],
}

const FLAG_CLAIMED := &"camp_claimed"
const FLAG_COLD := &"camp_cold"
const FLAG_WINS := &"camp_raids_won"
const FLAG_FIRST_RAID := &"camp_first_raid_done"

## Palisade: how far from the hearth, how many posts, and the gap (the gate)
## which faces the Crossroads (west).
const RING_RADIUS := 10.0
const RING_POSTS := 24
const GATE_POSTS := 3
const WATCH_RADIUS := 14.0

var raids: CampRaids

var _decor: Node3D
var _terrain: ZoneTerrain
var _wood: StandardMaterial3D
var _shown := ""


func _ready() -> void:
	super._ready()
	add_to_group(&"camp")
	_terrain = get_tree().get_first_node_in_group(&"zone_terrain") as ZoneTerrain
	_wood = StandardMaterial3D.new()
	_wood.albedo_color = Color(0.3, 0.22, 0.14)
	_wood.roughness = 0.95
	_decor = Node3D.new()
	_decor.name = "Decor"
	add_child(_decor)
	WorldState.flag_changed.connect(func(_k: StringName, _v: Variant) -> void: _rebuild_if_changed())
	raids = CampRaids.new()
	raids.name = "Raids"
	raids.camp = self
	add_child(raids)
	_rebuild_if_changed()


# --- The state (all world flags) -------------------------------------------------------

func is_claimed() -> bool:
	return bool(WorldState.get_flag(FLAG_CLAIMED, false))


func is_cold() -> bool:
	return bool(WorldState.get_flag(FLAG_COLD, false))


func is_active() -> bool:
	return is_claimed() and not is_cold()


func level(kind: StringName) -> int:
	return clampi(int(WorldState.get_flag(StringName("camp_" + String(kind)), 0)), 0, MAX_LEVEL)


## Total of all upgrade levels (0..9): how well kept the camp is.
func total_level() -> int:
	var n := 0
	for kind in UPGRADES:
		n += level(kind)
	return n


func wins() -> int:
	return int(WorldState.get_flag(FLAG_WINS, 0))


## Price of the next level of an upgrade, or -1 if it is maxed.
func next_cost(kind: StringName) -> int:
	var lv := level(kind)
	return -1 if lv >= MAX_LEVEL else UPGRADE_COSTS[lv]


# --- Using it ---------------------------------------------------------------------------

func get_interact_text() -> String:
	if not is_claimed():
		return "Claim the camp (%d coins)" % CLAIM_COST
	if is_cold():
		return "Relight the hearth (%d coins)" % RELIGHT_COST
	return "Use the Camp Hearth (rest, travel, bank, upgrades)"


func interact(player: Node3D) -> void:
	if not is_claimed():
		var why := claim(player as Player)
		if why != "":
			CombatFx.word(global_position + Vector3.UP * 2.6, why)
		return
	if is_cold():
		var why2 := relight(player as Player)
		if why2 != "":
			CombatFx.word(global_position + Vector3.UP * 2.6, why2)
		return
	super.interact(player)


func claim(player: Player) -> String:
	if is_claimed():
		return "Already claimed"
	var why := _pay(player, CLAIM_COST)
	if why != "":
		return why
	WorldState.set_flag(FLAG_CLAIMED, true)
	CombatFx.word(global_position + Vector3.UP * 2.6, "The camp is yours")
	Audio.sfx(&"shrine_rest", global_position + Vector3.UP * 1.5)
	return ""


func relight(player: Player) -> String:
	if not is_cold():
		return "The hearth is lit"
	var why := _pay(player, RELIGHT_COST)
	if why != "":
		return why
	WorldState.set_flag(FLAG_COLD, false)
	CombatFx.word(global_position + Vector3.UP * 2.6, "The hearth burns again")
	Audio.sfx(&"shrine_rest", global_position + Vector3.UP * 1.5)
	return ""


## Buy the next level of an upgrade. Returns "" or why not.
func upgrade(kind: StringName, player: Player) -> String:
	if not UPGRADES.has(kind):
		return "No such upgrade"
	if not is_active():
		return "The hearth is cold"
	var cost := next_cost(kind)
	if cost < 0:
		return "Already at the highest level"
	var why := _pay(player, cost)
	if why != "":
		return why
	WorldState.set_flag(StringName("camp_" + String(kind)), level(kind) + 1)
	CombatFx.word(global_position + Vector3.UP * 2.6, "%s improved" % UPGRADES[kind][0])
	Audio.sfx(&"equip")
	return ""


func _pay(player: Player, coins: int) -> String:
	if player == null:
		return "No one is here"
	if player.inventory.coins < coins:
		return "Not enough coins (%d)" % coins
	player.inventory.coins -= coins
	player.inventory.changed.emit()
	return ""


# --- Light and looks ----------------------------------------------------------------------

func _process(delta: float) -> void:
	if is_active():
		super._process(delta)
	else:
		# Cold: only a few embers.
		_light.light_energy = lerpf(_light.light_energy, 0.25, 0.1)


func _rebuild_if_changed() -> void:
	var key := "%s/%s/%d/%d/%d" % [is_claimed(), is_cold(), level(&"palisade"), level(&"watch"), level(&"stores")]
	if key == _shown:
		return
	_shown = key
	for c in _decor.get_children():
		c.queue_free()
	if not is_claimed():
		return
	_build_banner()
	_build_palisade(level(&"palisade"))
	_build_watchfires(level(&"watch"))
	_build_stores(level(&"stores"))


func _ground(x: float, z: float) -> float:
	return _terrain.height_at(x, z) if _terrain else global_position.y


## A point at (dx, dz) from the hearth, on the ground, in world space.
func _spot(dx: float, dz: float) -> Vector3:
	var p := global_position + Vector3(dx, 0.0, dz)
	return Vector3(p.x, _ground(p.x, p.z), p.z)


func _add_box(size: Vector3, at: Vector3, solid := false, material: Material = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = material if material else _wood
	_decor.add_child(mi)
	mi.global_position = at + Vector3.UP * size.y * 0.5
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		mi.add_child(body)
	return mi


func _build_banner() -> void:
	var pole := _spot(3.0, -2.0)
	_add_box(Vector3(0.12, 3.6, 0.12), pole)
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color(0.5, 0.45, 0.32)
	cloth.roughness = 1.0
	var flag := _add_box(Vector3(0.05, 1.1, 0.8), pole + Vector3(0, 2.3, 0.46), false, cloth)
	flag.rotation_degrees.y = 8.0


func _build_palisade(lv: int) -> void:
	if lv <= 0:
		return
	for i in RING_POSTS:
		# Posts i%3 < lv are built: a third of them at level 1, two thirds at 2, all at 3.
		if i % 3 >= lv:
			continue
		var angle := TAU * i / RING_POSTS
		# The gate: no posts in the arc facing west (toward the Crossroads).
		var from_west := absf(wrapf(angle - PI, -PI, PI))
		if from_west < TAU * GATE_POSTS / RING_POSTS * 0.5:
			continue
		var at := _spot(cos(angle) * RING_RADIUS, sin(angle) * RING_RADIUS)
		var post := _add_box(Vector3(0.45, 2.4, 0.45), at, true)
		post.rotation.y = angle
		# A sharpened tip.
		var tip := _add_box(Vector3(0.3, 0.35, 0.3), at + Vector3.UP * 2.4)
		tip.rotation_degrees = Vector3(0, 45, 0)


func _build_watchfires(lv: int) -> void:
	if lv <= 0:
		return
	var count := lv * 3
	var flame := StandardMaterial3D.new()
	flame.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame.albedo_color = Color(1.0, 0.6, 0.25)
	flame.emission_enabled = true
	flame.emission = Color(1.0, 0.55, 0.22)
	flame.emission_energy_multiplier = 4.0
	for i in count:
		var angle := TAU * i / count + 0.3
		var at := _spot(cos(angle) * WATCH_RADIUS, sin(angle) * WATCH_RADIUS)
		_add_box(Vector3(0.14, 2.2, 0.14), at)
		var fire := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.16
		sphere.height = 0.4
		fire.mesh = sphere
		fire.material_override = flame
		fire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_decor.add_child(fire)
		fire.global_position = at + Vector3.UP * 2.35
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.65, 0.3)
		light.light_energy = 1.6
		light.omni_range = 8.0
		fire.add_child(light)


func _build_stores(lv: int) -> void:
	if lv <= 0:
		return
	var count: int = [0, 2, 5, 8][lv]
	for i in count:
		var angle := TAU * i / 8.0 + 0.5
		var at := _spot(cos(angle) * 4.5, sin(angle) * 4.5)
		var crate := _add_box(Vector3(0.9, 0.9, 0.9), at, true)
		crate.rotation.y = angle * 2.0
		if i % 2 == 1:
			_add_box(Vector3(0.7, 0.7, 0.7), at + Vector3.UP * 0.9).rotation.y = angle


## Where raiders are drawn to, and the camp's reach for raids (meters).
func center() -> Vector3:
	return global_position


## The sight-range multiplier near the camp at Watchfires level 3 (see Enemy).
func raider_sight_mult() -> float:
	return 0.6 if level(&"watch") >= 3 else 1.0
