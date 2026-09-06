function Weight()
	if not dyn_GetIdleMember("dynasty", "SIM") then
		return 0
	end
	
	if SimGetSpouse("SIM") then
		-- already married
		return 0
	end
	
	if not ReadyToRepeat("SIM", "AI_CourtLover") then
		return 0
	end
	
	return utility_Score("dynasty", 50, {}, "CourtLover", "Family")
end

function Execute()
	utility_Picked("dynasty", "CourtLover")
	SetRepeatTimer("SIM", "AI_CourtLover", 2)
	aitwp_CourtLover("SIM")
end