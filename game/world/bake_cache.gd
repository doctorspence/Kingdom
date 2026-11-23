class_name BakeCache
## A small disk cache for slow load-time work whose result never changes unless the
## scripts or settings that make it change: code-painted textures, tree shapes, where
## plants and trees stand, terrain meshes. Each entry lives in user://bake_cache/ with
## a key made from everything it depends on (the source text of the scripts involved
## plus the settings), so editing the land or a builder simply rebuilds it once.
## Exported builds have no script source: the key is then "" and nothing is cached.

const DIR := "user://bake_cache"

static var _src_hash := {}


## A key from script paths (their source text) and any extra values; "" = don't cache.
static func key(script_paths: Array, extra: Variant = null) -> String:
	var s := ""
	for path: String in script_paths:
		if not _src_hash.has(path):
			var sc := load(path) as Script
			_src_hash[path] = "" if sc == null or sc.source_code.is_empty() else sc.source_code.sha256_text()
		if _src_hash[path] == "":
			return ""
		s += _src_hash[path]
	return (s + var_to_str(extra)).sha256_text()


static func fetch(name: String, k: String) -> Variant:
	if k == "" or not FileAccess.file_exists(_path(name)):
		return null
	var f := FileAccess.open(_path(name), FileAccess.READ)
	if f == null or f.get_length() < 9:
		return null
	var raw_size := int(f.get_64())
	var packed := f.get_buffer(f.get_length() - 8)
	if raw_size <= 0 or raw_size > 512 * 1024 * 1024:
		return null
	var raw := packed.decompress(raw_size, FileAccess.COMPRESSION_ZSTD)
	if raw.size() != raw_size:
		return null
	var d: Variant = bytes_to_var(raw)
	if not (d is Dictionary) or d.get("key", "") != k:
		return null
	return d.get("value")


## Writes to a temporary file first and then renames it, so several game copies
## starting together (the network check) never read a half-written file.
static func store(name: String, k: String, value: Variant) -> void:
	if k == "":
		return
	DirAccess.make_dir_recursive_absolute(DIR)
	var raw := var_to_bytes({"key": k, "value": value})
	var tmp := "%s.%d.tmp" % [_path(name), OS.get_process_id()]
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_64(raw.size())
	f.store_buffer(raw.compress(FileAccess.COMPRESSION_ZSTD))
	f.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_path(name)))
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(_path(name)))


## A code-painted image: from the cache, or drawn by maker (a Callable returning Image) and stored.
static func image(name: String, script_paths: Array, maker: Callable) -> Image:
	var k := key(script_paths, name)
	var d: Variant = fetch("img_" + name, k)
	if d is Dictionary:
		var img := Image.create_from_data(d.w, d.h, d.mip, d.fmt, d.data)
		if img and not img.is_empty():
			return img
	var made: Image = maker.call()
	store("img_" + name, k, {"w": made.get_width(), "h": made.get_height(), "mip": made.has_mipmaps(), "fmt": made.get_format(), "data": made.get_data()})
	return made


## Mesh <-> plain data (each surface's arrays), for storing generated meshes.
static func mesh_data(m: Mesh) -> Array:
	var out: Array = []
	if m == null:
		return out
	for s in m.get_surface_count():
		out.append(m.surface_get_arrays(s))
	return out


static func mesh_from(data: Array, mats: Array) -> ArrayMesh:
	if data.is_empty():
		return null
	var m := ArrayMesh.new()
	for s in data.size():
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data[s])
		if s < mats.size() and mats[s] != null:
			m.surface_set_material(s, mats[s])
	return m


static func _path(name: String) -> String:
	return "%s/%s.bin" % [DIR, name.validate_filename()]
