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
			local maxLevel = CityGetHighestOfficeLevel("city")
			if maxLevel > 0 then
				if GetOfficeTypeHolder("city", 1, "Office") then
					dyn_AddImperialFame("Office", 1)
				end
				for level = 1, maxLevel do
					local officeCount = CityGetOfficeCountAtLevel("city", level)
					for officeIndex = 0, officeCount - 1 do
						if SettlementGetOffice("city", level, officeIndex, "CurrentOffice") then
							if OfficeGetHolder("CurrentOffice", "OfficeHolder") then
								dyn_AddFame("OfficeHolder", 1)
							end
						end
					end
				end
			end
		end
	end
	
	if not GetState("", STATE_TRADERCONTROL) then
		SetState("", STATE_TRADERCONTROL, true)
	end
end