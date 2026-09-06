function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "VictimDynasty", "toad_slime") then
		return 0
	end

	local	Item = "Toadslime"
	
	if GetRepeatTimerLeft("SIM", GetMeasureRepeatName2("Use"..Item)) > 0 then
		return 0
	end
	
	if GetItemCount("SIM", Item, INVENTORY_STD) > 0 then
		return 100
	end
	
	if not aitwp_FindTargetBuilding("Victim", GL_BUILDING_CLASS_WORKSHOP, "strongest", "VicBuilding") then
		return 0
	end
	
	if AliasExists("RivalBuild") then
		CopyAlias("RivalBuild", "VicBuilding")
	end
	
	if GetImpactValue("VicBuilding","toadslime") > 0 then
		return 0
	end

	local Price = ai_CanBuyItem("SIM", Item)
	
	if Price < 0 then
		return 0
	end
	
	if GetMoney("SIM") < 4000 then
		return 0
	end

	return 20
end

function Execute()
	MeasureRun("SIM", "VicBuilding", "UseToadslime")
end
