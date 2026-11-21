extends RefCounted
## What people left lying around the Tithelands: each group tells what happens
## at that place. [scene, x, z, yaw, scale]. Read by SetDressing.

const HAY := "res://levels/tithelands/props/hay_bale.tscn"

var items := [
	# The alehouse on the green (VillageW): a trestle table and stools outside, a torch.
	["Camp_Equipment/table_trestle", -18.5, 100.0, 51.0],
	["Camp_Equipment/stool_0", -17.4, 98.9, 20.0],
	["Camp_Equipment/stool_1", -19.7, 101.3, 200.0],
	["Storage_Containers/barrel_stack", -28.5, 98.5, 30.0],
	["Lighting_Props/torch_stand", -19.5, 103.5, 0.0],
	# The smithy (VillageE, where Old Wenna trades): rack, water barrel, bucket.
	["Environmental_Props/weapon_rack", 13.2, 101.0, -55.0, 1.0, -0.53],
	["Storage_Containers/barrel_water", 12.6, 98.6, 0.0],
	["Storage_Containers/bucket_water", 14.2, 103.2, 0.0],
	# VillageS: the harvest coming in.
	["Storage_Containers/basket_turnips", -15.8, 120.8, 10.0],
	["Storage_Containers/sack_grain", -15.0, 123.0, 60.0],
	["Mining_Equipment/wheelbarrow_loaded", -13.6, 118.6, 30.0],
	# Farmstead A: yard toward the lane, hay by the paddock.
	["Mining_Equipment/wheelbarrow_empty", -41.6, 89.4, 70.0],
	["Storage_Containers/sack_grain", -50.8, 87.6, 10.0],
	["Storage_Containers/sack_slumped", -51.3, 86.2, 80.0],
	["Storage_Containers/basket_turnips", -43.4, 90.6, 0.0],
	[HAY, -34.0, 76.0, 20.0],
	[HAY, -30.6, 77.6, 75.0],
	# Farmstead B.
	["Storage_Containers/barrel_water", -40.6, 116.8, 0.0],
	["Storage_Containers/bucket_empty", -39.4, 115.8, 0.0],
	["Storage_Containers/crate_small", -31.4, 117.4, 15.0],
	# The burned hamlet: looted and smashed, bandits camped behind the one standing house.
	["Storage_Containers/barrel_broken", -63.2, 66.0, 40.0],
	["Storage_Containers/crate_broken", -64.6, 64.4, 10.0],
	["Storage_Containers/chest_broken", -82.6, 57.4, 113.0],
	["Storage_Containers/sack_slumped", -66.6, 58.0, 0.0],
	["Mining_Equipment/broken_tools", -84.0, 50.0, 30.0],
	["Mining_Equipment/rubble_small", -58.2, 73.4, 0.0],
	["Camp_Equipment/campfire_ring", -65.8, 43.8, 0.0],
	["Camp_Equipment/stool_0", -64.3, 45.0, 0.0],
	["Camp_Equipment/stool_2", -67.4, 42.6, 0.0],
	["Camp_Equipment/bedding_straw", -63.2, 47.6, 30.0],
	# The mill: grain in, flour out.
	["Storage_Containers/sack_grain", -98.0, 7.0, 0.0],
	["Storage_Containers/sack_grain", -97.3, 8.2, 50.0],
	["Storage_Containers/sack_slumped", -98.6, 8.6, 20.0],
	["Storage_Containers/barrel_grain", -98.8, 10.6, 0.0],
	["Storage_Containers/crate_large", -100.0, 12.0, 15.0],
	# The tithe yard: the village's tithe, stacked and counted.
	["Storage_Containers/barrel_stack", 20.0, -40.0, 0.0],
	["Storage_Containers/sack_grain", 24.0, -39.5, 0.0],
	["Storage_Containers/sack_grain", 25.2, -40.2, 40.0],
	["Storage_Containers/sack_grain", 23.4, -41.0, 80.0],
	["Storage_Containers/crate_large", 30.0, -40.0, 10.0],
	["Storage_Containers/basket_turnips", 27.6, -39.6, 0.0],
	["Storage_Containers/crate_large", 20.0, -60.0, 0.0],
	["Storage_Containers/crate_small", 21.6, -61.0, 30.0],
	["Storage_Containers/barrel_grain", 28.0, -60.5, 0.0],
	["Storage_Containers/barrel_large", 29.4, -59.8, 0.0],
	["Lighting_Props/torch_stand", 13.6, -46.8, 0.0],
	["Lighting_Props/torch_stand", 13.6, -53.2, 0.0],
	# The Knights' checkpoint: supplies and arms.
	["Storage_Containers/crate_large", 10.5, -110.0, 0.0],
	["Storage_Containers/barrel_small", 11.4, -112.6, 0.0],
	["Environmental_Props/weapon_rack", -9.5, -115.0, 90.0, 1.0, -0.53],
	# The quarry: crane over the floor, the winch on the bench, ore carts, tools, the workers' shelter.
	["Mining_Equipment/pulley_gantry", -150.0, -108.5, 0.0],
	["Mining_Equipment/winch", -154.0, -113.6, 0.0],
	["Mining_Equipment/mine_cart_loaded", -145.0, -96.0, 90.0],
	["Mining_Equipment/ore_pile", -160.0, -95.0, 0.0],
	["Mining_Equipment/rubble_large", -166.0, -107.0, 40.0],
	["Mining_Equipment/rubble_small", -138.0, -90.0, 0.0],
	["Mining_Equipment/wheelbarrow_loaded", -140.0, -106.0, 30.0],
	["Mining_Equipment/pickaxe", -158.4, -93.8, 30.0],
	["Mining_Equipment/shovel", -157.4, -95.6, 80.0],
	["Storage_Containers/mining_box_tools", -150.0, -91.0, 0.0],
	["Mining_Equipment/rope_coil", -151.2, -90.4, 0.0],
	["Camp_Equipment/campfire_ring", -155.0, -87.6, 0.0],
	["Camp_Equipment/stool_1", -153.6, -86.4, 0.0],
	# Hobb's hollow.
	["Camp_Equipment/bedding_straw", -115.2, 29.6, 20.0],
	["Camp_Equipment/bedding_rolled", -109.2, 35.6, 70.0],
	["Camp_Equipment/meat_rack", -108.2, 26.6, 30.0],
	["Environmental_Props/weapon_rack", -117.2, 27.8, 120.0, 1.0, -0.53],
	# The raiders' farmstead: stolen goods broken open.
	["Storage_Containers/chest_open", 126.0, -79.0, 200.0],
	["Storage_Containers/crate_broken", 118.0, -89.0, 0.0],
	["Storage_Containers/barrel_broken", 130.0, -82.0, 0.0],
	["Storage_Containers/sack_slumped", 117.0, -80.0, 0.0],
	# The ford camp.
	["Camp_Equipment/bedding_rolled", 25.8, -30.0, 30.0],
	["Camp_Equipment/utensils", 31.2, -30.6, 0.0],
	# An abandoned cart by the road: someone fled and left their goods.
	["Storage_Containers/barrel_broken", -11.6, 32.6, 0.0],
	["Storage_Containers/sack_slumped", -8.0, 32.2, 40.0],
	# The watchtower's summit.
	["Environmental_Props/weapon_rack", 110.0, 23.0, -90.0, 1.0, -0.53],
	["Storage_Containers/barrel_water", 99.0, 22.0, 0.0],
	["Storage_Containers/crate_small", 100.2, 20.8, 20.0],
]
