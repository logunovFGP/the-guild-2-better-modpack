function Weight()
	
	-- ship is already fighting
	if GetState("SHIP", STATE_FIGHTING) then
		return 0
	end
	
	-- no attacks if ship is damaged
	if GetHPRelative("SHIP") < 0.7 then
		SetData("GetSupplies", 1)
		return 100
	end
	
	-- maybe upgrade crew
	if Rand(10) > 7 then
		local MaxCrew = GetProperty("SHIP", "ShipMenCntMax")
		local MenCnt = GetProperty("SHIP", "ShipMenCnt")
		
		if MenCnt < MaxCrew then
			SetData("RaiseMenTo", 1)
			SetData("GetSupplies", 1)
			return 100
		end
	end
	
	-- find a target ship
	local ShipFilter = "__F((Object.GetObjectsByRadius(Ship)==10000)AND NOT(Object.IsType(4))AND NOT(Object.BelongsToMe())AND NOT(Object.HasImpact(shipplunderedtoday)))"
	local NumDamagedShips = Find("SHIP", ShipFilter, "MyTarget", -1)
	local Found = 0
	if NumDamagedShips > 0 then
		Found = 1
	elseif ScenarioGetRandomObject("cl_Ship", "MyTarget") then
		Found = 1
	end
	
	if Found == 0 then
		return 0
	end
	
	-- Fisherboats can't fight back thus it needs to be forbidden
	local Type = CartGetType("MyTarget")
	if Type == EN_CT_FISHERBOOT then
		return 0
	end

	-- no attacks on friendly dynasties
	local TargetID = GetDynastyID("MyTarget")

	if TargetID > 0 then
		if GetDynasty("MyTarget", "TargetDynasty") then
			GetDynasty("SHIP", "MyDynasty")
			if DynastyGetDiplomacyState("MyDynasty", "TargetDynasty") >= DIP_NAP  then
				return 0
			end
		end
	end
	
	-- already has been plundered
	if GetImpactValue("MyTarget","shipplunderedtoday") > 0 then
		return 0
	end
	
	local Booty = chr_GetBootyCount("MyTarget", INVENTORY_STD)
	
	-- no booty no attack
	if Booty < 200 then
		return 0
	end
	
	return 30
end

function Execute()
	MeasureCreate("Measure")
	if HasData("GetSupplies") then
		if HasData("RaiseMenTo") then
			MeasureAddData("Measure", "RaiseMenTo", GetData("RaiseMenTo"))
		end
		MeasureStart("Measure", "SHIP", "SHIP", "SailHomeAndRepair")
	else
		MeasureStart("Measure", "SHIP", "MyTarget", "PlunderShip")
	end
end
