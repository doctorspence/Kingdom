class_name ItemGrid
extends RefCounted
## A grid of cells where items take up their shape (a ring 1×1, a sword 1×3).
## Used for the backpack and the bank.

var width := 10
var height := 6
var items := {}  # uid -> ItemInstance
var positions := {}  # uid -> Vector2i (top-left cell)


func _init(w := 10, h := 6) -> void:
	width = w
	height = h


func item_at(cell: Vector2i) -> ItemInstance:
	for uid in items:
		var p: Vector2i = positions[uid]
		var s: Vector2i = items[uid].base.grid_size
		if cell.x >= p.x and cell.x < p.x + s.x and cell.y >= p.y and cell.y < p.y + s.y:
			return items[uid]
	return null


func can_place(item: ItemInstance, at: Vector2i, ignore_uid := "") -> bool:
	var s := item.base.grid_size
	if at.x < 0 or at.y < 0 or at.x + s.x > width or at.y + s.y > height:
		return false
	for uid in items:
		if uid == ignore_uid:
			continue
		var p: Vector2i = positions[uid]
		var o: Vector2i = items[uid].base.grid_size
		if at.x < p.x + o.x and p.x < at.x + s.x and at.y < p.y + o.y and p.y < at.y + s.y:
			return false
	return true


## First free spot for this item (scanning row by row), or (-1, -1).
func find_space(item: ItemInstance) -> Vector2i:
	for y in height:
		for x in width:
			if can_place(item, Vector2i(x, y)):
				return Vector2i(x, y)
	return Vector2i(-1, -1)


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
	var at := find_space(item)
	if at.x < 0:
		return false
	place(item, at)
	return true


func place(item: ItemInstance, at: Vector2i) -> void:
	items[item.uid] = item
	positions[item.uid] = at


func remove(uid: String) -> ItemInstance:
	var it: ItemInstance = items.get(uid)
	items.erase(uid)
	positions.erase(uid)
	return it


func has_room_for(item: ItemInstance) -> bool:
	if item.base.stack_max > 1:
		for uid in items:
			var other: ItemInstance = items[uid]
			if other.base == item.base and other.count + item.count <= other.base.stack_max:
				return true
	return find_space(item).x >= 0


func to_dict() -> Dictionary:
	var list := []
	for uid in items:
		var d: Dictionary = items[uid].to_dict()
		d["x"] = positions[uid].x
		d["y"] = positions[uid].y
		list.append(d)
	return {"w": width, "h": height, "items": list}


func load_dict(d: Dictionary) -> void:
	width = int(d.get("w", width))
	height = int(d.get("h", height))
	items.clear()
	positions.clear()
	for e in d.get("items", []):
		var it := ItemInstance.from_dict(e)
		if it:
			place(it, Vector2i(int(e.get("x", 0)), int(e.get("y", 0))))
