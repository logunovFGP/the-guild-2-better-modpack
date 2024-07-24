function Weight()
	return 0
end

function Execute()
	random = Rand(TotalFound)
	if not CopyAlias("MEMBER"..random, "SIM") then
		return 0
	end
	
--	name = GetName("SIM")
--	str = "CheckDynastyChar: Selected "..name
--	LogMessage(str);
	
	SetRepeatTimer("dynasty", "AI_CheckDynasty", 0.5)
	
	return 1
end
