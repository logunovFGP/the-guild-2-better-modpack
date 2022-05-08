function Run()
	
	if not ai_GetWorkBuilding("", GL_BUILDING_TYPE_HOSPITAL, "Hospital") then
		StopMeasure() 
		return
	end

	local Producer = BuildingGetProducerCount("Hospital", PT_MEASURE, "Quacksalver")
	
	if IsStateDriven() then
		if Producer >1 then
			StopMeasure()
			return
		end
	end

	MeasureSetStopMode(STOP_NOMOVE)

	if not AliasExists("Destination") then
		if IsStateDriven() then
			if not GetSettlement("Hospital", "City") then
				return
			end
			
			if CityFindCrowdedPlace("City", "", "Destination")==0 then
				return
			end
		else
			if HasProperty("","MyQuacksalvePosX") then
				if not ScenarioCreatePosition(GetProperty("","MyQuacksalvePosX"), GetProperty("","MyQuacksalvePosZ"), "Destination") then
					return
				end
			else
				return
			end
		end

	else	
		if GetID("Hospital")==GetID("Destination") then
			if IsStateDriven() then
				if not GetSettlement("Hospital", "City") then
					return
				end
				
				if CityFindCrowdedPlace("City", "", "Destination")==0 then
					return
				end
			else
				if HasProperty("","MyQuacksalvePosX") then
					if not ScenarioCreatePosition(GetProperty("","MyQuacksalvePosX"), GetProperty("","MyQuacksalvePosZ"), "Destination") then
						return
					end
				else
					return
				end
			end
		end
	end
	
	SetData("IsProductionMeasure", 0)
	SimSetProduceItemID("", -GetCurrentMeasureID(""), -1)
	SetData("IsProductionMeasure", 1)
	
	while true do
		if not ms_quacksalver_GetPlacebo() then
			StopMeasure()
		end

		if not f_MoveTo("","Destination",GL_MOVESPEED_RUN) then
			StopMeasure()
		end
		
	  GetPosition("","MyPos")
	  local x,y,z = PositionGetVector("MyPos")
		SetProperty("","MyQuacksalvePosX",x)
		SetProperty("","MyQuacksalvePosZ",z)

		local MeasureID = GetCurrentMeasureID("")
		local duration = mdata_GetDuration(MeasureID)
		local EndTime = GetGametime() + duration

		CommitAction("quacksalver", "", "")
		while GetGametime() < EndTime do
		
			if GetItemCount("", "MiracleCure")<1 then
				break
			end
			
			PlayAnimation("","pray_standing")
			PlayAnimation("","preach")
			Sleep( 1 + 0.1*Rand(20) )
		end
		StopAction("quacksalver", "")
	end

	StopMeasure()
end

function GetPlacebo()

	local ItemCount = GetItemCount("", "Lavender", INVENTORY_STD) 
		
	-- lavender is deleted from the inventory of the doctor and added to the inventory of the hospital
	if ItemCount("", "Lavender", INVENTORY_STD) >= 1 then
		if CanAddItems("Hospital", "Lavender", Count, INVENTORY_STD) then
			RemoveItems("", "Lavender", ItemCount)
			AddItems("Hospital", "Lavender", ItemCount)
		end
	end
		

	if GetItemCount("", "MiracleCure") > 0 then
		return true
	end
	
	if GetInsideBuildingID("") ~= GetID("Hospital") then
		if not f_MoveTo("", "Hospital", GL_MOVESPEED_RUN) then
			return false
		end
	end
	
	local	Done
	local	Result
	
	Result, Done = Transfer("", "", INVENTORY_STD, "Hospital", INVENTORY_STD, "MiracleCure", 99)
	if Done>0 then
		return true
	end
	
	Result, Done = Transfer("", "", INVENTORY_STD, "Hospital", INVENTORY_SELL, "MiracleCure", 99)
	if Done>0 then
		return true
	end
	
	return false
end

function CleanUp()

	StopAnimation("")
	StopAction("quacksalver", "")
end

function GetOSHData(MeasureID)
	--can be used again in:
	--OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2",Gametime2Total(mdata_GetTimeOut(MeasureID)))
end


