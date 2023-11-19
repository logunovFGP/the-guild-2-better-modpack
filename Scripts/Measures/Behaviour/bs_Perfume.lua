function Run()
	
	-- doesn't effect thugs
	if SimGetProfession("") == GL_PROFESSION_MYRMIDON then
		return ""
	end
		
	local modval = 0  --other gender
	local modval2 = 0 --same gender

	if GetProperty("Actor", "perfume") == 5 then
		modval = GL_FAVOR_MOD_SMALL
		modval2 = GL_FAVOR_MOD_VERYSMALL
	elseif GetProperty("Actor", "perfume") == 4 then
		modval = 4
		modval2 = 2
	elseif GetProperty("Actor", "perfume") == 3 then
		modval = GL_FAVOR_MOD_VERYSMALL
		modval2 = GL_FAVOR_MOD_TINY
	elseif GetProperty("Actor", "perfume") == 2 then
		modval = 2
		modval2 = 1
	elseif GetProperty("Actor", "perfume") == 1 then
		modval = GL_FAVOR_MOD_TINY
	end

	if SimGetGender("") == SimGetGender("Actor") then
		if modval2 > 0 then
			chr_ModifyFavor("", "Actor", modval2)
		end
	else
		if modval > 0 then
			chr_ModifyFavor("", "Actor", modval)
		end
	end

	return ""
end

