-- Arm the house. Party members, thugs and employees get the weapon and armour tier
-- the head's nobility title and the treasury allow (aitwp_EquipmentTier). Members
-- and thugs buy at the market through AIBuyWeapon/AIBuyArmor; employees are issued
-- their piece from the treasury at base price, the way the engine equips guards
-- when they are hired.
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
	SetRepeatTimer("dynasty", "AI_BF_Equip", 2)
	aitwp_Log("equips " .. GetName("Recruit") .. " with " .. GetData("EquipItem") .. " (" .. GetData("EquipMode") .. ")", "dynasty")
	aitwp_Equip("dynasty", "Recruit", GetData("EquipItem"), GetData("EquipMode"))
end
