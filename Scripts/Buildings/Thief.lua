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
	
	for i=0, 5 do
		-- all hands on pockets for now (testing)
		SetProperty("", "WorkerTask"..i, "PICKPOCKET")
	end
end


function CheckInForWork(BldAlias, SimAlias)
	local Task, Detail, Index = bld_GetJobAssignment(BldAlias, SimAlias)
	if "PICKPOCKET" == Task then
		if Detail and Rand(5) < 3 then -- locator name of destination; occasionally choose a different destination
			GetOutdoorLocator(Detail, 1, "Destination")
		else -- try to initialize destination
			GetSettlement(BldAlias, "City")
			Detail = chr_CityFindCrowdedPlace("City", SimAlias, "Destination")
			if "Market" ~= Detail then
				SetProperty(BldAlias, "WorkerDetail"..Index, Detail)
			end
		end
		LogMessage("Starting PickpocketMeasure at locator: " .. Detail)
		MeasureCreate("Measure")
		MeasureAddData("Measure", "TimeOut", 2)
		MeasureStart("Measure", SimAlias, "Destination", "PickpocketPeople")
		return "PICKPOCKET"
	elseif "SCOUT" == Task then
	
	elseif "BURGLE" == Task then
	
	elseif "KIDNAP" == Task then
		
	end

end

