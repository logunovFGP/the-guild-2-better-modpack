function Run()

	if HasProperty("", "NotAffectable") then
		return "-"
	end

	if ActionIsStopped("Action") then
		if not GetState("", STATE_SCANNING) then
			return ""
		end
	end

	if GetState("", STATE_NPC) then
		return "-"
	end
	
	if GetState("", STATE_ROBBERGUARD) then
		return ""
	end
	
	if GetImpactValue("", "spying") == 1 then
		return ""
	end

	if BattleIsFighting("") then
		return ""
	end
	
	local MeasureName = GetCurrentMeasureName("")
	
	if MeasureName == "BurgleAHouse"  then
		return ""
	elseif MeasureName == "PickpocketPeople" then
		return ""
	elseif MeasureName == "AttackEnemy" then
		return ""
	elseif MeasureName == "SquadWaylayMember" then
		SetProperty("", "DontLeave", 1)
	end
	
	local MyProfession = SimGetProfession("")
	local MyDyn = GetDynastyID("")
	local ActorDyn = GetDynastyID("Actor")
	local VictimDyn = GetDynastyID("Victim")
	
	if MyProfession == GL_PROFESSION_COCOTTE then
		if MyDyn == ActorDyn then
			return ""
		elseif MyDyn > 0 and MyDyn == VictimDyn then
			return "-CallGuards:2"
		else
			return "-Flee"
		end
	end

	local bEvidence = ActionIsEvidence("Action")
	local bIsGuard = (MyDyn == -1) and (MyProfession == GL_PROFESSION_CITYGUARD or MyProfession == GL_PROFESSION_ELITEGUARD)

	-- join an existing Fight
	if not (bIsGuard) then
		if BattleGetNextEnemy("Owner", "Actor", "nextEnemy") then
			CopyAlias("nextEnemy", "Destination")
			return "Attack"
		end
	end
	
	-- starts a new Fight
	if IsType("", "Ship") then
		-- attack if i am the victim to protect myself
		if MyDyn == VictimDyn then
			if DynastyGetDiplomacyState("", "Actor")>DIP_NEUTRAL then
				DynastySetDiplomacyState("", "Actor", DIP_NEUTRAL)
			end
			CopyAlias("Actor", "Destination")
			return "Attack"
		end
		
		-- attack if i am allied with victim
		if DynastyGetDiplomacyState("", "Victim") == DIP_ALLIANCE then
			if DynastyGetDiplomacyState("", "Actor") <= DIP_NEUTRAL then
				CopyAlias("Actor", "Destination")
				return "Attack"
			end
		end
	end
	
	if SimGetClass("") == GL_CLASS_CHISELER then

		-- am i a robber with protectionmoney measure (ms_134_PressProtectionMoney.lua) and is my house the victim
		local bRobberGuard = HasProperty("", "RobberProtecting")
		if (bRobberGuard == true) then
			local iRobberID = GetDynastyID("")
			if AliasExists("VictimObject") then
				local iRobberProtHouseDynID = GetProperty("VictimObject", "RobberProtected")
				if (iRobberID == iRobberProtHouseDynID) then
					CopyAlias("Actor", "Destination")
					return "Attack"
				end
			end			
		end

		-- Fighter without a dynasty means guard, and guards attack illegals
		if (bEvidence and (bIsGuard or HasProperty("", "Guarding"))) then
			local	ActorID = GetDynastyID("Actor")
			if ActorID < 1 then
				CopyAlias("Actor", "Destination")
				return "Attack"
			-- check if I am a servant of the attacker, attack if not
			elseif ActorID ~= SimGetServantDynastyId("") then
				CopyAlias("Actor", "Destination")
				return "Attack"
			else
				if HasProperty("", "Guarding") then
					return ""
				else
					SetData("Distance", 2000)
					return "-Flee"
				end
			end
		end

		-- attack if i am the victim to protect myself
		if AliasExists("Victim") and MyDyn == VictimDyn then
			if DynastyGetDiplomacyState("", "Actor") > DIP_NEUTRAL then
				DynastySetDiplomacyState("", "Actor", DIP_NEUTRAL)
			end
			CopyAlias("Actor", "Destination")
			return "Attack"
		end
		
		-- attack if i am allied with victim
		if AliasExists("Victim") and DynastyGetDiplomacyState("", "Victim") == DIP_ALLIANCE then
			if DynastyGetDiplomacyState("", "Actor") <= DIP_NEUTRAL then
				CopyAlias("Actor", "Destination")
				return "Attack"
			end
		end
	end

	if MyDyn > 0 and AliasExists("Victim") and MyDyn == VictimDyn then
		return "-CallGuards"
	end
	
	-- if GetFavorToSim("Owner", "Actor") > 50 then
		-- return "-Flee"
	-- end

	-- habe ich einen Nicht-Angriffs-Pakt, dann gaffe ich nur
	if Status == DIP_NAP then
		-- return "-Gape:8"
		return ""
	end
	
	-- some workless just flee at random
	local random = Rand(5)
	if ((random > 2) and (MyDyn < 1)) then
		return "-Flee"
	elseif (MyDyn < 1) then
		return "-Gape:8"
	end		
	
	-- der Rest ruft Wachen
	if (bEvidence) then
		return "-CallGuards:2"
	end
	
	--return "-Gape:8"
	return ""
end

