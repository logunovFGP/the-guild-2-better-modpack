local function ImprovedRun()

	local function IsBusyWithIgnoredMeasure()
		local MeasureName = GetCurrentMeasureName("")

		if MeasureName == "BurgleAHouse" then
			return true
		elseif MeasureName == "PickpocketPeople" then
			return true
		elseif MeasureName == "AttackEnemy" then
			return true
		elseif MeasureName == "SquadWaylayMember" then
			SetProperty("", "DontLeave", 1)
			return true
		end

		return false
	end

	local function ShouldRunStandardReaction()
		if HasProperty("", "NotAffectable") then
			return false
		end

		if ActionIsStopped("Action") and not GetState("", STATE_SCANNING) then
			return false
		end

		if GetState("", STATE_NPC) then
			return false
		end

		if GetState("", STATE_ROBBERGUARD) then
			return false
		end

		if GetImpactValue("", "spying") == 1 then
			return false
		end

		if BattleIsFighting("") then
			return false
		end

		if GetDistance("", "Actor") > 3000 then
			return false
		end

		if IsBusyWithIgnoredMeasure() then
			return false
		end

		return true
	end

	local function GetGuardOwnerDynasty()
		local GuardOwnerDyn = SimGetServantDynastyId("")

		if GuardOwnerDyn < 1 then
			if SimGetWorkingPlace("", "WorkingPlace") then
				GuardOwnerDyn = GetDynastyID("WorkingPlace")
			end
		end

		return GuardOwnerDyn
	end

	local function ExistingFightTargetIsValid(MyDyn)
		if BattleGetNextEnemy("Owner", "Actor", "nextEnemy") then
			local NextEnemyDyn = GetDynastyID("nextEnemy")

			if MyDyn < 1 or NextEnemyDyn ~= MyDyn then
				return true
			end
		end

		return false
	end

	local function AttackActor()
		CopyAlias("Actor", "Destination")
		return "Attack"
	end

	local function AttackNextEnemy()
		CopyAlias("nextEnemy", "Destination")
		return "Attack"
	end

	local function NeutralizeActorDiplomacy()
		if DynastyGetDiplomacyState("", "Actor") > DIP_NEUTRAL then
			dyn_SetDiplomacyState("", "Actor", DIP_NEUTRAL)
		end
	end

	local function IsOnActorTeam()
		return DynastyGetTeam("") > 0 and DynastyGetTeam("") == DynastyGetTeam("Actor")
	end

	local function AttackActorIfVictim(MyDyn, VictimDyn)
		if MyDyn ~= VictimDyn then
			return nil, false
		end

		if IsOnActorTeam() then
			return nil, true
		end

		NeutralizeActorDiplomacy()
		return AttackActor(), true
	end

	local function AttackActorIfVictimAlly()
		if DynastyGetDiplomacyState("", "Victim") == DIP_ALLIANCE then
			if DynastyGetDiplomacyState("", "Actor") <= DIP_NEUTRAL then
				return AttackActor(), true
			end
		end

		return nil, false
	end

	-- bDecisionMade can mean either a concrete behavior in Reaction or an intentional no-reaction.
	local Reaction = nil
	local bDecisionMade = false

	if ShouldRunStandardReaction() then
		local MyProfession = SimGetProfession("")
		local MyDyn = GetDynastyID("")
		local ActorDyn = GetDynastyID("Actor")
		local VictimDyn = GetDynastyID("Victim")
		local bEvidence = ActionIsEvidence("Action")
		local bIsGuard = (MyDyn == -1) and (MyProfession == GL_PROFESSION_CITYGUARD or MyProfession == GL_PROFESSION_ELITEGUARD)
		local bHasGuarding = HasProperty("", "Guarding")
		local bIsHiredGuard = (MyProfession == GL_PROFESSION_PRIVATEGUARD) or bHasGuarding
		local bActorIsMyDyn = (MyDyn > 0 and MyDyn == ActorDyn)
		local bActorIsGuardOwner = false

		if bIsHiredGuard and ActorDyn > 0 then
			bActorIsGuardOwner = (GetGuardOwnerDynasty() == ActorDyn)
		end

		local bCanActAgainstActor = not bActorIsMyDyn and not bActorIsGuardOwner

		if MyProfession == GL_PROFESSION_COCOTTE then
			if MyDyn > 0 and MyDyn == VictimDyn and bCanActAgainstActor then
				Reaction = "-CallGuards:2"
			elseif not bActorIsMyDyn then
				Reaction = "-Flee"
			end
			bDecisionMade = true
		end

		-- Join an existing fight before considering new reactions against the actor.
		if not bDecisionMade and not bIsGuard and ExistingFightTargetIsValid(MyDyn) then
			Reaction = AttackNextEnemy()
			bDecisionMade = true
		end

		if not bDecisionMade and bActorIsGuardOwner then
			bDecisionMade = true
		end

		if not bDecisionMade and IsType("", "Ship") then
			if bCanActAgainstActor then
				Reaction, bDecisionMade = AttackActorIfVictim(MyDyn, VictimDyn)
				if not bDecisionMade then
					Reaction, bDecisionMade = AttackActorIfVictimAlly()
				end
			end
			bDecisionMade = true
		end

		if not bDecisionMade and SimGetClass("") == GL_CLASS_CHISELER then
			if HasProperty("", "RobberProtecting") then
				local RobberDyn = GetDynastyID("")
				if AliasExists("VictimObject") then
					local ProtectedHouseDyn = GetProperty("VictimObject", "RobberProtected")
					if RobberDyn == ProtectedHouseDyn and bCanActAgainstActor then
						Reaction = AttackActor()
						bDecisionMade = true
					end
				end
			end

			-- Fighter without a dynasty means guard, and guards attack illegals.
			if not bDecisionMade and bEvidence and (bIsGuard or bHasGuarding) then
				local ActorID = GetDynastyID("Actor")

				if ActorID < 1 then
					Reaction = AttackActor()
				elseif bCanActAgainstActor and ActorID ~= SimGetServantDynastyId("") then
					Reaction = AttackActor()
				elseif not bHasGuarding then
					SetData("Distance", 2000)
					Reaction = "-Flee"
				end
				bDecisionMade = true
			end

			if not bDecisionMade and bCanActAgainstActor and AliasExists("Victim") then
				Reaction, bDecisionMade = AttackActorIfVictim(MyDyn, VictimDyn)
				if not bDecisionMade then
					Reaction, bDecisionMade = AttackActorIfVictimAlly()
				end
			end
		end

		if not bDecisionMade and MyDyn > 0 and AliasExists("Victim") and MyDyn == VictimDyn and bCanActAgainstActor then
			Reaction = "-CallGuards"
			bDecisionMade = true
		end

		-- Habe ich einen Nicht-Angriffs-Pakt, dann gaffe ich nur.
		if not bDecisionMade and bCanActAgainstActor and DynastyGetDiplomacyState("", "Actor") == DIP_NAP then
			bDecisionMade = true
		end

		-- Workless witnesses mostly raise the alarm, the rest panics or gapes.
		if not bDecisionMade and MyDyn < 1 then
			local random = Rand(5)
			if bEvidence and bCanActAgainstActor and random < 3 then
				Reaction = "-CallGuards:2"
			elseif random > 3 then
				Reaction = "-Flee"
			else
				Reaction = "-Gape:8"
			end
			bDecisionMade = true
		end

		if not bDecisionMade and bEvidence and bCanActAgainstActor then
			Reaction = "-CallGuards:2"
			bDecisionMade = true
		end
	end

	if Reaction ~= nil then
		return Reaction
	end

	return ""
