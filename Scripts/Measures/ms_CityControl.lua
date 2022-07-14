function Run()

	GetScenario("World")
	if HasProperty("World", "static") then
		StopMeasure()
	end
	
	local CityID = GetProperty("", "CityID")
	if not GetAliasByID(CityID, "MyCity") then
		StopMeasure()
	end

	if CityIsKontor("MyCity") then
		StopMeasure()
	end

	while true do
		Sleep(Rand(600)+400)
		local Choice = Rand(160)+1
		if ScenarioGetDifficulty()<3 then 
			if Choice ==1 then
				ms_citycontrol_Inferno()
			elseif Choice == 2 and Weather_GetSeason()~=3 then
				ms_citycontrol_Heuschrecken()
			else
				ms_citycontrol_InfectPartyMember()
			end
		elseif ScenarioGetDifficulty()==3 then
			if Choice <3 then
				ms_citycontrol_Inferno()
			elseif Choice >2 and Choice <5 and Weather_GetSeason()~=3 then
				ms_citycontrol_Heuschrecken()
			elseif Choice == 5 then
				if GetRound() > (3+Rand(5)) then
					if not HasProperty("MyCity","Ratboy") then
						SetProperty("MyCity","Ratboy",1)
						ms_citycontrol_RatBoy()
					end
				end
			elseif Choice == 6 then
				if GetRound() > (5+Rand(5)) then
					if not HasProperty("MyCity","Pest") then
						SetProperty("MyCity","Pest",1)
						ms_citycontrol_TheBlackDeath()
					end
				end
			else
				ms_citycontrol_InfectPartyMember()
			end
		elseif ScenarioGetDifficulty()==4 then
			if Choice <4 then
				ms_citycontrol_Inferno()
			elseif Choice >3 and Choice <6 and Weather_GetSeason()~=3 then
				ms_citycontrol_Heuschrecken()
			elseif Choice == 6 or Choice == 7 then
				if GetRound() > (4+Rand(4)) then
					if not HasProperty("MyCity","Ratboy") then
						SetProperty("MyCity","Ratboy",1)
						ms_citycontrol_RatBoy()
					end
				end
			elseif Choice == 8 or Choice == 9 then
				if GetRound() > (6+Rand(6)) then
					if not HasProperty("MyCity","Pest") then
						SetProperty("MyCity","Pest",1)
						ms_citycontrol_TheBlackDeath()
					end
				end
			else
				ms_citycontrol_InfectPartyMember()
			end
		end
	end
end

function InfectPartyMember()
	
	ScenarioGetRandomObject("cl_Dynasty", "CurrentDyn")
	if not AliasExists("CurrentDyn") then
		return
	end
	
	local MemberCount = DynastyGetMemberCount("CurrentDyn")
	if MemberCount > 0 then
		 for i=0, MemberCount-1 do
		 	 if DynastyGetMember("CurrentDyn", i, "CurrentMember") then
		 	 	if IsPartyMember("CurrentMember") then 
		 	 		if GetID("CurrentMember") then
		 	 			if GetState("CurrentMember", STATE_SICK) then 
		 	 				return
		 	 			end
		 	 		end
		 	 	end
		 	 end
		 end
	end
	
	if AliasExists("CurrentMember") then
		if GetImpactValue("CurrentMember", "Resist") > 0 then --check if you were ill or used soap or staff of aesculap
			return 
		end
		if GetImpactValue("CurrentMember", "Sickness") > 0 then -- check if you are already ill
			return 
		end
	
		local SickChoice = 1 + Rand(10)
		local krankH
		-- check the scenario difficulty
		if ScenarioGetDifficulty() > 2 then -- hard settings?
		
			if SickChoice < 4 then -- 30%
				diseases_Cold("CurrentMember", true, true) -- you got lucky
				krankH = 2
			elseif SickChoice < 6 then --20%
				diseases_Sprain("CurrentMember", true, true) -- still lucky
				krankH = 1
			elseif SickChoice < 8 then --20%
				diseases_Influenza("CurrentMember", true, true) -- influenza? not nice
				krankH = 3
			elseif SickChoice < 9 then --10%
				diseases_Pox("CurrentMember", true, true) -- damn!
				SetState("CurrentMember", STATE_CONTAMINATED, true)
				krankH = 4
			elseif SickChoice < 10 then --10%	
				diseases_Fracture("CurrentMember", true, true) -- that hurts
				krankH = 5
			else -- 10%
				diseases_Caries("CurrentMember", true, true) -- c'mon!
				krankH = 6
			end
		else -- low settings
			if SickChoice < 6 then -- 50%
				diseases_Cold("CurrentMember", true, true) -- you got lucky
				krankH = 2
			elseif SickChoice < 9 then --40%
				diseases_Sprain("CurrentMember", true, true) -- still lucky
				krankH = 1
			else -- 10%
				diseases_Influenza("CurrentMember", true, true) -- influenza? not nice
				krankH = 3
			end
		end
	ms_citycontrol_Warnung(1, "CurrentMember", krankH) -- send a message to the poor guy
	end
	
	RemoveAlias("CurrentMember")	-- cleanup
