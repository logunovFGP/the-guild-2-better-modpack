-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_147_PatrolTheTown"
----
----	with this measure, the player can send a myrmidon to patrol between 
----	2 waypoints or guard an building
----
-------------------------------------------------------------------------------

function Init() 
	local i = 2
	local Distance
	CopyAlias("Destination", "Waypoint1")
	--collect the waypoints
	if AliasExists("Waypoint1") then
		while true do 
			InitAlias("Waypoint"..i,MEASUREINIT_SELECTION, "__F((Object.Type == Building) OR (Object.Type == Position))",
				"@L_GENERAL_MEASURES_147_PATROLTHETOWN_WAYPOINT_+0", AIInit)
			GetPosition("Waypoint"..i, "ParticleSpawnPos")
			StartSingleShotParticle("particles/aimingpoint.nif", "ParticleSpawnPos", 4, 5)
			Distance = GetDistance("Waypoint"..i, "Waypoint"..i-1)
			i = i + 1
			if Distance < 200 then
				break
			end	
			Sleep(1)
		end
	end
	i = i-1
	SetData("WaypointCount", i)
	MsgMeasure("", "")
end

function AIInit()
end

function Run()
	local Count

	if AliasExists("Waypoint1") then
		Count = 0+GetData("WaypointCount")
	end

	--ai timeout
	local TimeOut = GetData("TimeOut")
	if TimeOut then
		TimeOut = GetGametime() + TimeOut
	end
	
	while true do
		if TimeOut then
			if TimeOut < GetGametime() then
				break
			end
		end
		
		--for the ai
		if not AliasExists("Waypoint1") then
			
			if not AliasExists("Destination") then
				f_Stroll("", 600, 20)
				Sleep(30)
				return
			end

			if (GetOutdoorMovePosition("", "Destination", "Target")) then
				if not (f_MoveTo("", "Target", GL_MOVESPEED_WALK, 100)) then
					return
				end
			end
			f_Stroll("", 600, 20)
			Sleep(45)
			return
		else
			--if only one waypoint, and waypoint1 is building
			if (Count == 2 and IsType("Waypoint1","Building")) then
					
				for k=1, 4 do
					if GetLocatorByName("Waypoint1", "Walledge"..k, "VictimsCorner"..k) then
						f_MoveTo("", "VictimsCorner"..k, GL_MOVESPEED_WALK, 10)
					end
					Sleep(Rand(5)+10)
				end
			else
				
				--walk through all waypoints
				for i=1, Count do
					f_MoveTo("", "Waypoint"..i)
					Sleep(10)
				end
			end
		end
		
		--check for blackboard
		if SimGetWorkingPlace("", "Workbuilding") then
			if BuildingGetOwner("Workbuilding", "Boss") then
				if DynastyIsPlayer("Boss") then
					local BlackBoard = false
					if FindNearestBuilding("", 3, 41, 0, false, "BlackBoardNear") then
						local cost = GetNobilityTitle("Boss")*50
						if (GetDistance("", "BlackBoardNear") <= 800) and GetMoney("Boss") >= cost then
							BlackBoard = true
							--check for pamphlets and remove them
							ms_147_patrolthetown_RemovePamphlet("BlackBoardNear", cost)
						end
					end
				end	
			end
		end
		Sleep(5)
	end
end

-- patrolling myrmidon should remove a pamphlet against his dynasty
--added by Napi & Fajeth

function RemovePamphlet(blackboard, cost)
	
	--check pamphlets (from di_RemovePamphlet.lua)
	local Idx = -1
	
	for i=0, 3 do
		if HasProperty(blackboard,"Pamphlet_"..i) then
			local PamphletID = GetProperty(blackboard, "Pamphlet_"..i)
			if GetAliasByID(PamphletID, "PamphletVictim") then
				if (GetDynastyID("PamphletVictim") == GetDynastyID("")) then
					Idx = i
				end
			end
		end
	end
	
	if Idx >= 0 then
		if not HasProperty(blackboard, "Pamphlet_"..Idx) then
			return		
		end
	else
		return
	end
	
	-- animation stuff
	
	GetLocatorByName(blackboard, "entry1", "MovePos")
	f_MoveTo("", "MovePos", GL_MOVESPEED_RUN)
	AlignTo("", blackboard)
	Sleep(1)
	PlayAnimationNoWait("", "manipulate_middle_up_r")
	MsgSay("", "@L_PATROLTOWN_PAMPHLET_REMOVE_SAY", GetID("Boss"))
	Sleep(1)
	
	-- check again
	if not HasProperty(blackboard, "Pamphlet_"..Idx) then
		return		
	end
	
	-- remove pamphlet if you have enough money
	if GetMoney("Boss") >= cost then
		if BlackBoardRemovePamphlet(blackboard, Idx) then
			chr_SpendMoney("Boss", cost, "CostBribes", true)

			if HasProperty(blackboard, "Pamphlet_"..Idx) then
				RemoveProperty(blackboard, "Pamphlet_"..Idx)
			end

			if HasProperty(blackboard, "Pamphlet_"..Idx.."Dur") then
				RemoveProperty(blackboard, "Pamphlet_"..Idx.."Dur")
			end

			IncrementXPQuiet("", 15)
		
			--message
			SimGetWorkingPlace("", "Workbuilding")
			BuildingGetOwner("Workbuilding", "Boss")
		
			MsgNewsNoWait("Boss", "", "", "intrigue" , -1,
				"@L_PATROLTOWN_PAMPHLET_REMOVE_SUCCESS_HEAD_+0",
				"@L_PATROLTOWN_PAMPHLET_REMOVE_SUCCESS_BODY_+0",
				GetID(""), GetID("Boss"), cost)
		end
	end
end

function CleanUp()
end

