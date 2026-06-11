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

	return 10 + math.floor(aitwp_GetAgressiveness("dynasty") / 5)
end

function Execute()
	aitwp_Log("Enter subtree Underworld", "dynasty", true)
end