class_name Player
extends CharacterBody3D
## The player character: movement, rolling, jumping, stamina, health, falls,
## attacks, blocking, parrying, flasks, class abilities and taking hits.
##
## Movement numbers come from data/balance/player_tuning.tres; class, weapon
## and ability numbers from the files in data/.
## The character is in one "state" at a time:
##   MOVE        on the ground: walk, run, sprint, block
##   AIR         jumping or falling
##   ROLL        dodge roll (invincible for the first part)
##   LANDING     stumbling after a hard landing
##   ATTACK      swinging (also ripostes and strike abilities)
##   DRINK       drinking a flask
##   CAST        using a class ability (shouts, throws, charges...)
##   STAGGER     knocked off balance by a hit
##   GUARD_BREAK shield knocked aside after running out of stamina
##   DOWNED      at 0 health in co-op: crawling, bleeding out, waiting for a revive
##   DEAD        waiting to respawn
##
## Multiplayer: each player's own game runs their character ("authority") and
## shares its position, animation and health. Everyone else's copy of that
## character is a "proxy" that just mirrors what it's told.

signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal flasks_changed(current: int, maximum: int)
signal leveled_up(level: int)
signal died
signal respawned
## A shrine, merchant or similar wants a menu opened (the HUD shows it).
signal menu_requested(kind: StringName, source: Node)

enum State { MOVE, AIR, ROLL, LANDING, ATTACK, DRINK, CAST, STAGGER, GUARD_BREAK, DOWNED, DEAD }

const RESPAWN_DELAY := 3.0
## Below this height you've fallen out of the world.
const KILL_HEIGHT := -60.0

const INTERACT_RANGE := 2.2
const FISTS: WeaponData = preload("res://data/weapons/weapon_fists.tres")
const ARROW_SCRIPT := preload("res://game/items/arrow.gd")
## Your character is saved this often (seconds), and when you rest, level up or leave.
const AUTOSAVE_INTERVAL := 300.0
## Debug weights F3 adds on top of your gear (share of capacity).
const TEST_EXTRA_LOADS := [0.0, 0.3, 0.6, 1.0]
## The legendary "cheat death" effect can only save you this often (seconds).
const CHEAT_DEATH_COOLDOWN := 120.0

@export var tuning: PlayerTuning = preload("res://data/balance/player_tuning.tres")
## Used when no class was picked (e.g. running a test map straight from the editor).
@export var default_class: ClassData = preload("res://data/classes/class_bulwark.tres")
## Gear weight ÷ carrying capacity. Phase 6 will compute this from your gear.
@export var equip_load := 0.2

var weapon: WeaponData
## Everything you carry: gear, backpack, bank, gold, souls.
var inventory := Inventory.new()
var shield: ShieldData
var stats: CharacterStats
var effects := Effects.new()

var state := State.MOVE
var health := 100.0
var stamina := 100.0
var flasks := 4
var is_sprinting := false
var is_walking := false
var is_blocking := false
## Show debug visuals (invincibility tint). The HUD's F2 toggles this.
var show_debug := false
var last_fall_height := 0.0

var _state_time := 0.0
var _iframe_timer := 0.0
var _regen_cooldown := 0.0
var _sprint_locked := false
var _off_floor_time := 0.0
var _fall_peak_y := 0.0
var _jumped := false
var _roll_dir := Vector3.FORWARD
var _roll_duration := 0.6
var _roll_distance := 3.5
var _since_roll := 99.0
var _roll_backward := false
var _buffered := &""
var _buffer_timer := 0.0
var _dodge_held := -1.0
var _spawn: Transform3D
# Combat
var _attack := AttackRunner.new()
var _combo_index := 0
var _charge := 0.0
var _charging := false
var _is_riposte := false
var _riposte_victim: Node3D
var _poise := 30.0
var _poise_timer := 0.0
var _hitstop := 0.0
var _block_started := -99.0
var _block_released := -99.0
var _clock := 0.0
var _drink_healed := false
var _stun_time := 0.0
# Abilities
var _ability_strike: AbilityData
var _cast: AbilityData
var _cast_done := false
var _cast_hits: Array[Node] = []
var _cast_dir := Vector3.FORWARD
# Co-op
var _downs := 0
var _bleed := 0.0
var _revive_target: Player
var _revive_progress := 0.0
# Gear
var _debug_load := 0.0
var _cheat_death_cd := 0.0
var _arrow_fired := false

## Shared with everyone (see the Sync node in player.tscn).
var net_pos := Vector3.ZERO
var net_yaw := 0.0
var net_anim := &""
var net_anim_speed := 1.0
var net_anim_count := 0
var net_state := 0
var net_health := 100.0
var net_max_health := 100.0
var net_bleed := 0.0
var net_class := &""
var net_body := 0
var net_color := 0
var net_level := 1
## Item IDs in your hands (so friends see your weapon and shield).
var net_main := &""
var net_off := &""
var spawn_yaw := 0.0
var player_name := ""

var _name_label: Label3D
var _shown_look := ""
var _placed := true
var _spawn_pos := Vector3.ZERO

@onready var model: CharacterModel = $Visual
@onready var camera_rig: PlayerCamera = $CameraRig
@onready var targeting: Targeting = $Targeting
@onready var caster: AbilityCaster = $AbilityCaster


func _enter_tree() -> void:
	# Characters are named after their owner's network id ("1" = host).
	if name.is_valid_int():
		set_multiplayer_authority(name.to_int())


func _ready() -> void:
	add_to_group(&"player")
	# The body itself never rotates; only the visible model turns.
	if net_pos != Vector3.ZERO:
		global_position = net_pos
		global_rotation.y = spawn_yaw
	_spawn = global_transform
	global_basis = Basis.IDENTITY
	camera_rig.follow = self
	camera_rig.targeting = targeting
	targeting.camera = camera_rig.camera
	player_name = Net.name_of(get_multiplayer_authority())
	Net.names_changed.connect(func() -> void: player_name = Net.name_of(get_multiplayer_authority()))
	_spawn_pos = net_pos
	if is_multiplayer_authority():
		var choice := Net.character
		net_class = choice.get("class", default_class.id)
		net_body = choice.get("body", 0)
		net_color = choice.get("color", 0)
		var saved := SaveSystem.load_character(Net.player_name) if Net.save_settings_enabled else {}
		if not saved.is_empty():
			_load_character(saved)
		else:
			_set_class(Classes.by_id(net_class))
			_give_starting_gear()
			save_character()
		add_to_group(&"local_player")
		get_tree().create_timer(AUTOSAVE_INTERVAL, false).timeout.connect(_autosave)
		camera_rig.activate()
		_face_spawn_direction()
		if not multiplayer.is_server():
			# Joined a friend's game: wait for the host to say where we start.
			_placed = false
			visible = false
			_request_placement.rpc_id(1)
		else:
			_write_net_state()
	else:
		_set_class(Classes.by_id(net_class) if net_class != &"" else default_class)
		_become_proxy()


## Set up class, stats and gear (also used when a proxy learns its class).
func _set_class(c: ClassData) -> void:
	stats = CharacterStats.new(c)
	stats.gear = inventory
	stats.leveled_up.connect(_on_leveled_up)
	if not inventory.changed.is_connected(_on_gear_changed):
		inventory.changed.connect(_on_gear_changed)
	_refresh_gear()
	health = max_health()
	stamina = max_stamina()
	flasks = tuning.flask_count
	_poise = max_poise()
	caster.refill()
	_apply_look()


## A brand-new character: equip the class's starting gear.
func _give_starting_gear() -> void:
	inventory.load_dict({})
	for base in stats.class_data.starting_items:
		var it := ItemInstance.make(base, 1, ItemInstance.Rarity.COMMON)
		inventory.backpack.add(it)
		inventory.equip(it.uid)
	_refresh_gear()
	health = max_health()


