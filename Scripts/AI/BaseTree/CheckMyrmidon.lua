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
