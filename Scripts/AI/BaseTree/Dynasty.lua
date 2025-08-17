--- Dynasty (weight more or less static)
    -- Economic Expansion, build/buy workshops DONE
    -- Manage party, includes finding spouses
    -- Nobility
function Weight()
	local PartyCount = DynastyGetMemberCount("dynasty")
	if PartyCount < 2 then
		return 50
	end
	if PartyCount < 3 then
		return 30
	end
	return 20
end

function Execute()
end
