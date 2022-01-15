function Weight()
	local Time = math.mod(GetGametime(), 24)
	if Time<6 and Time>21 then	
		return 0
	end
	
	if not GetSettlement("SIM", "City") then
		return 0
	end
	
	local BestDistance = 10000
	local Trys = 30
	local Profession = SimGetProfession("SIM")
		
	for i = 1, trys do
		if GetOutdoorLocator("Crowded"..i, 1, "Pos") then
			-- check the distance first
			local DistanceFound = GetDistance("City", "Pos")
			if DistanceFound < BestDistance then
				-- Now check whether there are already more than 1 actor of that profession
				local Count = Find("Pos", "__F((Object.GetObjectsByRadius(Sim) == 1500) AND (Object.GetProfession() == "..Profession..") AND (Object.BelongsToMe()))", "Result", 2)
				if Count < 2 then
					BestDistance = DistanceFound
					CopyAlias("Pos", "pick_pos")
					-- stop right here if it is perfect already
					if BestDistance < 2000 then
						break
					end
				end
			end
		end
	end

	-- still no Destination? Select Market then
	if not AliasExists("pick_pos") then
		local Market = Rand(5)+1
		if not CityGetRandomBuilding("City", 5, 14, Market, -1, FILTER_IGNORE, "pick_pos") then
			StopMeasure()
			return
		end
	end
	
	if not AliasExists("pick_pos")
		return 0
	end
	
	return 100
end

function Execute()
	MeasureCreate("Measure")
	MeasureAddData("Measure", "TimeOut", 2)
	MeasureStart("Measure", "SIM", "pick_pos", "PickpocketPeople")
end

