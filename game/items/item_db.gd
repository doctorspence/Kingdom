extends Node
## Every base item in data/items/, looked up by ID, plus loot rolling.
## Runs at start-up (autoload "ItemDB").

const ITEMS_DIR := "res://data/items"
var balance: LootBalance = load("res://data/balance/loot.tres")

var _items := {}  # id -> ItemData


func _ready() -> void:
	_scan(ITEMS_DIR)


func _scan(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_scan(dir_path.path_join(sub))
	for f in dir.get_files():
		# Exported games list "x.tres.remap"; load() still wants "x.tres".
		var file := f.trim_suffix(".remap")
		if file.ends_with(".tres"):
			var item := load(dir_path.path_join(file)) as ItemData
			if item:
				_items[item.id] = item


func get_item(id: StringName) -> ItemData:
	return _items.get(id)


func all_items() -> Array:
	return _items.values()


## Roll a table: returns {"items": Array[ItemInstance], "gold": int, "souls": int}.
func roll(table: LootTable, rng: RandomNumberGenerator = null) -> Dictionary:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var out: Array[ItemInstance] = []
	for item in table.always:
		out.append(make_item(item, rng.randi_range(table.item_level.x, table.item_level.y), item.min_rarity, rng))
	if rng.randf() < table.drop_chance:
		var n := rng.randi_range(table.item_count.x, table.item_count.y)
		for i in n:
			var base := _pick_base(table, rng)
			if base == null:
				continue
			var rarity := _pick_rarity(table.rarity_weights, rng)
			if i == 0:
				rarity = maxi(rarity, table.guaranteed_min_rarity)
			out.append(make_item(base, rng.randi_range(table.item_level.x, table.item_level.y), rarity, rng))
	return {
		"items": out,
		"gold": rng.randi_range(table.gold.x, table.gold.y),
		"souls": rng.randi_range(table.souls.x, table.souls.y),
	}


## Make a real item with random bonus rolls for its rarity.
func make_item(base: ItemData, ilvl: int, rarity: int, rng: RandomNumberGenerator = null) -> ItemInstance:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var it := ItemInstance.make(base, ilvl, rarity)
	if base.slot == ItemData.Slot.CONSUMABLE:
		it.rarity = ItemInstance.Rarity.COMMON
		return it
	var pool := PackedStringArray()
	for k in balance.bonus_ranges:
		if k in balance.weapon_only and base.weapon == null:
			continue
		pool.append(k)
	for i in ItemInstance.BONUS_COUNT[it.rarity]:
		if pool.is_empty():
			break
		var k := pool[rng.randi() % pool.size()]
		pool.remove_at(pool.find(k))
		var r: Vector2 = balance.bonus_ranges[k]
		var v := rng.randf_range(r.x, r.y)
		if not (k in balance.flat_bonuses):
			v *= 1.0 + balance.per_ilvl * (ilvl - 1)
			v = roundf(v)
		it.bonuses[k] = v
	return it


func _pick_base(table: LootTable, rng: RandomNumberGenerator) -> ItemData:
	var candidates: Array = table.items if not table.items.is_empty() else _general_pool(rng)
	candidates = candidates.filter(func(i: ItemData) -> bool: return i.min_rarity < ItemInstance.Rarity.LEGENDARY)
	if candidates.is_empty():
		return null
	return candidates[rng.randi() % candidates.size()]


## Pick a category (weapon / shield / armor / jewelry), then items of it.
func _general_pool(rng: RandomNumberGenerator) -> Array:
	var weights := balance.category_weights
	var total := 0.0
	for w in weights:
		total += w
	var r := rng.randf() * total
	var cat := 0
	for i in weights.size():
		r -= weights[i]
		if r <= 0.0:
			cat = i
			break
	return _items.values().filter(func(i: ItemData) -> bool:
		match cat:
			0: return i.weapon != null
			1: return i.shield != null
			2: return i.slot in [ItemData.Slot.HEAD, ItemData.Slot.SHOULDERS, ItemData.Slot.CHEST, ItemData.Slot.HANDS,
					ItemData.Slot.LEGS, ItemData.Slot.FEET, ItemData.Slot.CLOAK]
			_: return i.slot in [ItemData.Slot.NECK, ItemData.Slot.RING]
	)


func _pick_rarity(weights: PackedFloat32Array, rng: RandomNumberGenerator) -> int:
	var total := 0.0
	for w in weights:
		total += w
	var r := rng.randf() * total
	for i in weights.size():
		r -= weights[i]
		if r <= 0.0:
			return i
	return 0