end


function Run()

	-- return ImprovedRun() -- TODO enable this (or copy the code) when the new code was properly tested



--	local debug_labels = "bs_IllegalDetection.lua,"

--	if GetName("Owner") ~= nil then
--		debug_labels = debug_labels .. " | Owner: " .. GetName("Owner")
--	end

--	if GetName("actor") ~= nil then
--		debug_labels = debug_labels .. " | actor: " .. GetName("actor")
--	end

--	if GetCurrentMeasureName("") ~= nil then
--		debug_labels = debug_labels .. " | MeasureName: " .. GetCurrentMeasureName("")
--	end 

--	LogMessage(debug_labels)

	if HasProperty("", "NotAffectable") then
		return ""
	end

	if ActionIsStopped("Action") then
		if not GetState("", STATE_SCANNING) then
			return ""
		end
	end

	if GetState("", STATE_NPC) then 
		return ""
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
	
	-- check distance
	if GetDistance("", "Actor") > 3000 then
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
		return "" -- dont do other actions like CallGuards while Waylaying
	end
	
	local MyProfession = SimGetProfession("")
	local MyDyn = GetDynastyID("")
	local ActorDyn = GetDynastyID("Actor")
	local VictimDyn = GetDynastyID("Victim")
	local bActorIsMyDyn = (MyDyn > 0 and MyDyn == ActorDyn)
	
	if MyProfession == GL_PROFESSION_COCOTTE then
		if bActorIsMyDyn then
			return ""
		elseif MyDyn > 0 and MyDyn == VictimDyn then
			return "-CallGuards:2"
		else
			return "-Flee"
		end
	end

	local bEvidence = ActionIsEvidence("Action")
	local bIsGuard = (MyDyn == -1) and (MyProfession == GL_PROFESSION_CITYGUARD or MyProfession == GL_PROFESSION_ELITEGUARD)
	local bIsHiredGuard = (MyProfession == GL_PROFESSION_PRIVATEGUARD) or HasProperty("", "Guarding")
	local bActorIsGuardOwner = false

	if bIsHiredGuard and ActorDyn > 0 then
		local GuardOwnerDyn = SimGetServantDynastyId("")
		if GuardOwnerDyn < 1 then
			if SimGetWorkingPlace("", "WorkingPlace") then
				GuardOwnerDyn = GetDynastyID("WorkingPlace")
			end
		end

		if GuardOwnerDyn == ActorDyn then
			bActorIsGuardOwner = true
		end
	end

	-- join an existing Fight
	if not (bIsGuard) then
		if BattleGetNextEnemy("Owner", "Actor", "nextEnemy") then
			CopyAlias("nextEnemy", "Destination")
			return "Attack"
		end
	end

	if bActorIsGuardOwner then
		return ""
	end

	local bCanActAgainstActor = not bActorIsMyDyn
	
	-- starts a new Fight
	if IsType("", "Ship") then
		-- attack if i am the victim to protect myself
		if MyDyn == VictimDyn and bCanActAgainstActor then
			if DynastyGetTeam("") > 0 and DynastyGetTeam("") == DynastyGetTeam("Actor") then
				return ""
			elseif DynastyGetDiplomacyState("", "Actor")>DIP_NEUTRAL then
				dyn_SetDiplomacyState("", "Actor", DIP_NEUTRAL)
			end
			CopyAlias("Actor", "Destination")
			return "Attack"
		end
		
		-- attack if i am allied with victim
		if bCanActAgainstActor and DynastyGetDiplomacyState("", "Victim") == DIP_ALLIANCE then
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
				if (iRobberID == iRobberProtHouseDynID) and bCanActAgainstActor then
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
			elseif bCanActAgainstActor and ActorID ~= SimGetServantDynastyId("") then
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
		if AliasExists("Victim") and MyDyn == VictimDyn and bCanActAgainstActor then
			if DynastyGetTeam("") > 0 and DynastyGetTeam("") == DynastyGetTeam("Actor") then
				return ""
			elseif DynastyGetDiplomacyState("", "Actor") > DIP_NEUTRAL then
				dyn_SetDiplomacyState("", "Actor", DIP_NEUTRAL)
			end
			CopyAlias("Actor", "Destination")
			return "Attack"
		end
		
		-- attack if i am allied with victim
		if AliasExists("Victim") and bCanActAgainstActor and DynastyGetDiplomacyState("", "Victim") == DIP_ALLIANCE then
			if DynastyGetDiplomacyState("", "Actor") <= DIP_NEUTRAL then
				CopyAlias("Actor", "Destination")
				return "Attack"
			end
		end
	end

	if MyDyn > 0 and AliasExists("Victim") and MyDyn == VictimDyn and bCanActAgainstActor then
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
	
	-- workless witnesses mostly raise the alarm, the rest panics or gapes
	if (MyDyn < 1) then
		local random = Rand(5)
		if (bEvidence) and bCanActAgainstActor and (random < 3) then
			return "-CallGuards:2"
		elseif (random > 3) then
			return "-Flee"
		else
			return "-Gape:8"
		end
	end

	-- der Rest ruft Wachen
	if (bEvidence) and bCanActAgainstActor then
		return "-CallGuards:2"
	end
	
	--return "-Gape:8"
	return ""
end

