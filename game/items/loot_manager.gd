extends Node
## Loot in the world (autoload "Loot").
##
## The host decides everything: what an enemy drops, who may pick a drop up,
## and who wins a Need/Greed roll. Drops appear on every machine.
##   - Common items: first come, first served.
##   - Uncommon and better, with 2+ players nearby: a Need / Greed / Pass roll
##     (30 s). Need beats Greed; the highest number wins. The drop is then
##     reserved for the winner.
##   - Gold, souls and XP go to everyone nearby in full (no kill-stealing).

signal roll_offered(drop_id: int, item: ItemInstance, seconds: float)
signal roll_closed(drop_id: int)

const DROP_SCRIPT := preload("res://game/items/loot_drop.gd")
const ROLL_TIME := 30.0
const SHARE_RANGE := 50.0
enum Choice { PASS, GREED, NEED }

var _next_id := 1
var _drops := {}  # id -> LootDrop node (on every machine)
## Host only: id -> {"item": dict, "owner": peer (0 = anyone), "rolling": bool}
var _host_drops := {}
## Host only: id -> {"choices": {peer: Choice}, "timer": SceneTreeTimer, "peers": [ids]}
var _rolls := {}


# --- Host: enemies die ------------------------------------------------------------

## Host: an enemy died. Share money and XP; scatter its items.
func enemy_died(enemy: Node3D, table: LootTable, xp: int) -> void:
	if not multiplayer.is_server():
		return
	var nearby := _players_near(enemy.global_position)
	var result := ItemDB.roll(table) if table else {"items": [], "gold": 0, "souls": 0}
	for p in nearby:
		p.gain_xp(xp)
		p.gain_money(result.gold, result.souls)
	var i := 0
	for it: ItemInstance in result.items:
		var offset := Vector3(cos(i * 2.1), 0, sin(i * 2.1)) * 0.8
		_host_spawn(it, enemy.global_position + offset, nearby)
		i += 1


func _players_near(where: Vector3) -> Array[Player]:
	var out: Array[Player] = []
	for n in get_tree().get_nodes_in_group(&"player"):
		var p := n as Player
		if p and not p.is_dead() and p.global_position.distance_to(where) <= SHARE_RANGE:
			out.append(p)
	return out


func _host_spawn(item: ItemInstance, where: Vector3, nearby: Array[Player]) -> void:
	var id := _next_id
	_next_id += 1
	var roll := item.rarity >= ItemInstance.Rarity.UNCOMMON and nearby.size() >= 2
	_host_drops[id] = {"item": item.to_dict(), "owner": 0, "rolling": roll}
	_spawn_drop.rpc(id, item.to_dict(), where, roll)
	if roll:
		var peers := []
		for p in nearby:
			peers.append(p.get_multiplayer_authority())
		var timer := get_tree().create_timer(ROLL_TIME, false)
		_rolls[id] = {"choices": {}, "peers": peers}
		timer.timeout.connect(_resolve_roll.bind(id))
		for peer in peers:
			if peer == multiplayer.get_unique_id():
				_offer_roll(id, item.to_dict())
			else:
				_offer_roll.rpc_id(peer, id, item.to_dict())


# --- Everyone: drops appear and disappear ---------------------------------------------

@rpc("authority", "call_local", "reliable")
func _spawn_drop(id: int, item_dict: Dictionary, where: Vector3, rolling: bool) -> void:
	var item := ItemInstance.from_dict(item_dict)
	if item == null:
		return
	var drop: Node3D = DROP_SCRIPT.new()
	drop.set(&"drop_id", id)
	drop.set(&"item", item)
	drop.set(&"rolling", rolling)
	CombatFx.world().add_child(drop)
	drop.global_position = where
	_drops[id] = drop


@rpc("authority", "call_local", "reliable")
func _remove_drop(id: int) -> void:
	var drop: Node = _drops.get(id)
	_drops.erase(id)
	if is_instance_valid(drop):
		drop.queue_free()


@rpc("authority", "call_local", "reliable")
func _reserve_drop(id: int, owner_peer: int, owner_name: String) -> void:
	var drop: Node = _drops.get(id)
	if is_instance_valid(drop):
		drop.set(&"rolling", false)
		drop.set(&"owner_peer", owner_peer)
		drop.set(&"owner_name", owner_name)


# --- Picking up --------------------------------------------------------------------

## Ask to pick up a drop (checks your backpack has room first).
func request_pickup(id: int, player: Player) -> void:
	var drop: Node = _drops.get(id)
	if not is_instance_valid(drop):
		return
	if not player.inventory.backpack.has_room_for(drop.get(&"item")):
		CombatFx.word(player.global_position + Vector3.UP * 2.0, "Backpack full")
		return
	if multiplayer.is_server():
		_host_pickup(id, multiplayer.get_unique_id())
	else:
		_net_request_pickup.rpc_id(1, id)


@rpc("any_peer", "call_remote", "reliable")
func _net_request_pickup(id: int) -> void:
	if multiplayer.is_server():
		_host_pickup(id, multiplayer.get_remote_sender_id())


