extends Node
## Automated check of the code-built bandits: the model on the shared skeleton, animations, gear
## in the hands, feet on the ground, and that each one still fights, takes hits and dies.
##   ... --headless --script res://tests/run.gd -- bandit_check

const BANDITS := ["bandit_sword", "bandit_pick", "bandit_lookout", "bandit_archer", "bandit_archer_ambush",
		"marauder", "bandit_captain", "bandit_rook", "hobb", "harl"]
const MAX_TRIANGLES := 6000
## the boss may be more detailed, and is built bigger
const BOSS_TRIANGLES := 9000

var failures := 0
var _rig_bones: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var rig: Node = (load("res://assets/characters/mannequin/UAL1_Standard.glb") as PackedScene).instantiate()
	var sk: Skeleton3D = rig.find_children("*", "Skeleton3D", true, false)[0]
	for i in sk.get_bone_count():
		_rig_bones.append(sk.get_bone_name(i))
	rig.free()
	var scene: Node = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(30)
	var player := get_tree().get_first_node_in_group(&"player") as Player
	for e in get_tree().get_nodes_in_group(&"enemies"):
		(e as Node3D).global_position = Vector3(90, 0, 90)
	var home := player.global_position
	for id: String in BANDITS:
		await _one(id, scene, player, home)
	await _looks(scene)
	await _stone(scene, player)
	print("PASS: 0 problem(s)" if failures == 0 else "FAIL: %d problem(s)" % failures)
	get_tree().quit(1 if failures > 0 else 0)


func _one(id: String, scene: Node, player: Player, home: Vector3) -> void:
	print("--- ", id)
	var e := (load("res://game/enemies/%s.tscn" % id) as PackedScene).instantiate() as Enemy
	var archer := e.data.keep_distance > 0.0
	var ambush := e.data.ambush_range > 0.0
	var away := 11.0 if archer else 2.2
	player.global_position = home
	player.health = player.max_health()
	e.position = home + Vector3(0, 0, -away)
	e.rotation.y = PI   # facing the player
	scene.get_node("Enemies").add_child(e)
	await _frames(3)
	var model: CharacterModel = e.model
	var sk: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
	var names: Array[String] = []
	for i in sk.get_bone_count():
		names.append(sk.get_bone_name(i))
	_check("on the shared UAL1 skeleton (%d bones)" % names.size(), names == _rig_bones)
	var tris := 0
	var shown: Array[MeshInstance3D] = []
	var mannequin := false
	for c in sk.get_children():
		var mi := c as MeshInstance3D
		if mi and mi.visible and not mi.is_queued_for_deletion():
			shown.append(mi)
			mannequin = mannequin or mi.name.begins_with("Mannequin")
			tris += mi.mesh.surface_get_array_len(0) / 3
	_check("wears the bandit (%d parts, %d triangles), no mannequin" % [shown.size(), tris],
			shown.size() >= 4 and tris > 2000 and tris < (BOSS_TRIANGLES if e.data.boss else MAX_TRIANGLES) and not mannequin)
	var anims: Array[StringName] = [&"Idle", &"Walk", &"Jog_Fwd", &"Sword_Idle", &"Hit_Chest", &"ual2/Hit_Knockback", &"Death01"]
	for a in e.data.attacks:
		anims.append(a.anim)
	var missing: Array[StringName] = []
	var player_node: AnimationPlayer = model.find_children("*", "AnimationPlayer", true, false)[0]
	for a in anims:
		if not player_node.has_animation(a):
			missing.append(a)
	_check("has idle, walk, run, combat idle, its attacks, hit and death %s" % str(missing), missing.is_empty())
	var right := 0
	for c in sk.get_children():
		if c is BoneAttachment3D:
			right += c.get_child_count()
	# calm bandits stow their gear, so count it wherever it hangs
	var wanted := 2 if e.data.offhand_scene else 1
	_check("carries its weapon%s (in hand or stowed)" % (" and shield" if e.data.offhand_scene else ""),
			right == wanted)
	var shape := (e.get_node("CollisionShape3D") as CollisionShape3D).shape as CapsuleShape3D
	var capsule := Vector2(0.55, 2.7) if e.data.boss else Vector2(0.42, 2.0)
	_check("same collision capsule as before", is_equal_approx(shape.radius, capsule.x) and is_equal_approx(shape.height, capsule.y))
	_check("stands on the floor (feet %.3f m)" % (_lowest(e, sk, shown)), absf(_lowest(e, sk, shown)) < 0.05)
	var top := _highest(e, sk, shown)
	_check("a man's height (%.2f m)" % top, top > 1.75 and top < 1.98 * e.data.scale)

	# it notices you and fights
	if not ambush:
		e.target = player
		e._set_state(Enemy.State.CHASE)
	else:
		player.global_position = e.global_position + Vector3(0, 0, 2.5)
	var attacked := false
	var low := 9.0
	for i in 600:
		await get_tree().physics_frame
		for a in e.data.attacks:
			attacked = attacked or model.current_anim() == a.anim
		if i % 20 == 0:
			low = minf(low, _lowest(e, sk, shown))
		if attacked and player.health < player.max_health():
			break
	_check("attacks (%s)" % ("hit the player" if player.health < player.max_health() else "swung"), attacked)
	_check("never sinks through the floor while moving (lowest %.3f m)" % low, low > -0.12)

	# takes a blow
	player.global_position = home
	var hp := e.health
	var hit := HitInfo.new()
	hit.attacker = player
	hit.damage = 20.0
	hit.origin = player.global_position
	for i in 40:
		e.receive_hit(hit)
		if e.health < hp:
			break
		await _frames(15)   # it may have been guarding
	_check("takes damage (%.0f -> %.0f)" % [hp, e.health], e.health < hp)

	# and dies
	var coins := player.inventory.coins
	var drops := Loot.drop_count()
	hit.damage = 100000.0
	for i in 40:
		if e.state == Enemy.State.DEAD:
			break
		e.receive_hit(hit)
		await _frames(10)
	_check("dies, stops blocking the way", e.state == Enemy.State.DEAD and e.collision_layer == 0 and model.current_anim() == CharacterModel.ANIM_DEATH)
	await _frames(150)
	_check("lies on the ground (lowest %.3f m, top %.2f m)" % [_lowest(e, sk, shown), _highest(e, sk, shown)],
			_lowest(e, sk, shown) > -0.2 and _highest(e, sk, shown) < 0.9 * maxf(1.0, e.data.scale / 1.1))
	_check("loot as before (%d coins, %d drops)" % [player.inventory.coins - coins, Loot.drop_count() - drops],
			player.inventory.coins > coins or Loot.drop_count() > drops)
	e.global_position = Vector3(90, 0, 90 + failures)
	e.queue_free()
	await _frames(5)


