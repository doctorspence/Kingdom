class_name Inventory
extends RefCounted
## Everything a character carries: equipped gear (two weapon sets), the
## backpack grid, the bank, coins and souls. Saved with the character.

signal changed

const SLOTS := ["head", "shoulders", "chest", "hands", "legs", "feet", "cloak", "neck", "ring1", "ring2",
		"main1", "off1", "main2", "off2"]
const SLOT_LABELS := {"head": "Head", "shoulders": "Shoulders", "chest": "Chest", "hands": "Hands", "legs": "Legs",
		"feet": "Feet", "cloak": "Cloak", "neck": "Neck", "ring1": "Ring", "ring2": "Ring",
		"main1": "Weapon (set 1)", "off1": "Off hand (set 1)", "main2": "Weapon (set 2)", "off2": "Off hand (set 2)"}
const BANK_WIDTH := 12
const BANK_START_ROWS := 4
const BANK_MAX_ROWS := 10
const BUYBACK_SIZE := 10

var equipped := {}  # slot key -> ItemInstance
var backpack := ItemGrid.new(10, 6)
var bank := ItemGrid.new(BANK_WIDTH, BANK_START_ROWS)
var coins := 0
var souls := 0
## Which weapon set is in your hands: 1 or 2.
var active_set := 1
## Recently sold items you can buy back (not saved).
var buyback: Array[ItemInstance] = []


# --- Equipment ------------------------------------------------------------------

func main_hand() -> ItemInstance:
	return equipped.get("main%d" % active_set)


func off_hand() -> ItemInstance:
	return equipped.get("off%d" % active_set)


## Which equipment slots this item can go in.
func slots_for(item: ItemInstance) -> PackedStringArray:
	match item.base.slot:
		ItemData.Slot.HEAD: return PackedStringArray(["head"])
		ItemData.Slot.SHOULDERS: return PackedStringArray(["shoulders"])
		ItemData.Slot.CHEST: return PackedStringArray(["chest"])
		ItemData.Slot.HANDS: return PackedStringArray(["hands"])
		ItemData.Slot.LEGS: return PackedStringArray(["legs"])
		ItemData.Slot.FEET: return PackedStringArray(["feet"])
		ItemData.Slot.CLOAK: return PackedStringArray(["cloak"])
		ItemData.Slot.NECK: return PackedStringArray(["neck"])
		ItemData.Slot.RING: return PackedStringArray(["ring1", "ring2"])
		ItemData.Slot.MAIN_HAND, ItemData.Slot.TWO_HAND: return PackedStringArray(["main%d" % active_set, "main%d" % (3 - active_set)])
		ItemData.Slot.OFF_HAND: return PackedStringArray(["off%d" % active_set, "off%d" % (3 - active_set)])
	return PackedStringArray()


## Equip a backpack item. Picks the best slot if none given. Whatever was in
## the slot goes back to the backpack. Returns "" or the reason it failed.
func equip(uid: String, slot := "") -> String:
	var item: ItemInstance = backpack.items.get(uid)
	if item == null:
		return "Not in your backpack"
	var options := slots_for(item)
	if options.is_empty():
		return "Can't be equipped"
	if slot == "":
		slot = options[0]
		for s in options:
			if not equipped.has(s):
				slot = s
				break
	elif not (slot in options):
		return "Doesn't go there"
	var set_n := slot.right(1)
	# Two-handed weapons need a free off hand (and vice versa).
	var to_backpack: Array[ItemInstance] = []
	if equipped.has(slot):
		to_backpack.append(equipped[slot])
	if item.base.slot == ItemData.Slot.TWO_HAND and equipped.has("off" + set_n):
		to_backpack.append(equipped["off" + set_n])
	if item.base.slot == ItemData.Slot.OFF_HAND:
		var main: ItemInstance = equipped.get("main" + set_n)
		if main and main.base.slot == ItemData.Slot.TWO_HAND:
			to_backpack.append(main)
	backpack.remove(uid)
	for old in to_backpack:
		equipped.erase(_slot_of(old))
	for old in to_backpack:
		if not backpack.add(old):
			# No room: undo everything.
			for o in to_backpack:
				backpack.remove(o.uid)
			for o in to_backpack:
				equipped[_restore_slot(o, slot, set_n)] = o
			backpack.add(item)
			return "No room in your backpack"
	equipped[slot] = item
	changed.emit()
	return ""


func _restore_slot(o: ItemInstance, slot: String, set_n: String) -> String:
	if o.base.slot == ItemData.Slot.OFF_HAND:
		return "off" + set_n
	if o.base.slot == ItemData.Slot.TWO_HAND or o.base.slot == ItemData.Slot.MAIN_HAND:
		return "main" + set_n
	return slot


