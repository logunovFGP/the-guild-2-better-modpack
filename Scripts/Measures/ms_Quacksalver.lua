function Run()
	
	--LogMessage("StartQuacksalver")
	
	if not ai_GetWorkBuilding("", GL_BUILDING_TYPE_HOSPITAL, "Hospital") then
		StopMeasure() 
	end
	
	if not GetSettlement("", "City") then
		StopMeasure()
	end

	local Producer = BuildingGetProducerCount("Hospital", PT_MEASURE, "Quacksalver")
	
	if IsStateDriven() and BuildingGetAISetting("Hospital", "Produce_Selection") > 0 then
		if Producer > 1 then
	--		LogMessage("Abort StartQuacksalver")
			StopMeasure()
		end
	end

	MeasureSetStopMode(STOP_NOMOVE)

	if not AliasExists("Destination") then
		chr_CityFindCrowdedPlace("City", "", false, "Destination")
	else	
		if GetID("Hospital") == GetID("Destination") then -- stuck in hospital, search a new place
			chr_CityFindCrowdedPlace("City", "", false, "Destination")
		end
	end
	
	SetData("IsProductionMeasure", 0)
	SimSetProduceItemID("", -GetCurrentMeasureID(""), -1)
	SetData("IsProductionMeasure", 1)
	
	while true do
		if not ms_quacksalver_GetPlacebo() then
			break
		end
		
		if GetID("Hospital") == GetID("Destination") then -- stuck in hospital, search a new place
			chr_CityFindCrowdedPlace("City", "", false, "Destination")
		end
		
		if not f_MoveTo("", "Destination", GL_MOVESPEED_RUN) then
	--		LogMessage("Abort Quacksalver Move Error")
			break
		end
		
		CommitAction("quacksalver", "", "")
		while true do
			
			if GetItemCount("", "MiracleCure") < 1 then
				break
			end
			
			PlayAnimation("", "pray_standing")
			PlayAnimation("", "preach")
			Sleep(2)
		end
		StopAction("quacksalver", "")
		
		if BuildingGetAISetting("Hospital", "Produce_Selection") > 0 then
			break
		end
	end
	StopAction("quacksalver", "")
	f_MoveTo("", "Hospital", GL_MOVESPEED_RUN)
	StopMeasure()
end

function GetPlacebo()

	local ItemCount = GetItemCount("", "Lavender", INVENTORY_STD) 
		
	-- lavender is deleted from the inventory of the doctor and added to the inventory of the hospital
	if ItemCount >= 1 then
		if CanAddItems("Hospital", "Lavender", ItemCount, INVENTORY_STD) then
			RemoveItems("", "Lavender", ItemCount)
			AddItems("Hospital", "Lavender", ItemCount)
		end
	end
		
	if GetItemCount("", "MiracleCure") > 0 then
		return true
	end
	
	if not f_MoveTo("", "Hospital", GL_MOVESPEED_RUN) then
		return false
	end
	
	local	Done, Result
	
	Result, Done = Transfer("", "", INVENTORY_STD, "Hospital", INVENTORY_STD, "MiracleCure", 99)
	if Done>0 then
		return true
	end
	
	return false
end

function CleanUp()
	-- clean the inventory of miracle cures
	if GetInsideBuilding("", "Inside") then
		if GetID("Inside") == GetID("Hospital") then
			local CureCount = GetItemCount("", "MiracleCure")
			local Added = AddItems("Hospital", "MiracleCure", CureCount)
			RemoveItems("", "MiracleCure", Added)
		end
	end
	
	StopAnimation("")
	StopAction("quacksalver", "")
end