## Marauders come in two looks, picked from the name, so every player sees the same one.
func _looks(scene: Node) -> void:
	print("--- marauder looks")
	var seen := {}
	var steady := true
	for i in 8:
		var name_ := "Spawn_%d" % i
		var mesh: Mesh = null
		for again in 2:
			var e := (load("res://game/enemies/marauder.tscn") as PackedScene).instantiate() as Enemy
			e.name = name_
			e.position = Vector3(80, 0, 80)
			scene.get_node("Enemies").add_child(e)
			await _frames(2)
			var body := (e.model.find_child("ClothingMesh", true, false) as MeshInstance3D)
			var armor := (e.model.find_child("ArmorMesh", true, false) as MeshInstance3D)
			if again == 0:
				mesh = armor.mesh
			else:
				steady = steady and armor.mesh == mesh and body != null
			e.free()
			await _frames(2)
		seen[mesh] = true
	_check("marauders wear both looks (%d seen)" % seen.size(), seen.size() == 2)
	_check("the same name always gets the same look", steady)


## Harl's second phase shows on his own skin: the marks and the stone's light, once he has
## finished kneeling to it, and gone again if the fight resets.
func _stone(scene: Node, player: Player) -> void:
	print("--- Harl and the stone")
	var e := (load("res://game/enemies/harl.tscn") as PackedScene).instantiate() as Enemy
	e.position = Vector3(70, 0, 70)
	scene.get_node("Enemies").add_child(e)
	await _frames(10)
	var model: CharacterModel = e.model
	var body := model.find_child("BodyMesh", true, false) as MeshInstance3D
	var pick := model.find_child("PickMesh", true, false) as MeshInstance3D
	_check("carries his own pick", pick != null)
	_check("starts with the marks only on his arm", body.material_override == null)
	# someone to fight, or he gives up and starts the fight over
	player.global_position = e.global_position + Vector3(0, 0, 6)
	player.health = player.max_health()
	e.target = player
	e._start_phase2()
	await _frames(15)
	_check("no change while he is still kneeling to the stone", body.material_override == null)
	await _frames(ceili((e.data.call_time + 0.5) * Engine.physics_ticks_per_second))
	var skin := body.material_override as StandardMaterial3D
	_check("then the stone shows on him, his own painted skin", skin != null and skin.emission_enabled
			and skin.albedo_texture != null)
	_check("...and on the pick", pick != null and pick.material_override != null)
	e._reset()
	await _frames(10)
	_check("gone again when the fight starts over", body.material_override == null and (pick == null or pick.material_override == null))
	e.free()
	await _frames(5)


## Heights of the posed model above the enemy's origin, skinned on the CPU.
func _extent(e: Enemy, sk: Skeleton3D, meshes: Array[MeshInstance3D]) -> Vector2:
	var lo := 1e9
	var hi := -1e9
	var to_world := sk.global_transform
	for mi in meshes:
		var arr := mi.mesh.surface_get_arrays(0)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var b: PackedInt32Array = arr[Mesh.ARRAY_BONES]
		var w: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
		var mats: Array[Transform3D] = []
		for i in mi.skin.get_bind_count():
			mats.append(to_world * sk.get_bone_global_pose(i) * mi.skin.get_bind_pose(i))
		for i in range(0, v.size(), 3):
			var p := Vector3.ZERO
			for k in 4:
				if w[i * 4 + k] > 0.0:
					p += (mats[b[i * 4 + k]] * v[i]) * w[i * 4 + k]
			lo = minf(lo, p.y - e.global_position.y)
			hi = maxf(hi, p.y - e.global_position.y)
	return Vector2(lo, hi)


func _lowest(e: Enemy, sk: Skeleton3D, meshes: Array[MeshInstance3D]) -> float:
	return _extent(e, sk, meshes).x


func _highest(e: Enemy, sk: Skeleton3D, meshes: Array[MeshInstance3D]) -> float:
	return _extent(e, sk, meshes).y


func _check(label: String, ok: bool) -> void:
	print("%s  %s" % ["ok  " if ok else "FAIL", label])
	if not ok:
		failures += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
