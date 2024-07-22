function Run()
	
	chr_CheckHome("") -- make sure we have a home
	
	-- debug actions
	GetScenario("World")
	local Prop = GetProperty("World", "DebugActions") or 0
	if Prop == 1 then
		while Prop > 0 do
			LogMessage(GetName("").." ID: "..GetID("").." commits action attackbuilding")
			CommitAction("attackbuilding", "", "", "")
			Sleep(1)
			StopAction("attackbuilding", "")
			LogMessage(GetName("").." ID: "..GetID("").." stopped action")
			Prop = GetProperty("World", "DebugActions") or 0
			Sleep(1)
		end
	end

	-- special behavior banned
	if GetImpactValue("", "banned") == 1 then
		MeasureRun("", nil, "DynastyBanned")
		return
	end
	
	-- Do nothing once in a while
	local DoNothing = GetProperty("", "_DO_NOTHING_TIME") or 0
	if DoNothing > 0 then
		RemoveProperty("", "_DO_NOTHING_TIME")
		Sleep(DoNothing*60)
	end 
	
	-- cleanup moveset
	if GetImpactValue("", "Sickness") < 1 then
		MoveSetActivity("")
	end	
	
	-- check for treatment need
	if chr_NeedsTreatment("") then
		if gameplayformulas_CheckMoneyForTreatment("") == 1 then
			if ReadyToRepeat("", "ai_VisitDoc") then
				idlelib_VisitDoc()
			end
		end
	end
	
	-- check again. If still true, go to the market
	if chr_NeedsTreatment("") then
		idlelib_Illness()
		SetProperty("", "_DO_NOTHING_TIME", 4)
		return
	end
	
	--Sleep at night?
	local currentGameTime = math.mod(GetGametime(),24)
	if (currentGameTime >23 or currentGameTime < 4) then
		idlelib_GoSleep()
		SetProperty("", "_DO_NOTHING_TIME", 1)
		return
	end
	
	-- WIP
	if Rand(2) == 0 then
		if dyn_GetRandomWorkshopForSim("", "MyWorkshop") then
			f_MoveTo("", "MyWorkshop")
			return
		end
	end
	idlelib_DoNothing()
	return
end
