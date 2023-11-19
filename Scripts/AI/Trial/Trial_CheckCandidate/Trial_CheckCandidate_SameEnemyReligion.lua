function Weight()
	local TargetArray = Trial_returnMembers()
	
	local ModifyFavorJury = 0
	
	if (TargetArray[2][2] ~= GetID("SIM")) then
		GetAliasByID(TargetArray[2],"Trial_LetterTarget")
	else
		GetAliasByID(TargetArray[3],"Trial_LetterTarget")
	end	
	
	for UseTarget = 1, 5 do
		CurrentJury = TargetArray[UseTarget]
		if (CurrentJury ~= GetID("SIM")) then
			GetAliasByID(CurrentJury,"TA_CurrentJury")
			if (DynastyIsPlayer("TA_CurrentJury") == false) then
				GetInsideBuilding("","InsideBuilding")
				if (GetID("trial_destination_ID") == GetID("InsideBuilding")) then
					local Favor	= GetFavorToSim("TA_CurrentJury","Trial_LetterTarget")
					if (Favor < 100) and (Favor > 51) then
						if (SimGetReligion("TA_CurrentJury") == SimGetReligion("Trial_LetterTarget")) then
							ModifyFavorJury = ModifyFavorJury + 1
						end
					end
				end
			end
		end
	end
	
	if (ModifyFavorJury > 0) then
		local HaveLetter = GetItemCount("SIM", "LetterFromRome",INVENTORY_STD)
		if (HaveLetter > 1) and (GetMeasureRepeat("SIM", "UseLetterFromRome") <= 0) then
			SetData("ItemToUse","LetterFromRome")
			if (ModifyFavorJury == MaxInviters) then
				return 100
			elseif (ModifyFavorJury >= MaxInviters/2) and (ModifyFavorJury > 1) then
				return 80
			else
				return 50
			end
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
	MeasureRun("SIM", "Trial_LetterTarget", "Use"..GetData("ItemToUse"),true)
end

