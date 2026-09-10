-- mobs_chaos_npcs/init.lua

local S = minetest.get_translator("mobs_chaos_npcs")

-- Helper function to register falling mesh nodes
local function register_falling_mesh(name, desc, mesh_file, box)
	minetest.register_node("mobs_chaos_npcs:" .. name, {
		description = desc,
		drawtype = "mesh",
		mesh = mesh_file,
		paramtype2 = "facedir",
		paramtype = "light",
		walkable = true,
		buildable_to = false,
		selection_box = {type = "fixed", fixed = box},
		collision_box = {type = "fixed", fixed = box},
		groups = {falling_node = 1, oddly_breakable_by_hand = 3},
		tiles = {"colormap.png"}, -- Dummy tile to suppress missing texture warnings, colored by palette
	})
end

register_falling_mesh("barrel", "Chaos Barrel", "barrel.obj", {-0.78, -0.5, -0.78, 0.78, 0.93, 0.78})
register_falling_mesh("chair", "Chaos Chair", "chair.obj", {-0.52, -0.5, -0.56, 0.52, 0.93, 0.56})
register_falling_mesh("table", "Chaos Table", "table.obj", {-1.31, -0.5, -0.98, 1.31, 0.44, 0.98})
minetest.register_node("mobs_chaos_npcs:wood_structure", {
	description = "Chaos Wood Structure",
	drawtype = "mesh",
	mesh = "wood-structure.obj",
	paramtype2 = "facedir",
	paramtype = "light",
	walkable = true,
	buildable_to = false,
	selection_box = {
		type = "fixed",
		fixed = {
			{-1.63, 1.4, -1.63, 1.63, 2.5, 1.63},
			{-1.5, -0.5, -1.5, -1.05, 1.4, -1.05},
			{1.05, -0.5, -1.5, 1.5, 1.4, -1.05},
			{-1.5, -0.5, 1.05, -1.05, 1.4, 1.5},
			{1.05, -0.5, 1.05, 1.5, 1.4, 1.5}
		}
	},
	collision_box = {
		type = "fixed",
		fixed = {
			{-1.63, 1.4, -1.63, 1.63, 2.5, 1.63},
			{-1.5, -0.5, -1.5, -1.05, 1.4, -1.05},
			{1.05, -0.5, -1.5, 1.5, 1.4, -1.05},
			{-1.5, -0.5, 1.05, -1.05, 1.4, 1.5},
			{1.05, -0.5, 1.05, 1.5, 1.4, 1.5}
		}
	},
	groups = {falling_node = 1, oddly_breakable_by_hand = 3},
	tiles = {"colormap.png"},
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then return itemstack end
		local pos = pointed_thing.above
		local minp = {x=pos.x-2, y=pos.y-2, z=pos.z-2}
		local maxp = {x=pos.x+2, y=pos.y+2, z=pos.z+2}
		local overlap = minetest.find_nodes_in_area(minp, maxp, {"mobs_chaos_npcs:wood_structure"})
		if #overlap > 0 then
			return itemstack
		end
		return minetest.item_place(itemstack, placer, pointed_thing)
	end,
})

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
	walkable = true,
	buildable_to = false,
	selection_box = {type = "fixed", fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}},
	collision_box = {type = "fixed", fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}},
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
	tiles = {"colormap.png"},

	-- Open/close animation definitions per specification (0.05s buffered)
	-- chest.glb timings: open = 0.3s, close = 1.0s
	animation = {
		open_start = 2, open_end = 11,
		close_start = 12, close_end = 42,
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
		minetest.sound_play("default_chest_open", {pos = pos, gain = 0.3, max_hear_distance = 10}, true)
		if minetest.set_node_animation then
			minetest.set_node_animation(pos, {range = {x = 2, y = 11}, speed = 30, blend = 0})
		end
	end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname:sub(1, 28) == "mobs_chaos_npcs:chaos_chest_" then
		if fields.quit then
			local pos_str = formname:sub(29)
			local pos = minetest.string_to_pos(pos_str)
			if pos then
				minetest.sound_play("default_chest_close", {pos = pos, gain = 0.3, max_hear_distance = 10}, true)
				if minetest.set_node_animation then
					minetest.set_node_animation(pos, {range = {x = 12, y = 42}, speed = 30, blend = 0})
				end
			end
		end
	end
end)

