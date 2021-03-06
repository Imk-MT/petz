local modpath, S = ...

petz.get_node_below = function(pos)
	local pos_below = {
		x = pos.x,
		y = pos.y - 1.0,
		z = pos.z,
	}
	local node = minetest.get_node(pos_below)
	return node
end

petz.spawn_mob = function(spawn_pos, limit_max_mobs, abr)		
	local node = petz.get_node_below(spawn_pos) --the node below the spawn pos
	local candidates_list = {} --Create a sublist of the petz with the same node to spawnand between max_height and min_height	
	for i = 1, #petz.petz_list do
		local pet_name
		local can_spawn = true
		pet_name = petz.petz_list[i]
		local mob_ent_name = "petz:"..pet_name
		--minetest.chat_send_player("singleplayer", mob_ent_name)	
		local ent = minetest.registered_entities[mob_ent_name]
		-- Note: using a function that just returns false on the first condition that is not met
		-- might be easier to read than this current implementation
		if ent then --do several checks to know if the mob can be included in the list or not		
			if can_spawn and petz.settings[pet_name.."_spawn"] == false then
				can_spawn = false
			end
			if can_spawn and ent.spawn_max_height then --check max_height
				if spawn_pos.y > ent.spawn_max_height then
					can_spawn = false
				end
			end
			if can_spawn and ent.spawn_min_height then --check min_height
				if spawn_pos.y < ent.spawn_min_height then
					can_spawn = false
				end
			end		
			if can_spawn and ent.min_daylight_level then --check min_light
				if minetest.get_node_light(spawn_pos, 0.5) < ent.min_daylight_level then				
					can_spawn = false
				end
			end					
			if can_spawn and ent.max_daylight_level then --check max_light
				if minetest.get_node_light(spawn_pos, 0.5) > ent.max_daylight_level then
					can_spawn = false
				end
			end							
			--Check if this mob spawns at night
			if can_spawn and ent.spawn_at_night then
				if not(petz.is_night()) then --if not at night
					can_spawn = false
				end
			end
			--Check if monsters are disabled
			if can_spawn and ent.is_monster == true then
				if petz.settings.disable_monsters == true then
					can_spawn = false
				end
			end
			--Check if seasonal mobs
			local season = petz.settings[pet_name.."_seasonal"]
			if can_spawn and season then				
				local now_month = petz.get_os_month()
				if season == "halloween" then					
					if now_month ~= 10 then
						can_spawn = false						
					end
				elseif season == "christmas" then					
					if now_month ~= 12 then
						can_spawn = false
					end
				end
			end
		end				
		if can_spawn and petz.item_in_itemlist(node.name, petz.settings[pet_name.."_spawn_nodes"]) == true then
			table.insert(candidates_list, pet_name)
		end
	end --end for
		
	--minetest.chat_send_player("singleplayer", minetest.serialize(candidates_list))
	
	if #candidates_list < 1 then --if no candidates, then return
		return
	end
	
	local random_mob = candidates_list[math.random(1, #candidates_list)] --Get a random mob from the list of candidates
	local random_mob_name = "petz:" .. random_mob
	--minetest.chat_send_player("singleplayer", random_mob)
	local spawn_chance = petz.settings[random_mob.."_spawn_chance"]
	if spawn_chance < 0 then
		spawn_chance = 0
	elseif spawn_chance > 1 then
		spawn_chance = 1
	end
	spawn_chance = math.floor((1 / spawn_chance)+0.5)
	--minetest.chat_send_player("singleplayer", tostring(spawn_chance))
	local random_chance = math.random(1, spawn_chance)
	--minetest.chat_send_player("singleplayer", tostring(random_chance))		
	if random_chance == 1 then			
		local random_mob_biome = petz.settings[random_mob.."_spawn_biome"]
		--minetest.chat_send_player("singleplayer", "biome="..random_mob_biome)		
		if random_mob_biome ~= "default" then --specific biome to spawn for this mob
			local biome_name = minetest.get_biome_name(minetest.get_biome_data(spawn_pos).biome) --biome of the spawn pos
			--minetest.chat_send_player("singleplayer", "biome="..biome_name)	
			if biome_name ~= random_mob_biome then
				return
			end
		end	
		local mob_count = 0	
		if limit_max_mobs then
			local objs = minetest.get_objects_inside_radius(spawn_pos, abr*16 + 5)		
			for _, obj in ipairs(objs) do		-- count mobs in abrange
				if not obj:is_player() then
					local luaent = obj:get_luaentity()
					if luaent then
						mob_count = mob_count + 1
					end
				end
			end
		end
		if (limit_max_mobs) == false or (mob_count < petz.settings.max_mobs) then --check for bigger mobs:				
			local spawn_herd = petz.settings[random_mob.."_spawn_herd"]			
			if spawn_herd then
				--minetest.chat_send_player("singleplayer", tonumber(spawn_herd))				
				if spawn_herd == 0 then
					spawn_herd = 1
				elseif spawn_herd > 5 then
					spawn_herd = 5
				end			
			else
				spawn_herd = 1
			end
			for i = 1, math.random(1, spawn_herd) do
				local spawn = true
				if i == 2 then
					spawn_pos.x = spawn_pos.x + 1					
				elseif i == 3 then
					spawn_pos.x = spawn_pos.x - 2
				elseif i == 4 then
					spawn_pos.x = spawn_pos.x + 1
					spawn_pos.z = spawn_pos.z + 1
				else
					spawn_pos.z = spawn_pos.z - 2
				end
				if i > 1 then					
					local height, liquidflag = mobkit.get_terrain_height(spawn_pos, 32)					
					if height then
						local node = petz.get_node_below(spawn_pos)						
						if not(petz.item_in_itemlist(node.name, petz.settings[random_mob.."_spawn_nodes"])) then							
							spawn = false
						end
					end
				end
				if spawn == true then
					spawn_pos = petz.pos_to_spawn(random_mob_name, spawn_pos) --recalculate pos.y for bigger mobs
					minetest.add_entity(spawn_pos, random_mob_name)	
					--minetest.chat_send_player("singleplayer", random_mob.. " spawned!!!")
				end							
				--minetest.chat_send_player("singleplayer", "cave="..tostring(cave))				
			end
		end
	end
end

minetest.register_globalstep(function(dtime)
	local abr = minetest.get_mapgen_setting('active_block_range')
	local radius =  abr * 16 --recommended		
	local interval = petz.settings.spawn_interval	
	local spawn_pos, liquidflag, cave = mobkit.get_spawn_pos_abr(dtime, interval, radius, petz.settings.spawn_chance, 0.2)	
	if spawn_pos then
		petz.spawn_mob(spawn_pos, true, abr)
	end
end)

-- Spawn some mobs when area loaded
--minetest.register_on_generated(function(minp, maxp, seed)
	--if not(petz.settings.generated_area_create_mobs) then
		--return
	--end
	--local debug = "minp="..(minetest.pos_to_string(minp))..", maxp="..(minetest.pos_to_string(maxp))..", seed="..seed
	--minetest.chat_send_all(debug)
	--local max_mobs = petz.settings.max_mobs * (petz.settings.generated_area_mob_ratio or 1)
	--Get a random pos
	--for i = 1, max_mobs do
		--local spawn_pos = { x= math.random(minp.x, maxp.x), y = math.random(minp.y, maxp.y)+32, z = math.random(minp.z, maxp.z)}
		--local height, liquidflag = mobkit.get_terrain_height(spawn_pos, 32)
							--local debug = "spawn pos=".. minetest.pos_to_string(spawn_pos)
		--minetest.chat_send_all(debug)
		--if height then
			--minetest.chat_send_all("test")	
			--petz.spawn_mob(spawn_pos, false)
		--end
	--end	
--end)

petz.pos_to_spawn = function(pet_name, pos)	
	local x = pos.x
	local y = pos.y
	local z = pos.z
	if minetest.registered_entities[pet_name] and minetest.registered_entities[pet_name].visual_size.x then
		if minetest.registered_entities[pet_name].visual_size.x >= 32 and
			minetest.registered_entities[pet_name].visual_size.x <= 48 then
				y = y + 2
		elseif minetest.registered_entities[pet_name].visual_size.x > 48 then
			y = y + 5
		else
			y = y + 1
		end
	end
	local spawn_pos = { x = x, y = y, z = z}
	return spawn_pos
end
