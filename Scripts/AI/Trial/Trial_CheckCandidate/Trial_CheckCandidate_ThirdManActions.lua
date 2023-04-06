function Weight()
	local TargetArray = Trial_returnMembers()
	
	if (TargetArray[2] ~= GetID("SIM")) then
		GetAliasByID(TargetArray[2],"Trial_ThirdManTarget")
	else
		GetAliasByID(TargetArray[3],"Trial_ThirdManTarget")
	end

	local MaxFavor = 100
	local MinFavor = 51
	local ModifyFavorJury = -1

	for UseTarget = 1, 5 do
		CurrentJury = TargetArray[UseTarget]
		if (CurrentJury ~= GetID("SIM")) then
			GetAliasByID(CurrentJury,"TA_CurrentJury")
			if (DynastyIsPlayer("TA_CurrentJury") == false) then
				GetInsideBuilding("","InsideBuilding")
				if (GetID("trial_destination_ID") == GetID("InsideBuilding")) then
					local Favor	= GetFavorToSim("TA_CurrentJury","Trial_ThirdManTarget")
					if (Favor < MaxFavor) and (Favor > MinFavor) then
						MaxFavor = Favor
						ModifyFavorJury = "TA_CurrentJury"
						SetData("Victim",ModifyFavorJury)
					end
				end
			end
		end
	end
	
	if (ModifyFavorJury ~= -1) then
		local CanDeliver = GetMeasureRepeat("SIM", "DeliverTheFalseGauntlet")
		local HaveFlower = GetItemCount("SIM", "FlowerOfDiscord",INVENTORY_STD)
		if (HaveFlower > 0) and (GetMeasureRepeat("SIM", "UseFlowerOfDiscord") <= 0) then
			SetData("ActionToDo","UseFlowerOfDiscord")
			return 70
		elseif (CanDeliver <= 0) and (GetImpactValue("SIM","DeliverTheFalseGauntlet")==1) then
			SetData("ActionToDo","DeliverTheFalseGauntlet")
			return 70
		end
	end
	return 0
end

function GetDataFromCutscene(CutsceneAlias,Data)
	CutsceneGetData("CutsceneAlias",Data)
	local returnData = GetData(Data)
	return returnData
end

function Execute()
	MeasureCreate("Measure")
	MeasureAddAlias("Measure","Believer",GetData("Victim"),false)
	MeasureStart("Measure","SIM","Trial_ThirdManTarget",GetData("ActionToDo"))	
end

