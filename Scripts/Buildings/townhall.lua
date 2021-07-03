function Run()
end

function OnLevelUp()
end

function Setup()
end

function PingHour()
	
	local currentRound = GetRound()
	local currentGameTime = math.mod(GetGametime(),24)
	if currentRound > 0 then
		BuildingGetCity("","city")
		if (currentGameTime == 12) then
			if GetOfficeTypeHolder("city", 1, "Office") then
				chr_SimAddImperialFame("Office",1)
			end
			if GetOfficeTypeHolder("city", 6, "Office") then
				chr_SimAddFame("Office",1)
			end	
			if GetOfficeTypeHolder("city", 7, "Office") then
				chr_SimAddFame("Office",1)
			end	
		end
	end
	
	if currentGameTime == 0.5 then
		if BuildingGetCutscene("", "CutsceneAlias") then
			LogMessage("Cutscene has been terminated")
			EndCutscene("CutsceneAlias")
		end
		
		-- look for locked sims
		local CutsceneFilter = "__F( (Object.GetObjectsByRadius(Sim)==500)AND(Object.GetState(cutscene)))"
		local NumCutsceneSims = Find("", CutsceneFilter, "CutsceneSim", -1)
		if NumCutsceneSims > 0 then
			for i=0, NumCutsceneSims do
				if AliasExists("CutsceneSim"..i) then
					if SimGetCutscene("CutsceneSim"..i, "MyCutscene") and not GetState("CutsceneSim"..i, STATE_TOWNNPC) then
						EndCutscene("MyCutscene")
						if GetState("CutsceneSim"..i, STATE_CUTSCENE) then
							SetState("CutsceneSim"..i, STATE_CUTSCENE, false)
						end
					end
					if DynastyIsAI("CutsceneSim"..i) then
						AllowAllMeasures("CutsceneSim"..i)
						SimResetBehavior("CutsceneSim"..i)
					end
				end
			end
		end
		
		-- look for locked sims inside
		BuildingGetInsideSimList("", "InsideList")
		local ListSize = ListSize("InsideList")
		
		if ListSize >0 then
			for i=0, ListSize-1 do
				ListGetElement("InsideList", i, "SimToCheck")
				if not GetState("SimToCheck", STATE_TOWNNPC) then
					if SimGetCutscene("SimToCheck", "MyCutscene") then
						EndCutscene("MyCutscene")
						if GetState("SimToCheck", STATE_CUTSCENE) then
							SetState("SimToCheck", STATE_CUTSCENE, false)
						end
					end
					if DynastyIsAI("SimToCheck") then
						AllowAllMeasures("SimToCheck")
						SimResetBehavior("SimToCheck")
					end
				end
			end
		end
	end
	
	if not GetState("", STATE_TRADERCONTROL) then
		SetState("", STATE_TRADERCONTROL, true)
	end
end
