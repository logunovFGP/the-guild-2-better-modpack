function Weight()

	if not HasProperty("dynasty", "AI_PERSONA") then
		ai_ChoosePersonality("dynasty")
	end
	
	if not ReadyToRepeat("dynasty", "AI_CheckDynasty") then
		return 0
	end	
	
	TotalFound = 0
	Count = DynastyGetMemberCount("dynasty")
	for i=0, Count-1 do
		if DynastyGetMember("dynasty", i, "CHECKME") then
			if DynastyIsAI("CHECKME") then
				if GetState("CHECKME", STATE_WORKING) then
					if Rand(6) == 0 then
						CopyAlias("CHECKME", "MEMBER"..TotalFound)
						TotalFound = TotalFound + 1
					end
				elseif GetState("CHECKME", STATE_IDLE) then
					CopyAlias("CHECKME", "MEMBER"..TotalFound)
					TotalFound = TotalFound + 1
				end
			end
		end
	end
	
	if TotalFound == 0 then
		return 0
	end
	
	return TotalFound*100
end

function Execute()
	random = Rand(TotalFound)
	if not CopyAlias("MEMBER"..random, "SIM") then
		return 0
	end
	
	name = GetName("SIM")
	str = "CheckDynastyChar: Selected "..name
	LogMessage(str);
	
	SetRepeatTimer("dynasty", "AI_CheckDynasty", 0.5)
	
	return 1
end
