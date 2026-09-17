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
	if GetMoney("dynasty") < TWP_BF_SUPPLY then
		return 0
	end
	if not aitwp_Residence("dynasty", "home") or BuildingGetType("home") ~= GL_BUILDING_TYPE_RESIDENCE then
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
	elseif Total < TWP_BF_CARTS and GetMoney("dynasty") >= TWP_BF_SUPPLY + gameplayformulas_CalcCartBuyPrice(EN_CT_HORSE) then
		SetData("CartMode", "buy")
	else
		return 0
	end
	-- scored: a fuller treasury and a longer list make the run more worthwhile
	return utility_Score("dynasty", 60, {
		{ value = utility_Norm(GetMoney("dynasty"), TWP_BF_SUPPLY, 1000000), curve = "sqrt" },
		{ value = utility_Norm(N, 1, 6), curve = "linear" },
	}, "bf_Procure")
end

function Execute()
	utility_Picked("dynasty", "bf_Procure")
	SetRepeatTimer("dynasty", "AI_BF_Supply", TWP_BF_SUPPLY_HOURS)
	local Needs = {}
	local N = aitwp_ShoppingList("dynasty", "PlayerDyn", Needs)
	local Total, Busy = aitwp_ResidenceCarts("dynasty", "Cart")
	if GetData("CartMode") == "buy" then
		-- bld_BuyCart, not BuildingBuyCart: the latter is the ship path (harbours and
		-- pirate nests buy EN_CT_CORSAIR with it) and returns false for a land cart at a
		-- residence, which is why session 4 logged six failed buys and never grew the fleet.
		-- The residence is re-resolved here: "home" was set in Weight(), twelve siblings ago.
		local Bought = aitwp_Residence("dynasty", "home")
			and bld_BuyCart("home", "Cart", EN_CT_HORSE)
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
