function Weight()
<<<<<<< master
	if ai_AICheckAction() == false then
		return 0
	end

	local Favor = GetFavorToSim("Victim", "dynasty")
=======
	if ai_AICheckAction()==false then
		return 0
	end

	local Favor = GetFavorToSim("dynasty", "Victim")
>>>>>>> e6fb8ee first try at importing the TWP AI
	local Difficulty = ScenarioGetDifficulty()
	local RetVal = 40 + (Difficulty * 15) - Favor
	if RetVal<0 then
		RetVal = 0
	elseif RetVal>100 then
		RetVal = 100
	end
	
	return RetVal
end

function Execute()
end

