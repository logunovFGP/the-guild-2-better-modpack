function Run()
	
	-- doesn't effect thugs
	if SimGetProfession("") == GL_PROFESSION_MYRMIDON then
		return ""
	end
	
	if SimGetGender("Actor") == SimGetGender("") then
		if SimGetOfficeLevel("Actor") == SimGetOfficeLevel("") then
			chr_ModifyFavor("", "Actor", GL_FAVOR_MOD_NORMAL)
			if IsPartyMember("")  then
				MsgNewsNoWait("","Actor","","intrigue",-1,
					"@L_HPFZ_ARTEFAKT_MOSCHUS_OPFER_KOPF_+0",
					"@L_HPFZ_ARTEFAKT_MOSCHUS_OPFER_RUMPF_+0", GetID(""), GetID("Actor"))
			end
		end
	else
		return ""
	end
end
