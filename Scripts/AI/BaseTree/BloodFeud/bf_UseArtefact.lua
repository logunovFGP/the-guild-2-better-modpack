-- Character artefacts against the player, by the ladder: documents and letters go to
-- the most valuable character (the fixed evidence target), poisons, spells and fog
-- to the weakest fighter caught outdoors, the stink bomb and the thesis paper are
-- thrown or read wherever a player character stands close. The SIM must hold the
-- item already (bf_Procure -> bf_Stock -> bf_Draw); the sorcerer documents belong
-- to bf_ForgeEvidence. Highest rung first; the item's own repeat timer is the cooldown.
function Weight()
	for i = #TWP_TOOL_LIST, 1, -1 do
		local T = TWP_TOOL_LIST[i]
		if T.item and T.target and T.target ~= "building" and T.item ~= "HexerdokumentI" and T.item ~= "HexerdokumentII"
				and GetItemCount("SIM", T.item, INVENTORY_STD) > 0
				and GetRepeatTimerLeft("SIM", GetMeasureRepeatName2("Use" .. T.item)) <= 0
				and aitwp_Allowed("dynasty", "PlayerDyn", T.name) then
			local Found = false
			if T.target == "best" then
				Found = aitwp_EvidenceTarget("dynasty", "PlayerDyn", "Victim")
			elseif T.target == "weak" then
				Found = aitwp_FindPlayerTarget("PlayerDyn", "duel", "Victim") or aitwp_FindPlayerTarget("PlayerDyn", "rogue", "Victim")
			else
				Found = aitwp_NearbyPlayerSim("SIM", "PlayerDyn", 800, "Victim")
			end
			if Found then
				SetData("ArtefactItem", T.item)
				SetData("ArtefactTarget", T.target)
				local W = 120
				if T.lethal then
					W = 150
				end
				return utility_Trace("dynasty", "bf_UseArtefact", W)
			end
		end
	end
	return 0
end

function Execute()
	utility_Picked("dynasty", "bf_UseArtefact")
	local Item = GetData("ArtefactItem")
	aitwp_Log("uses " .. Item .. " on " .. GetName("Victim"), "dynasty")
	if GetData("ArtefactTarget") == "near" then
		MeasureRun("SIM", nil, "Use" .. Item)
	else
		MeasureRun("SIM", "Victim", "Use" .. Item)
	end
end
