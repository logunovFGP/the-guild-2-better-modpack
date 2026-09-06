-- A party member at home takes an artefact of the ladder from the residence store
-- (the highest rung first) so it can be used by bf_UseArtefact or bf_UseBuildingArtefact.
function Weight()
	if not GetHomeBuilding("dynasty", "home") then
		return 0
	end
	if not GetInsideBuilding("SIM", "TWP_In") or GetID("TWP_In") ~= GetID("home") then
		return 0
	end
	local Items = {}
	local N = aitwp_ProcureList("dynasty", "PlayerDyn", Items)
	for i = N, 1, -1 do
		if GetItemCount("home", Items[i], INVENTORY_STD) > 0 and GetItemCount("SIM", Items[i], INVENTORY_STD) == 0 then
			SetData("DrawItem", Items[i])
			return utility_Trace("dynasty", "bf_Draw", 90)
		end
	end
	return 0
end

function Execute()
	utility_Picked("dynasty", "bf_Draw")
	local Item = GetData("DrawItem")
	aitwp_Log("takes " .. Item .. " from the house store", "dynasty")
	RemoveItems("home", Item, 1, INVENTORY_STD)
	AddItems("SIM", Item, 1, INVENTORY_STD)
end
