extends Node
## 3-player network check. Run three copies of the game:
##   ... --script res://tests/run.gd -- net_check host
##   ... --script res://tests/run.gd -- net_check a
##   ... --script res://tests/run.gd -- net_check b
## They connect over 127.0.0.1, follow the same timeline, and print
## "RESULT ..." lines that are compared afterwards.

var role := "host"
var me: Player
var enemy: Enemy
var started := false
var t := 0.0
var _done := {}
var _chat_seen := false
var _min_stamina := 999.0
var _bag := 0
var _gold := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	role = args[1] if args.size() > 1 else "host"
	Net.player_name = {"host": "Host", "a": "Alda", "b": "Bryn"}[role]
	Net.chat_received.connect(func(sender: String, text: String, _sys: bool) -> void:
		if text == "hello from A":
			_chat_seen = true
			print("RESULT %s chat_from=%s" % [role, sender]))
	if role == "host":
		Net.host_game()
	else:
		Net.join_game("127.0.0.1")
	Loot.roll_offered.connect(func(id: int, _item: ItemInstance, _s: float) -> void:
		var choice: int = {"host": Loot.Choice.PASS, "a": Loot.Choice.NEED, "b": Loot.Choice.GREED}[role]
		print("RESULT %s roll_offered=true" % role)
		Loot.choose(id, choice))
	get_tree().create_timer(80.0).timeout.connect(func() -> void:
		print("RESULT %s timeout=true" % role)
		get_tree().quit(3))


func _physics_process(delta: float) -> void:
	var players := get_tree().get_nodes_in_group(&"player")
	if not started:
		if players.size() >= 3:
			started = true
			me = get_tree().get_first_node_in_group(&"local_player") as Player
			enemy = get_tree().current_scene.get_node("Enemies/Marauder") as Enemy
			print("RESULT %s players=%d" % [role, players.size()])
			if role == "host":
				print("RESULT host enemy_max_health=%d" % enemy.max_health)
		return
	t += delta
	if me and t > 10.0 and t < 13.0:
		_min_stamina = minf(_min_stamina, me.stamina)
	var b := _player_named("Bryn")
	var a := _player_named("Alda")

	if role == "host":
		_host_keep_enemy_still(b)
		_at(1.0, func() -> void:
			(get_tree().current_scene.get_node("Enemies/Marauder2") as Node3D).global_position = Vector3(60, 0, 60))
		_at(5.0, func() -> void: print("RESULT host enemy_health_after_A_hit=%d" % enemy.health))
		_at(6.0, func() -> void: _host_force_attack_on(b))
		_at(9.0, func() -> void: print("RESULT host sees_B_health=%d" % b.health))
		_at(10.6, func() -> void: _host_force_attack_on(b))
		_at(14.5, func() -> void: _host_force_attack_on(b))
		_at(17.0, func() -> void: print("RESULT host sees_B_state=%s" % Player.State.keys()[b.state]))
		_at(22.0, func() -> void: print("RESULT host sees_B_state_after_revive=%s" % Player.State.keys()[b.state]))
		_at(25.0, func() -> void:
			var rich: LootTable = (load("res://data/loot/loot_marauder.tres") as LootTable).duplicate()
			rich.drop_chance = 1.0
			rich.item_count = Vector2i(1, 1)
			rich.guaranteed_min_rarity = ItemInstance.Rarity.RARE
			enemy.data = enemy.data.duplicate()
			enemy.data.loot_table = rich
			enemy.global_position = Vector3(3, 0, -3)
			enemy.health = 0.0
			enemy._die())
		_at(31.0, func() -> void: print("RESULT host drops_after_pickup=%d" % Loot.drop_count()))
	if role != "host":
		_at(0.5, func() -> void: print("RESULT %s starts_at_spawn=%s health=%d" % [role, str(me.global_position.z > 10.0), me.health]))
	if role == "a":
		_at(1.0, func() -> void: _place(me, Vector3(0, 0.05, 2.2), Vector3.FORWARD))
		_at(3.0, func() -> void: _tap("light_attack"))
		_at(5.0, func() -> void: print("RESULT a sees_enemy_health=%d" % enemy.health))
		_at(17.5, func() -> void:
			_place(me, b.global_position + Vector3(0.8, 0, 0.5), Vector3.LEFT)
			Input.action_press("interact"))
		_at(21.5, func() -> void: Input.action_release("interact"))
		_at(22.0, func() -> void: print("RESULT a flasks_after_revive=%d" % me.flasks))
		_at(23.0, func() -> void: Net.send_chat("hello from A"))
		_at(29.5, func() -> void:
			_bag = me.inventory.backpack.items.size()
			_gold = me.inventory.gold
			for d in Loot.drops():
				d.call(&"interact", me))
		_at(30.5, func() -> void: print("RESULT a got_won_item=%s got_gold=%s" % [str(me.inventory.backpack.items.size() == _bag + 1), str(me.inventory.gold > 0)]))
		_at(33.0, func() -> void:
			_gold = me.inventory.gold
			print("RESULT a sees_bryn_pile=%s" % str(Loot.pile_count() == 1))
			for p in Loot.piles():
				p.call(&"interact", me))
		_at(34.5, func() -> void: print("RESULT a kept_none_of_bryns_gold=%s" % str(me.inventory.gold == _gold)))
	elif role == "b":
		_at(1.0, func() -> void: _place(me, Vector3(6, 0.05, 0), Vector3.FORWARD))
		_at(9.0, func() -> void: print("RESULT b own_health_after_hit=%d" % me.health))
		_at(10.0, func() -> void: Input.action_press("block"))
		_at(13.0, func() -> void:
			Input.action_release("block")
			print("RESULT b health_after_block=%d stamina_used=%s" % [me.health, str(_min_stamina < me.tuning.max_stamina - 5.0)]))
		_at(14.0, func() -> void: me.health = 1.0)
		_at(17.0, func() -> void: print("RESULT b state=%s" % Player.State.keys()[me.state]))
		_at(22.0, func() -> void: print("RESULT b state_after_revive=%s health=%d" % [Player.State.keys()[me.state], me.health]))
		_at(28.5, func() -> void:
			_bag = me.inventory.backpack.items.size()
			for d in Loot.drops():
				d.call(&"interact", me))
		_at(29.4, func() -> void: print("RESULT b took_alda_item=%s got_gold=%s" % [str(me.inventory.backpack.items.size() > _bag), str(me.inventory.gold > 0)]))
		_at(31.0, func() -> void:
			me.inventory.gold = 77
			me._die())
		_at(35.5, func() -> void: print("RESULT b gold_back_after_alda_recovered=%s (gold %d)" % [str(me.inventory.gold == 77), me.inventory.gold]))
	_at(40.0, func() -> void:
		print("RESULT %s chat_seen=%s" % [role, str(_chat_seen)])
		get_tree().quit(0))


