function GetWorld()
	return "charactercreation.wld"
end


function Prepare()
	SetTime(EN_SEASON_AUTUMN, 1400, 14, 0)
	GetScenario("World")
	SetProperty("World", "static", 1)
	
	SetProperty("World", "StartCam_PosX", 33651.7578)
	SetProperty("World", "StartCam_PosY", 619.3578)
	SetProperty("World", "StartCam_PosZ", 9172.6406)
	SetProperty("World", "StartCam_RotX", 13.4532)
	SetProperty("World", "StartCam_RotY", 233.9456)
	
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
	
		if not SimCreate(17, "", "Position", "NPC") then
			break -- return "Unable to create NPC number "..n.." for the startup scene"
		end

		SetProperty("NPC", "Point1", "End"..n)
		SetProperty("NPC", "Point2", "Start"..n)
	
		SimSetBehavior("NPC", "Patroille")
		SimStartIdleMeasure("NPC")
		
		if GetOutdoorLocator("Cart"..n, 1, "CartPos" )~=0 then
			ScenarioCreateCart(EN_CT_HORSE, nil, "CartPos", "Cart")
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

