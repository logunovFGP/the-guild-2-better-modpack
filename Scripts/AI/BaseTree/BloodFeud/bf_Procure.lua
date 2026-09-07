-- The feud supply run. A horse cart of the residence - never a party member or a
-- thug - buys the shopping list (aitwp_ShoppingList: ladder artefacts, forgery
-- papers, missing equipment; 7% of cash, 15% at rung 8) at the markets and Kontors
-- and unloads at the residence (Measures/ms_bf_FeudSupply.lua); the use nodes draw
-- from the store just in time, bf_Equip issues the gear. An idle cart is sent; when every cart is out, another horse
-- cart is bought, five at most. Treasury >= 100k.
function Weight()
	if not ReadyToRepeat("dynasty", "AI_BF_Supply") then
		return 0
	end
	if GetMoney("dynasty") < 100000 then
		return 0
	end
	if not GetHomeBuilding("dynasty", "home") or BuildingGetType("home") ~= GL_BUILDING_TYPE_RESIDENCE then
		return 0
	end
	local Needs = {}
	local N = aitwp_ShoppingList("dynasty", "PlayerDyn", Needs)
	if N <= 0 then
		return 0
	end
	local Total, Busy, Idle = aitwp_ResidenceCarts("dynasty", "Cart")
	if Idle then
		SetData("CartMode", "send")
	elseif Total < 5 and GetMoney("dynasty") >= 100000 + gameplayformulas_CalcCartBuyPrice(EN_CT_HORSE) then
		SetData("CartMode", "buy")
	else
		return 0
	end
	-- scored: a fuller treasury and a longer list make the run more worthwhile
	return utility_Score("dynasty", 60, {
		{ value = utility_Norm(GetMoney("dynasty"), 100000, 1000000), curve = "sqrt" },
		{ value = utility_Norm(N, 1, 6), curve = "linear" },
	}, "bf_Procure")
end

function Execute()
	utility_Picked("dynasty", "bf_Procure")
	SetRepeatTimer("dynasty", "AI_BF_Supply", 2)
	local Needs = {}
	local N = aitwp_ShoppingList("dynasty", "PlayerDyn", Needs)
	local Total, Busy = aitwp_ResidenceCarts("dynasty", "Cart")
	if GetData("CartMode") == "buy" then
		local Bought = BuildingBuyCart("home", EN_CT_HORSE, true, "Cart")
		aitwp_LogCart("dynasty", "buy", "Cart", Total + 1, Busy, Needs, N, Bought)
		if not Bought or not AliasExists("Cart") then
			return
		end
		Total = Total + 1
	end
	MeasureCreate("Measure")
	local Ok = MeasureStart("Measure", "Cart", nil, "FeudSupply", true)
	aitwp_Log("sends a cart for " .. N .. " goods", "dynasty")
	aitwp_LogCart("dynasty", "send", "Cart", Total, Busy + 1, Needs, N, Ok)
end
