function Weight()
	return 0
end

function Execute()
	LogMessage("Dynasty added "..GetName("SIM").." to group of Dynasty "..GetName("dynasty"))
	DynastyAddMember("dynasty", "SIM")
	SetRepeatTimer("dynasty", "AI_CheckPartyMember", 1)
end

