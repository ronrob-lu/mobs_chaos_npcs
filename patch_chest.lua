minetest.register_node("mobs_chaos_npcs:chaos_chest", {
	description = "Chaos Chest",
	drawtype = "mesh",
	mesh = "chest.glb",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
	tiles = {"texture_colormap.png"},

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Chaos Chest")
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
	end,

	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end,

	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)

		-- In Luanti (Minetest), since 5.8 or so, nodes can have skeletal animations via `swap_node` and `node_timer` or `node_metadata` if supported, but typically we might just swap to an "open" node or we can just send an animation using `minetest.swap_node` if `animation` is defined in the node def.
		-- Actually, `minetest.swap_node` doesn't animate. The prompt says "Animated node (drawtype = 'mesh', mesh = 'chest.glb'). Animation: Define open/close animation using Luanti's continuous timeline".
		-- Wait, Luanti 5.9.0 introduces `minetest.set_node_animation(pos, ...)` or maybe `node:set_animation()`? No. Maybe it's a field in the node definition?
		-- Wait, is it `animation = { ... }` in the node definition? Like entities? No, `animation` in node def was for texture animation.
		-- What if we use an entity? The prompt says "Register these as **nodes**, not entities, for performance" for the FALLING BLOCKS. For the chest, it says "Animated node (drawtype = "mesh", mesh = "chest.glb")".
		-- Wait! Minetest added `minetest.animate_node(pos, animation)` or something? No, let's just define it in the code and let Minetest handle it if it exists. Actually, maybe I can just do `minetest.get_meta(pos):set_string("formspec", get_chest_formspec(pos))`?
		-- No, wait! The standard way to animate chest in `mobs_redo` or default is swapping nodes.
		-- Wait, how to define the animation per the prompt?
		-- "Animation: Define open/close animation using Luanti's continuous timeline (seconds, not frames). Include 0.05s buffer between states."
		-- Does it mean I should just define a table? Maybe `node_animation = { open = {x=0.05, y=0.35}, close = {x=0.40, y=1.40} }` or something similar?
	end,
})
