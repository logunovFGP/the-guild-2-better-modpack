-- A bank clerk goes after a defaulter on his own. Until this node existed only the AI
-- dynasty tree (BaseTree/Dynasty/CollectBankDebts.lua) ever ran CollectDebts, so a
-- player bank never chased anyone. Ruled by the bank's Actions tab like OfferCredit;
-- what the clerk does when a debtor begs is the bank's DebtPolicy (ms_CollectDebts).
function Weight()
	if IsDynastySim("SIM") then
		return 0
	end
	if not SimGetWorkingPlace("SIM", "MyBank") then
		return 0
	end
	if GetInsideBuildingID("SIM") ~= GetID("MyBank") then
		return 0
	end
	-- the cheap count first: the sweep for the debtor stays in Execute
	if (GetProperty("MyBank", "StolenCount") or 0) < 1 then
		return 0
	end
	if not ReadyToRepeat("MyBank", "AI_COLLECTDEBTS") then
		return 0
	end
	if gameplayformulas_MActRule("MyBank", "CollectDebts", "enabled", 1) == 0 then
		return 0
	end
	if BuildingGetProducerCount("MyBank", PT_MEASURE, "CollectDebts") >= gameplayformulas_MActRule("MyBank", "CollectDebts", "maxw", 1) then
		return 0
	end
	if gameplayformulas_MActRule("MyBank", "CollectDebts", "prio", 1) == 0 then
		return 20
	end
	return 100
end

function Execute()
	SetRepeatTimer("MyBank", "AI_COLLECTDEBTS", 8)
	local BankID = GetID("MyBank")
	local Count = ScenarioGetObjects("cl_Sim", 9999, "CD_Sim")
	for i = 0, Count - 1 do
		local Alias = "CD_Sim" .. i
		if HasProperty(Alias, "StolenSum") and HasProperty(Alias, "CreditBank")
				and GetProperty(Alias, "CreditBank") == BankID and not GetState(Alias, STATE_DEAD) then
			LogMessage("@BANK ClerkCollect bank=" .. BankID .. " clerk=" .. GetName("SIM") .. " target=" .. GetName(Alias) ..
					" stolen=" .. GetProperty(Alias, "StolenSum"))
			MeasureRun("SIM", Alias, "CollectDebts", false)
			return
		end
	end
	-- StolenCount said there was a defaulter and the sweep found none: it drifted
	LogMessage("@BANK ClerkCollect bank=" .. BankID .. " no debtor found, StolenCount=" ..
			tostring(GetProperty("MyBank", "StolenCount")))
end
