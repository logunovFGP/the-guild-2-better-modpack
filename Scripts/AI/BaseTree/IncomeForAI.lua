---
-- This is not an AI cheat. 
-- Any normal call to CreditMoney and SpendMoney fails to credit/spend money on AI dynasties.
-- This is also true for Transfer of items at the market.
-- Instead, measures and other scripts should call "chr_CreditMoney" and "chr_SpendMoney".
-- The finances of the AI will then be correctly updated by this script. 
-- 

-- Bookkeeping, not a choice: it must run about hourly. Scored by how overdue it is,
-- so once due it wins the roulette within a tick or two instead of drifting.
function Weight()
	if not ReadyToRepeat("dynasty", "AI_Income") then
		return 0
	end
	local Overdue = GetGametime() - (GetProperty("dynasty", "AI_IncomeLast") or 0) - 1
	return utility_Score("dynasty", 60, {
		{ value = utility_Norm(Overdue, 0, 2), curve = "linear", lo = 1, hi = 3 },
	}, "IncomeForAI")
end


function Execute()
	utility_Picked("dynasty", "IncomeForAI")
	SetRepeatTimer("dynasty", "AI_Income", 1)
	SetProperty("dynasty", "AI_IncomeLast", GetGametime())
	CreateScriptcall("GiveAIMoney", 1, "Library/chr.lua", "GiveMoney", "dynasty")
end

