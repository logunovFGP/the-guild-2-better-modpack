-- Keep a gang: thugs up to 2 + the head's nobility title, as the treasury allows.
function Weight()
	if not ReadyToRepeat("dynasty", "AI_BF_Recruit") then
		return 0
	end
	if GetMoney("dynasty") < 3000 then
		return 0
	end
	if not aitwp_Residence("dynasty", "bf_home") or BuildingGetType("bf_home") ~= GL_BUILDING_TYPE_RESIDENCE then
		return 0
	end
	if not BuildingCanHireNewWorker("bf_home") then
		return 0
	end
	if DynastyGetWorkerCount("dynasty", GL_PROFESSION_MYRMIDON) >= 2 + GetNobilityTitle("SIM") then
		return 0
	end
	-- scored: the shortfall against 2 + title thugs, and the treasury
	return utility_Score("dynasty", 80, {
		{ value = utility_Norm(2 + GetNobilityTitle("SIM") - DynastyGetWorkerCount("dynasty", GL_PROFESSION_MYRMIDON), 0, 3), curve = "sqrt" },
		{ value = utility_Norm(GetMoney("dynasty"), 3000, 100000), curve = "sqrt" },
	}, "bf_Recruit")
end

function Execute()
	utility_Picked("dynasty", "bf_Recruit")
	SetRepeatTimer("dynasty", "AI_BF_Recruit", 6)
	MeasureRun("bf_home", 0, "HireEmployeeBuildingRandom")
end
