-- A thug back home with purchases of the ladder puts them into the residence store
-- (everything it carries: thugs carry nothing else in the standard inventory).
function Weight()
	if not AliasExists("MYRM") then
		return 0
	end
	if not GetHomeBuilding("dynasty", "home") then
		return 0
	end
	if not GetInsideBuilding("MYRM", "TWP_In") or GetID("TWP_In") ~= GetID("home") then
		return 0
	end
	if not aitwp_CarriesArtefact("MYRM") then
		return 0
	end
	return utility_Trace("dynasty", "bf_Stock", 90)
end

function Execute()
	utility_Picked("dynasty", "bf_Stock")
	aitwp_Log("stores the thug's purchases at home", "dynasty")
	TransferItems("MYRM", "home")
end
