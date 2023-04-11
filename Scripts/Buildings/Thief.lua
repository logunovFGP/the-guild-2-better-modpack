function Run()
end

function OnLevelUp()
	bld_HandleOnLevelUp("")
end

function Setup()
	bld_HandleSetup("")	-- create ambient animals
	if Rand(2) == 0 then
		worldambient_CreateAnimal("Cat", "", 1)
	else
		worldambient_CreateAnimal("Dog", "", 1)
	end
end

function PingHour()
	bld_HandlePingHour("", true)
	
	local HijackTargetID = GetProperty("", "HijackingOrder")
	if HijackTargetID and BuildingHasUpgrade("", "PrisonDoor") then
		-- check current prisoner and release first if it is someone else
		if BuildingGetPrisoner("", "Prisoner") and GetID("Prisoner") ~= HijackTargetID then
			-- release prisoner (building measure)
			MeasureRun("", nil, "LetAbducteeFree", false)
		end
	end
end

-- Measures: PickpocketPeople, ScoutAHouse, BurgleAHouse, Hijack, DemandRansom, (LetAbducteeFree--building measure)
-- During the day: PickpocketPeople, ScoutAHouse, DemandRansom
-- During the night: BurgleAHouse, Hijack
function GetWorkerTask(BldAlias, WorkerAlias)
	local WorkerIndex
	local WorkerCount = BuildingGetWorkerCount(BldAlias)
	local WorkerID = GetID(WorkerAlias)
	for i=0, WorkerCount-1 do
		if BuildingGetWorker(BldAlias, i, "Worker") and GetID("Worker") == WorkerID then
			WorkerIndex = i
		end
	end
	
	if not WorkerIndex then
		LogMessage("Thief JobAssignment failed, missing WorkerIndex for " .. GetName(WorkerAlias) .. " of " .. GetName(BldAlias))
		return
	end

	local Time = math.mod(GetGametime(), 24)
	local IsDaytime = (4 <= Time and Time <= 20)
	local BldLvl = BuildingGetLevel(BldAlias)
	local HijackTargetID = GetProperty(BldAlias, "HijackingOrder")
	
	local Tasks = {}
	if IsDaytime then
		Tasks = { "PickpocketPeople", "PickpocketPeople", "ScoutAHouse" }
		if BldLvl >= 2 then
			Tasks[4] = "DemandRansom" -- special case: will go pocketpicking if idle
		end
		if BldLvl >=3 then
			Tasks[5] = "ScoutAHouse"
		end
	else -- night time
		Tasks = { "PickpocketPeople", "BurgleAHouse", "BurgleAHouse" } -- burglers have a chance of pocketpicking instead
		if BldLvl >= 2 then
			Tasks[4] = "PickpocketPeople"
		end
		if BldLvl >=3 then
			Tasks[5] = "BurgleAHouse"
		end
		
		if (not HijackTargetID) and BuildingHasUpgrade(BldAlias, "PrisonDoor") and Rand(10) < 1  then
			if thief_FindHijackVictim(BldAlias, "HijackVictim") then
				HijackTargetID = GetID("HijackVictim")
				SetProperty(BldAlias, "HijackingOrder", HijackTargetID)
			end
		end
	end
	
	if HijackTargetID and BuildingHasUpgrade(BldAlias, "PrisonDoor") then
		GetAliasByID(HijackTargetID, "HijackTarget")
		Tasks = { "Hijack", "Hijack", "Hijack", "Hijack" }
		if BldLvl >=3 then
			Tasks[5] = "Hijack"
		end
	end
	
	if not Tasks[WorkerIndex+1] then
		LogMessage("Thief JobAssignment failed, missing Task for " .. WorkerIndex .. ": " .. GetName(WorkerAlias) .. " of " .. GetName(BldAlias))
	end
	return Tasks[WorkerIndex + 1], HijackTargetID, WorkerIndex
end

function CheckInForWork(BldAlias, SimAlias)
	-- Task may be one of: PickpocketPeople, ScoutAHouse, BurgleAHouse, Hijack, DemandRansom
	local Task, Detail, Index = thief_GetWorkerTask(BldAlias, SimAlias)
	LogMessage("Thief JobAssignment " .. Index .." : " .. Task .. ", " .. (Detail or "")  )
	if "PickpocketPeople" == Task then
		thief_StartPickpocket(BldAlias, SimAlias, Detail, Index)
		return Task
	elseif "ScoutAHouse" == Task then
		thief_StartScoutBuilding(BldAlias, SimAlias)
		return Task
	elseif "BurgleAHouse" == Task then
		if Rand(10) > 4 then
			thief_StartBurgleBuilding(BldAlias, SimAlias)
			return Task
		else
			thief_StartPickpocket(BldAlias, SimAlias, nil, Index)
			return "PickpocketPeople"
		end
	elseif "Hijack" == Task then
		GetAliasByID(Detail, "HijackVictim")
		SquadCreate(SimAlias, "SquadHijackCharacter", "HijackVictim", "SquadHijackMember", "SquadHijackMember")
		return Task
	elseif "DemandRansom" == Task then
		if BuildingGetPrisoner(BldAlias, "Victim") and ReadyToRepeat(SimAlias, GetMeasureRepeatName2("DemandRansom")) then
			MeasureCreate("Measure")
			MeasureAddData("Measure", "Victim", "Victim")
			MeasureStart("Measure", "SIM", nil, "DemandRansom")
			return Task
		else
			thief_StartPickpocket(BldAlias, SimAlias, nil, Index)
			return "PickpocketPeople"
		end
	end
	return nil
