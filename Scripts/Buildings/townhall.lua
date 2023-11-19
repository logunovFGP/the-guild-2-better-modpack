function Run()
end

function OnLevelUp()
end

function Setup()
end

function PingHour()
	
	local currentRound = GetRound()
	local currentGameTime = math.mod(GetGametime(), 24)
	
	if currentRound > 0 then
		BuildingGetCity("", "city")
		if (currentGameTime == 12) then
			if GetOfficeTypeHolder("city", 1, "Office") then
				dyn_AddImperialFame("Office", 1)
			end
			if GetOfficeTypeHolder("city", 6, "Office") then
				dyn_AddFame("Office", 1)
			end	
			if GetOfficeTypeHolder("city", 7, "Office") then
				dyn_AddFame("Office", 1)
			end	
		end
	end
	
	if not GetState("", STATE_TRADERCONTROL) then
		SetState("", STATE_TRADERCONTROL, true)
	end
end
