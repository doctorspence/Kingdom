class_name Exploration
extends RefCounted
## What one character has explored, kept per world and zone (DESIGN.md 11.4):
## the fog-of-war map, the shrines they found, and the last shrine they rested at.
## Saved with the character, so it travels with them, but each world keeps its own.

## The map is a GRID x GRID grid of cells over the zone, one bit each.
const GRID := 128

## key ("world/zone") -> {"fog": PackedByteArray, "shrines": Array[String], "last_shrine": String}
var worlds := {}


func _entry(key: String) -> Dictionary:
	if not worlds.has(key):
		var fog := PackedByteArray()
		fog.resize(GRID * GRID / 8)
		worlds[key] = {"fog": fog, "shrines": [], "last_shrine": ""}
	return worlds[key]


## Clear the fog in a circle around a spot. Returns how many cells were new.
func reveal(key: String, pos: Vector3, radius: float, zone_size: float) -> int:
	var fog: PackedByteArray = _entry(key).fog
	var cell := zone_size / GRID
	var c := _cell_of(pos, zone_size)
	var r := int(ceil(radius / cell))
	var fresh := 0
	for y in range(maxi(c.y - r, 0), mini(c.y + r + 1, GRID)):
		for x in range(maxi(c.x - r, 0), mini(c.x + r + 1, GRID)):
			if Vector2(x - c.x, y - c.y).length() * cell > radius:
				continue
			var i := y * GRID + x
			var bit := 1 << (i & 7)
			if fog[i >> 3] & bit == 0:
				fog[i >> 3] |= bit
				fresh += 1
	return fresh


func is_revealed(key: String, x: int, y: int) -> bool:
	if not worlds.has(key) or x < 0 or y < 0 or x >= GRID or y >= GRID:
		return false
	var i := y * GRID + x
	return (worlds[key].fog as PackedByteArray)[i >> 3] & (1 << (i & 7)) != 0


func revealed_at(key: String, pos: Vector3, zone_size: float) -> bool:
	var c := _cell_of(pos, zone_size)
	return is_revealed(key, c.x, c.y)


## How much of the zone is uncovered (0..1).
func revealed_fraction(key: String) -> float:
	if not worlds.has(key):
		return 0.0
	var n := 0
	for b in (worlds[key].fog as PackedByteArray):
		while b:
			n += b & 1
			b >>= 1
	return float(n) / (GRID * GRID)


## A grayscale image, white where explored (for the map screen).
func fog_image(key: String) -> Image:
	var img := Image.create(GRID, GRID, false, Image.FORMAT_L8)
	for y in GRID:
		for x in GRID:
			img.set_pixel(x, y, Color.WHITE if is_revealed(key, x, y) else Color.BLACK)
	return img


func found_shrines(key: String) -> Array:
	return _entry(key).shrines


## Returns true the first time.
func discover_shrine(key: String, id: StringName) -> bool:
	var list: Array = _entry(key).shrines
	if list.has(String(id)):
		return false
	list.append(String(id))
	return true


func last_shrine(key: String) -> String:
	return _entry(key).last_shrine


func set_last_shrine(key: String, id: StringName) -> void:
	_entry(key).last_shrine = String(id)


func _cell_of(pos: Vector3, zone_size: float) -> Vector2i:
	var half := zone_size * 0.5
	return Vector2i(int((pos.x + half) / zone_size * GRID), int((pos.z + half) / zone_size * GRID))


func to_dict() -> Dictionary:
	var out := {}
	for key in worlds:
		var w: Dictionary = worlds[key]
		out[key] = {
			"fog": Marshalls.raw_to_base64((w.fog as PackedByteArray).compress(FileAccess.COMPRESSION_DEFLATE)),
			"shrines": w.shrines.duplicate(),
			"last_shrine": w.last_shrine,
		}
	return out


func load_dict(d: Dictionary) -> void:
	worlds.clear()
	for key in d:
		var w: Dictionary = d[key]
		var e := _entry(key)
		var raw := Marshalls.base64_to_raw(String(w.get("fog", "")))
		if raw.size() > 0:
			var fog := raw.decompress(GRID * GRID / 8, FileAccess.COMPRESSION_DEFLATE)
			if fog.size() == GRID * GRID / 8:
				e.fog = fog
		for s in w.get("shrines", []):
			e.shrines.append(String(s))
		e.last_shrine = String(w.get("last_shrine", ""))
