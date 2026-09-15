-- mobs_chaos_npcs/init.lua

local S = minetest.get_translator("mobs_chaos_npcs")

local orcs_destroy = false

minetest.register_chatcommand("orcs_destroy", {
	params = "<on|off>",
	description = "Toggle whether orcs can destroy blocks",
	privs = {server = true},
	func = function(name, param)
		if param == "on" then
			orcs_destroy = true
			return true, "Orc block destruction enabled."
		elseif param == "off" then
			orcs_destroy = false
			return true, "Orc block destruction disabled."
		else
			return false, "Invalid parameter. Usage: /orcs_destroy on|off"
		end
	end,
})

-- Animation tables based on the glb timings with 0.05s buffer
local human_anim = {
	stand_start = 0.150, stand_end = 1.383, stand_speed = 1,
	walk_start = 1.483, walk_end = 2.050, walk_speed = 1,
	run_start = 2.150, run_end = 2.550, run_speed = 1,
	jump_start = 2.650, jump_end = 3.050, jump_speed = 1,
	punch_start = 7.085, punch_end = 7.402, punch_speed = 1,
	die_start = 3.984, die_end = 4.217, die_speed = 1,
	attack_start = 7.085, attack_end = 7.402, attack_speed = 1,
	shoot_start = 6.485, shoot_end = 6.585, shoot_speed = 1,
	speed_normal = 1, speed_run = 1
}

local orc_anim = {
	stand_start = 0.150, stand_end = 1.383, stand_speed = 1,
	walk_start = 1.483, walk_end = 2.050, walk_speed = 1,
	run_start = 2.150, run_end = 2.550, run_speed = 1,
	jump_start = 2.650, jump_end = 3.050, jump_speed = 1,
	punch_start = 7.085, punch_end = 7.402, punch_speed = 1,
	die_start = 3.984, die_end = 4.217, die_speed = 1,
	attack_start = 7.085, attack_end = 7.402, attack_speed = 1,
	shoot_start = 6.485, shoot_end = 6.585, shoot_speed = 1,
	speed_normal = 1, speed_run = 1
}

local function npc_do_custom(self, dtime)
	if self.name == "mobs_chaos_npcs:orc" and not orcs_destroy then
		return nil
	end

	self.destroy_timer = (self.destroy_timer or 0) + dtime
	if self.destroy_timer >= 1.0 then
		self.destroy_timer = 0
		local pos = vector.round(self.object:get_pos())
		for dx = -1, 1 do
			for dz = -1, 1 do
				if dx ~= 0 or dz ~= 0 then
					for dy = 0, 1 do
						local p = {x = pos.x + dx, y = pos.y + dy, z = pos.z + dz}
						local node = minetest.get_node(p)
						if node.name ~= "air" and node.name ~= "ignore" then
							local is_stone = minetest.get_item_group(node.name, "stone") > 0
							local is_steel = string.find(node.name, "steel") ~= nil
							local is_xpanes = string.find(node.name, "xpanes") ~= nil
							local is_immortal = minetest.get_item_group(node.name, "immortal") > 0
							local is_xpanes = string.find(node.name, "xpanes") ~= nil
							local nodedef = minetest.registered_nodes[node.name]
							local is_liquid = nodedef and (nodedef.liquidtype ~= "none")

							if not is_stone and not is_steel and not is_xpanes and not is_immortal and not is_liquid then
								minetest.remove_node(p)
							end
						end
					end
				end
			end
		end
	end
	return nil
end

local function is_valid_target(target)
	if not target or not target:get_pos() then
		return false
	end
	if target:is_player() then
		return target:get_hp() > 0
	else
		local ent = target:get_luaentity()
		if not ent then return false end
		local hp = ent.health or (ent.object and ent.object:get_hp()) or 0
		return hp > 0
	end
end

mobs:register_mob("mobs_chaos_npcs:human", {
	do_custom = npc_do_custom,
	pathfinding = 1,
	lifetimer = 0,
	type = "npc",
	order = "wander",
	jump = true,
	jump_height = 3,
	stepheight = 1.1,
	walk_chance = 70,
	stand_chance = 30,
	hp_min = 20, hp_max = 30,
	collisionbox = {-0.35, 0.0, -0.35, 0.35, 1.8, 0.35},
	visual = "mesh",
	mesh = "character-human.glb",
	visual_size = {x = 20, y = 20, z = 20},
	textures = {{"colormap.png"}},
	rotate = 180,
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
	fall_damage = 1,
	can_swim = false,
	floats = 0,
	air_damage = 0,
	blood_amount = 0,
	blood_texture = "",
})

mobs:register_mob("mobs_chaos_npcs:orc", {
	do_custom = npc_do_custom,
	pathfinding = 1,
	lifetimer = 0,
	type = "monster",
	order = "wander",
	jump = true,
	jump_height = 3,
	stepheight = 1.1,
	walk_chance = 70,
	stand_chance = 30,
	hp_min = 25, hp_max = 35,
	collisionbox = {-0.35, 0.0, -0.35, 0.35, 1.8, 0.35},
	visual = "mesh",
	mesh = "character-orc.glb",
	visual_size = {x = 20, y = 20, z = 20},
	textures = {{"colormap.png"}},
	rotate = 180,
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
	fall_damage = 1,
	can_swim = false,
	floats = 0,
	air_damage = 0,
	blood_amount = 0,
	blood_texture = "",
})

-- Spawning
mobs:spawn({
	name = "mobs_chaos_npcs:human",
	nodes = {"group:soil", "group:stone"},
	min_light = 0,
	max_light = 15,
	chance = 1000,
	active_object_count = 10,
	min_height = 0,
})

mobs:spawn({
	name = "mobs_chaos_npcs:orc",
	nodes = {"group:soil", "group:stone"},
	min_light = 0,
	max_light = 15,
	chance = 1000,
	active_object_count = 10,
	min_height = 0,
	on_spawn = function(self, pos)
		local nods = minetest.find_nodes_in_area_under_air(
			{x = pos.x - 4, y = pos.y - 3, z = pos.z - 4},
			{x = pos.x + 4, y = pos.y + 3, z = pos.z + 4},
			{"group:soil", "group:stone"}
		)

		if nods and #nods > 0 then
			local iter = math.min(#nods, math.random(1, 3))
			for n = 1, iter do
				local pos2 = nods[math.random(#nods)]
				pos2.y = pos2.y + 2
				if minetest.get_node(pos2).name == "air" then
					minetest.add_entity(pos2, "mobs_chaos_npcs:orc")
				end
			end
		end
	end,
})

-- Spawn Eggs
mobs:register_egg("mobs_chaos_npcs:human", "Human Spawn Egg", "default_dirt.png", 1)
mobs:register_egg("mobs_chaos_npcs:orc", "Orc Spawn Egg", "default_cobble.png", 1)
