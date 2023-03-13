function Run()
end

function OnLevelUp()
	bld_HandleOnLevelUp("")
	thief_UpdateWorkerTasks("")
end

function Setup()
	bld_HandleSetup("")	-- create ambient animals
	if Rand(2) == 0 then
		worldambient_CreateAnimal("Cat", "", 1)
	else
		worldambient_CreateAnimal("Dog", "", 1)
	end
	thief_UpdateWorkerTasks("")
end

function PingHour()
	bld_HandlePingHour("", true)
	-- at 5am, 11am, 5pm, 11pm
	if BuildingGetAISetting("", "Enable") > 0 and math.mod(GetGametime(), 6)==4 then
		thief_UpdateWorkerTasks("")
	end
end

-- Measures: PickpocketPeople, ScoutAHouse, BurgleAHouse, Hijack, DemandRansom, (LetAbducteeFree--building measure)
-- During the day: PickpocketPeople, ScoutAHouse, DemandRansom
-- During the night: BurgleAHouse, Hijack
function UpdateWorkerTasks(BldAlias)
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
		
		if (not HijackTargetID) and Rand(10) < 1  then
			if thief_FindHijackVictim(BldAlias, "HijackVictim") then
				HijackTargetID = GetID("HijackVictim")
			end
		end
	end
	
	if HijackTargetID and BuildingHasUpgrade(BldAlias, "PrisonDoor") then
		-- check current prisoner and release first if it is someone else
		if BuildingGetPrisoner(BldAlias, "Prisoner") and GetID("Prisoner") ~= HijackTargetID then
			-- release prisoner (building measure)
			MeasureRun(BldAlias, nil, "LetAbducteeFree", false)
		end
		GetAliasByID(HijackTargetID, "HijackTarget")
		Tasks = { "Hijack", "Hijack", "Hijack", "Hijack" }
		if BldLvl >=3 then
			Tasks[5] = "Hijack"
		end
	end

	for i=0, 5 do
		if Tasks[i+1] then
			SetProperty(BldAlias, "WorkerTask"..i, Tasks[i+1])
			if HijackTargetID then
				SetProperty(BldAlias, "WorkerDetail"..i, HijackTargetID)
			else
				RemoveProperty(BldAlias, "WorkerDetail"..i)
			end
		end
	end

end

function CheckInForWork(BldAlias, SimAlias)
	-- Task may be one of: PickpocketPeople, ScoutAHouse, BurgleAHouse, Hijack, DemandRansom
	local Task, Detail, Index = bld_GetJobAssignment(BldAlias, SimAlias)
	if "PickpocketPeople" == Task then
		thief_StartPickpocket(BldAlias, SimAlias, Detail, Index)
	elseif "ScoutAHouse" == Task then
		thief_StartScoutBuilding(BldAlias, SimAlias)
	elseif "BurgleAHouse" == Task then
		thief_StartBurgleBuilding(BldAlias, SimAlias)
	elseif "Hijack" == Task then
		GetAliasByID(Detail, "HijackVictim")
		SquadCreate(SimAlias, "SquadHijackCharacter", "HijackVictim", "SquadHijackMember", "SquadHijackMember")
	elseif "DemandRansom" == Task then
		if BuildingGetPrisoner(BldAlias, "Victim") and ReadyToRepeat(SimAlias, GetMeasureRepeatName2("DemandRansom")) then
			MeasureCreate("Measure")
			MeasureAddData("Measure", "Victim", "Victim")
			MeasureStart("Measure", "SIM", nil, "DemandRansom")
		else
			thief_StartPickpocket(BldAlias, SimAlias, nil, Index)
		end
	end
end

function StartPickpocket(BldAlias, SimAlias, CrowdedLocator, TaskIndex)
	if CrowdedLocator and Rand(5) < 3 then -- locator name of destination; occasionally choose a different destination
		GetOutdoorLocator(CrowdedLocator, 1, "Destination")
	else -- try to initialize destination
		GetSettlement(BldAlias, "City")
		CrowdedLocator = chr_CityFindCrowdedPlace("City", SimAlias, "Destination")
		if "Market" ~= CrowdedLocator then
			SetProperty(BldAlias, "WorkerDetail"..TaskIndex, CrowdedLocator)
		end
	end
	--LogMessage("Starting PickpocketMeasure at locator: " .. Detail)
	MeasureCreate("Measure")
	MeasureAddData("Measure", "TimeOut", 2)
	MeasureStart("Measure", SimAlias, "Destination", "PickpocketPeople")
end

-- taken from TWP, needs to be adapted
function StartBurgleBuilding(BldAlias, WorkerAlias) 
	--LogMessage("::TOM::Thief Let's burgle")
	if not GetSettlement(BldAlias, "City") then
		return false
	end
	
	if BuildingGetLevel(BldAlias) < 2 then	
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
	
	if DynastyGetDiplomacyState("SIM", "HIJ_VICTIM") > DIP_NEUTRAL then
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