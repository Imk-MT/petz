local modpath, S = ...

petz.puncher_is_player = function(puncher)
	if type(puncher) == 'userdata' and puncher:is_player() then
		return true
	else
		return false
	end
end

petz.calculate_damage = function(tool_capabilities)
	local damage_points
	if tool_capabilities.damage_groups["fleshy"] ~= nil or tool_capabilities.damage_groups["fleshy"] ~= "" then		
		damage_points = tool_capabilities.damage_groups["fleshy"] or 0
		--minetest.chat_send_player("singleplayer", "hp : "..tostring(damage_points))	
	else
		damage_points = 0
	end
	return damage_points
end

petz.kick_back= function(self, dir) 
	local hvel = vector.multiply(vector.normalize({x=dir.x, y=0, z=dir.z}), 4)
	self.object:set_velocity({x=hvel.x, y=2, z=hvel.z})
end

petz.punch_tamagochi = function (self, puncher)
	if self.affinity == nil then
		return
    end
    if petz.settings.tamagochi_mode == true then         
        if self.owner == puncher:get_player_name() then
            petz.set_affinity(self, -petz.settings.tamagochi_punch_rate)            
        end
    end
end

--
--on_punch event for all the Mobs
--

function petz.on_punch(self, puncher, time_from_last_punch, tool_capabilities, dir)
	if mobkit.is_alive(self) then
		if self.is_wild == true then
			petz.tame_whip(self, puncher)
		end
		if petz.puncher_is_player(puncher) then		
			if self.dreamcatcher == true and self.owner ~= puncher:get_player_name() then --The dreamcatcher protects the petz
				return
			end
			petz.punch_tamagochi(self, puncher) --decrease affinity when in Tamagochi mode
			mobkit.hurt(self, tool_capabilities.damage_groups.fleshy or 1)
			petz.update_nametag(self)
			self.was_killed_by_player = petz.was_killed_by_player(self, puncher)							
		end	
		petz.kick_back(self, dir) -- kickback	
		petz.do_sound_effect("object", self.object, "petz_default_punch")	--sound
		if (petz.settings.blood == true and not(self.no_blood)) then --blood
			petz.blood(self)
		end
		if self.hp <= 0 and self.driver then --important for mountable petz!
			petz.force_detach(self.driver)
		end
		if self.is_wild and not(self.tamed) and not(self.attack_player) then --if you hit it, will attack player
			self.warn_attack = true	
			mobkit.clear_queue_high(self)
		end
	end
end
