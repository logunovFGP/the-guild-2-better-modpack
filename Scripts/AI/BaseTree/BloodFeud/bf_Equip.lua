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
	return utility_Trace("dynasty", "bf_Equip", 90)
end

function Execute()
	utility_Picked("dynasty", "bf_Equip")
	SetRepeatTimer("dynasty", "AI_BF_Equip", 1)
	aitwp_Log("issues " .. GetData("EquipItem") .. " to " .. GetName("Recruit"), "dynasty")
	aitwp_Equip("dynasty", "Recruit", GetData("EquipItem"))
end