## Which weapon and shield are in your hands, how heavy you are, what others see.
func _refresh_gear() -> void:
	if is_multiplayer_authority():
		var main := inventory.main_hand()
		var off := inventory.off_hand()
		net_main = main.base.id if main and main.base.weapon else &""
		net_off = off.base.id if off and off.base.shield else &""
	var main_item := ItemDB.get_item(net_main) if net_main != &"" else null
	var off_item := ItemDB.get_item(net_off) if net_off != &"" else null
	weapon = main_item.weapon if main_item and main_item.weapon else FISTS
	shield = off_item.shield if off_item and off_item.shield and not weapon.two_handed else null
	if stats:
		equip_load = inventory.equipped_weight() / (60.0 + 0.5 * stats.strength()) + _debug_load


func _on_gear_changed() -> void:
	_refresh_gear()
	_apply_look()
	if stats:
		health = minf(health, max_health())
		health_changed.emit(health, max_health())
		stamina_changed.emit(stamina, max_stamina())


func _apply_look() -> void:
	var key := "%s/%d/%d/%s/%s" % [stats.class_data.id, net_body, net_color, net_main, net_off]
	if key == _shown_look:
		return
	_shown_look = key
	model.clear_hands()
	if weapon and weapon.visual_scene:
		model.attach_to_hand(weapon.visual_scene.instantiate(), "r")
	if shield and shield.visual_scene:
		model.attach_to_hand(shield.visual_scene.instantiate(), "l")
	model.set_body(net_body == 1)
	model.set_tint(Classes.LOOK_COLORS[clampi(net_color, 0, Classes.LOOK_COLORS.size() - 1)])


@rpc("any_peer", "call_remote", "reliable")
func _request_placement() -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == get_multiplayer_authority():
		_net_place.rpc_id(get_multiplayer_authority(), _spawn_pos, spawn_yaw)


@rpc("any_peer", "call_remote", "reliable")
func _net_place(where: Vector3, yaw: float) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	global_position = where
	_spawn = Transform3D(Basis(Vector3.UP, yaw), where)
	_face_spawn_direction()
	_placed = true
	visible = true
	_write_net_state()


## Someone else's character on this machine: no camera, no input, just mirroring.
func _become_proxy() -> void:
	camera_rig.camera.current = false
	camera_rig.set_process(false)
	camera_rig.set_process_unhandled_input(false)
	targeting.set_physics_process(false)
	targeting.set_process_unhandled_input(false)
	set_process_unhandled_input(false)
	collision_mask = 0
	_name_label = Label3D.new()
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.pixel_size = 0.004
	_name_label.font_size = 48
	_name_label.outline_size = 10
	_name_label.position = Vector3(0, 2.25, 0)
	_name_label.modulate = Color(0.85, 0.9, 1.0)
	add_child(_name_label)
	global_position = net_pos


# --- Public -------------------------------------------------------------------

func max_health() -> float:
	return stats.max_health() if stats else tuning.max_health


func max_stamina() -> float:
	return stats.max_stamina() if stats else tuning.max_stamina


func max_poise() -> float:
	return tuning.poise * (stats.mod_mult("poise_mult") if stats else 1.0) + inventory.stat_total("poise")


func level() -> int:
	return stats.level if stats else 1


func is_invulnerable() -> bool:
	return _iframe_timer > 0.0 or (state == State.ATTACK and _is_riposte)


func is_dead() -> bool:
	return state == State.DEAD


## Down (co-op) or dead: enemies leave you alone.
func is_out_of_fight() -> bool:
	return state == State.DEAD or state == State.DOWNED


func is_downed() -> bool:
	return state == State.DOWNED


func bleed_time_left() -> float:
	return _bleed if is_multiplayer_authority() else net_bleed


## Revive progress 0..1 (for the HUD), and who you're reviving.
func revive_progress() -> float:
	return _revive_progress / _revive_time() if _revive_target else 0.0


func revive_target() -> Player:
	return _revive_target


func load_tier() -> PlayerTuning.LoadTier:
	return tuning.load_tier(equip_load)


func state_name() -> String:
	return State.keys()[state]


func hit_radius() -> float:
	return 0.35


func armor() -> float:
	return stats.armor() if stats else 0.0


## Is the parry window open right now?
func is_parrying() -> bool:
	var window := (shield.parry_window if shield else 0.12) + (stats.mod_add("parry_window_add") if stats else 0.0)
	return is_blocking and _clock - _block_started <= window


## Weapon damage after stat bonuses (before the attack's own multiplier).
func weapon_damage() -> float:
	return weapon.damage * (1.0 + stats.damage_bonus(weapon)) * effects.product("damage_dealt")


## An enemy blow arrives. The player's own game decides what happened
## ("favor the dodger").
func receive_hit(hit: HitInfo) -> HitInfo.Result:
	if state == State.DEAD or state == State.DOWNED:
		return HitInfo.Result.IGNORED
	var chest := global_position + Vector3.UP * 1.3
	if is_invulnerable():
		return HitInfo.Result.DODGED
	var to_attacker := hit.origin - global_position
	to_attacker.y = 0.0
	var holding_line := effects.any("block_all")
	var in_front := holding_line or rad_to_deg(model.forward().angle_to(to_attacker)) <= tuning.block_arc * 0.5
	var damage := hit.damage * (1.0 - HitInfo.armor_reduction(armor(), hit.attacker_level)) * effects.damage_taken_mult()
	if (is_blocking or holding_line) and in_front and not hit.unblockable:
		if hit.parryable and is_parrying():
			CombatFx.sparks(chest + model.forward() * 0.4, to_attacker, true)
			_share_fx(2, chest + model.forward() * 0.4, to_attacker)
			CombatFx.word(chest + Vector3.UP * 0.5, "Parry!")
			freeze(0.12)
			camera_rig.add_shake(0.25)
			caster.on_blocked()
			return HitInfo.Result.PARRIED
		var reduction := shield.block_reduction if shield else weapon.block_reduction
		var stamina_cost := damage * (shield.stamina_per_damage if shield else 1.0) * stats.mod_mult("block_stamina_mult")
		_spend_stamina(stamina_cost)
		CombatFx.sparks(chest + model.forward() * 0.4, to_attacker)
		_share_fx(1, chest + model.forward() * 0.4, to_attacker)
		freeze(hit.hit_stop)
		camera_rig.add_shake(0.2)
		caster.on_blocked()
		var chip := damage * (1.0 - reduction)
		if chip > 0.0:
			_apply_damage(chip)
		if state == State.DEAD or state == State.DOWNED:
			return HitInfo.Result.KILLED
		if stamina <= 0.0 and not holding_line:
			_guard_break()
		else:
			CombatFx.word(chest + Vector3.UP * 0.5, "Blocked")
		return HitInfo.Result.BLOCKED

	# Clean hit.
	CombatFx.blood(chest, -to_attacker.normalized())
	_share_fx(0, chest, -to_attacker.normalized())
	camera_rig.add_shake(0.45 if damage >= 30.0 else 0.3)
	freeze(hit.hit_stop)
	caster.on_hit_taken()
	_apply_damage(damage)
	if state == State.DEAD or state == State.DOWNED:
		return HitInfo.Result.KILLED
	_apply_status(hit.status, hit.status_amount)
	_poise -= hit.poise_damage
	_poise_timer = tuning.poise_regen_delay
	if _poise <= 0.0:
		_poise = max_poise()
		_stagger(tuning.stagger_time)
	return HitInfo.Result.HIT


func _apply_status(status: Effects.Status, amount: float) -> void:
	amount *= 1.0 - clampf(inventory.stat_total("status_resist"), 0.0, 0.8)
	var triggered := effects.add_buildup(status, amount)
	var head := global_position + Vector3.UP * 2.0
	match triggered:
		Effects.Status.BLEED:
			CombatFx.word(head, "Bleeding!")
			CombatFx.blood(global_position + Vector3.UP * 1.2, Vector3.UP, 2.0)
			_apply_damage(max_health() * Effects.BLEED_BURST)
		Effects.Status.POISON:
			CombatFx.word(head, "Poisoned!")
		Effects.Status.FROST:
			CombatFx.word(head, "Frostbitten!")
			_apply_damage(max_health() * Effects.FROST_BURST)


