---
-- This is not an AI cheat. 
-- Any normal call to CreditMoney and SpendMoney fails to credit/spend money on AI dynasties.
-- This is also true for Transfer of items at the market.
-- Instead, measures and other scripts should call "chr_CreditMoney" and "chr_SpendMoney".
-- The finances of the AI will then be correctly updated by this script. 
function Weight()
	if not ReadyToRepeat("dynasty", "AI_Income") then
		return 0
	end
	return 60
end


function Execute()
	SetRepeatTimer("dynasty", "AI_Income", 1)
	CreateScriptcall("GiveAIMoney", 1, "Library/chr.lua", "GiveMoney", "dynasty")
end

