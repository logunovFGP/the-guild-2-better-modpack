function Weight()
	return 0
end

function Execute()
	SetRepeatTimer("dynasty", "AI_CheckDynastyHeir", 12)
--	LogMessage("Dynasty selected "..GetName("SIM").." as the heir of Dynasty "..GetName("dynasty"))
	-- set heir
	SetProperty("dynasty", "Heir", GetID("SIM"))
	SetProperty("SIM", "DynastyHeir", 1)
end

