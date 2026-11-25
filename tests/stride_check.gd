extends Node
## Measures how fast each looping run animation's planted foot moves backwards
## (= the ground speed at which the feet don't slide), so the numbers in
## CharacterModel (walk/run/sprint_anim_speed) can be checked against the animation.
##   Godot_console.exe --headless --path . --script res://tests/run.gd -- stride_check


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	# The player's model, built the way player.tscn builds it ("Visual" + the mannequin).
	var model := CharacterModel.new()
	model.add_child((load("res://assets/characters/mannequin/UAL1_Standard.glb") as PackedScene).instantiate())
	add_child(model)
	model.set_physics_process(false)
	await get_tree().process_frame
	var anim: AnimationPlayer = model.find_children("*", "AnimationPlayer", true, false)[0]
	var skel: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
	var cm := model as CharacterModel
	for pair in [[CharacterModel.ANIM_WALK, cm.walk_anim_speed], [CharacterModel.ANIM_RUN, cm.run_anim_speed],
			[CharacterModel.ANIM_SPRINT, cm.sprint_anim_speed]]:
		var anim_name: StringName = pair[0]
		var a := anim.get_animation(anim_name)
		anim.play(anim_name)
		anim.speed_scale = 0.0
		var speeds: Array[float] = []
		for foot in ["foot_l", "foot_r"]:
			var bone := skel.find_bone(foot)
			var samples: Array[Vector3] = []
			var steps := 120
			for i in steps + 1:
				anim.seek(a.length * i / steps, true)
				skel.force_update_all_bone_transforms()
				samples.append(skel.global_transform * skel.get_bone_global_pose(bone).origin)
			var low := INF
			for s in samples:
				low = minf(low, s.y)
			# Planted = within 5 cm of the lowest point and moving backwards.
			# Take the median backward speed (heel-to-toe roll makes the ends noisy).
			var dt := a.length / steps
			var planted: Array[float] = []
			for i in steps:
				var v := -(samples[i + 1] - samples[i]).dot(model.forward()) / dt
				if samples[i].y < low + 0.05 and samples[i + 1].y < low + 0.05 and v > 0.0:
					planted.append(v)
			var lo := INF
			var hi := -INF
			for s in samples:
				var f := s.dot(model.forward())
				lo = minf(lo, f)
				hi = maxf(hi, f)
			print("  %s %s: foot swings %.2f m front-to-back, planted %d of %d samples" % [anim_name, foot, hi - lo, planted.size(), steps])
			planted.sort()
			if not planted.is_empty():
				speeds.append(planted[planted.size() / 2])
		var measured := (speeds[0] + speeds[1]) * 0.5 if speeds.size() == 2 else NAN
		print("%-10s length %.2fs  planted-foot speed %.2f m/s (CharacterModel says %.2f)" % [anim_name, a.length, measured, pair[1]])
	get_tree().quit()
