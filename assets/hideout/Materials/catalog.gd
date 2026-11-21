extends RefCounted
## Every asset in the library: [folder, file name, builder Callable]. The exporter bakes each one
## to <folder>/<name>.scn; scenes then instance those files instead of rebuilding meshes.

const Cave := preload("res://assets/hideout/Cave_Geometry/cave.gd")
const CaveX := preload("res://assets/hideout/Cave_Geometry/cave_extra.gd")
const Struct := preload("res://assets/hideout/Wooden_Structures/structures.gd")
const StructX := preload("res://assets/hideout/Wooden_Structures/structures_extra.gd")
const Store := preload("res://assets/hideout/Storage_Containers/storage.gd")
const StoreX := preload("res://assets/hideout/Storage_Containers/storage_extra.gd")
const Camp := preload("res://assets/hideout/Camp_Equipment/camp.gd")
const CampX := preload("res://assets/hideout/Camp_Equipment/camp_extra.gd")
const Mine := preload("res://assets/hideout/Mining_Equipment/mining.gd")
const MineX := preload("res://assets/hideout/Mining_Equipment/mining_extra.gd")
const Light := preload("res://assets/hideout/Lighting_Props/lighting.gd")
const LightX := preload("res://assets/hideout/Lighting_Props/lighting_extra.gd")
const Props := preload("res://assets/hideout/Environmental_Props/props.gd")


