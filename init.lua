-- mobs_chaos_npcs/init.lua

local S = minetest.get_translator("mobs_chaos_npcs")

-- Helper function to register falling mesh nodes
local function register_falling_mesh(name, desc, mesh_file)
	minetest.register_node("mobs_chaos_npcs:" .. name, {
		description = desc,
		drawtype = "mesh",
		mesh = mesh_file,
		paramtype2 = "facedir",
		visual_scale = 100.0,
		paramtype = "light",
		groups = {falling_node = 1, oddly_breakable_by_hand = 3},
		tiles = {"texture_colormap.png"}, -- Dummy tile to suppress missing texture warnings, colored by palette
	})
end

register_falling_mesh("barrel", "Chaos Barrel", "barrel.obj")
register_falling_mesh("chair", "Chaos Chair", "chair.obj")
register_falling_mesh("table", "Chaos Table", "table.obj")
register_falling_mesh("wood_structure", "Chaos Wood Structure", "wood-structure.obj")

-- Chaos Chest implementation
local function get_chest_formspec(pos)
	local spos = pos.x .. "," .. pos.y .. "," .. pos.z
	return "size[8,9]" ..
		"list[nodemeta:" .. spos .. ";main;0,0.3;8,4;]" ..
		"list[current_player;main;0,4.85;8,1;]" ..
		"list[current_player;main;0,6.08;8,3;8]" ..
		"listring[nodemeta:" .. spos .. ";main]" ..
		"listring[current_player;main]"
end

