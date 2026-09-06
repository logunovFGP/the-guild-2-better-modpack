function Weight()
	if not dyn_GetIdleMember("dynasty", "SIM") or not AliasExists("SIM") then
		return 0
	end

	return 0
end

function Execute()
	utility_Picked("dynasty", "d_GoIdle")
	if Rand(10) < 8 and dyn_GetRandomWorkshopForSim("SIM", "MyWorkshop") then
		f_MoveToNoWait("SIM", "MyWorkshop")
	else
		MeasureRun("SIM", 0, "DynastyIdle")
	end
end