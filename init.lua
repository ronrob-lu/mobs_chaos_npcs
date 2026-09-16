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


local function orc_do_custom(self, dtime)
	if self.name == "mobs_chaos_npcs:orc" and not orcs_destroy then
		return nil
	end
	self.destroy_timer = (self.destroy_timer or 0) + dtime
	if self.destroy_timer >= 1.0 then
		self.destroy_timer = 0
		local pos = vector.round(self.object:get_pos())
		local to_place = {}

		for dx = -1, 1 do
			for dz = -1, 1 do
				if dx ~= 0 or dz ~= 0 then
					for dy = 0, 1 do
						local p = {x = pos.x + dx, y = pos.y + dy, z = pos.z + dz}
						local node = minetest.get_node(p)
						if node.name ~= "air" and node.name ~= "ignore" then
							local is_tree = minetest.get_item_group(node.name, "tree") > 0 or minetest.get_item_group(node.name, "leaves") > 0
							local is_glass = string.find(node.name, "glass") ~= nil
							local is_wood = string.find(node.name, "wood") ~= nil
							local is_dirt = string.find(node.name, "dirt") ~= nil
							local is_sand = string.find(node.name, "sand") ~= nil

							local is_allowed = is_tree or is_glass or is_wood or is_dirt or is_sand

							if is_allowed then
								table.insert(to_place, {name = node.name, pos = {x = p.x, y = p.y, z = p.z}})
								minetest.remove_node(p)

								if is_tree then
									local queue = {{x = p.x, y = p.y, z = p.z}}
									local q_first = 1
									local q_last = 1
									local visited = {}
									visited[minetest.hash_node_position(p)] = true
									local destroyed_count = 0
									local max_destroy = 150

									while q_first <= q_last and destroyed_count < max_destroy do
										local curr = queue[q_first]
										q_first = q_first + 1

										-- Check surrounding blocks (including above/below and sides)
										for qdx = -1, 1 do
											for qdy = -1, 1 do
												for qdz = -1, 1 do
													if qdx ~= 0 or qdy ~= 0 or qdz ~= 0 then
														local npos = {x = curr.x + qdx, y = curr.y + qdy, z = curr.z + qdz}
														local hash = minetest.hash_node_position(npos)

														if not visited[hash] then
															visited[hash] = true
															local tnode = minetest.get_node(npos)

															if tnode.name ~= "air" and tnode.name ~= "ignore" then
																if minetest.get_item_group(tnode.name, "tree") > 0 or minetest.get_item_group(tnode.name, "leaves") > 0 then
																	table.insert(to_place, {name = tnode.name, pos = {x = npos.x, y = npos.y, z = npos.z}})
																	minetest.remove_node(npos)
																	destroyed_count = destroyed_count + 1
																	q_last = q_last + 1
																	queue[q_last] = npos

																	if destroyed_count >= max_destroy then
																		break
																	end
																end
															end
														end
													end
													if destroyed_count >= max_destroy then break end
												end
												if destroyed_count >= max_destroy then break end
											end
											if destroyed_count >= max_destroy then break end
										end
									end
								end
							end
						end
					end
				end
			end
		end

		for _, item in ipairs(to_place) do
			local random_pos = {
				x = item.pos.x + math.random(-2, 2),
				y = item.pos.y + math.random(0, 1),
				z = item.pos.z + math.random(-2, 2)
			}
			local rnode = minetest.get_node(random_pos)
			if rnode.name == "air" then
				minetest.set_node(random_pos, {name = item.name})
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
	attack_npcs = false,
	attack_animals = false,
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
	do_custom = orc_do_custom,
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

minetest.register_node("mobs_chaos_npcs:human_spawner", {
	description = "Human Spawner",
	tiles = {
		"spawner_bottom_top.png",
		"spawner_bottom_top.png",
		"human_spawner-side.png",
		"human_spawner-side.png",
		"human_spawner-side.png",
		"human_spawner-side.png",
	},
	groups = {cracky = 1},
})

minetest.register_node("mobs_chaos_npcs:orc_spawner", {
	description = "Orc Spawner",
	tiles = {
		"spawner_bottom_top.png",
		"spawner_bottom_top.png",
		"orc_spawner_side.png",
		"orc_spawner_side.png",
		"orc_spawner_side.png",
		"orc_spawner_side.png",
	},
	groups = {cracky = 1},
})

-- Spawning
mobs:spawn({
	name = "mobs_chaos_npcs:human",
	nodes = {"group:soil", "group:stone"},
	neighbors = {"mobs_chaos_npcs:human_spawner"},
	min_light = 0,
	max_light = 15,
	chance = 2,
	active_object_count = 10,
	min_height = 0,
})

mobs:spawn({
	name = "mobs_chaos_npcs:orc",
	nodes = {"group:soil", "group:stone"},
	neighbors = {"mobs_chaos_npcs:orc_spawner"},
	min_light = 0,
	max_light = 15,
	chance = 2,
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