func _host_pickup(id: int, peer: int) -> void:
	var d: Dictionary = _host_drops.get(id, {})
	if d.is_empty() or d.rolling or (d.owner != 0 and d.owner != peer):
		return
	_host_drops.erase(id)
	_remove_drop.rpc(id)
	if peer == multiplayer.get_unique_id():
		_give(d.item)
	else:
		_net_give.rpc_id(peer, d.item)


@rpc("authority", "call_remote", "reliable")
func _net_give(item_dict: Dictionary) -> void:
	_give(item_dict)


func _give(item_dict: Dictionary) -> void:
	var me := get_tree().get_first_node_in_group(&"local_player") as Player
	var it := ItemInstance.from_dict(item_dict)
	if me and it and not me.receive_item(it):
		drop_item(it, me.global_position)  # no room after all: put it back down


## Put an item on the ground (dropping from your backpack, or trading to a friend).
func drop_item(item: ItemInstance, where: Vector3) -> void:
	if multiplayer.is_server():
		_host_spawn(item, where, [])
	else:
		_net_drop.rpc_id(1, item.to_dict(), where)


@rpc("any_peer", "call_remote", "reliable")
func _net_drop(item_dict: Dictionary, where: Vector3) -> void:
	if multiplayer.is_server():
		var it := ItemInstance.from_dict(item_dict)
		if it:
			_host_spawn(it, where, [])


# --- Need / Greed / Pass -------------------------------------------------------------

@rpc("authority", "call_remote", "reliable")
func _offer_roll(id: int, item_dict: Dictionary) -> void:
	var it := ItemInstance.from_dict(item_dict)
	if it:
		roll_offered.emit(id, it, ROLL_TIME)


## Your answer to a roll (from the roll pop-up).
func choose(id: int, choice: Choice) -> void:
	if multiplayer.is_server():
		_host_choice(id, multiplayer.get_unique_id(), choice)
	else:
		_net_choose.rpc_id(1, id, choice)
	roll_closed.emit(id)


@rpc("any_peer", "call_remote", "reliable")
func _net_choose(id: int, choice: int) -> void:
	if multiplayer.is_server():
		_host_choice(id, multiplayer.get_remote_sender_id(), choice)


func _host_choice(id: int, peer: int, choice: int) -> void:
	var r: Dictionary = _rolls.get(id, {})
	if r.is_empty() or not (peer in r.peers):
		return
	r.choices[peer] = choice
	if r.choices.size() >= r.peers.size():
		_resolve_roll(id)


func _resolve_roll(id: int) -> void:
	var r: Dictionary = _rolls.get(id, {})
	if r.is_empty():
		return
	_rolls.erase(id)
	var d: Dictionary = _host_drops.get(id, {})
	if d.is_empty():
		return
	var best_peer := 0
	var best_choice := Choice.PASS
	var best_number := -1
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var lines := PackedStringArray()
	for peer in r.peers:
		var c: int = r.choices.get(peer, Choice.PASS)
		if c == Choice.PASS:
			continue
		var n := rng.randi_range(1, 100)
		lines.append("%s %s %d" % [Net.name_of(peer), ["passes", "Greed", "Need"][c], n])
		if c > best_choice or (c == best_choice and n > best_number):
			best_choice = c
			best_number = n
			best_peer = peer
	var item := ItemInstance.from_dict(d.item)
	d.rolling = false
	if best_peer == 0:
		_announce.rpc("Everyone passed on %s." % item.display_name())
		_reserve_drop.rpc(id, 0, "")
		return
	d.owner = best_peer
	_announce.rpc("%s wins %s (%s)" % [Net.name_of(best_peer), item.display_name(), ", ".join(lines)])
	_reserve_drop.rpc(id, best_peer, Net.name_of(best_peer))
	_close_rolls.rpc(id)


@rpc("authority", "call_local", "reliable")
func _close_rolls(id: int) -> void:
	roll_closed.emit(id)


@rpc("authority", "call_local", "reliable")
func _announce(text: String) -> void:
	Net.system_message(text)


# --- Death piles (DESIGN.md 10) ---------------------------------------------------------

const PILE_SCRIPT := preload("res://game/items/death_pile.gd")
## How long a death pile lasts while the world is running (server setting).
var pile_minutes := 60.0

var _piles := {}  # id -> pile node (every machine)
## Host only: id -> {"owner": peer, "name": String, "items": [dicts], "gold", "souls", "expires": msec}
var _host_piles := {}


## You died: leave everything you lost in a pile (called on the dying player's machine).
func create_death_pile(owner_name: String, items: Array, gold: int, souls: int, where: Vector3) -> void:
	if items.is_empty() and gold <= 0 and souls <= 0:
		_destroy_owner_piles_everywhere()
		return
	if multiplayer.is_server():
		_host_create_pile(multiplayer.get_unique_id(), owner_name, items, gold, souls, where)
	else:
		_net_create_pile.rpc_id(1, owner_name, items, gold, souls, where)


