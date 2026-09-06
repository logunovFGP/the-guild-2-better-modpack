--- Dynasty (weight more or less static)
    -- Economic Expansion, build/buy workshops DONE
    -- Manage party, includes finding spouses
    -- Nobility
function Weight()
	local PartyCount = DynastyGetMemberCount("dynasty")
	if PartyCount < 2 then
		return utility_Trace("dynasty", "Dynasty", 50)
	end
	if PartyCount < 3 then
		return utility_Trace("dynasty", "Dynasty", 30)
	end
	return utility_Trace("dynasty", "Dynasty", 20)
end

function Execute()
	utility_Picked("dynasty", "Dynasty")
end