## Fall damage and other unblockable harm.
func take_damage(amount: float, ignore_iframes := false) -> void:
	if state == State.DEAD or amount <= 0.0:
		return
	if is_invulnerable() and not ignore_iframes:
		return
	_apply_damage(amount)


## Hit-stop: freeze in place for a moment on impact.
func freeze(duration: float) -> void:
	_hitstop = maxf(_hitstop, duration)


## Rest at a shrine: full health and flasks, cures statuses, sets your respawn point.
func rest_at(spawn_point: Transform3D) -> void:
	_spawn = spawn_point
	_downs = 0
	health = max_health()
	stamina = max_stamina()
	flasks = tuning.flask_count
	effects.cleanse()
	caster.refill()
	health_changed.emit(health, max_health())
	stamina_changed.emit(stamina, max_stamina())
	flasks_changed.emit(flasks, tuning.flask_count)

	save_character()

func respawn() -> void:
	global_position = _spawn.origin
	velocity = Vector3.ZERO
	health = max_health()
	stamina = max_stamina()
	flasks = tuning.flask_count
	_poise = max_poise()
	_sprint_locked = false
	_iframe_timer = 0.0
	_hitstop = 0.0
	is_blocking = false
	effects.clear_all()
	caster.refill()
	targeting.clear()
	_face_spawn_direction()
	_set_state(State.MOVE)
	health_changed.emit(health, max_health())
	stamina_changed.emit(stamina, max_stamina())
	flasks_changed.emit(flasks, tuning.flask_count)
	respawned.emit()


## The closest thing you can interact with (shrine, later doors, loot...).
func nearest_interactable() -> Node3D:
	var best: Node3D
	var best_d := INTERACT_RANGE
	for n in get_tree().get_nodes_in_group(&"interactables"):
		var node := n as Node3D
		if node == null:
			continue
		var d := node.global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = node
	return best


func _face_spawn_direction() -> void:
	var facing := -_spawn.basis.z
	model.face_instantly(facing)
	camera_rig.yaw = atan2(-facing.x, -facing.z)
	camera_rig.global_position = global_position + Vector3.UP * camera_rig.pivot_height
	model.reset_physics_interpolation()
	reset_physics_interpolation()


# --- Healing, buffs, XP (these work across the network) ------------------------

## Heal this player. Called on any machine; the owner's game applies it.
func heal_from(amount: float, healer_name: String) -> void:
	if is_multiplayer_authority():
		_receive_heal(amount, healer_name)
	else:
		_net_heal.rpc_id(get_multiplayer_authority(), amount, healer_name)


@rpc("any_peer", "call_remote", "reliable")
func _net_heal(amount: float, healer_name: String) -> void:
	_receive_heal(amount, healer_name)


func _receive_heal(amount: float, _healer_name: String) -> void:
	if state == State.DEAD or state == State.DOWNED or amount <= 0.0:
		return
	var real := minf(amount, max_health() - health)
	if real <= 0.0:
		return
	health += real
	health_changed.emit(health, max_health())
	CombatFx.damage_number(global_position + Vector3.UP * 2.0, real, CombatFx.NumberKind.HEAL)


## Give this player a timed buff or debuff (see Effects.add_mod).
func apply_effect(id: StringName, duration: float, values: Dictionary) -> void:
	if is_multiplayer_authority():
		effects.add_mod(id, duration, values)
	else:
		_net_effect.rpc_id(get_multiplayer_authority(), id, duration, values)


@rpc("any_peer", "call_remote", "reliable")
func _net_effect(id: StringName, duration: float, values: Dictionary) -> void:
	effects.add_mod(id, duration, values)


## Cure bleed/poison/frost (Snuff).
func cleanse_from(_healer_name: String) -> void:
	if is_multiplayer_authority():
		effects.cleanse()
	else:
		_net_cleanse.rpc_id(get_multiplayer_authority())


@rpc("any_peer", "call_remote", "reliable")
func _net_cleanse() -> void:
	effects.cleanse()


func restore_stamina(amount: float) -> void:
	stamina = minf(max_stamina(), stamina + amount)
	stamina_changed.emit(stamina, max_stamina())


## Kill XP from the host (shared in full by everyone nearby).
func gain_xp(amount: int) -> void:
	if is_multiplayer_authority():
		_receive_xp(amount)
	else:
		_net_xp.rpc_id(get_multiplayer_authority(), amount)


@rpc("any_peer", "call_remote", "reliable")
func _net_xp(amount: int) -> void:
	if multiplayer.get_remote_sender_id() == 1:
		_receive_xp(amount)


func _receive_xp(amount: int) -> void:
	stats.add_xp(amount)
	CombatFx.word(global_position + Vector3.UP * 2.4, "+%d XP" % amount)


func _on_leveled_up(new_level: int) -> void:
	save_character.call_deferred()
	# Keep the same share of health; new maximums apply at once.
	health = minf(max_health(), health + max_health() * 0.25)
	stamina = max_stamina()
	health_changed.emit(health, max_health())
	stamina_changed.emit(stamina, max_stamina())
	CombatFx.burst_visual(&"beacon_column", global_position, 0.8, 1.0)
	leveled_up.emit(new_level)


## Debug: jump to a level (PageUp / PageDown).
func set_level(new_level: int) -> void:
	stats.set_level(new_level)
	health = max_health()
	stamina = max_stamina()
	health_changed.emit(health, max_health())
	stamina_changed.emit(stamina, max_stamina())
	leveled_up.emit(stats.level)


## Ask the HUD to open a menu ("shrine", "shop"...).
func open_menu(kind: StringName, source: Node) -> void:
	menu_requested.emit(kind, source)

# --- Money, items, saving ---------------------------------------------------------

## Gold and souls from a kill (the host sends these to everyone nearby).
func gain_money(gold_amount: int, souls_amount: int) -> void:
	if is_multiplayer_authority():
		_receive_money(gold_amount, souls_amount)
	else:
		_net_money.rpc_id(get_multiplayer_authority(), gold_amount, souls_amount)


@rpc("any_peer", "call_remote", "reliable")
func _net_money(gold_amount: int, souls_amount: int) -> void:
	if multiplayer.get_remote_sender_id() == 1:
		_receive_money(gold_amount, souls_amount)


func _receive_money(gold_amount: int, souls_amount: int) -> void:
	inventory.add_money(gold_amount, souls_amount)
	if gold_amount > 0 or souls_amount > 0:
		CombatFx.word(global_position + Vector3.UP * 2.0, "+%d gold  +%d souls" % [gold_amount, souls_amount])


## Put a found item in the backpack. Returns false if there's no room.
func receive_item(item: ItemInstance) -> bool:
	if not inventory.add_item(item):
		CombatFx.word(global_position + Vector3.UP * 2.0, "Backpack full")
		return false
	CombatFx.word(global_position + Vector3.UP * 2.0, item.display_name())
	return true


## Use a consumable from the backpack (antidote, draught, bandage).
func use_item(uid: String) -> String:
	var it: ItemInstance = inventory.backpack.items.get(uid)
	if it == null or it.base.use_effect == &"":
		return "Can't be used"
	if state == State.DEAD or state == State.DOWNED:
		return "Not now"
	match it.base.use_effect:
		&"cure_poison":
			effects.poison_left = 0.0
			effects.buildup[Effects.Status.POISON] = 0.0
		&"cure_frost":
			effects.frost_left = 0.0
			effects.buildup[Effects.Status.FROST] = 0.0
		&"heal":
			_receive_heal(it.base.use_amount, player_name)
	it.count -= 1
	if it.count <= 0:
		inventory.remove_item(uid)
	else:
		inventory.changed.emit()
	return ""


## Drop an item from the backpack onto the ground (friends can pick it up).
func drop_item(uid: String) -> void:
	var it := inventory.remove_item(uid)
	if it:
		Loot.drop_item(it, global_position + model.forward() * 1.0)


func save_character() -> void:
	if not is_multiplayer_authority() or stats == null or not Net.save_settings_enabled:
		return
	SaveSystem.save_character({
		"name": Net.player_name,
		"class": String(stats.class_data.id),
		"body": net_body,
		"color": net_color,
		"level": stats.level,
		"xp": stats.xp,
		"talents": stats.talents.map(func(t: StringName) -> String: return String(t)),
		"inventory": inventory.to_dict(),
	})


