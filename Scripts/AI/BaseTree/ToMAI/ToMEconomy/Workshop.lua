function Weight()
	if not dyn_GetIdleMember("dynasty", "SIM") then
		return 0
	end
	
	if not AliasExists("SIM") then
		return 0
	end

	if not dyn_GetRandomWorkshopForSim("SIM", "MyWorkshop") then
		return 0
	end
	
	return 60
end

function Execute()
	aitwp_Log("Enter subtree ToMEconomy::Workshop", "SIM", true)
end