func _destroy_owner_piles_everywhere() -> void:
	if multiplayer.is_server():
		_host_destroy_piles_of(multiplayer.get_unique_id())
	else:
		_net_destroy_my_piles.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _net_destroy_my_piles() -> void:
	if multiplayer.is_server():
		_host_destroy_piles_of(multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "reliable")
func _net_create_pile(owner_name: String, items: Array, gold: int, souls: int, where: Vector3) -> void:
	if multiplayer.is_server():
		_host_create_pile(multiplayer.get_remote_sender_id(), owner_name, items, gold, souls, where)


func _host_destroy_piles_of(peer: int) -> bool:
	var any := false
	for id in _host_piles.keys():
		if _host_piles[id].owner == peer:
			_host_piles.erase(id)
			_remove_pile.rpc(id)
			any = true
	return any


func _host_create_pile(peer: int, owner_name: String, items: Array, gold: int, souls: int, where: Vector3) -> void:
	# Dying again before recovering the old pile: it's gone for good.
	if _host_destroy_piles_of(peer):
		_announce.rpc("%s's earlier belongings are lost for good." % owner_name)
	var id := _next_id
	_next_id += 1
	var seconds := pile_minutes * 60.0
	_host_piles[id] = {"owner": peer, "name": owner_name, "items": items, "gold": gold, "souls": souls,
			"expires": Time.get_ticks_msec() + int(seconds * 1000.0)}
	_spawn_pile.rpc(id, peer, owner_name, items.size(), gold, souls, where, seconds)


@rpc("authority", "call_local", "reliable")
func _spawn_pile(id: int, peer: int, owner_name: String, count: int, gold: int, souls: int, where: Vector3, seconds: float) -> void:
	var pile: Node3D = PILE_SCRIPT.new()
	pile.set(&"pile_id", id)
	pile.set(&"owner_peer", peer)
	pile.set(&"owner_name", owner_name)
	pile.set(&"item_count", count)
	pile.set(&"gold", gold)
	pile.set(&"souls", souls)
	pile.set(&"time_left", seconds)
	CombatFx.world().add_child(pile)
	pile.global_position = where
	_piles[id] = pile


@rpc("authority", "call_local", "reliable")
func _remove_pile(id: int) -> void:
	var pile: Node = _piles.get(id)
	_piles.erase(id)
	if is_instance_valid(pile):
		pile.queue_free()


## Anyone in the party can recover a pile; it all goes back to its owner.
func request_recover(id: int) -> void:
	if multiplayer.is_server():
		_host_recover(id, multiplayer.get_unique_id())
	else:
		_net_recover.rpc_id(1, id)


@rpc("any_peer", "call_remote", "reliable")
func _net_recover(id: int) -> void:
	if multiplayer.is_server():
		_host_recover(id, multiplayer.get_remote_sender_id())


func _host_recover(id: int, by_peer: int) -> void:
	var p: Dictionary = _host_piles.get(id, {})
	if p.is_empty():
		return
	_host_piles.erase(id)
	_remove_pile.rpc(id)
	if by_peer != p.owner:
		_announce.rpc("%s recovered %s's belongings." % [Net.name_of(by_peer), p.name])
	if p.owner == multiplayer.get_unique_id():
		_return_pile(p.items, p.gold, p.souls)
	else:
		_net_return_pile.rpc_id(p.owner, p.items, p.gold, p.souls)


@rpc("authority", "call_remote", "reliable")
func _net_return_pile(items: Array, gold: int, souls: int) -> void:
	_return_pile(items, gold, souls)


## Your belongings come back: backpack first, then the bank, then the ground at your feet.
func _return_pile(items: Array, gold: int, souls: int) -> void:
	var me := get_tree().get_first_node_in_group(&"local_player") as Player
	if me == null:
		return
	me.inventory.add_money(gold, souls)
	for d in items:
		var it := ItemInstance.from_dict(d)
		if it == null:
			continue
		if not me.inventory.backpack.add(it) and not me.inventory.bank.add(it):
			drop_item(it, me.global_position)
	me.inventory.changed.emit()
	CombatFx.word(me.global_position + Vector3.UP * 2.2, "Belongings recovered")
	me.save_character()


func _process(_delta: float) -> void:
	if not multiplayer.has_multiplayer_peer() or not multiplayer.is_server():
		return
	var now := Time.get_ticks_msec()
	for id in _host_piles.keys():
		if now >= int(_host_piles[id].expires):
			var p: Dictionary = _host_piles[id]
			_host_piles.erase(id)
			_remove_pile.rpc(id)
			_announce.rpc("%s's belongings have crumbled to dust." % p.name)


func pile_count() -> int:
	return _piles.size()


func piles() -> Array:
	return _piles.values()


func drop_count() -> int:
	return _drops.size()


## For tests: the drop nodes currently in the world.
func drops() -> Array:
	return _drops.values()
