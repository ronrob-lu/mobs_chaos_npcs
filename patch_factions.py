import re

with open('init.lua', 'r') as f:
    content = f.read()

# We need to add faction logic, weapons, spawning, and spawn eggs.
# Factions:
# Human: `owner_loyal = true`, `friendly = true` (actually for players).
# Human hostile to non-human mobs.
# Orc: Hostile to players, humans, non-orcs. Friendly ONLY to other orcs.

# We can handle faction logic via `specific_attack` or overriding `do_attack` or `group_attack`.
# In mobs_redo:
# `type = "npc"` (friendly to players, attacks monsters).
# `type = "monster"` (attacks players, npcs).
# "Human: owner_loyal = true, friendly = true to players and other humans. Hostile to ALL non-human mobs."
# "Orc: Hostile to players, humans, and non-orc mobs. Friendly ONLY to other orcs."

# For Humans: type="npc" already makes them friendly to players and attack monsters. But they need to attack ALL non-human mobs.
# So we can set `attack_type = "dogfight"`, `specific_attack = {"mobs_chaos_npcs:orc", "mobs_animal:cow", "mobs_monster:dirt_monster", ...}` but it's hard to list all.
# Better to use `mobs:register_mob`'s `attack_npcs`? No. We can use a custom `do_attack` or `on_step` or just use the `type = "monster"` for Orcs, which will attack players and NPCs.
# But Orcs need to attack non-orcs. If an animal (type="animal") is near, they should attack it.
# Wait, mobs_redo `attack_animals = true` works.

human_faction = """
	owner_loyal = true,
	attack_animals = true,
	attack_monsters = true,
	attack_npcs = false, -- Don't attack other humans/npcs
	group_attack = true,
"""

orc_faction = """
	attack_animals = true,
	attack_monsters = true, -- Attack other monsters
	attack_npcs = true,
	group_attack = true,
	specific_attack = {"player"}, -- Will attack everything basically

	-- Custom do_attack or target filtering if needed, but attack_monsters/animals/npcs covers all non-orcs.
	-- We want them friendly ONLY to other orcs.
"""

# Weapon selection logic:
# "Random weapon selection from a predefined list on spawn."
# We can use `on_spawn` to attach a weapon or change texture/drop.
# Since we have `weapon-spear.glb` and `weapon-sword.glb`, and `shield-rectangle.glb`, `shield-round.glb` in `models/`.
# Mobs Redo doesn't have a direct "attach weapon" unless we use bone attachment or it's built into the mesh.
# But `on_spawn` can be used to set a property or we can attach an entity?
# Actually, the prompt says "Random weapon selection from a predefined list on spawn."
# The GLB models for weapons might be meant to be attached using `self.object:set_properties({textures = ...})`? No, `.glb` are meshes.
# Maybe we attach them as entities using `minetest.add_entity` and `self.object:set_attach(...)`?
# Wait! "Random weapon selection from a predefined list on spawn" -> maybe `mobs_redo` has `weapons`? No.
# If I attach an entity, it's just a dummy entity that has the mesh of the weapon.

weapon_entity_code = """
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
		-- Attach to right hand bone if possible, or just default attachment
		weapon:set_attach(self.object, "arm-right", {x=0, y=0, z=0}, {x=0, y=0, z=0})
	end
end
"""

on_spawn_code = """
	on_spawn = function(self)
		attach_random_weapon(self)
	end,
"""

# Let's insert weapon_entity_code before the mobs
content = content.replace('mobs:register_mob("mobs_chaos_npcs:human"', weapon_entity_code + '\nmobs:register_mob("mobs_chaos_npcs:human"')

# Human faction logic
content = re.sub(
    r'(mobs:register_mob\("mobs_chaos_npcs:human", \{)',
    r'\g<1>\n' + human_faction + on_spawn_code,
    content
)

# Orc faction logic
# "Orc: Hostile to players, humans, and non-orc mobs. Friendly ONLY to other orcs. Implement via custom do_attack or faction check override."
orc_faction_custom = """
	on_spawn = function(self)
		attach_random_weapon(self)
	end,
	do_custom = function(self, dtime)
		-- Base destructive pathing
		local pos = self.object:get_pos()
		if pos then
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

		-- Custom faction check override (Hostile to all non-orcs)
		-- mobs_redo usually handles this via target search. We can manually set the target.
		if not self.attack or not self.attack:get_pos() then
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
"""

# Replace the old do_custom for Orc
content = re.sub(
    r'do_custom = function\(self, dtime\).*?return false -- Allow other mob logic to continue\n\tend,',
    '-- Removed old do_custom',
    content, count=1 # Wait, we have two do_customs now. Better to just regex replace the exact orc definition.
)

with open('init.lua', 'w') as f:
    f.write(content)
