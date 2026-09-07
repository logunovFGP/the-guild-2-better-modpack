-- Building artefacts against the player's strongest workshop: toad slime (rung 4,
-- infects everyone who passes the door) and toad excrement (rung 3, the staff walk
-- out for four hours). Used from the SIM's inventory; the residence store hands one
-- over just in time when the SIM holds none (aitwp_DrawFromStock, rationed).
function Weight()
	local Items = { "Toadslime", "ToadExcrements" }
	local Tools = { "toad_slime", "toad_excrement" }
	for i = 1, 2 do
		if (GetItemCount("SIM", Items[i], INVENTORY_STD) > 0
					or (aitwp_InStore("dynasty", Items[i]) and aitwp_CanHandOver("dynasty", "SIM")))
				and GetRepeatTimerLeft("SIM", GetMeasureRepeatName2("Use" .. Items[i])) <= 0
				and aitwp_Allowed("dynasty", "PlayerDyn", Tools[i])
				and aitwp_FindTargetBuilding("PlayerDyn", GL_BUILDING_CLASS_WORKSHOP, "strongest", "RaidTarget") then
			SetData("BuildingItem", Items[i])
			-- scored: the bigger the workshop hit, the better
			return utility_Score("dynasty", 100, {
				{ value = utility_Norm(BuildingGetLevel("RaidTarget"), 1, 3), curve = "linear" },
			}, "bf_UseBuildingArtefact")
		end
	end
	return 0
end

function Execute()
	utility_Picked("dynasty", "bf_UseBuildingArtefact")
	local Item = GetData("BuildingItem")
	if GetItemCount("SIM", Item, INVENTORY_STD) == 0 and not aitwp_DrawFromStock("SIM", Item, 1) then
		return
	end
	aitwp_Log("uses " .. Item .. " on " .. GetName("RaidTarget"), "dynasty")
	MeasureRun("SIM", "RaidTarget", "Use" .. Item)
end