static func entries() -> Array:
	var e: Array = []
	var S := "Storage_Containers"
	for k in ["small", "large", "water", "grain", "broken"]:
		e.append([S, "barrel_" + k, Store.barrel.bind(k, 1)])
	e.append([S, "barrel_stack", Store.barrel_stack.bind(4)])
	for k in ["small", "large", "open", "broken"]:
		e.append([S, "crate_" + k, Store.crate.bind(k, 1)])
	for k in ["grain", "slumped"]:
		e.append([S, "sack_" + k, Store.sack.bind(k, 3)])
	for k in ["water", "empty"]:
		e.append([S, "bucket_" + k, StoreX.bucket.bind(k, 61)])
	for k in ["turnips", "bread", "empty"]:
		e.append([S, "basket_" + k, StoreX.basket.bind(k, 62)])
	for k in ["closed", "open", "broken"]:
		e.append([S, "chest_" + k, StoreX.chest.bind(k, 63)])
	for k in ["tools", "empty"]:
		e.append([S, "mining_box_" + k, StoreX.mining_box.bind(k, 64)])
	var W := "Wooden_Structures"
	e.append([W, "platform_4x2", Struct.platform.bind(4.0, 2.0, 1.5, "plain", 1)])
	e.append([W, "platform_2x2", Struct.platform.bind(2.0, 2.0, 1.0, "plain", 2)])
	e.append([W, "platform_2x4_worn", Struct.platform.bind(2.0, 4.0, 1.0, "worn", 3)])
	e.append([W, "platform_6x2_tall", Struct.platform.bind(6.0, 2.0, 2.5, "plain", 4)])
	e.append([W, "stairs_1m", Struct.stairs.bind(1.0, 1.0, 2)])
	e.append([W, "stairs_2m", Struct.stairs.bind(2.0, 1.2, 3)])
	e.append([W, "railing_1m", Struct.railing.bind(1.0, 1.0, 3)])
	e.append([W, "railing_2m", Struct.railing.bind(2.0, 1.0, 3)])
	e.append([W, "railing_4m", Struct.railing.bind(4.0, 1.0, 4)])
	e.append([W, "ladder_2m", Struct.ladder.bind(2.0, 5)])
	e.append([W, "ladder_3m", Struct.ladder.bind(3.2, 6)])
	for h in [1.8, 2.4, 3.2]:
		e.append([W, "post_%dcm" % roundi(h * 100), Struct.post.bind(h, 0.11, 6)])
	for l in [2.0, 3.0, 4.0]:
		e.append([W, "crossbeam_%dm" % roundi(l), Struct.crossbeam.bind(l, 7)])
	for k in ["door", "gate", "broken"]:
		e.append([W, "door_" + k, StructX.door.bind(k, 51)])
	e.append([W, "scaffold", StructX.scaffold.bind(2.0, 1.6, 3.2, 1.6, 52)])
	e.append([W, "bridge_3m", StructX.bridge.bind(3.0, 1.2, 53)])
	e.append([W, "bridge_5m", StructX.bridge.bind(5.0, 1.4, 54)])
	e.append([W, "barricade", StructX.barricade.bind(2.4, 54)])
	e.append([W, "hanging_platform", StructX.hanging_platform.bind(1.6, 1.4, 2.0, 55)])
	e.append([W, "shelf_3tier", StructX.shelf.bind(1.3, 1.5, 3, 56)])
	e.append([W, "shelf_4tier", StructX.shelf.bind(1.3, 1.9, 4, 57)])
	var C := "Camp_Equipment"
	e.append([C, "campfire_ring", Camp.campfire.bind("ring", 11, true)])
	e.append([C, "campfire_communal", Camp.campfire.bind("communal", 11, true)])
	e.append([C, "tripod_pot", Camp.tripod_pot.bind(12)])
	for v in 3:
		e.append([C, "stool_%d" % v, Camp.stool.bind(v, 21)])
		e.append([C, "chair_%d" % v, CampX.chair.bind(v, 71)])
	for k in ["trestle", "slab"]:
		e.append([C, "table_" + k, CampX.table.bind(k, 72)])
	e.append([C, "utensils", CampX.utensils.bind(73)])
	for k in ["rolled", "open", "straw", "blanket"]:
		e.append([C, "bedding_" + k, CampX.bedding.bind(k, 74)])
	e.append([C, "tent_small", CampX.tent.bind(75)])
	e.append([C, "meat_rack", CampX.meat_rack.bind(76)])
	e.append([C, "hanging_rope_2m", CampX.hanging_rope.bind(2.0, 77)])
	e.append([C, "personal_area", CampX.personal_area.bind(78)])
	var M := "Mining_Equipment"
	e.append([M, "mine_cart_loaded", Mine.mine_cart.bind(true, 31)])
	e.append([M, "mine_cart_empty", Mine.mine_cart.bind(false, 31)])
	e.append([M, "track_2m", Mine.track.bind(32)])
	e.append([M, "pickaxe", Mine.pickaxe.bind(33)])
	e.append([M, "shovel", Mine.shovel.bind(34)])
	e.append([M, "ore_pile", Mine.ore_pile.bind(1.0, 35)])
	e.append([M, "rope_coil", Mine.rope_coil.bind(36)])
	e.append([M, "wheelbarrow_empty", MineX.wheelbarrow.bind(false, 81)])
	e.append([M, "wheelbarrow_loaded", MineX.wheelbarrow.bind(true, 81)])
	e.append([M, "mining_hammer", MineX.hammer.bind(82)])
	e.append([M, "winch", MineX.winch.bind(83)])
	e.append([M, "pulley_gantry", MineX.pulley.bind(84)])
	e.append([M, "support_frame", MineX.support_frame.bind(2.4, 2.4, "intact", 85)])
	e.append([M, "support_frame_broken", MineX.support_frame.bind(2.4, 2.4, "broken", 85)])
	e.append([M, "broken_tools", MineX.broken_tools.bind(86)])
	e.append([M, "rubble_small", MineX.rubble.bind(0.6, 87)])
	e.append([M, "rubble_large", MineX.rubble.bind(1.4, 87)])
	var L := "Lighting_Props"
	e.append([L, "torch_wall_bracket", Light.wall_torch.bind("bracket", true, 41)])
	e.append([L, "torch_wall_cresset", Light.wall_torch.bind("cresset", true, 41)])
	e.append([L, "torch_stand", Light.torch_stand.bind(42)])
	e.append([L, "brazier", Light.brazier.bind(43)])
	e.append([L, "lantern", LightX.lantern.bind(true, 91)])
	e.append([L, "candles_1", LightX.candles.bind(1, 92)])
	e.append([L, "candles_3", LightX.candles.bind(3, 92)])
	e.append([L, "oil_lamp", LightX.oil_lamp.bind(93)])
	var P := "Environmental_Props"
	e.append([P, "chain_1m", Props.chain.bind(1.0, 101)])
	e.append([P, "chain_2m", Props.chain.bind(2.0, 101)])
	e.append([P, "hook_iron", Props.hook.bind("iron", 102)])
	e.append([P, "hook_rope", Props.hook.bind("rope", 102)])
	e.append([P, "sign_post", Props.sign_board.bind("post", 103)])
	e.append([P, "sign_mining", Props.sign_board.bind("mining", 103)])
	e.append([P, "weapon_rack", Props.weapon_rack.bind(104)])
	var G := "Cave_Geometry"
	e.append([G, "cave_floor_4m", Cave.floor_section.bind(4.0, 1)])
	e.append([G, "cave_wall_4m", Cave.wall_section.bind(4.0, 3.6, 2)])
	e.append([G, "cave_wall_wet_4m", CaveX.wet_wall.bind(4.0, 3.6, 116)])
	e.append([G, "cave_ceiling_4m", Cave.ceiling_section.bind(4.0, 7)])
	e.append([G, "tunnel_4m", CaveX.tunnel.bind(4.0, 3.2, 2.8, 111)])
	e.append([G, "tunnel_8m", CaveX.tunnel.bind(8.0, 3.2, 2.8, 111)])
	e.append([G, "cave_opening", CaveX.cave_opening.bind(3.2, 3.0, 112)])
	e.append([G, "collapsed_rock", CaveX.collapsed_rock.bind(3.2, 2.6, 113)])
	e.append([G, "rock_pillar", CaveX.rock_pillar.bind(3.2, 0.55, 114)])
	e.append([G, "stone_ledge_3m", CaveX.stone_ledge.bind(3.0, 115)])
	for s in ["large", "medium", "small"]:
		e.append([G, "rock_" + s, Cave.rock_formation.bind(s, 3)])
	e.append([G, "stalagmites", Cave.stalagmites.bind(5, false, 4)])
	e.append([G, "stalactites", Cave.stalagmites.bind(5, true, 4)])
	e.append([G, "water_pool", Cave.water_pool.bind(1.1, 5)])
	return e
