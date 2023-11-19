function GetWorld()
	return "charactercreation.wld"
end


function Prepare()
	local RandomTime = 6 + Rand(12)
	local Season = { EN_SEASON_SPRING, EN_SEASON_SUMMER, EN_SEASON_AUTUMN, EN_SEASON_WINTER }
	local Randomizer = 1 + Rand(4)
	
	SetTime(Season[Randomizer], 1400, RandomTime, 0)
	GetScenario("World")
	SetProperty("World", "static", 1)
	
	SetProperty("World", "StartCam_PosX", 33781.7578)
	SetProperty("World", "StartCam_PosY", 598.3578)
	SetProperty("World", "StartCam_PosZ", 9079.6406)
	SetProperty("World", "StartCam_RotX", 13.2332)
	SetProperty("World", "StartCam_RotY", 238.9456)
	
	SetProperty("World", "AppearanceCam_PosX", 30267.0391)
	SetProperty("World", "AppearanceCam_PosY", -182.0921)
	SetProperty("World", "AppearanceCam_PosZ", 6900.5098)
	SetProperty("World", "AppearanceCam_RotX", -5.0)
	SetProperty("World", "AppearanceCam_RotY", 62.5890)
	
	SetProperty("World", "AppearanceFaceCam_PosX", 30601.5332)
	SetProperty("World", "AppearanceFaceCam_PosY", -167.6296)
	SetProperty("World", "AppearanceFaceCam_PosZ", 7120.0967)
	SetProperty("World", "AppearanceFaceCam_RotX", 0.0)
	SetProperty("World", "AppearanceFaceCam_RotY", 76.0144)

	SetProperty("World", "EditCam_PosX", 30024.5430)
	SetProperty("World", "EditCam_PosY", -55.6803)
	SetProperty("World", "EditCam_PosZ", 6650.2314)
	SetProperty("World", "EditCam_RotX", 5.0)
	SetProperty("World", "EditCam_RotY", 37.9336)

	SetProperty("World", "CharPos_PosX", 30710.3496)
	SetProperty("World", "CharPos_PosY", -347.9283)
	SetProperty("World", "CharPos_PosZ", 7152.3535)
	SetProperty("World", "CharPos_RotX", 0)
	SetProperty("World", "CharPos_RotY", -98.8780)
	
	return true
end

function CreatePlayerDynasty()
	return ""
end

function CreateShadowDynasty()
	return ""
end

function CreateComputerDynasty()
	return "no"
end

function Start()
	for n=1, 50 do
		if GetOutdoorLocator("Start"..n, 1, "Position" )==0 then
			break	-- return "Unable to locate the locator Start"..n.." in the startup scene"
		end
	
		local SwitchSim = 0
		SwitchSim = Rand(5)
		
		if SwitchSim == 1 then
			if not SimCreate(3, "", "Position", "NPC") then
				break -- return "Unable to create NPC number "..n.." for the startup scene"
			end
			SimSetBehavior("NPC", "apprenticeship")
		elseif SwitchSim == 2 then
			if not BossCreate(nil, Rand(2), 1+Rand(4), 6, "NPC") then
				break -- return "Unable to create NPC number "..n.." for the startup scene"
			end
			SimBeamMeUp("NPC", "Position")
		elseif SwitchSim == 3 then
			if not SimCreate(15, "", "Position", "NPC") then
				break -- return "Unable to create NPC number "..n.." for the startup scene"
			end
		else
			if not SimCreate(17, "", "Position", "NPC") then
				break -- return "Unable to create NPC number "..n.." for the startup scene"
			end
		end

		SetProperty("NPC", "Point1", "End"..n)
		SetProperty("NPC", "Point2", "Start"..n)
		if GetOutdoorLocator("Start"..n+1, 1, "Pos") then
			SetProperty("NPC", "Point3", "Start"..n+1)
		end
		
		if SimGetAge("NPC") > 15 then
			SimSetBehavior("NPC", "Patroille")
		end
		
		SimStartIdleMeasure("NPC")
		
		if GetOutdoorLocator("Cart"..n, 1, "CartPos" )~=0 then
			if n == 1 then
				ScenarioCreateCart(EN_CT_HORSE, nil, "CartPos", "Cart")
			else
				ScenarioCreateCart(EN_CT_MIDDLE, nil, "CartPos", "Cart")
			end
		end

		if GetOutdoorLocator("Dog"..n, 1, "DogPos" )~=0 then
			SimCreate(906, "", "DogPos", "NPC")
			SetState("NPC", STATE_ANIMAL, true)
		end
		if GetOutdoorLocator("Cat"..n, 1, "CatPos" )~=0 then
			SimCreate(908, "", "CatPos", "NPC")
			SetState("NPC", STATE_ANIMAL, true)
		end
	end
	
	if GetOutdoorLocator("Dyn1", 1, "DynPos" )~=0 then
		if BossCreate(nil, Rand(2), 1+Rand(4), 6, "NPCDyn") then
			SimBeamMeUp("NPCDyn", "DynPos")
			if GetOutdoorLocator("Dyn2", 1, "FriendPos" )~=0 then
				if BossCreate(nil, Rand(2), 1+Rand(4), 6, "NPCFriend") then
					SimBeamMeUp("NPCFriend", "FriendPos")
					AlignTo("NPCDyn", "NPCFriend")
					AlignTo("NPCFriend", "NPCDyn")
					SimSetBehavior("NPCDyn", "StartUpDyn")
					SimStartIdleMeasure("NPCDyn")
					SimSetBehavior("NPCFriend", "StartUpDyn")
					SimStartIdleMeasure("NPCFriend")
				end
			end
		end
	end
	
	for i = 1, 5 do
		if GetOutdoorLocator("Guard"..i, 1, "GuardPos") then
			SimCreate(918, "", "GuardPos", "NPC")
			GetNearestSettlement("NPC", "City")
			if CityGetNearestBuilding("City", "NPC", -1, GL_BUILDING_TYPE_WELL, -1, -1, FILTER_IGNORE, "Target") then
				AlignTo("NPC", "Target")
			end
			SimSetBehavior("NPC", "StartUpGuard")
			SimStartIdleMeasure("NPC")
		end
	end

	if GetOutdoorLocator("Priest1", 1, "PriestPos" )~=0 then
		SimCreate(20, "", "PriestPos", "NPC")
		LoopAnimation("NPC", "sing_for_peace", -1)
	end
	
	if GetOutdoorLocator("Water"..1, 1, "Position" )~=0 then
		if ScenarioCreateCart(EN_CT_WARSHIP, nil, "Position", "Boat") then
			MeasureRun("Boat", nil, "StartmenuShip")
		end
	end
	
end

