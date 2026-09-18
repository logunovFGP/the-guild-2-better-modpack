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
	-- The last clause is a backoff, not a cooldown: a purchase the engine refuses will be
	-- refused again a minute later, and without this the node asked once an hour all day
	-- and logged eleven identical failures. Telling a refused action from an unlucky one is
	-- the difference between an agent that recovers and one that spends the game retrying.
	elseif Total < TWP_BF_CARTS and GetMoney("dynasty") >= TWP_BF_SUPPLY + gameplayformulas_CalcCartBuyPrice(EN_CT_HORSE)
			and GetGametime() - (GetProperty("dynasty", "AI_BF_CartFailed") or -999) >= TWP_BF_CART_RETRY then
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
		-- BuildingBuyCart, through the helper: bld_BuyCart cannot be used from here because
		-- it reads the empty alias as the building it runs on, which from an AI node is the
		-- dynasty. The helper checks BuildingGetCartCount rather than the native return.
		local Bought = aitwp_BuyResidenceCart("dynasty", "Cart")
		-- Total, not Total + 1: the old line counted the cart before knowing whether it
		-- existed, which made every failed purchase read as a successful one in the log.
		aitwp_LogCart("dynasty", "buy", "Cart", Total, Busy, Needs, N, Bought)
		if not Bought or not AliasExists("Cart") then
			SetProperty("dynasty", "AI_BF_CartFailed", GetGametime())
			return
		end
		Total = Total + 1
	end
	MeasureCreate("Measure")
	local Ok = MeasureStart("Measure", "Cart", nil, "FeudSupply", true)
	aitwp_Log("sends a cart for " .. N .. " goods", "dynasty")
	aitwp_LogCart("dynasty", "send", "Cart", Total, Busy + 1, Needs, N, Ok)
end
