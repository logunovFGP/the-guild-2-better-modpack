function Weight()
	if not dyn_GetIdleMember("dynasty", "SIM") then
		return 0
	end
	
	-- If you are available for high offices, get that titles you need
	if (GetNobilityTitle("SIM") <= 4) and (SimGetOfficeLevel("SIM") > 0) then
		return utility_Score("dynasty", 20, {
			utility_Priority("dynasty", "Political"),
			utility_Trait("dynasty", "ambition"),
		}, "NobilityTitle", "Politics")
	end
	
	if not ReadyToRepeat("dynasty", "AI_NobilityTitle") then
		return 0
	end
	
	local currenttitle = GetNobilityTitle("SIM")
	local cost = GetDatabaseValue("NobilityTitle", currenttitle+1, "price")
	local famelvl = GetDatabaseValue("NobilityTitle", currenttitle+1, "minimperialfame")

	-- need to add tonumber to engine
	-- cost = tonumber(cost)
	-- famelvl = tonumber(famelvl)
	if cost == "" or famelvl == "" then
		return 0
	end

	if not DynastyIsShadow("SIM") then
		ai_CalcItemBudget("dynasty")

		if (chr_DynastyGetImperialFameLevel("dynasty") < famelvl) then
			if famelvl <= 2 then
				-- XXX temporary workaround to enable AI to reach title 8 and 9 and advance to imperial offices
				dyn_AddImperialFame("SIM", 1)
			else
				return 0
			end
		end
	end
	
	if DynastyIsShadow("SIM") or GetMoney("SIM") > (cost+5000) then
		return utility_Score("dynasty", 10, {
			utility_Priority("dynasty", "Political"),
			utility_Trait("dynasty", "ambition"),
		}, "NobilityTitle", "Politics")
	end

	return 0
end

function Execute()
	utility_Picked("dynasty", "NobilityTitle")
	local Difficulty = ScenarioGetDifficulty()
	local Repeat = 48 - Difficulty*6 
	SetRepeatTimer("dynasty", "AI_NobilityTitle", Repeat)
	
	MeasureRun("SIM", nil, "BuyNobilityTitle", false)
	return
end