end

function RatBoy()
	if not CityGetRandomBuilding("MyCity", 3, 23, -1, -1, FILTER_IGNORE, "RatBoyHomeBuilding") then
		return
	end
	
	GetPosition("RatBoyHomeBuilding", "RatBoySpawnPos")
	if not SimCreate(904,"RatBoyHomeBuilding", "RatBoySpawnPos", "RatBoy") then
		return
	end
	
	SimSetBehavior("RatBoy", "RatBoy")
	ms_citycontrol_Warnung(2, "RatBoy")
end

function Inferno()
	local NumBuildings = CityGetBuildingCount("MyCity", 1, -1, -1, -1, FILTER_IGNORE)
	CityGetBuildings("MyCity", 1, -1, -1, -1, FILTER_IGNORE, "Building")
	for i=0, NumBuildings-3 do
		SetState("Building"..i, STATE_BURNING, true)
		Sleep(5)
	end
	ms_citycontrol_Warnung(3, "MyCity")
end

function Heuschrecken()
	if not CityGetRandomBuilding("MyCity", 6, 33, 0, -1, FILTER_IGNORE, "Feld") then
		return
	end
	
	if not HasProperty("Feld", "Heuschrecken") then
		SetProperty("Feld", "Heuschrecken", 1)
	else
		return
	end
	MeasureRun("Feld", "", "HeuPlage", true)
	ms_citycontrol_Warnung(4, "MyCity")
end

function TheBlackDeath()
	if not ReadyToRepeat("MyCity", "Pest") then
		return
	end
	
	local opfer = Rand(2) + 1
	if CityGetRandomBuilding("MyCity", opfer, -1, -1, -1, FILTER_HAS_DYNASTY, "Ausbruch") then
		if BuildingGetSim("Ausbruch", 1, "ErstOpfer") then
			diseases_Blackdeath("ErstOpfer", true, true)
			SetRepeatTimer("MyCity", "Pest", 192)
		end
	end
end

function Warnung(danger, opfer, zusatz)

	local krankNam = { "@L_HPFZ_KATASTR_KRANK_NAM_+0", "@L_HPFZ_KATASTR_KRANK_NAM_+1", "@L_HPFZ_KATASTR_KRANK_NAM_+2", "@L_HPFZ_KATASTR_KRANK_NAM_+3", "@L_HPFZ_KATASTR_KRANK_NAM_+4", "@L_HPFZ_KATASTR_KRANK_NAM_+5" }
	
	if danger == 2 then
		MsgNewsNoWait("All", opfer, "", "intrigue", -1, "@L_HPFZ_KATASTR_RATTE_KOPF",
					"@L_HPFZ_KATASTR_RATTE_RUMPF")
	elseif danger == 3 then
		MsgNewsNoWait("All", opfer, "", "intrigue", -1, "@L_HPFZ_KATASTR_FEUER_KOPF",
					"@L_HPFZ_KATASTR_FEUER_RUMPF", GetID(opfer))
	elseif danger == 4 then
		MsgNewsNoWait("All", opfer, "", "intrigue", -1, "@L_HPFZ_KATASTR_GRILLEN_KOPF",
					"@L_HPFZ_KATASTR_GRILLEN_RUMPF", GetID(opfer))
	end
end

function CleanUp()
	if HasProperty("", "CityID") then
		RemoveProperty("", "CityID")
	end
end