func _slot_of(item: ItemInstance) -> String:
	for s in equipped:
		if equipped[s] == item:
			return s
	return ""


## Put an equipped item back in the backpack.
func unequip(slot: String) -> String:
	var item: ItemInstance = equipped.get(slot)
	if item == null:
		return ""
	if not backpack.has_room_for(item):
		return "No room in your backpack"
	equipped.erase(slot)
	backpack.add(item)
	changed.emit()
	return ""


func swap_weapon_set() -> void:
	active_set = 3 - active_set
	changed.emit()


## Gear that counts right now (the other weapon set doesn't).
func worn() -> Array[ItemInstance]:
	var out: Array[ItemInstance] = []
	for s in equipped:
		if s.begins_with("main") or s.begins_with("off"):
			if s.right(1) != str(active_set):
				continue
		out.append(equipped[s])
	return out


func stat_total(name: String) -> float:
	var v := 0.0
	for it in worn():
		v += it.stat(name)
	return v


func armor_total() -> float:
	var v := 0.0
	for it in worn():
		v += it.armor()
	return v


## Weight of everything equipped (both weapon sets count: you carry them).
func equipped_weight() -> float:
	var v := 0.0
	for s in equipped:
		v += equipped[s].weight()
	return v


## Legendary effects of worn items, merged.
func legendary_mods() -> Dictionary:
	var out := {}
	for it in worn():
		for k in it.base.legendary_mods:
			out[k] = out.get(k, 0.0) + float(it.base.legendary_mods[k])
	return out


# --- Backpack, money, bank ----------------------------------------------------------

func add_item(item: ItemInstance) -> bool:
	var ok := backpack.add(item)
	if ok:
		changed.emit()
	return ok


func remove_item(uid: String) -> ItemInstance:
	var it := backpack.remove(uid)
	if it == null:
		it = bank.remove(uid)
	changed.emit()
	return it


func add_money(add_coins: int, add_souls: int) -> void:
	coins += add_coins
	souls += add_souls
	changed.emit()


## Cost in coins of the next bank row (more space).
func next_bank_row_cost() -> int:
	return 150 * (bank.height - BANK_START_ROWS + 1)


func buy_bank_row() -> String:
	if bank.height >= BANK_MAX_ROWS:
		return "The bank is as big as it gets"
	var cost := next_bank_row_cost()
	if coins < cost:
		return "Not enough coins (%d)" % cost
	coins -= cost
	bank.height += 1
	changed.emit()
	return ""


## Move an item between backpack and bank.
func move_between(uid: String) -> String:
	if backpack.items.has(uid):
		var it: ItemInstance = backpack.items[uid]
		if not bank.has_room_for(it):
			return "The bank is full"
		backpack.remove(uid)
		bank.add(it)
	elif bank.items.has(uid):
		var it2: ItemInstance = bank.items[uid]
		if not backpack.has_room_for(it2):
			return "Your backpack is full"
		bank.remove(uid)
		backpack.add(it2)
	changed.emit()
	return ""


func sell(uid: String) -> int:
	var it: ItemInstance = backpack.remove(uid)
	if it == null:
		return 0
	var price := it.sell_value()
	coins += price
	buyback.push_front(it)
	if buyback.size() > BUYBACK_SIZE:
		buyback.pop_back()
	changed.emit()
	return price


func buy_back(uid: String) -> String:
	for it in buyback:
		if it.uid == uid:
			var price := it.sell_value()
			if coins < price:
				return "Not enough coins"
			if not backpack.has_room_for(it):
				return "Your backpack is full"
			coins -= price
			buyback.erase(it)
			backpack.add(it)
			changed.emit()
			return ""
	return "Gone"


# --- Saving ----------------------------------------------------------------------------

func to_dict() -> Dictionary:
	var eq := {}
	for s in equipped:
		eq[s] = equipped[s].to_dict()
	return {"equipped": eq, "backpack": backpack.to_dict(), "bank": bank.to_dict(),
			"coins": coins, "souls": souls, "active_set": active_set}


func load_dict(d: Dictionary) -> void:
	equipped.clear()
	var eq: Dictionary = d.get("equipped", {})
	for s in eq:
		var it := ItemInstance.from_dict(eq[s])
		if it:
			equipped[s] = it
	backpack.load_dict(d.get("backpack", {}))
	bank.load_dict(d.get("bank", {}))
	coins = int(d.get("coins", d.get("gold", 0)))  # old saves used "gold"
	souls = int(d.get("souls", 0))
	active_set = int(d.get("active_set", 1))
	changed.emit()
