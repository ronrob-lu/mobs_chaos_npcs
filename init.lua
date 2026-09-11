-- mobs_chaos_npcs/init.lua

local S = minetest.get_translator("mobs_chaos_npcs")

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

-- Shield Entities for Attachment
minetest.register_entity("mobs_chaos_npcs:shield_round", {
	initial_properties = {
		visual = "mesh",
		mesh = "shield-round.glb",
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

minetest.register_entity("mobs_chaos_npcs:shield_rectangle", {
	initial_properties = {
		visual = "mesh",
		mesh = "shield-rectangle.glb",
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

local function attach_random_shield(self)
	local pos = self.object:get_pos()
	if not pos then return end
	local shields = {"mobs_chaos_npcs:shield_round", "mobs_chaos_npcs:shield_rectangle"}
	local choice = shields[math.random(#shields)]
	local shield = minetest.add_entity(pos, choice)
	if shield then
		shield:set_attach(self.object, "arm-left", {x=0, y=2.5, z=1.5}, {x=90, y=0, z=0})
	end
end

local function is_valid_target(target)
	if not target or not target:get_pos() then
		return false
	end
	if target:is_player() then
		return target:get_hp() > 0
	else
		local ent = target:get_luaentity()
		return ent and ent.health and ent.health > 0
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
	owner_loyal = true,
	animation = human_anim,

	water_damage = 1,
	lava_damage = 5,
	can_swim = false,
	floats = 0,
	air_damage = 1,

	on_spawn = function(self)
		self.damage = math.random(3, 8)
		attach_random_weapon(self)
		if math.random(1, 2) == 1 then
			attach_random_shield(self)
		end
	end,

	do_custom = function(self, dtime)
		if not is_valid_target(self.attack) then
			self.attack = nil
			local pos = self.object:get_pos()
			if pos then
				local objects = minetest.get_objects_inside_radius(pos, self.view_range or 15)
				for _, obj in ipairs(objects) do
					if not obj:is_player() then
						local lua_entity = obj:get_luaentity()
						if lua_entity and lua_entity.name ~= "mobs_chaos_npcs:human" and lua_entity.health and lua_entity.health > 0 then
							if not lua_entity.name:find("weapon") and not lua_entity.name:find("shield") then
								self.attack = obj
								break
							end
						end
					end
				end
			end
		end
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

	on_spawn = function(self)
		self.damage = math.random(3, 8)
		attach_random_weapon(self)
		if math.random(1, 2) == 1 then
			attach_random_shield(self)
		end
	end,

	do_custom = function(self, dtime)
		if not is_valid_target(self.attack) then
			self.attack = nil
			local pos = self.object:get_pos()
			if pos then
				local objects = minetest.get_objects_inside_radius(pos, self.view_range or 15)
				for _, obj in ipairs(objects) do
					if obj:is_player() then
						if obj:get_hp() > 0 then
							self.attack = obj
							break
						end
					else
						local lua_entity = obj:get_luaentity()
						if lua_entity and lua_entity.name ~= "mobs_chaos_npcs:orc" and lua_entity.health and lua_entity.health > 0 then
							if not lua_entity.name:find("weapon") and not lua_entity.name:find("shield") then
								self.attack = obj
								break
							end
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