end

function StartPickpocket(BldAlias, SimAlias, CrowdedLocator)
	CrowdedLocator = CrowdedLocator or GetProperty(SimAlias, "LastPickpocketLocator")
	if CrowdedLocator and Rand(5) < 3 then -- locator name of destination; occasionally choose a different destination
		GetOutdoorLocator(CrowdedLocator, 1, "Destination")
	else -- try to initialize destination
		GetSettlement(BldAlias, "City")
		CrowdedLocator = chr_CityFindCrowdedPlace("City", SimAlias, "Destination")
		if "Market" ~= CrowdedLocator then
			SetProperty(SimAlias, "LastPickpocketLocator", CrowdedLocator)
		end
	end
	--LogMessage("Starting PickpocketMeasure at locator: " .. CrowdedLocator )
	MeasureCreate("Measure")
	MeasureAddData("Measure", "TimeOut", 2)
	MeasureStart("Measure", SimAlias, "Destination", "PickpocketPeople")
end

-- taken from TWP, needs to be adapted
function StartBurgleBuilding(BldAlias, WorkerAlias) 
	if not GetSettlement(BldAlias, "City") then
		return false
	end
	
	local DynID = GetDynastyID(BldAlias)

	-- filter for buildings that have been scouted
	local DynId = GetDynastyID(BldAlias)
	local BldCount = Find(BldAlias, "__F((Object.GetObjectsByRadius(Building)==10000)AND NOT(Object.BelongsToMe())AND NOT(Object.HasImpact(buildingburgledtoday))AND(Object.HasProperty(ScoutedBy"..DynId..")))", "Bld", 10)
	local TargetAlias
	for i = 0, BldCount - 1 do
		TargetAlias = "Bld"..i
		if BuildingGetOwner(TargetAlias, "BuildingOwner") and DynastyGetDiplomacyState(BldAlias, "BuildingOwner") < DIP_ALLIANCE then
			if Find(TargetAlias, "__F((Object.GetObjectsByRadius(Sim)==500) AND NOT(Object.BelongsToMe()))","Sims",10) < 5 then
				--LogMessage("::TOM::Thief Found a building to burgle."..GetName(TargetAlias).." Diplomacy is "..DynastyGetDiplomacyState(HomeAlias, "BuildingOwner"))
				MeasureRun(WorkerAlias, TargetAlias, "BurgleAHouse")
				return true
			end
		end
	end
	if BldCount <= 0 then
		-- if no scouted buildings are available, go scouting
		thief_StartScoutBuilding(BldAlias, WorkerAlias)
	end
	return false
end

function StartScoutBuilding(BldAlias, WorkerAlias)
	local BuildingClass = Rand(2) + 1 -- GL_BUILDING_CLASS_LIVINGROOM == 1, GL_BUILDING_CLASS_WORKSHOP == 2
	local DynId = GetDynastyID(BldAlias)
	GetSettlement(BldAlias, "City")
	for j = 0, 5 do
		if CityGetRandomBuilding("City", BuildingClass, -1, -1, -1, FILTER_HAS_DYNASTY, "BuildingToScout") 
				and DynId ~= GetDynastyID("BuildingToScout")
				and BuildingGetOwner("BuildingToScout", "BldOwner") 
				and DynastyGetDiplomacyState(BldAlias, "BldOwner") <= DIP_NEUTRAL then
			MeasureRun(WorkerAlias, "BuildingToScout", "ScoutAHouse")
		end
	end
end

function FindHijackVictim(BldAlias, RetAlias)
	if not DynastyGetRandomVictim(BldAlias, 50, "HIJ_VICTIM") then
		return false
	end
	
	if DynastyGetDiplomacyState(BldAlias, "HIJ_VICTIM") > DIP_NEUTRAL then
		return false
	end
	
	local Count = DynastyGetMemberCount("HIJ_VICTIM")
	if Count < 1 then
		return false
	end
	
	if not DynastyGetMember("HIJ_VICTIM", Rand(Count), "HIJ_SIM") then
		return false
	end
	
	CopyAlias("HIJ_VICTIM", RetAlias)
	return true
end