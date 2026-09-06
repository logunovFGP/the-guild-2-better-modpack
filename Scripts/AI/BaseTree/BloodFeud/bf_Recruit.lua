-- Keep a gang: thugs up to 2 + the head's nobility title, as the treasury allows.
function Weight()
	if not ReadyToRepeat("dynasty", "AI_BF_Recruit") then
		return 0
	end
	if GetMoney("dynasty") < 3000 then
		return 0
	end
	if not GetHomeBuilding("dynasty", "bf_home") or BuildingGetType("bf_home") ~= GL_BUILDING_TYPE_RESIDENCE then
		return 0
	end
	if not BuildingCanHireNewWorker("bf_home") then
		return 0
	end
	if DynastyGetWorkerCount("dynasty", GL_PROFESSION_MYRMIDON) >= 2 + GetNobilityTitle("SIM") then
		return 0
	end
	return utility_Trace("dynasty", "bf_Recruit", 80)
end

function Execute()
	utility_Picked("dynasty", "bf_Recruit")
	SetRepeatTimer("dynasty", "AI_BF_Recruit", 6)
	MeasureRun("bf_home", 0, "HireEmployeeBuildingRandom")
end