func _load_character(data: Dictionary) -> void:
	net_class = StringName(data.get("class", default_class.id))
	net_body = int(data.get("body", 0))
	net_color = int(data.get("color", 0))
	inventory.load_dict(data.get("inventory", {}))
	_set_class(Classes.by_id(net_class))
	stats.level = int(data.get("level", 1))
	stats.xp = int(data.get("xp", 0))
	for t in data.get("talents", []):
		stats.talents.append(StringName(t))
	_refresh_gear()
	health = max_health()
	stamina = max_stamina()


func _autosave() -> void:
	save_character()
	if is_inside_tree():
		get_tree().create_timer(AUTOSAVE_INTERVAL, false).timeout.connect(_autosave)


func _exit_tree() -> void:
	save_character()


# --- Abilities: used by AbilityCaster -------------------------------------------

func can_start_ability() -> bool:
	return state == State.MOVE and is_on_floor()


## A strike ability (Shield Bash, Hamstring, Behead, Cleave): a weapon swing.
func start_ability_strike(a: AbilityData) -> void:
	_start_attack(a.attack, _input_direction())
	_ability_strike = a


## A cast ability: shouts, throws, charges, stances.
func start_cast(a: AbilityData) -> void:
	_cast = a
	_cast_done = false
	_cast_hits.clear()
	is_sprinting = false
	_stop_blocking()
	_aim_attack(_input_direction())
	_cast_dir = model.forward()
	if a.kind == AbilityData.Kind.FEINT:
		var side := _move_input().x
		_cast_dir = model.forward().cross(Vector3.UP) * (-1.0 if side < 0.0 else 1.0)
	if a.kind == AbilityData.Kind.LUNGE:
		_iframe_timer = maxf(_iframe_timer, 0.25)
	_set_state(State.CAST)
	if a.cast_anim != &"":
		model.play(a.cast_anim, 0.08, 1.0, true)


## A hit built from this player's numbers (for abilities that hit directly).
func make_hit(damage: float, poise: float) -> HitInfo:
	var hit := HitInfo.new()
	hit.attacker = self
	hit.origin = global_position
	hit.damage = damage
	hit.poise_damage = poise
	hit.attacker_level = level()
	hit.threat_mult = stats.mod_mult("threat_mult") + stats.mod_add("threat_mult_add")
	return hit


## The enemy you're locked on to, or the best one ahead of you within range.
func forward_target(max_range: float) -> Node3D:
	if targeting.has_target() and targeting.target.global_position.distance_to(global_position) <= max_range:
		return targeting.target
	var best: Node3D
	var best_angle := 50.0
	for n in get_tree().get_nodes_in_group(&"enemies"):
		var e := n as Node3D
		if e == null or not e.call(&"can_be_locked"):
			continue
		var to := e.global_position - global_position
		to.y = 0.0
		if to.length() > max_range:
			continue
		var angle := rad_to_deg(model.forward().angle_to(to))
		if angle < best_angle:
			best_angle = angle
			best = e
	return best


## Where the middle of your screen points, at most `max_range` meters away
## (on the ground). Used to throw embers, lanterns and beacons.
func aim_point(max_range: float) -> Vector3:
	var cam := camera_rig.camera
	var from := cam.global_position
	var dir := -cam.global_transform.basis.z
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * 80.0, 1 | 4)
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	var point: Vector3 = hit.position if hit else from + dir * 80.0
	var flat := point - global_position
	flat.y = 0.0
	if flat.length() > max_range:
		point = global_position + flat.normalized() * max_range + Vector3.UP * 2.0
	# Drop it onto the ground.
	var down := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 3.0, point + Vector3.DOWN * 20.0, 1)
	var ground := space.intersect_ray(down)
	return ground.position if ground else Vector3(point.x, global_position.y, point.z)


func _state_cast(delta: float) -> void:
	var a := _cast
	var h := Vector3.ZERO
	match a.kind:
		AbilityData.Kind.SHOULDER_CHARGE, AbilityData.Kind.LUNGE:
			var dist := a.ability_range * stats.mod_mult("charge_distance_mult" if a.kind == AbilityData.Kind.SHOULDER_CHARGE else "lunge_distance_mult")
			var dash_time := 0.4
			if _state_time < dash_time:
				h = _cast_dir * (dist / dash_time)
				caster.dash_hit(a, _cast_hits)
				if _something_close_in_front(0.9):
					h = Vector3.ZERO
		AbilityData.Kind.FEINT:
			if _state_time < 0.25:
				h = _cast_dir * 8.0
		AbilityData.Kind.HOLD_THE_LINE:
			is_blocking = true
			caster.hold_line_cover(a)
			model.play(CharacterModel.ANIM_BLOCK, 0.1)
	velocity.x = h.x
	velocity.z = h.z
	if not is_on_floor():
		velocity.y -= tuning.gravity * delta
	move_and_slide()
	if not _cast_done and _state_time >= a.cast_time:
		_cast_done = true
		caster.cast_effect(a)
	var end := a.lock_time
	if a.kind == AbilityData.Kind.HOLD_THE_LINE:
		end = a.duration
		if _state_time > 0.5 and _consume(&"roll"):
			end = 0.0
	if _state_time >= end:
		is_blocking = false
		effects.remove_mod(&"hold_line")
		_cast = null
		_set_state(State.MOVE)


# --- Input --------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if Net.typing or Net.in_menu:
		return
	# Gamepad: hold LT, then A/B/X/Y/RB/RT use abilities 1-6.
	if Input.is_action_pressed("ability_modifier") and event is InputEventJoypadButton and event.pressed:
		var map := {JOY_BUTTON_A: 0, JOY_BUTTON_B: 1, JOY_BUTTON_X: 2, JOY_BUTTON_Y: 3, JOY_BUTTON_RIGHT_SHOULDER: 4}
		if map.has(event.button_index):
			_buffer(StringName("ability_%d" % map[event.button_index]))
			get_viewport().set_input_as_handled()
			return
	if Input.is_action_pressed("ability_modifier") and event.is_action_pressed("heavy_attack"):
		_buffer(&"ability_5")
		return
	for i in 6:
		if event.is_action_pressed("ability_%d" % (i + 1)):
			_buffer(StringName("ability_%d" % i))
			return
	if event.is_action_pressed("jump"):
		_buffer(&"jump")
	elif event.is_action_pressed("light_attack"):
		_buffer(&"light")
	elif event.is_action_pressed("heavy_attack"):
		_buffer(&"heavy")
	elif event.is_action_pressed("flask"):
		_buffer(&"flask")
	elif event.is_action_pressed("interact"):
		_buffer(&"interact")
	elif event.is_action_pressed("lock_on"):
		if state != State.DEAD and not targeting.toggle():
			camera_rig.recenter(model.forward())
	elif event.is_action_pressed("swap_weapons"):
		if state == State.MOVE:
			inventory.swap_weapon_set()
			CombatFx.word(global_position + Vector3.UP * 2.2, "Weapon set %d" % inventory.active_set)
	elif event.is_action_pressed("debug_equip_load"):
		var i := TEST_EXTRA_LOADS.find(_debug_load)
		_debug_load = TEST_EXTRA_LOADS[(i + 1) % TEST_EXTRA_LOADS.size()]
		_refresh_gear()
	elif event.is_action_pressed("debug_reset"):
		respawn()
	elif event.is_action_pressed("debug_level_up"):
		set_level(stats.level + 1)
	elif event.is_action_pressed("debug_level_reset"):
		set_level(1)


## Remember a button press briefly, so pressing it slightly early still works.
func _buffer(action: StringName) -> void:
	_buffered = action
	_buffer_timer = tuning.input_buffer_time


func _consume(action: StringName) -> bool:
	if _buffered == action and _buffer_timer > 0.0:
		_buffered = &""
		return true
	return false


func _has_buffered(action: StringName) -> bool:
	return _buffered == action and _buffer_timer > 0.0


