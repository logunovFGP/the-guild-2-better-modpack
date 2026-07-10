function Run()

	if GetImpactValue("Actor", "revolt") > 0 then
		if HasProperty("Actor", "RevoltCityID") then
			local RevoltCityID = GetProperty("Actor", "RevoltCityID")
			local MyCityID = -1
			if GetSettlement("", "bsRevoltMyCity") then
				MyCityID = GetID("bsRevoltMyCity")
			end
			if MyCityID ~= RevoltCityID then
				return ""
			end
		end
		chr_ModifyFavor("", "Actor", -GL_FAVOR_MOD_GREATER)

		if SimGetProfession("") == GL_PROFESSION_CITYGUARD then
			if GetState("Actor",STATE_UNCONSCIOUS) and GetImpactValue("Actor", "REVOLT") > 0 then
				MeasureRun("", "Actor", "Kill")
			else
				gameplayformulas_SimAttackWithRangeWeapon("", "Actor")
				BattleJoin("", "Actor", true)
			end
		end
	end

	return ""
end

