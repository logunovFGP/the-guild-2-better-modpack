function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "Victim", "finish_off") then
		return 0
	end
	if not AliasExists("SIM") then
		return 0
	end
	if GetState("SIM", STATE_DEAD) or GetState("SIM", STATE_UNCONSCIOUS) or GetState("SIM", STATE_CUTSCENE) then
		return 0
	end
	if GetMeasureRepeat("SIM", "Kill") > 0 then
		return 0
	end

	local NumDynasties = ScenarioGetObjects("cl_Dynasty", 99, "FoeDyn")
	local i, j
	for i = 0, NumDynasties - 1 do
		if DynastyGetDiplomacyState("dynasty", "FoeDyn"..i) == DIP_FOE then
			local Count = DynastyGetMemberCount("FoeDyn"..i)
			for j = 0, Count - 1 do
				if DynastyGetMember("FoeDyn"..i, j, "FinishTarget") then
					if GetState("FinishTarget", STATE_UNCONSCIOUS)
						and not GetState("FinishTarget", STATE_DEAD)
						and not GetState("FinishTarget", STATE_CUTSCENE)
						and GetHPRelative("FinishTarget") <= 0.2
						and GetDistance("SIM", "FinishTarget") <= 2500 then
						if Rand(100) < 40 then
							return 90
						end
						return 0
					end
				end
			end
		end
	end
	return 0
end

function Execute()
	MeasureRun("SIM", "FinishTarget", "Kill", true)
end