## Run `action` once, the first frame after `time` seconds.
func _at(time: float, action: Callable) -> void:
	if t >= time and not _done.has(time):
		_done[time] = true
		action.call()


func _host_keep_enemy_still(b: Player) -> void:
	if enemy.state == Enemy.State.ATTACK:
		return
	enemy.target = null
	enemy._cooldown = 999.0
	enemy._set_state(Enemy.State.IDLE)
	var spot := Vector3(0, 0, 0) if t < 5.5 else b.global_position + Vector3(0, -0.05, -2.2)
	if t > 17.0:
		spot = Vector3(-10, 0, -10)  # out of the way for the revive
	enemy.global_position = spot
	enemy.model.face_instantly(Vector3.BACK)


func _host_force_attack_on(p: Player) -> void:
	enemy.global_position = p.global_position + Vector3(0, -0.05, -2.2)
	enemy.model.face_instantly(p.global_position - enemy.global_position)
	enemy.target = p
	enemy.start_attack(0)


func _player_named(n: String) -> Player:
	for x in get_tree().get_nodes_in_group(&"player"):
		if (x as Player).player_name == n:
			return x as Player
	return null


func _place(p: Player, where: Vector3, facing: Vector3) -> void:
	p.global_position = where
	p.model.face_instantly(facing)
	p.camera_rig.yaw = atan2(-facing.x, -facing.z)
	p.reset_physics_interpolation()


func _tap(action: StringName) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	var r := InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event.call_deferred(r)