-- Animation tables based on the glb timings with 0.05s buffer
local human_anim = {
	stand_start = 0.200, stand_end = 1.533, stand_speed = 1,
	walk_start = 1.583, walk_end = 2.250, walk_speed = 1,
	run_start = 2.300, run_end = 2.800, run_speed = 1,
	jump_start = 2.850, jump_end = 3.350, jump_speed = 1,
	punch_start = 8.035, punch_end = 8.452, punch_speed = 1,
	die_start = 4.434, die_end = 4.767, die_speed = 1,
	attack_start = 8.035, attack_end = 8.452, attack_speed = 1,
	shoot_start = 7.285, shoot_end = 7.485, shoot_speed = 1,
	speed_normal = 1, speed_run = 1
}

local orc_anim = {
	stand_start = 0.200, stand_end = 1.533, stand_speed = 1,
	walk_start = 1.583, walk_end = 2.250, walk_speed = 1,
	run_start = 2.300, run_end = 2.800, run_speed = 1,
	jump_start = 2.850, jump_end = 3.350, jump_speed = 1,
	punch_start = 8.035, punch_end = 8.452, punch_speed = 1,
	die_start = 4.434, die_end = 4.767, die_speed = 1,
	attack_start = 8.035, attack_end = 8.452, attack_speed = 1,
	shoot_start = 7.285, shoot_end = 7.485, shoot_speed = 1,
	speed_normal = 1, speed_run = 1
}

-- Weapon Entities for Attachment
minetest.register_entity("mobs_chaos_npcs:weapon_spear", {
	initial_properties = {
		visual = "mesh",
		mesh = "weapon-spear.glb",
		textures = {"colormap.png"},
		physical = false,
		collide_with_objects = false,
	},
	on_step = function(self, dtime)
		if not self.object:get_attach() then
			self.object:remove()
		end
	end
})

minetest.register_entity("mobs_chaos_npcs:weapon_sword", {
	initial_properties = {
		visual = "mesh",
		mesh = "weapon-sword.glb",
		textures = {"colormap.png"},
		physical = false,
		collide_with_objects = false,
	},
	on_step = function(self, dtime)
		if not self.object:get_attach() then
			self.object:remove()
		end
	end
})

local function attach_random_weapon(self)
	local pos = self.object:get_pos()
	if not pos then return end
	local weapons = {"mobs_chaos_npcs:weapon_sword", "mobs_chaos_npcs:weapon_spear"}
	local choice = weapons[math.random(#weapons)]
	local weapon = minetest.add_entity(pos, choice)
	if weapon then
		weapon:set_attach(self.object, "arm-right", {x=0, y=2.5, z=1.5}, {x=90, y=0, z=0})
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
						-- minetest.dig_node(p)
					end
				end
			end
		end
	end
end

mobs:register_mob("mobs_chaos_npcs:human", {
	pathfinding = 1,
	type = "npc",
	order = "wander",
	jump = true,
	jump_height = 3,
	stepheight = 1.1,
	walk_chance = 50,
	stand_chance = 50,
	hp_min = 20, hp_max = 30,
	collisionbox = {-1.2, -0.01, -1.2, 1.2, 5.7, 1.2},
	visual = "mesh",
	mesh = "character-human.glb",
	visual_size = {x = 20, y = 20, z = 20},
	textures = {{"colormap.png"}},
	makes_footstep_sound = true,
	view_range = 15,
	walk_velocity = 2,
	run_velocity = 4,
	damage = 4,
	reach = 3,
	attack_type = "dogfight",
	armor = 100,
	passive = false,
	attack_players = false,
	attack_npcs = true,
	attack_animals = true,
	attack_monsters = true,
	group_attack = true,
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
	pathfinding = 1,
	type = "monster",
	order = "wander",
	jump = true,
	jump_height = 3,
	stepheight = 1.1,
	walk_chance = 50,
	stand_chance = 50,
	hp_min = 25, hp_max = 35,
	collisionbox = {-1.2, -0.01, -1.2, 1.2, 5.7, 1.2},
	visual = "mesh",
	mesh = "character-orc.glb",
	visual_size = {x = 20, y = 20, z = 20},
	textures = {{"colormap.png"}},
	makes_footstep_sound = true,
	view_range = 15,
	walk_velocity = 2,
	run_velocity = 4,
	damage = 5,
	reach = 3,
	attack_type = "dogfight",
	armor = 100,
	passive = false,
	attack_players = true,
	attack_npcs = true,
	attack_animals = true,
	attack_monsters = true,
	group_attack = true,
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
