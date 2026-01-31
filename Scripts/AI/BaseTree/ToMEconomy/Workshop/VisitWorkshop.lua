function Weight()
	
	if GetInsideBuildingID("SIM") == GetID("MyWorkshop") then
		return 0
	end
	
	if not AliasExists("MyWorkshop") then
		return 0
	end
	
	return 50
end

function Execute()
	--aitwp_Log("AI::VisitWorkshop Executing.", "SIM")
	f_MoveToNoWait("SIM", "MyWorkshop")
end


