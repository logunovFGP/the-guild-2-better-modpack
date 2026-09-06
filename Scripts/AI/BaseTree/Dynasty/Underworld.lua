function Weight()
	if not DynastyGetRandomBuilding("dynasty", GL_BUILDING_CLASS_WORKSHOP, GL_BUILDING_TYPE_THIEF, "UW_Guild") then
		return 0
	end

	if not dyn_GetIdleMember("dynasty", "SIM") then
		return 0
	end

	if SimGetClass("SIM") ~= GL_CLASS_CHISELER then
		return 0
	end

	return utility_Score("dynasty", 15, {
		utility_Priority("dynasty", "Agressive"),
		utility_Trait("dynasty", "sabotage"),
	}, "Underworld", "Conflict")
end

function Execute()
	utility_Picked("dynasty", "Underworld")
	aitwp_Log("Enter subtree Underworld", "dynasty", true)
end