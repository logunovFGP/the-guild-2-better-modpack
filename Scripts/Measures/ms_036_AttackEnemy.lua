function Run()

	MeasureSetNotRestartable()
	
	-- ms_092_SingForPeacefulness.lua active
	if (GetImpactValue("", "Peaceful") ~= 0) then
		StopMeasure("") 
		return
	end	
	
	-- sight distance   
	local DistanceToJoinBattle = gameplayformulas_CalcSightRange("Destination")
	
	-- Favor
	if GetDynasty("Destination", "TargetDyn") then
		ModifyFavorToDynasty("", "TargetDyn", -10)
	end

	-- i am a building no need to move
	if IsType("", "Building") then
		BattleJoin("","Destination", false)
		Sleep(1)
		return
	end

	--dont follow buildings and force outdoor position
	if IsType("Destination", "Building") then
		BuildingGetOwner("Destination", "BOwner") -- just to safe it in BOwner, do not require it anymore, so you can now also attack unowned buildings (like intended in the AttackEnemy Filter)
		if GetState("Destination", STATE_REPAIRING) then 
			SetState("Destination", STATE_REPAIRING, false)
		end
		
		if GetFleePosition("", "Destination", 1000, "AttackPos") then
			if not f_MoveTo("", "AttackPos", GL_MOVESPEED_RUN) then
				StopMeasure("")
				return
			end
		end
	
		AlignTo("","Destination")
		
	elseif IsType("Destination", "Ship") then
		local radius = 3200
		if not ai_StartInteraction("", "Destination", radius, radius, nil, true) then
			StopMeasure("")
			return
		end
	elseif IsType("Destination", "Cart") then
		local radius = GetRadius("Destination")*2
		if not ai_StartInteraction("", "Destination", radius, radius, nil, true) then
			StopMeasure("")
			return
		end
	else
		if not ai_StartInteraction("", "Destination", DistanceToJoinBattle, DistanceToJoinBattle, nil, true) then
			StopMeasure("")
			return
		end
	end
	
	gameplayformulas_SimAttackWithRangeWeapon("", "Destination")
	local iBattleID = BattleJoin("", "Destination", false)
	Sleep(2) -- required to be at least 1, better 2, otherwise attackers will abort attack within a second after attack
end


