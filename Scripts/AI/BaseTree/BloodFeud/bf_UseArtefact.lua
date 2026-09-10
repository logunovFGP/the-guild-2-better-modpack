-- Character artefacts against the player, by the ladder: documents and letters go to
-- the most valuable character (the fixed evidence target), poisons, spells and fog
-- to the weakest fighter caught outdoors, the stink bomb and the thesis paper are
-- thrown or read wherever a player character stands close. The item is used from
-- the SIM's inventory; when the SIM holds none, the residence store hands one over
-- just in time (aitwp_DrawFromStock, rationed). The sorcerer documents belong to
-- bf_ForgeEvidence. Highest rung first; the item's own repeat timer is the cooldown.
function Weight()
	for i = #TWP_TOOL_LIST, 1, -1 do
		local T = TWP_TOOL_LIST[i]
		if T.item and T.target and T.target ~= "building" and T.item ~= "HexerdokumentI" and T.item ~= "HexerdokumentII"
				and GetRepeatTimerLeft("SIM", GetMeasureRepeatName2("Use" .. T.item)) <= 0
				and aitwp_Allowed("dynasty", "PlayerDyn", T.name)
				and (GetItemCount("SIM", T.item, INVENTORY_STD) > 0
					or (aitwp_InStore("dynasty", T.item) and aitwp_CanHandOver("dynasty", "SIM"))) then
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
				-- scored: the tool's severity and how well the victim fits it - value for a
				-- paper or letter, weakness for a poison or spell, neutral for a throw
				local Fit = 0.5
				if T.target == "best" then
					Fit = utility_Norm(aitwp_PlayerTargetScore("Victim", "best") or 0, 20, 200)
				elseif T.target == "weak" then
					Fit = 1 - GetHPRelative("Victim")
				end
				-- siblings share the alias "Victim" and the engine runs every Weight() before
				-- the winner's Execute(); file it under this node so no sibling can take it
				aiboard_Stash("bf_UseArtefact", "Victim")
				return utility_Score("dynasty", W, {
					{ value = utility_Norm(aitwp_Severity(T), 1, 5), curve = "linear" },
					{ value = Fit, curve = "linear", lo = 0.8 },
				}, "bf_UseArtefact")
			end
		end
	end
	return 0
end

function Execute()
	utility_Picked("dynasty", "bf_UseArtefact")
	if not aiboard_Claim("bf_UseArtefact", "BF_ArtefactVictim") then
		return
	end
	local Item = GetData("ArtefactItem")
	if GetItemCount("SIM", Item, INVENTORY_STD) == 0 and not aitwp_DrawFromStock("SIM", Item, 1) then
		return
	end
	aitwp_Log("uses " .. Item .. " on " .. GetName("BF_ArtefactVictim"), "dynasty")
	if GetData("ArtefactTarget") == "near" then
		MeasureRun("SIM", nil, "Use" .. Item)
	else
		MeasureRun("SIM", "BF_ArtefactVictim", "Use" .. Item)
	end
	aiboard_Drop("BF_ArtefactVictim")
end
