function Run()
	GetDynasty("", "Dynasty")
	while not GetState("", STATE_DEAD) do
		if IsType("", "Sim") then
			state_scanning_ArrestLoop()
		elseif IsType("", "Building") then
			state_scanning_WatchtowerLoop() -- towers are deactivated currently
			if GetDynastyID("") < 1 then
				state_scanning_ArrestLoop()
			end
		end
		Sleep(1)
	end
end

function ArrestLoop() -- LogMessage("@NAO Arrestloop for "..GetName(""))
	if CityGuardScan("", "Penalty") then
		if PenaltyGetOffender("Penalty", "Wanted") then
			LogMessage("@NAO [i] state_scanning.lua -> " .. GetName("") .. " has found felon " .. GetName("Wanted"))
			if GetImpactValue("Wanted", "REVOLT") > 0 then
				if GetState("Wanted", STATE_UNCONSCIOUS) then
					feedback_OverheadActionName("Wanted")
					GetPosition("Wanted", "ParticleSpawnPos")
					BattleWeaponPresent("")
					Sleep(2)
					PlayAnimationNoWait("", "finishing_move_01")
					Sleep(0.6)	
					StartSingleShotParticle("particles/bloodsplash.nif", "ParticleSpawnPos", 1, 4)
					PlaySound3DVariation("Wanted", "Effects/combat_strike_mace", 1)
					Sleep(2)
					BattleWeaponStore("")	
					if AliasExists("Wanted") then
						SetProperty("Wanted", "UnconsciousKill", 1)
						Kill("Wanted")
					end
				else
					gameplayformulas_SimAttackWithRangeWeapon("", "Wanted")
					BattleJoin("", "Wanted", true)
				end
			else
				if GetDistance("", "Wanted") < 4000 then 
					if ReadyToRepeat("Wanted", "TimerGetArrested") then 
						SetRepeatTimer("Wanted", "TimerGetArrested", 1)
						MeasureRun("", "Wanted", "Arrest")
						LogMessage("@NAO #W " .. GetName("") .. " is arresting felon " .. GetName("Wanted") .. "!")
					end
				end
			end
		end
	end
end

function WatchtowerLoop()
	if not GetState("", STATE_FIGHTING) then
		-- Detect enemy ships
		local ShipFilter = "__F((Object.GetObjectsByRadius(Ship)==4000)AND(Object.IsHostile()))"
		local NumOfShips = Find("", ShipFilter,"HostileShip", -1)
		if NumOfShips > 0 then
			local iBattleID = BattleJoin("","HostileShip", false)
			return
		end
		
		--Detect enemy and fighting Sims
		local SimFilter = "__F((Object.GetObjectsByRadius(Sim)==2000)AND(Object.IsInCombatWithMyDynasty()))"
		local NumOfSims = Find("", SimFilter,"HostileSim", -1) 
		if NumOfSims > 0 then
			local iBattleID = BattleJoin("","HostileSim", false)
			return
		end	
	end	
end