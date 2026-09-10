import re

with open('init.lua', 'r') as f:
    content = f.read()

# We need to add do_custom, water_damage, lava_damage, can_swim, fall_damage, blood_amount
# "Hazards: Take damage from lava/water. Cannot swim (can_swim = false). Drown if submerged."
# "Destruction: On collision/pathing, destroy adjacent nodes EXCEPT group:dirt. Use minetest.dig_node() or equivalent."
hazard_fields = """
	water_damage = 1,
	lava_damage = 5,
	can_swim = false,
	floats = 0,
	air_damage = 1, -- Drown if submerged
"""

destruction_func = """
	do_custom = function(self, dtime)
		-- Destructive pathing
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
							-- Destroy adjacent non-dirt nodes
							minetest.dig_node(p)
						end
					end
				end
			end
		end
		return false -- Allow other mob logic to continue
	end,
"""

# Inject these into both mob registrations
content = re.sub(
    r'(mobs:register_mob\("mobs_chaos_npcs:human", \{)',
    r'\g<1>\n' + hazard_fields + destruction_func,
    content
)

content = re.sub(
    r'(mobs:register_mob\("mobs_chaos_npcs:orc", \{)',
    r'\g<1>\n' + hazard_fields + destruction_func,
    content
)

with open('init.lua', 'w') as f:
    f.write(content)
