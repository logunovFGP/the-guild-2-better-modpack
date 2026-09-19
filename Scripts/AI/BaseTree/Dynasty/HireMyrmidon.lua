function Weight()
	if not ReadyToRepeat("dynasty", "AI_HireMyrmidon") then
		return 0
	end

	if GetMoney("dynasty") < 3000 then
		return 0
	end
	
	if not aitwp_Residence("dynasty", "myrm_home") then
		return 0
	end
	
	if BuildingGetType("myrm_home") ~= GL_BUILDING_TYPE_RESIDENCE then
		return 0
	end
	
	if not BuildingCanHireNewWorker("myrm_home") then
		return 0
	end
	
	return utility_Score("dynasty", 10, {
		utility_Priority("dynasty", "Agressive"),
		utility_Trait("dynasty", "bloodlust"),
		utility_Money("dynasty", 20000),
	}, "HireMyrmidon", "Conflict")
end

function Execute()
	utility_Picked("dynasty", "HireMyrmidon")
	SetRepeatTimer("dynasty", "AI_HireMyrmidon", TWP_HIRE_HOURS)
	aitwp_LogHire("dynasty", "myrm_home", "HireMyrmidon")
	MeasureRun("myrm_home", 0, "HireEmployeeBuildingRandom")
end

