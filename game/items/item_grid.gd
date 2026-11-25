class_name ItemGrid
extends RefCounted
## A grid of cells where items take up their shape (a ring 1×1, a sword 1×3).
## Used for the backpack and the bank. Long items can lie turned on their side
## (rotated): a 1×3 sword then takes 3×1.

var width := 10
var height := 6
var items := {}  # uid -> ItemInstance
var positions := {}  # uid -> Vector2i (top-left cell)
var rotated := {}  # uid -> true when the item lies on its side


func _init(w := 10, h := 6) -> void:
	width = w
	height = h


## The cells an item covers (columns × rows), turned or not.
static func footprint(item: ItemInstance, rot := false) -> Vector2i:
	var s := item.base.grid_size
	return Vector2i(s.y, s.x) if rot and s.x != s.y else s


## How a placed item lies right now.
func size_of(uid: String) -> Vector2i:
	return footprint(items[uid], rotated.get(uid, false))


func is_rotated(uid: String) -> bool:
	return rotated.get(uid, false)


func item_at(cell: Vector2i) -> ItemInstance:
	for uid in items:
		var p: Vector2i = positions[uid]
		var s := size_of(uid)
		if cell.x >= p.x and cell.x < p.x + s.x and cell.y >= p.y and cell.y < p.y + s.y:
			return items[uid]
	return null


func can_place(item: ItemInstance, at: Vector2i, ignore_uid := "", rot := false) -> bool:
	var s := footprint(item, rot)
	if at.x < 0 or at.y < 0 or at.x + s.x > width or at.y + s.y > height:
		return false
	for uid in items:
		if uid == ignore_uid or uid == item.uid:
			continue
		var p: Vector2i = positions[uid]
		var o := size_of(uid)
		if at.x < p.x + o.x and p.x < at.x + s.x and at.y < p.y + o.y and p.y < at.y + s.y:
			return false
	return true


## First free spot for this item (scanning row by row), or (-1, -1). Tries it
## upright first, then on its side.
func find_space(item: ItemInstance) -> Vector2i:
	return _find_space(item)[0]


func _find_space(item: ItemInstance) -> Array:
	for rot in [false, true]:
		if rot and item.base.grid_size.x == item.base.grid_size.y:
			break
		for y in height:
			for x in width:
				if can_place(item, Vector2i(x, y), "", rot):
					return [Vector2i(x, y), rot]
	return [Vector2i(-1, -1), false]


## Add anywhere (stacks consumables first). Returns false if there's no room.
func add(item: ItemInstance) -> bool:
	if item.base.stack_max > 1:
		for uid in items:
			var other: ItemInstance = items[uid]
			if other.base == item.base and other.count < other.base.stack_max:
				var moved := mini(item.count, other.base.stack_max - other.count)
				other.count += moved
				item.count -= moved
				if item.count <= 0:
					return true
	var spot := _find_space(item)
	if spot[0].x < 0:
		return false
	place(item, spot[0], spot[1])
	return true


func place(item: ItemInstance, at: Vector2i, rot := false) -> void:
	items[item.uid] = item
	positions[item.uid] = at
	if rot and item.base.grid_size.x != item.base.grid_size.y:
		rotated[item.uid] = true
	else:
		rotated.erase(item.uid)


## Move an item already in this grid to a new spot (and turn it). False if it doesn't fit.
func move(uid: String, at: Vector2i, rot := false) -> bool:
	if not items.has(uid) or not can_place(items[uid], at, uid, rot):
		return false
	place(items[uid], at, rot)
	return true


## Pour one stack into another of the same item. Returns how many moved.
func merge(from_uid: String, into_uid: String) -> int:
	var a: ItemInstance = items.get(from_uid)
	var b: ItemInstance = items.get(into_uid)
	if a == null or b == null or a == b or a.base != b.base or b.base.stack_max <= 1:
		return 0
	var moved := mini(a.count, b.base.stack_max - b.count)
	b.count += moved
	a.count -= moved
	if a.count <= 0:
		remove(from_uid)
	return moved


func remove(uid: String) -> ItemInstance:
	var it: ItemInstance = items.get(uid)
	items.erase(uid)
	positions.erase(uid)
	rotated.erase(uid)
	return it


func has_room_for(item: ItemInstance) -> bool:
	if item.base.stack_max > 1:
		for uid in items:
			var other: ItemInstance = items[uid]
			if other.base == item.base and other.count + item.count <= other.base.stack_max:
				return true
	return find_space(item).x >= 0


## Tidy everything: stacks merged, then by kind (weapons, off hands, armor, jewelry,
## consumables, junk last), biggest first. Long items stand upright where they can.
## If the new layout wouldn't fit, nothing changes and it returns false.
func sort() -> bool:
	var list: Array[ItemInstance] = []
	for uid in items:
		list.append(items[uid])
	# Merge partial stacks first.
	for i in list.size():
		for j in range(i + 1, list.size()):
			if list[i].count > 0 and list[j].count > 0 and list[i].base == list[j].base and list[i].base.stack_max > 1:
				var moved := mini(list[j].count, list[i].base.stack_max - list[i].count)
				list[i].count += moved
				list[j].count -= moved
	var old_pos := positions.duplicate()
	var old_rot := rotated.duplicate()
	var old_items := items.duplicate()
	list = list.filter(func(it: ItemInstance) -> bool: return it.count > 0)
	list.sort_custom(func(a: ItemInstance, b: ItemInstance) -> bool:
		var ka := _sort_key(a)
		var kb := _sort_key(b)
		for k in ka.size():
			if ka[k] != kb[k]:
				return ka[k] < kb[k]
		return false)
	items.clear()
	positions.clear()
	rotated.clear()
	# Tall items first, packed column-wise from the left, so swords stand side by side.
	for it in list:
		var spot := _find_space_columns(it)
		if spot[0].x < 0:
			spot = _find_space(it)
		if spot[0].x < 0:
			items = old_items
			positions = old_pos
			rotated = old_rot
			return false
		place(it, spot[0], spot[1])
	return true


func _find_space_columns(item: ItemInstance) -> Array:
	for rot in [false, true]:
		if rot and item.base.grid_size.x == item.base.grid_size.y:
			break
		for x in width:
			for y in height:
				if can_place(item, Vector2i(x, y), "", rot):
					return [Vector2i(x, y), rot]
	return [Vector2i(-1, -1), false]


static func _sort_key(it: ItemInstance) -> Array:
	var s := it.base.grid_size
	return [1 if it.junk else 0, it.base.category(), -s.y, -s.x, -it.rarity, it.display_name()]


func to_dict() -> Dictionary:
	var list := []
	for uid in items:
		var d: Dictionary = items[uid].to_dict()
		d["x"] = positions[uid].x
		d["y"] = positions[uid].y
		if rotated.get(uid, false):
			d["r"] = 1
		list.append(d)
	return {"w": width, "h": height, "items": list}


func load_dict(d: Dictionary) -> void:
	width = int(d.get("w", width))
	height = int(d.get("h", height))
	items.clear()
	positions.clear()
	rotated.clear()
	for e in d.get("items", []):
		var it := ItemInstance.from_dict(e)
		if it:
			place(it, Vector2i(int(e.get("x", 0)), int(e.get("y", 0))), int(e.get("r", 0)) == 1)