minetest.register_node("mobs_chaos_npcs:chaos_chest", {
	description = "Chaos Chest",
	drawtype = "mesh",
	mesh = "chest.glb",
	paramtype = "light",
	paramtype2 = "facedir",
	visual_scale = 100.0,
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
	tiles = {"texture_colormap.png"},

	-- Open/close animation definitions per specification (0.05s buffered)
	-- chest.glb timings: open = 0.3s, close = 1.0s
	animation = {
		open_start = 0.05, open_end = 0.35,
		close_start = 0.40, close_end = 1.40,
	},

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Chaos Chest")
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
		inv:add_item("main", "mobs_chaos_npcs:barrel 10")
		inv:add_item("main", "mobs_chaos_npcs:chair 10")
		inv:add_item("main", "mobs_chaos_npcs:table 10")
		inv:add_item("main", "mobs_chaos_npcs:wood_structure 10")
	end,

	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end,

	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		minetest.show_formspec(clicker:get_player_name(), "mobs_chaos_npcs:chaos_chest_"..minetest.pos_to_string(pos), get_chest_formspec(pos))
		if minetest.set_node_animation then
			minetest.set_node_animation(pos, {range = {x = 0.05, y = 0.35}, speed = 1, blend = 0})
		end
	end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname:sub(1, 28) == "mobs_chaos_npcs:chaos_chest_" then
		if fields.quit then
			local pos_str = formname:sub(29)
			local pos = minetest.string_to_pos(pos_str)
			if pos and minetest.set_node_animation then
				minetest.set_node_animation(pos, {range = {x = 0.40, y = 1.40}, speed = 1, blend = 0})
			end
		end
	end
end)

-- Animation tables based on the glb timings with 0.05s buffer
local human_anim = {
	stand_start = 0.200, stand_end = 1.533,
	walk_start = 1.583, walk_end = 2.250,
	run_start = 2.300, run_end = 2.800,
	punch_start = 8.035, punch_end = 8.452,
	die_start = 4.434, die_end = 4.767,
	speed_normal = 1, speed_run = 1
}

local orc_anim = {
	stand_start = 0.200, stand_end = 1.533,
	walk_start = 1.583, walk_end = 2.250,
	run_start = 2.300, run_end = 2.800,
	punch_start = 8.033, punch_end = 8.450,
	die_start = 4.433, die_end = 4.767,
	speed_normal = 1, speed_run = 1
}

-- Weapon Entities for Attachment
minetest.register_entity("mobs_chaos_npcs:weapon_spear", {
	initial_properties = {
		visual = "mesh",
		mesh = "weapon-spear.glb",
		textures = {"texture_colormap.png"},
		visual_size = {x = 100, y = 100, z = 100},
		physical = false,
		collide_with_objects = false,
	}
})

minetest.register_entity("mobs_chaos_npcs:weapon_sword", {
	initial_properties = {
		visual = "mesh",
		mesh = "weapon-sword.glb",
		textures = {"texture_colormap.png"},
		visual_size = {x = 100, y = 100, z = 100},
		physical = false,
		collide_with_objects = false,
	}
})

local function attach_random_weapon(self)
	local pos = self.object:get_pos()
	if not pos then return end
	local weapons = {"mobs_chaos_npcs:weapon_sword", "mobs_chaos_npcs:weapon_spear"}
	local choice = weapons[math.random(#weapons)]
	local weapon = minetest.add_entity(pos, choice)
	if weapon then
		weapon:set_attach(self.object, "arm-right", {x=0, y=0, z=0}, {x=0, y=0, z=0})
	end
end

-- Shared destruction logic
local function custom_destructive_step(self, dtime)
	local pos = self.object:get_pos()
	if not pos then return false end

	pos = vector.round(pos)

	local radius = 1
	local minp = {x=pos.x-radius, y=pos.y+1, z=pos.z-radius}
	local maxp = {x=pos.x+radius, y=pos.y+1, z=pos.z+radius}

	for x = minp.x, maxp.x do
		for y = minp.y, maxp.y do
			for z = minp.z, maxp.z do
				local p = {x=x, y=y, z=z}
				local node = minetest.get_node(p)
				if node.name ~= "air" and node.name ~= "ignore" then
					local def = minetest.registered_nodes[node.name]
					if def and not (def.groups and def.groups.dirt) then
						minetest.dig_node(p)
					end
				end
			end
		end
	end
end

mobs:register_mob("mobs_chaos_npcs:human", {
	type = "npc",
	hp_min = 20, hp_max = 30,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "character-human.glb",
	visual_size = {x = 100, y = 100, z = 100},
	textures = {{"texture_colormap.png"}},
	makes_footstep_sound = true,
	view_range = 15,
	walk_velocity = 2,
	run_velocity = 4,
	damage = 4,
	reach = 3,
	attack_type = "dogfight",
	animation = human_anim,

	water_damage = 1,
	lava_damage = 5,
	can_swim = false,
	floats = 0,
	air_damage = 1,

	owner_loyal = true,
	attack_animals = true,
	attack_monsters = true,
	attack_npcs = false,
	group_attack = true,

	on_spawn = function(self)
		self.damage = math.random(3, 8)
		attach_random_weapon(self)
	end,

	do_custom = function(self, dtime)
		custom_destructive_step(self, dtime)
		return false
	end,
})

mobs:register_mob("mobs_chaos_npcs:orc", {
	type = "monster",
	hp_min = 25, hp_max = 35,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "character-orc.glb",
	visual_size = {x = 100, y = 100, z = 100},
	textures = {{"texture_colormap.png"}},
	makes_footstep_sound = true,
	view_range = 15,
	walk_velocity = 2,
	run_velocity = 4,
	damage = 5,
	reach = 3,
	attack_type = "dogfight",
	animation = orc_anim,

	water_damage = 1,
	lava_damage = 5,
	can_swim = false,
	floats = 0,
	air_damage = 1,

	attack_animals = true,
	attack_monsters = true,
	attack_npcs = true,
	group_attack = true,

	on_spawn = function(self)
		self.damage = math.random(3, 8)
		attach_random_weapon(self)
	end,

	do_custom = function(self, dtime)
		custom_destructive_step(self, dtime)

		-- Custom faction check: friendly only to other orcs, hostile to everything else.
		local pos = self.object:get_pos()
		if pos and (not self.attack or not self.attack:get_pos()) then
			local objects = minetest.get_objects_inside_radius(pos, self.view_range)
			for _, obj in ipairs(objects) do
				if obj:is_player() then
					self.attack = obj
					break
				else
					local lua_entity = obj:get_luaentity()
					if lua_entity and lua_entity.name ~= "mobs_chaos_npcs:orc" and lua_entity.health then
						if not lua_entity.name:match("weapon") then
							self.attack = obj
							break
						end
					end
				end
			end
		end

		return false
	end,
})

-- Spawning
mobs:spawn({
	name = "mobs_chaos_npcs:human",
	nodes = {"group:soil", "group:stone"},
	min_light = 0,
	max_light = 15,
	chance = 7000,
	active_object_count = 3,
	min_height = 0,
})

mobs:spawn({
	name = "mobs_chaos_npcs:orc",
	nodes = {"group:soil", "group:stone"},
	min_light = 0,
	max_light = 15,
	chance = 7000,
	active_object_count = 3,
	min_height = 0,
})

-- Spawn Eggs
mobs:register_egg("mobs_chaos_npcs:human", "Human Spawn Egg", "default_dirt.png", 1)
mobs:register_egg("mobs_chaos_npcs:orc", "Orc Spawn Egg", "default_cobble.png", 1)