## Shift / gamepad B: tap to roll (on release), hold to sprint.
func _read_dodge_button(delta: float) -> void:
	if Input.is_action_pressed("ability_modifier"):
		_dodge_held = -1.0
		return
	if Input.is_action_just_pressed("dodge_sprint"):
		_dodge_held = 0.0
	elif _dodge_held >= 0.0:
		if Input.is_action_pressed("dodge_sprint"):
			_dodge_held += delta
		else:
			if _dodge_held < tuning.dodge_hold_time:
				_buffer(&"roll")
			_dodge_held = -1.0


func _move_input() -> Vector2:
	if Net.typing or Net.in_menu:
		return Vector2.ZERO
	return Input.get_vector("move_left", "move_right", "move_forward", "move_back")


## Turn stick/WASD input into a world direction, relative to the camera.
func _input_direction() -> Vector3:
	var v := _move_input()
	return camera_rig.flat_basis() * Vector3(v.x, 0.0, v.y)


func _wants_sprint() -> bool:
	return _dodge_held >= tuning.dodge_hold_time


## Which ability slot is waiting in the input buffer (-1 = none).
func _buffered_ability() -> int:
	if _buffer_timer > 0.0 and String(_buffered).begins_with("ability_"):
		return String(_buffered).trim_prefix("ability_").to_int()
	return -1


# --- Main loop ----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		_proxy_update(delta)
		return
	if not _placed:
		return
	_authority_update(delta)
	_write_net_state()


## Share what this character is doing with everyone else.
func _write_net_state() -> void:
	net_pos = global_position
	net_yaw = model.rotation.y
	net_anim = model.current_anim()
	net_anim_speed = model.get_speed()
	net_anim_count = model.play_count
	net_state = state
	net_health = health
	net_max_health = max_health()
	net_bleed = _bleed
	net_level = level()


## Copy what the owner's machine says this character is doing.
func _proxy_update(delta: float) -> void:
	if net_class != &"" and (stats == null or stats.class_data.id != net_class):
		_set_class(Classes.by_id(net_class))
	_refresh_gear()
	_apply_look()
	if global_position.distance_to(net_pos) > 4.0:
		global_position = net_pos
	else:
		global_position = global_position.lerp(net_pos, 1.0 - exp(-18.0 * delta))
	model.rotation.y = lerp_angle(model.rotation.y, net_yaw, 1.0 - exp(-18.0 * delta))
	model.mirror(net_anim, net_anim_speed, net_anim_count)
	state = net_state as State
	health = net_health
	if stats and stats.level != net_level:
		stats.level = net_level
	if _name_label:
		_name_label.text = "%s  %d%s" % [player_name, net_level, "  (DOWN)" if state == State.DOWNED else ""]


func _authority_update(delta: float) -> void:
	_clock += delta
	_buffer_timer = maxf(0.0, _buffer_timer - delta)
	_read_dodge_button(delta)

	# Hit-stop: everything about this character pauses for a moment.
	if _hitstop > 0.0:
		_hitstop -= delta
		model.hold(true)
		return
	model.hold(false)

	_state_time += delta
	_since_roll += delta
	_iframe_timer = maxf(0.0, _iframe_timer - delta)
	_cheat_death_cd = maxf(0.0, _cheat_death_cd - delta)
	_poise_timer -= delta
	if _poise_timer <= 0.0:
		_poise = max_poise()
	_tick_effects(delta)

	match state:
		State.MOVE:
			_state_move(delta)
		State.AIR:
			_state_air(delta)
		State.ROLL:
			_state_roll(delta)
		State.LANDING:
			_state_stunned(delta, tuning.hard_landing_time)
		State.ATTACK:
			_state_attack(delta)
		State.DRINK:
			_state_drink(delta)
		State.CAST:
			_state_cast(delta)
		State.STAGGER, State.GUARD_BREAK:
			_state_stunned(delta, _stun_time)
		State.DOWNED:
			_state_downed(delta)
		State.DEAD:
			_state_dead(delta)

	if state != State.MOVE and state != State.CAST and is_blocking:
		_stop_blocking()
	if global_position.y < KILL_HEIGHT and state != State.DEAD:
		health = 0.0
		_die()
	_update_stamina(delta)
	if show_debug and is_invulnerable():
		model.set_overlay("iframes", Color(0.4, 0.8, 1.0, 0.35))
	elif model.overlay_kind() == "iframes":
		model.set_overlay("")


func _tick_effects(delta: float) -> void:
	if state == State.DEAD:
		return
	var dot := effects.tick(delta)
	if dot > 0.0 and state != State.DOWNED:
		_apply_damage(max_health() * dot)


func _set_state(new_state: State) -> void:
	state = new_state
	_state_time = 0.0


