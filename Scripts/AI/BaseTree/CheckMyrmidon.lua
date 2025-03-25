----
-- CheckMyrmidon is part of the vanilla AI and not used in Reforged.
-- 
-- 
-- * Actions of thugs are split into idle actions (patrol, escort, collec evidence) and dynasty actions (sabotage etc.) 
--

function Weight()
	return 0
end

function Execute()
	random = Rand(TotalFound)
	if not CopyAlias("MEMBER"..random, "SIM") then
		return 0
	end

	return 1
end
