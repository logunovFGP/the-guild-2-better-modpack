-- The market sweep, by a thug: the party never walks to market for the feud. With
-- 100k or more in the treasury the thug buys the highest-rung artefact the house may
-- use against the player and does not yet hold (aitwp_ProcureList, aitwp_HasStock),
-- within 7% of cash (15% at rung 8). bf_Stock then moves it into the residence and
-- bf_Draw hands it to a party member at home. The cooldown is the thug's.
function Weight()
	if not AliasExists("MYRM") then
		return 0
	end
	if not ReadyToRepeat("MYRM", "AI_BF_Procure") then
		return 0
	end
	local Money = GetMoney("dynasty")
	if Money < 100000 then
		return 0
	end
	local Budget = Money * 0.07
	if aitwp_Rung("dynasty", "PlayerDyn") >= 8 then
		Budget = Money * 0.15
	end
	local Items = {}
	local N = aitwp_ProcureList("dynasty", "PlayerDyn", Items)
	for i = N, 1, -1 do
		if not aitwp_HasStock("dynasty", Items[i]) then
			local Price = ai_CanBuyItem("MYRM", Items[i])
			if Price >= 0 and Price <= Budget then
				SetData("ProcureItem", Items[i])
				return utility_Trace("dynasty", "bf_Procure", 60)
			end
		end
	end
	return 0
end

function Execute()
	utility_Picked("dynasty", "bf_Procure")
	SetRepeatTimer("MYRM", "AI_BF_Procure", 6)
	aitwp_Log("sends a thug to buy " .. GetData("ProcureItem"), "dynasty")
	MeasureCreate("Measure")
	MeasureAddData("Measure", "ItemToBuy", GetData("ProcureItem"))
	MeasureStart("Measure", "MYRM", nil, "AIBuyItem")
end
