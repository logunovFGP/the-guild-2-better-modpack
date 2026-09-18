-- ::TWP::ATTACK t= sim= target= result=<joined|peaceful|noflee|unreachable|mayattack>
-- Six of the exits below are a silent StopMeasure, and a caller that re-orders on a timer
-- cannot tell "the fight started" from "we refused". ms_SquadHijackMember spun this measure
-- 136 times on one sim across the 2026-09-19 session without ever reaching BattleJoin, and
-- nothing in the log said which exit it took - the vanilla unreachable one or the
-- aitwp_MayAttackHere guard we added on 2026-09-10. One line per outcome ends that.
local function Outcome(Result)
	local Target = -1
	if AliasExists("Destination") then
		Target = GetID("Destination")
	end
	utility_Emit("::TWP::ATTACK t=" .. string.format("%.2f", GetGametime())
		.. " sim=" .. GetID("") .. " target=" .. Target .. " result=" .. Result)
end

function Run()

	MeasureSetNotRestartable()

	-- ms_092_SingForPeacefulness.lua active
	if (GetImpactValue("", "Peaceful") ~= 0) then
		Outcome("peaceful")
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
		Outcome("joined")
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
				Outcome("noflee")
				StopMeasure("")
				return
			end
		end
	
		AlignTo("","Destination")
		
	elseif IsType("Destination", "Ship") then
		local radius = 3200
		if not ai_StartInteraction("", "Destination", radius, radius, nil, true) then
			Outcome("unreachable")
			StopMeasure("")
			return
		end
	elseif IsType("Destination", "Cart") then
		local radius = GetRadius("Destination")*2
		if not ai_StartInteraction("", "Destination", radius, radius, nil, true) then
			Outcome("unreachable")
			StopMeasure("")
			return
		end
	else
		if not ai_StartInteraction("", "Destination", DistanceToJoinBattle, DistanceToJoinBattle, nil, true) then
			Outcome("unreachable")
			StopMeasure("")
			return
		end
	end
	
	-- The order can be hours old by the time we arrive: a thug sent after someone out on
	-- the road catches up in the middle of a market. Ask again where we are actually
	-- standing, for AI attackers only - what the player starts is the player's business.
	--
	-- Only for a fighter this house actually sent (aitwp_OnRaidOrder, stamped by
	-- aitwp_SquadAttack). Without that test this refused the engine's own AttackEnemy
	-- filter as well, and the engine simply re-selects: one sim logged 17 refusals in a
	-- 40 minute smoke test on 2026-09-19 and 136 across the session before it, one every
	-- two game minutes, never once joining a fight. A fresh decision by the engine is not
	-- a stale order, and refusing it does not stop it - it only makes it repeat for ever.
	if IsType("Destination", "Sim") and DynastyIsAI("") and aitwp_OnRaidOrder("")
			and GetDynasty("", "AttackerDyn")
			and not aitwp_MayAttackHere("AttackerDyn", "Destination") then
		Outcome("mayattack")
		RemoveAlias("AttackerDyn")
		StopMeasure("")
		return
	end
	RemoveAlias("AttackerDyn")

	Outcome("joined")
	gameplayformulas_SimAttackWithRangeWeapon("", "Destination")
	local iBattleID = BattleJoin("", "Destination", false)
	Sleep(2) -- required to be at least 1, better 2, otherwise attackers will abort attack within a second after attack
end


