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

	local Difficulty = ScenarioGetDifficulty()
	local Season
	while true do
		Sleep(Rand(120)+420)
		Season = GetSeason() 
		-- infection, Heuschrecken, inferno, black death, ratboy
		local probs = {8, 1, 2, 1, 1} -- spring and fall
		if Season == EN_SEASON_SUMMER then
			probs = {3, 2, 3, 2, 0} -- summer
		elseif Season == EN_SEASON_WINTER then
			probs = {15, 0, 0, 2, 0} -- winter
		end
	
		local Choice = Rand(100)+1
		if Choice < Difficulty * probs[1] then
			ms_citycontrol_InfectPartyMember()
		elseif Choice < Difficulty * (probs[1] + probs[2]) then
			ms_citycontrol_Heuschrecken()
		elseif Choice < Difficulty * (probs[1] + probs[2] + probs[3]) then
			ms_citycontrol_Inferno()
		elseif Choice < Difficulty * (probs[1] + probs[2] + probs[3] + probs[4])  and GetRound() > (10 - Difficulty) then
			ms_citycontrol_TheBlackDeath()
		elseif Choice < Difficulty * probs[5] then
			ms_citycontrol_RatBoy()
		else 
			-- DEBUG
			--MsgNewsNoWait("All","","","intrigue",-1,"Gl�ck gehabt!", "Es ist nichts passiert, Wahl: "..Choice)
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
				Disease.Cold:infectSim("CurrentMember") -- you got lucky
				krankH = 2
			elseif SickChoice < 6 then --20%
				Disease.Sprain:infectSim("CurrentMember") -- still lucky
				krankH = 1
			elseif SickChoice < 8 then --20%
				Disease.Influenza:infectSim("CurrentMember") -- influenza? not nice
				krankH = 3
			elseif SickChoice < 9 then --10%
				Disease.Pox:infectSim("CurrentMember") -- damn!
				SetState("CurrentMember", STATE_CONTAMINATED, true)
				krankH = 4
			elseif SickChoice < 10 then --10%	
				Disease.Fracture:infectSim("CurrentMember") -- that hurts
				krankH = 5
			else -- 10%
				Disease.Caries:infectSim("CurrentMember") -- c'mon!
				krankH = 6
			end
		else -- low settings
			if SickChoice < 6 then -- 50%
				Disease.Cold:infectSim("CurrentMember") -- you got lucky
				krankH = 2
			elseif SickChoice < 9 then --40%
				Disease.Sprain:infectSim("CurrentMember") -- still lucky
				krankH = 1
			else -- 10%
				Disease.Influenza:infectSim("CurrentMember") -- influenza? not nice
				krankH = 3
			end
		end
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
	do Sleep(5) return end
	local NumBuildings = CityGetBuildingCount("MyCity", 1, -1, -1, -1, FILTER_IGNORE)
	CityGetBuildings("MyCity", GL_BUILDING_CLASS_LIVINGROOM, -1, -1, -1, FILTER_IGNORE, "Building")
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
			Disease.Blackdeath:infectSim("ErstOpfer")
			SetRepeatTimer("MyCity", "Pest", 192)
		end
	end
end

function Warnung(danger, opfer, zusatz)
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
