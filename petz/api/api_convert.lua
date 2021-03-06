local modpath, S = ...

petz.convert = function(self, player_name)
	local old_pet_name = petz.first_to_upper(self.type)
	self.convert_count = self.convert_count - 1	
	mobkit.remember(self, "convert_count", self.convert_count)
	if self.convert_count <= 0 then
		local pos = self.object:get_pos()
		local converted_pet = minetest.add_entity(pos, self.convert_to)
		petz.do_sound_effect("object", converted_pet, "petz_pop_sound")
		local converted_entity = converted_pet:get_luaentity()
		converted_entity.tamed = true
		mobkit.remember(converted_entity, "tamed", converted_entity.tamed)
		converted_entity.owner = player_name 
		mobkit.remember(converted_entity, "owner", converted_entity.owner)
		self.object:remove()
		local new_pet_name = petz.first_to_upper(converted_entity.type)
		minetest.chat_send_player(player_name , S("The").." "..S(old_pet_name).." "..S("turn into").." "..S(new_pet_name))
	else
		minetest.chat_send_player(player_name , S("The").." "..S(old_pet_name).." "..S("is turning into another animal")..".")
		petz.do_sound_effect("object", self.object, "petz_"..self.type.."_moaning")
		petz.do_particles_effect(self.object, self.object:get_pos(), "heart") 
	end	
end
