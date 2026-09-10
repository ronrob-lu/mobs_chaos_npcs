with open('init.lua', 'r') as f:
    content = f.read()

import re

# Clean up the do_custom and inject the correct faction logic and spawning.
# Let's just rewrite the end of the file from the human_anim declaration to make sure it's perfect.

split_point = content.find('-- Animation tables')
base_content = content[:split_point]

new_mobs = """
-- Animation tables based on the glb timings with 0.05s buffer
local human_anim = {
	stand_start = 0.200, stand_end = 1.533,
	walk_start = 1.583, walk_end = 2.250,
	run_start = 2.300, run_end = 2.800,
	punch_start = 8.035, punch_end = 8.452,
	die_start = 4.434, die_end = 4.767,
	speed_normal = 30, speed_run = 30
}

local orc_anim = {
	stand_start = 0.200, stand_end = 1.533,
	walk_start = 1.583, walk_end = 2.250,
	run_start = 2.300, run_end = 2.800,
	punch_start = 8.033, punch_end = 8.450,
	die_start = 4.433, die_end = 4.767,
	speed_normal = 30, speed_run = 30
}

-- Weapon Entities for Attachment
minetest.register_entity("mobs_chaos_npcs:weapon_spear", {
	initial_properties = {
		visual = "mesh",
		mesh = "weapon-spear.glb",
		textures = {"texture_colormap.png"},
		physical = false,
		collide_with_objects = false,
	}
})

minetest.register_entity("mobs_chaos_npcs:weapon_sword", {
	initial_properties = {
		visual = "mesh",
		mesh = "weapon-sword.glb",
		textures = {"texture_colormap.png"},
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

	local radius = 1
	local minp = {x=pos.x-radius, y=pos.y, z=pos.z-radius}
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
"""

with open('init.lua', 'w') as f:
    f.write(base_content + new_mobs)
