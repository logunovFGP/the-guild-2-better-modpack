--- Dynasty (weight more or less static)
    -- Economic Expansion, build/buy workshops DONE
    -- Manage party, includes finding spouses
    -- Nobility
-- Scored: base 20, x2.5 for a house of one and x1.75 for a couple (the old 50/30/20
-- steps as a curve), and a gentle money band, since titles, homes and feasts cost
-- while family matters are free. No goal at this level: the children carry them.
function Weight()
	local PartyCount = DynastyGetMemberCount("dynasty")
	return utility_Score("dynasty", 20, {
		{ value = utility_Norm(3 - PartyCount, 0, 2), curve = "linear", lo = 1, hi = 2.5 },
		{ value = utility_Money("dynasty", 50000), curve = "sqrt", lo = 0.8, hi = 1.2 },
	}, "Dynasty")
end

function Execute()
	utility_Picked("dynasty", "Dynasty")
end
