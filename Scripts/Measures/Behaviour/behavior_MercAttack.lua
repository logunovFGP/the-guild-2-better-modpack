function Run()
	if GetProperty("", "Victim") == nil then
		local HeadMoney = GetProperty("", "HeadMoney")
		local Protectorate = GetProperty("", "Protectorate")
		RemoveProperty("", "HeadMoney")
		RemoveProperty("", "Protectorate")
		chr_RecieveMoney("dynasty", HeadMoney, "HeadMoney")

		if not SimGetWorkingPlace("", "MyHome") then
			if IsPartyMember("") then
				local NextBuilding = ai_GetNearestDynastyBuilding("", GL_BUILDING_CLASS_WORKSHOP, GL_BUILDING_TYPE_MERCENARY)
				if NextBuilding then
					CopyAlias(NextBuilding, "MyHome")
				end
			end
		end
		
		MeasureRun("",Protectorate,"Protectorate",true)
	else
		local VictimID = GetProperty("", "Victim")
		if not (GetAliasByID(VictimID,"Victim") and not GetState("Victim", STATE_DEAD)) then
			RemoveProperty("", "Victim")
		end
	end
end

