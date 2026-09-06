-- Building artefacts against the player's strongest workshop: toad slime (rung 4,
-- infects everyone who passes the door) and toad excrement (rung 3, the staff walk
-- out for four hours). The SIM must hold the item (bf_Procure -> bf_Stock -> bf_Draw).
function Weight()
	local Items = { "Toadslime", "ToadExcrements" }
	local Tools = { "toad_slime", "toad_excrement" }
	for i = 1, 2 do
		if GetItemCount("SIM", Items[i], INVENTORY_STD) > 0
				and GetRepeatTimerLeft("SIM", GetMeasureRepeatName2("Use" .. Items[i])) <= 0
				and aitwp_Allowed("dynasty", "PlayerDyn", Tools[i])
				and aitwp_FindTargetBuilding("PlayerDyn", GL_BUILDING_CLASS_WORKSHOP, "strongest", "RaidTarget") then
			SetData("BuildingItem", Items[i])
			return utility_Trace("dynasty", "bf_UseBuildingArtefact", 100)
		end
	end
	return 0
end

function Execute()
	utility_Picked("dynasty", "bf_UseBuildingArtefact")
	aitwp_Log("uses " .. GetData("BuildingItem") .. " on " .. GetName("RaidTarget"), "dynasty")
	MeasureRun("SIM", "RaidTarget", "Use" .. GetData("BuildingItem"))
end
