function Weight()
	if not ReadyToRepeat("dynasty", "AI_HireMyrmidon") then
		return 0
	end

	if GetMoney("dynasty") < 3000 then
		return 0
	end
	
	if not GetHomeBuilding("dynasty", "myrm_home") then
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
	local Difficulty = ScenarioGetDifficulty()
	SetRepeatTimer("dynasty", "AI_HireMyrmidon", 2 * (5 - Difficulty))
	MeasureRun("myrm_home", 0, "HireEmployeeBuildingRandom")
end

