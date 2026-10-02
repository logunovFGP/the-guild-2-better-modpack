function Run()

	-- etwa Abstand vom Geschehen, und gaffen
	GetFleePosition("Owner", "Actor", Rand(100)+150, "Away")
	f_MoveTo("Owner", "Away", GL_MOVESPEED_WALK)
	AlignTo("Owner", "Actor")
	Sleep(1)

	local ActionName = GetData("Action_Name")
	local Timer = 0
	SetRepeatTimer("Owner", "Listen2Quacksalver", 8)

	--listen
	while true do

		if ActionIsStopped("Action") then
			break
		end

		if Timer == 3 then
			break
		end

		Sleep(4)
		local Value = Rand(100)
			
		if Value < 50 then
			if SimGetGender("") == GL_GENDER_MALE then
				if Rand(2) == 0 then
					PlayAnimationNoWait("Owner", "cheer_01")
				else
					PlayAnimationNoWait("Owner", "cheer_02")
				end
				PlaySound3DVariation("", "CharacterFX/male_cheer", 0.6)
			else
				if Rand(2) == 0 then
					PlayAnimationNoWait("Owner", "cheer_01")
				else
					PlayAnimationNoWait("Owner", "cheer_02")
				end
				PlaySound3DVariation("", "CharacterFX/female_cheer", 0.6)
			end
		end
		Timer = Timer +1
	end
	
	--buy stuff or not
	if (GetID("Actor")) and not ActionIsStopped("Action") then
		local RhetoricSkillActor = GetSkillValue("Actor", RHETORIC)
		local BargainingActor = GetSkillValue("Actor", BARGAINING)
		local LevelActor = SimGetLevel("Actor")
		local Pitch = gameplayformulas_QuackPitch(RhetoricSkillActor, LevelActor)
		local EmpathyBuyer = GetSkillValue("", EMPATHY)
		local MoneyToGet = 0
		local RandomTime = 1+Rand(5)
		Sleep(RandomTime)
		-- a flat 10% lucky sale first, so no pitch is hopeless; otherwise the roll chr_SkillCheck
		-- makes (difficulty 1), with the level bonus on the seller's side
		local Lucky = Rand(100) < 10
		if Lucky or Rand(Pitch + Rand(3)) > Rand(EmpathyBuyer + 1) then
			MsgSayNoWait("", "@L_MEASURE_LISTENQUACKSALVER_YES")
			PlayAnimation("", "nod")
			if RemoveItems("Actor", "MiracleCure", 1, INVENTORY_STD) == 1 then
				MoneyToGet = gameplayformulas_QuackPrice(RhetoricSkillActor, BargainingActor, LevelActor, Rand(41), Rand(6))
				chr_CreditMoney("Actor", MoneyToGet, "Offering")
				
				local HasHospital = ai_GetWorkBuilding("Actor", GL_BUILDING_TYPE_HOSPITAL, "QuackHospital")
				if HasHospital then
					economy_UpdateBalance("QuackHospital", "Service", MoneyToGet)
				end
				if achievements_isValidSim("Actor", "MISC_QUACKSALVER") then
					UpdateStat("STAT_QUACKSALVER", (GetStat("STAT_QUACKSALVER") or 0) + math.floor(MoneyToGet))
				end
				
				if dyn_IsLocalPlayer("Actor") then
					ShowOverheadSymbol("Actor", false, true, 0, "%1t", MoneyToGet)
				end

				-- the buyer has been had: he now holds it against the seller's family, and may pin a lampoon.
				-- A hired quack is not a family member, so its employer's family takes the grudge.
				local Seller
				if IsDynastySim("Actor") then
					Seller = "Actor"
				elseif HasHospital and BuildingGetOwner("QuackHospital", "QuackBoss") then
					Seller = "QuackBoss"
				end
				local Difficulty = ScenarioGetDifficulty()
				local FavorLoss = gameplayformulas_QuackFavorLoss(RhetoricSkillActor, Difficulty)
				local FavorBefore = -1
				if Seller then
					FavorBefore = GetFavorToSim("", Seller)
					if FavorLoss > 0 then
						-- also shows the favour-down symbol over the buyer when the seller is the player
						chr_ModifyFavor("", Seller, -FavorLoss)
					end
				end
				local Chance = gameplayformulas_QuackPamphletChance(Difficulty)
				local Roll = Rand(100)
				local Pamphlet = "none"
				if Seller and Roll < Chance then
					Pamphlet = behavior_listenquacksalver_PostPamphlet(Seller)
				end
				LogMessage("@QUACK sale actor=" .. GetName("Actor") .. " seller=" .. (Seller and GetName(Seller) or "none") ..
						" buyer=" .. GetName("") .. " rhet=" .. tostring(RhetoricSkillActor) .. " barg=" .. tostring(BargainingActor) ..
						" lvl=" .. tostring(LevelActor) .. " pitch=" .. tostring(Pitch) .. " emp=" .. tostring(EmpathyBuyer) ..
						" lucky=" .. tostring(Lucky) ..
						" diff=" .. tostring(Difficulty) ..
						" money=" .. tostring(MoneyToGet) .. " favorloss=" .. tostring(FavorLoss) ..
						" favor=" .. tostring(FavorBefore) .. "->" .. tostring(Seller and GetFavorToSim("", Seller) or -1) ..
						" pamphlet=" .. Roll .. "<" .. Chance .. ":" .. Pamphlet)
			end
		else
			MsgSayNoWait("", "@L_MEASURE_LISTENQUACKSALVER_NO")
			LogMessage("@QUACK refused actor=" .. GetName("Actor") .. " buyer=" .. GetName("") ..
					" pitch=" .. tostring(Pitch) .. " emp=" .. tostring(EmpathyBuyer))
			if SimGetGender("") == GL_GENDER_MALE then
				PlaySound3DVariation("", "CharacterFX/male_hoot", 0.7)
			else
				PlaySound3DVariation("", "CharacterFX/female_hoot", 0.7)
			end

			PlayAnimation("", "shake_head")
		end
	end
end

-- Pins a lampoon against the seller on the buyer's town notice board, the same way
-- ms_027_AddPamphlet does, minus the walk: the scammed buyer does it on the spot.
-- Returns what happened, for the @QUACK log line.
function PostPamphlet(VictimAlias)
	if not GetSettlement("", "QuackCity") then
		return "nocity"
	end
	if not CityGetRandomBuilding("QuackCity", -1, 41, -1, -1, FILTER_IGNORE, "QuackBoard") then
		return "noboard"
	end
	if (GetProperty("QuackBoard", "PamphletCnt") or 0) >= 4 then
		return "boardfull"
	end
	local PIdx = BlackBoardAddPamphlet("QuackBoard", VictimAlias, "@L_LAMPOONS_A" .. (Rand(26) + 1) .. "_+0")
	if PIdx > -1 then
		SetProperty("QuackBoard", "Pamphlet_" .. PIdx, GetID(VictimAlias))
		StopAction("blackboard", "QuackBoard")
		Sleep(0.1)
		CommitAction("blackboard", "QuackBoard", "QuackBoard")
		return "posted" .. PIdx
	end
	return "refused"
end
