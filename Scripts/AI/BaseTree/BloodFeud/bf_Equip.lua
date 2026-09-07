-- Arm the house from the residence store: whoever lacks a piece of the tier the
-- head's title and treasury allow (aitwp_EquipmentTier) is issued it on the spot -
-- party members, thugs and employees alike. The feud cart (bf_Procure) buys the
-- pieces; nobody walks to the smithy.
function Weight()
	if not ReadyToRepeat("dynasty", "AI_BF_Equip") then
		return 0
	end
	local Tier = aitwp_EquipmentTier("dynasty")
	if not Tier then
		return 0
	end
	if not aitwp_FindUnequipped("dynasty", Tier, "Recruit") then
		return 0
	end
	-- scored: the higher the tier being issued, the more it matters
	local TierIdx = 1
	for i = 1, #TWP_EQUIPMENT do
		if TWP_EQUIPMENT[i] == Tier then
			TierIdx = i
		end
	end
	return utility_Score("dynasty", 90, {
		{ value = utility_Norm(TierIdx, 1, 3), curve = "linear" },
	}, "bf_Equip")
end

function Execute()
	utility_Picked("dynasty", "bf_Equip")
	SetRepeatTimer("dynasty", "AI_BF_Equip", 1)
	aitwp_Log("issues " .. GetData("EquipItem") .. " to " .. GetName("Recruit"), "dynasty")
	aitwp_Equip("dynasty", "Recruit", GetData("EquipItem"))
end