func _state_move(delta: float) -> void:
	# Walked off a ledge? A short grace period still lets you jump.
	if is_on_floor():
		_off_floor_time = 0.0
	else:
		_off_floor_time += delta
		if _off_floor_time > tuning.coyote_time:
			_enter_air(false)
			_state_air(delta)
			return

	var dir := _input_direction()
	var amount := minf(dir.length(), 1.0)

	var slot := _buffered_ability()
	if slot >= 0:
		_buffered = &""
		if caster.try_use(slot):
			return
	if _consume(&"roll") and _can_roll():
		_start_roll(dir)
		return
	if _consume(&"jump") and _can_jump():
		_start_jump()
		return
	if _has_buffered(&"light") and stamina > 0.0:
		_consume(&"light")
		_start_light_attack(dir)
		return
	if _has_buffered(&"heavy") and stamina > 0.0 and weapon.heavy:
		_consume(&"heavy")
		_start_attack(weapon.heavy, dir)
		_charging = true
		_charge = 0.0
		return
	if _update_revive(delta):
		move_and_slide()
		return
	if _consume(&"flask"):
		_start_drink()
		return
	if _consume(&"interact") and _nearest_downed_friend() == null:
		var thing := nearest_interactable()
		if thing:
			thing.call(&"interact", self)

	# Blocking
	var wants_block := Input.is_action_pressed("block")
	if wants_block and not is_blocking:
		is_blocking = true
		# No parry window if you only just let go of block (no mashing).
		_block_started = _clock if _clock - _block_released > tuning.parry_lockout else -99.0
	elif not wants_block and is_blocking:
		_stop_blocking()

	var locked := targeting.has_target()
	var overloaded := load_tier() == PlayerTuning.LoadTier.OVERLOADED
	is_walking = Input.is_action_pressed("walk") or (amount > 0.0 and amount < tuning.walk_stick_threshold)
	is_sprinting = _wants_sprint() and amount > 0.3 and not overloaded and not _sprint_locked \
			and stamina > 0.0 and not is_blocking

	var speed := tuning.run_speed
	if is_sprinting:
		speed = tuning.sprint_speed
	elif is_blocking:
		speed = tuning.block_move_speed
	elif is_walking:
		speed = tuning.walk_speed
	elif locked:
		speed = tuning.lock_on_speed
	speed *= effects.move_mult() * (1.0 + inventory.stat_total("move_speed"))

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var target_velocity := Vector3.ZERO
	if is_sprinting:
		# Sprinting turns in wide arcs: you go where your body points.
		model.turn_smooth(dir, 5.0, tuning.sprint_turn_speed * 0.5, delta)
		target_velocity = model.forward() * speed
	else:
		if amount > 0.0:
			target_velocity = dir.normalized() * speed
		if locked:
			model.turn_smooth(targeting.target_point() - global_position, 14.0, 180.0, delta)
		elif amount > 0.0:
			model.turn_smooth(dir, 14.0, 180.0, delta)

	horizontal = _steer(horizontal, target_velocity, speed, amount > 0.0 and not is_sprinting, delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity.y -= tuning.gravity * delta
	move_and_slide()

	if is_sprinting and horizontal.length() > 1.0:
		_spend_stamina(tuning.sprint_stamina_per_second * delta)
		if stamina <= 0.0:
			_sprint_locked = true
	if is_blocking:
		model.play(CharacterModel.ANIM_BLOCK, 0.12)
	else:
		model.update_locomotion(Vector3(velocity.x, 0.0, velocity.z).length(), is_sprinting, is_walking)


## Move the current velocity toward the wanted one. While walking or running,
## keep your speed through turns instead of slowing to a stop.
func _steer(horizontal: Vector3, target_velocity: Vector3, speed: float, keep_speed: bool, delta: float) -> Vector3:
	if keep_speed and horizontal.length() > 0.1:
		var cur_speed := horizontal.length()
		var cur_dir := horizontal / cur_speed
		var want_dir := target_velocity.normalized()
		var max_turn := deg_to_rad(tuning.direction_change_speed) * delta
		var angle := cur_dir.signed_angle_to(want_dir, Vector3.UP)
		if absf(angle) > PI - 0.05:
			angle = PI  # straight reversal: pick a side
		cur_dir = cur_dir.rotated(Vector3.UP, clampf(angle, -max_turn, max_turn))
		var rate := tuning.acceleration if cur_speed < speed else tuning.deceleration
		return cur_dir * move_toward(cur_speed, speed, rate * delta)
	var rate2 := tuning.acceleration if target_velocity.length() >= horizontal.length() else tuning.deceleration
	return horizontal.move_toward(target_velocity, rate2 * delta)


func _stop_blocking() -> void:
	if is_blocking:
		_block_released = _clock
	is_blocking = false


# --- Attacks ------------------------------------------------------------------

func _start_light_attack(dir: Vector3) -> void:
	# Riposte a stunned enemy in front of you.
	var victim := _find_riposte_victim()
	if victim and weapon.riposte:
		_is_riposte = true
		_riposte_victim = victim
		model.face_instantly(victim.global_position - global_position)
		victim.call(&"begin_riposte", self)
		_start_attack(weapon.riposte, Vector3.ZERO, false)
		return
	if is_sprinting and weapon.running_attack:
		_start_attack(weapon.running_attack, dir)
	elif _since_roll <= tuning.rolling_attack_window and weapon.rolling_attack:
		_start_attack(weapon.rolling_attack, dir)
	else:
		_combo_index = 0
		_start_attack(weapon.light_combo[0], dir)


func _start_attack(a: AttackData, dir: Vector3, aim := true) -> void:
	if aim:
		_aim_attack(dir)
	_spend_stamina(a.stamina_cost * effects.product("stamina_cost"))
	_charging = false
	_charge = 0.0
	_ability_strike = null
	if a != weapon.riposte:
		_is_riposte = false
	is_sprinting = false
	_arrow_fired = false
	_set_state(State.ATTACK)
	_attack.start(a, model)


## Turn toward the locked target, or the best nearby enemy, or where you push.
func _aim_attack(dir: Vector3) -> void:
	if targeting.has_target():
		model.face_instantly(targeting.target_point() - global_position)
		return
	var soft := targeting.find_soft_target(dir if dir.length() > 0.1 else model.forward())
	if soft:
		model.face_instantly(soft.global_position - global_position)
	elif dir.length() > 0.1:
		model.face_instantly(dir)


func _state_attack(delta: float) -> void:
	var a := _attack.attack
	# Heavy attack: holding the button at the wind-up point charges it.
	var mult := 1.0
	if _charging:
		if Input.is_action_pressed("heavy_attack") and _attack.t >= a.windup_until \
				and _charge < weapon.heavy_charge_time:
			_charge += delta
			mult = 0.12
		elif _attack.t >= a.windup_until:
			_charging = false
	_attack.step(delta, mult)

	# Stay locked toward the target during the wind-up.
	if targeting.has_target() and not _attack.past(a.hit_start):
		model.turn_toward(targeting.target_point() - global_position, deg_to_rad(360.0) * delta)

	# Lunge forward (but don't shove through whoever you're hitting).
	var lunge := _attack.lunge_speed()
	if lunge > 0.0 and _something_close_in_front(1.1):
		lunge = 0.0
	velocity.x = model.forward().x * lunge
	velocity.z = model.forward().z * lunge
	if not is_on_floor():
		velocity.y -= tuning.gravity * delta
	move_and_slide()

	if _attack.in_hit_window():
		if a.projectile_speed > 0.0:
			if not _arrow_fired:
				_arrow_fired = true
				_fire_arrow(a)
		else:
			for target in _attack.find_new_targets(self, model.forward(), &"hittable"):
				_land_hit(target)

	# What comes next: chain, cancel or finish.
	if _attack.past(a.chain_time) and _has_buffered(&"light") and not _is_riposte \
			and a in weapon.light_combo and stamina > 0.0:
		_consume(&"light")
		_combo_index = (weapon.light_combo.find(a) + 1) % weapon.light_combo.size()
		_start_attack(weapon.light_combo[_combo_index], _input_direction())
		return
	if _attack.past(a.chain_time) and _has_buffered(&"heavy") and not _is_riposte and stamina > 0.0:
		_consume(&"heavy")
		_start_attack(weapon.heavy, _input_direction())
		_charging = true
		return
	if _attack.past(a.cancel_time) and not _is_riposte:
		if _has_buffered(&"roll") and _can_roll():
			_consume(&"roll")
			_start_roll(_input_direction())
			return
		var slot := _buffered_ability()
		if slot >= 0:
			_finish_attack()
			return
		if Input.is_action_pressed("block"):
			_finish_attack()
			return
	if _attack.done():
		_finish_attack()


func _finish_attack() -> void:
	_is_riposte = false
	_riposte_victim = null
	_ability_strike = null
	_set_state(State.MOVE)


## Bows: shoot an arrow at the locked target, the enemy ahead, or the center dot.
func _fire_arrow(a: AttackData) -> void:
	var from := global_position + Vector3.UP * 1.45 + model.forward() * 0.5
	var aim: Vector3
	var t := forward_target(a.projectile_range)
	if t:
		aim = t.call(&"get_lock_point")
	else:
		var cam := camera_rig.camera
		var q := PhysicsRayQueryParameters3D.create(cam.global_position,
				cam.global_position - cam.global_transform.basis.z * a.projectile_range, 1 | 4)
		q.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		aim = hit.position if hit else cam.global_position - cam.global_transform.basis.z * a.projectile_range
	var dir := (aim - from).normalized()
	model.face_instantly(dir)
	var arrow: Node3D = ARROW_SCRIPT.new()
	arrow.set(&"shooter", self)
	arrow.set(&"attack", a)
	arrow.set(&"charge", _charge)
	arrow.set(&"direction", dir)
	arrow.set(&"speed", a.projectile_speed)
	arrow.set(&"max_range", a.projectile_range)
	CombatFx.world().add_child(arrow)
	arrow.global_position = from
	if Net.is_online():
		_net_arrow.rpc(from, dir, a.projectile_speed, a.projectile_range)


@rpc("authority", "call_remote", "unreliable")
func _net_arrow(from: Vector3, dir: Vector3, arrow_speed: float, arrow_range: float) -> void:
	var arrow: Node3D = ARROW_SCRIPT.new()
	arrow.set(&"direction", dir)
	arrow.set(&"speed", arrow_speed)
	arrow.set(&"max_range", arrow_range)
	CombatFx.world().add_child(arrow)
	arrow.global_position = from


## An arrow you shot reached something.
func arrow_hit(target: Node3D, a: AttackData, charge: float) -> void:
	_land_hit(target, a, charge)


func _land_hit(target: Node3D, a: AttackData = null, charge := -1.0) -> void:
	if a == null:
		a = _attack.attack
	if charge < 0.0:
		charge = _charge
	var hit := make_hit(0.0, weapon.poise_damage * a.poise_mult)
	# On-hit status from the weapon (axes bleed) and from gear bonus rolls.
	hit.status = weapon.status
	hit.status_amount = weapon.status_amount
	for kind in [["bleed_on_hit", Effects.Status.BLEED], ["poison_on_hit", Effects.Status.POISON], ["frost_on_hit", Effects.Status.FROST]]:
		var amount := inventory.stat_total(kind[0])
		if amount > 0.0 and (hit.status == Effects.Status.NONE or hit.status == kind[1]):
			hit.status = kind[1]
			hit.status_amount += amount
	hit.attack = a
	hit.is_riposte = _is_riposte
	var dmg := weapon_damage() * a.damage_mult
	if a == weapon.heavy:
		dmg *= stats.mod_mult("heavy_damage_mult")
	if charge > 0.0:
		dmg *= 1.0 + weapon.heavy_charge_bonus * clampf(charge / weapon.heavy_charge_time, 0.0, 1.0)
	var guaranteed := effects.any("guaranteed_crit")
	hit.is_crit = _is_riposte or guaranteed or randf() < stats.crit_chance(weapon)
	if guaranteed:
		effects.remove_mod(&"feint")
	if hit.is_crit and not _is_riposte:
		dmg *= weapon.crit_multiplier
	# Headsman passive: extra damage to bleeding targets.
	if target.has_method("is_bleeding") and target.call(&"is_bleeding"):
		dmg *= stats.mod_mult("bleeding_target_damage_mult")
	if target.has_method("armor"):
		dmg *= 1.0 - HitInfo.armor_reduction(float(target.call(&"armor")) * (1.0 - weapon.armor_pierce), level())
	hit.damage = dmg
	hit.hit_stop = 0.15 if hit.is_crit else a.hit_stop
	if _ability_strike and a == _ability_strike.attack:
		caster.modify_strike_hit(_ability_strike, hit, target)
	var result: HitInfo.Result = target.call(&"receive_hit", hit)
	if result == HitInfo.Result.HIT or result == HitInfo.Result.KILLED:
		freeze(hit.hit_stop)
		camera_rig.add_shake(0.35 if hit.is_crit else (0.25 if a == weapon.heavy else 0.15))
		caster.on_hit_landed(hit, a == weapon.heavy)
		if _ability_strike and a == _ability_strike.attack:
			caster.on_strike_hit(_ability_strike)
		var steal := effects.total("lifesteal")
		if steal > 0.0:
			_receive_heal(hit.damage * steal, player_name)


func _find_riposte_victim() -> Node3D:
	for n in get_tree().get_nodes_in_group(&"hittable"):
		var e := n as Node3D
		if e == null or not e.has_method("can_be_riposted") or not e.call(&"can_be_riposted"):
			continue
		var to := e.global_position - global_position
		to.y = 0.0
		if to.length() <= tuning.riposte_range:
			return e
	return null


func _something_close_in_front(distance: float) -> bool:
	for n in get_tree().get_nodes_in_group(&"hittable"):
		var e := n as Node3D
		if e == null:
			continue
		if e.has_method("can_be_locked") and not e.call(&"can_be_locked"):
			continue
		var to := e.global_position - global_position
		to.y = 0.0
		if to.length() < distance and model.forward().dot(to.normalized()) > 0.5:
			return true
	return false


# --- Flasks -------------------------------------------------------------------

func _start_drink() -> void:
	if flasks <= 0:
		CombatFx.word(global_position + Vector3.UP * 2.0, "No flasks")
		return
	flasks -= 1  # used up at the start, even if you get hit mid-drink
	flasks_changed.emit(flasks, tuning.flask_count)
	_drink_healed = false
	is_sprinting = false
	_set_state(State.DRINK)
	model.play_fitted(CharacterModel.ANIM_DRINK, tuning.drink_time)


func _state_drink(delta: float) -> void:
	var dir := _input_direction()
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(dir.normalized() * tuning.drink_move_speed if dir.length() > 0.1 else Vector3.ZERO,
			tuning.acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity.y -= tuning.gravity * delta
	move_and_slide()
	if not _drink_healed and _state_time >= tuning.drink_heal_at:
		_drink_healed = true
		var amount := minf(max_health() * tuning.flask_heal, max_health() - health)
		health += amount
		health_changed.emit(health, max_health())
		CombatFx.damage_number(global_position + Vector3.UP * 2.0, amount, CombatFx.NumberKind.HEAL)
	if _state_time >= tuning.drink_time:
		_set_state(State.MOVE)


# --- Being hit ----------------------------------------------------------------

func _apply_damage(amount: float) -> void:
	health = maxf(0.0, health - amount)
	if health <= 0.0 and effects.any("min_health"):
		health = 1.0  # Unbroken
	elif health <= 0.0 and stats.mod_add("cheat_death") > 0.0 and _cheat_death_cd <= 0.0:
		health = 1.0  # a legendary saved you
		_cheat_death_cd = CHEAT_DEATH_COOLDOWN
		CombatFx.word(global_position + Vector3.UP * 2.2, "Not today")
	health_changed.emit(health, max_health())
	if health <= 0.0:
		if _someone_else_standing():
			_go_down()
		else:
			_die()


func _stagger(duration: float) -> void:
	_stun_time = duration
	_cast = null
	_set_state(State.STAGGER)
	velocity = Vector3(velocity.x * 0.2, velocity.y, velocity.z * 0.2)
	model.play_fitted(CharacterModel.ANIM_HIT, duration * 1.2, 0.05)


func _guard_break() -> void:
	_stun_time = tuning.guard_break_time
	_set_state(State.GUARD_BREAK)
	CombatFx.word(global_position + Vector3.UP * 2.0, "Guard broken")
	model.play_fitted(CharacterModel.ANIM_GUARD_BREAK, tuning.guard_break_time, 0.05)


## Stunned states: no control until the time is up.
func _state_stunned(delta: float, duration: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(Vector3.ZERO, tuning.deceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity.y -= tuning.gravity * delta
	move_and_slide()
	if _state_time >= duration:
		_set_state(State.MOVE)


# --- Roll ---------------------------------------------------------------------

func _can_roll() -> bool:
	return stamina > 0.0 and load_tier() != PlayerTuning.LoadTier.OVERLOADED


func _start_roll(dir: Vector3) -> void:
	var tier := load_tier()
	_roll_duration = tuning.roll_duration[tier]
	_roll_distance = tuning.roll_distance[tier]
	_iframe_timer = tuning.roll_iframes[tier]
	_roll_backward = dir.length() <= 0.1
	if _roll_backward:
		# Standing still: roll straight back, still facing forward.
		_roll_dir = -model.forward()
	else:
		_roll_dir = dir.normalized()
		model.face_instantly(_roll_dir)
	_spend_stamina(tuning.roll_stamina)
	is_sprinting = false
	_set_state(State.ROLL)
	if _roll_backward:
		model.play_roll_backward(_roll_duration)
	else:
		model.play_roll(_roll_duration)


func _state_roll(delta: float) -> void:
	var u := _state_time / _roll_duration
	# Chain rolls: a roll pressed in the last quarter starts the next one at once.
	if u >= 0.75 and _has_buffered(&"roll") and _can_roll():
		_consume(&"roll")
		_since_roll = 0.0
		_start_roll(_input_direction())
		return
	# Fast at the start, easing down to running speed at the end (so you come out
	# of the roll still moving). Covers exactly the roll distance.
	var average := _roll_distance / _roll_duration
	var end_speed := minf(tuning.run_speed, average) * (0.25 if _roll_backward else 1.0)
	var start_speed := end_speed + 1.5 * (average - end_speed)
	if u >= 1.0:
		# Hand the momentum straight back to normal movement.
		velocity.x = _roll_dir.x * end_speed
		velocity.z = _roll_dir.z * end_speed
		_since_roll = 0.0
		_set_state(State.MOVE)
		_state_move(delta)
		return
	var speed := end_speed + (start_speed - end_speed) * (1.0 - u * u)
	velocity.x = _roll_dir.x * speed
	velocity.z = _roll_dir.z * speed
	if is_on_floor():
		_off_floor_time = 0.0
	else:
		velocity.y -= tuning.gravity * delta
		_off_floor_time += delta
	move_and_slide()
	if _off_floor_time > tuning.coyote_time:
		_enter_air(false)  # rolled off a ledge


# --- Jump, fall, land ---------------------------------------------------------

func _can_jump() -> bool:
	return stamina > 0.0 and (is_on_floor() or _off_floor_time <= tuning.coyote_time)


func _start_jump() -> void:
	velocity.y = sqrt(2.0 * tuning.gravity * tuning.jump_height)
	_iframe_timer = maxf(_iframe_timer, tuning.jump_iframes)
	_spend_stamina(tuning.jump_stamina)
	_enter_air(true)
	model.play_jump()


func _enter_air(jumped: bool) -> void:
	_jumped = jumped
	_fall_peak_y = global_position.y
	is_sprinting = false
	_set_state(State.AIR)
	if not jumped:
		model.play_fall()


func _state_air(delta: float) -> void:
	_fall_peak_y = maxf(_fall_peak_y, global_position.y)
	velocity.y -= tuning.gravity * delta

	# A little steering in the air, but you can't stop or turn around.
	var dir := _input_direction()
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var cap := maxf(horizontal.length(), tuning.walk_speed)
	horizontal = horizontal.move_toward(dir.normalized() * cap if dir.length() > 0.1 else horizontal,
			tuning.acceleration * tuning.air_control * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if horizontal.length() > 0.5:
		model.turn_toward(horizontal, deg_to_rad(tuning.turn_speed) * 0.25 * delta)
	move_and_slide()

	if _jumped and velocity.y < -1.0:
		_jumped = false
		model.play_fall()
	if is_on_floor() and velocity.y <= 0.0:
		_land()


func _land() -> void:
	last_fall_height = maxf(0.0, _fall_peak_y - global_position.y)
	_off_floor_time = 0.0
	var damage := tuning.fall_damage_fraction(last_fall_height) * max_health()
	if damage > 0.0:
		take_damage(damage, true)
		if state == State.DEAD or state == State.DOWNED:
			return
	if last_fall_height >= tuning.hard_landing_height:
		velocity.x *= 0.2
		velocity.z *= 0.2
		_set_state(State.LANDING)
		model.play_land(true)
	else:
		_set_state(State.MOVE)
		if last_fall_height > 0.8:
			model.play_land(false)


# --- Downed and revive (co-op) ------------------------------------------------

func _someone_else_standing() -> bool:
	for n in get_tree().get_nodes_in_group(&"player"):
		var p := n as Player
		if p and p != self and not p.is_out_of_fight():
			return true
	return false


func _go_down() -> void:
	var times := tuning.downed_bleed_times
	_bleed = times[mini(_downs, times.size() - 1)]
	_downs += 1
	is_sprinting = false
	is_blocking = false
	_cast = null
	targeting.clear()
	_set_state(State.DOWNED)
	model.play(&"Crouch_Idle", 0.2)
	CombatFx.word(global_position + Vector3.UP * 1.8, "Down!")


func _state_downed(delta: float) -> void:
	_bleed -= delta
	if _bleed <= 0.0 or not _someone_else_standing():
		_die()
		return
	var dir := _input_direction()
	var h := Vector3(velocity.x, 0.0, velocity.z).move_toward(
			dir.normalized() * tuning.downed_crawl_speed if dir.length() > 0.1 else Vector3.ZERO, 8.0 * delta)
	velocity.x = h.x
	velocity.z = h.z
	if not is_on_floor():
		velocity.y -= tuning.gravity * delta
	move_and_slide()
	if h.length() > 0.1:
		model.turn_toward(h, deg_to_rad(180.0) * delta)
		model.play(&"Crouch_Fwd", 0.2, 0.5)
	else:
		model.play(&"Crouch_Idle", 0.2)


func _revive_time() -> float:
	return tuning.revive_time * (stats.mod_mult("revive_time_mult") if stats else 1.0)


## Holding Interact next to a downed friend revives them (costs one flask).
## Returns true while reviving (you stand still).
func _update_revive(delta: float) -> bool:
	var target := _nearest_downed_friend() if Input.is_action_pressed("interact") and flasks > 0 else null
	if target == null or target != _revive_target:
		_revive_target = target
		_revive_progress = 0.0
		if target == null:
			return false
	_revive_progress += delta
	velocity.x = 0.0
	velocity.z = 0.0
	model.turn_toward(target.global_position - global_position, deg_to_rad(360.0) * delta)
	model.play(&"Interact", 0.15)
	if _revive_progress >= _revive_time():
		flasks -= 1
		flasks_changed.emit(flasks, tuning.flask_count)
		target.revive_by(self)
		_revive_target = null
		_revive_progress = 0.0
	return true


func _nearest_downed_friend() -> Player:
	var best: Player
	var best_d := tuning.revive_range
	for n in get_tree().get_nodes_in_group(&"player"):
		var p := n as Player
		if p == null or p == self or not p.is_downed():
			continue
		var d := p.global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = p
	return best


## Get this (downed) player back on their feet. Works across the network.
func revive_by(reviver: Player) -> void:
	if is_multiplayer_authority():
		_on_revived(reviver.player_name)
	else:
		_net_revive.rpc_id(get_multiplayer_authority(), reviver.player_name)


@rpc("any_peer", "call_remote", "reliable")
func _net_revive(reviver_name: String) -> void:
	_on_revived(reviver_name)


func _on_revived(reviver_name: String) -> void:
	if state != State.DOWNED:
		return
	health = max_health() * tuning.revive_health
	health_changed.emit(health, max_health())
	_set_state(State.MOVE)
	CombatFx.word(global_position + Vector3.UP * 2.0, "Revived by %s" % reviver_name)


# --- Network messages -----------------------------------------------------------

## The host says an enemy's blow reached this player. This player's own game
## decides what really happened (rolled through it? blocked? parried?).
@rpc("any_peer", "call_remote", "reliable")
func _net_enemy_hit(enemy_path: NodePath, attack_index: int, origin: Vector3) -> void:
	if multiplayer.get_remote_sender_id() != 1 or not is_multiplayer_authority():
		return
	var enemy := get_node_or_null(enemy_path) as Enemy
	if enemy == null:
		return
	var hit := enemy.make_hit(attack_index)
	hit.origin = origin
	# Favor the dodger: if on our screen we're already out of reach, it missed.
	var result := HitInfo.Result.DODGED
	if enemy.reaches(self, attack_index, 0.8):
		result = receive_hit(hit)
	enemy.report_hit_result.rpc_id(1, result)


## Let everyone else see this player's blood / sparks.
func _share_fx(kind: int, where: Vector3, dir: Vector3) -> void:
	if Net.is_online():
		_net_fx.rpc(kind, where, dir)


@rpc("authority", "call_remote", "unreliable")
func _net_fx(kind: int, where: Vector3, dir: Vector3) -> void:
	match kind:
		0:
			CombatFx.blood(where, dir)
		1:
			CombatFx.sparks(where, dir)
		2:
			CombatFx.sparks(where, dir, true)


# --- Death --------------------------------------------------------------------

func _die() -> void:
	_set_state(State.DEAD)
	is_sprinting = false
	is_blocking = false
	_cast = null
	targeting.clear()
	model.play_death()
	died.emit()


func _state_dead(delta: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(Vector3.ZERO, tuning.deceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity.y -= tuning.gravity * delta
	move_and_slide()
	if _state_time >= RESPAWN_DELAY:
		respawn()


# --- Stamina ------------------------------------------------------------------

func _spend_stamina(amount: float) -> void:
	stamina = maxf(0.0, stamina - amount)
	_regen_cooldown = tuning.stamina_regen_delay
	stamina_changed.emit(stamina, max_stamina())


func _update_stamina(delta: float) -> void:
	if state == State.DEAD or state == State.ATTACK:
		return
	if _regen_cooldown > 0.0:
		_regen_cooldown -= delta
	elif stamina < max_stamina():
		var rate := tuning.stamina_regen * (tuning.block_regen_mult if is_blocking else 1.0) \
				* effects.stamina_regen_mult() * stats.mod_mult("stamina_regen_mult") * (1.0 + inventory.stat_total("stamina_regen"))
		stamina = minf(max_stamina(), stamina + rate * delta)
		stamina_changed.emit(stamina, max_stamina())
	if _sprint_locked and stamina >= tuning.sprint_restart_stamina:
		_sprint_locked = false
