-- cu_autoheal.lua -- injured player-controlled sims seek treatment on idle
--
-- Injured or sick player-controlled characters look after themselves:
--   light HP loss -> rest (home bed, or rogue-camp campfire)
--   disease       -> an in-city hospital that has the cure in stock and is
--                    affordable, preferring the player's own hospitals
-- The player's MAIN characters (the controllable party slots) are excluded
-- and keep their manual doctor button. Fires the same measures the AI already
-- uses (idlelib VisitDoc / GoToSleep / GetCured); those are gated to AI
-- dynasties, which is why player sims never auto-healed. Invoked once from
-- the top of std_Idle.Run() as cu_autoheal_Process("").

-- Read [AUTOHEAL] from config.ini into globals. The defaults make the feature
-- work when the section is missing. Re-read every call: globals get frozen
-- into savegames, so a load-once guard would keep a stale value forever on an
-- existing save; the re-read is a cheap in-memory lookup.
function LoadConfig()
	cu_autoheal_Enabled      = GetSettingNumber("AUTOHEAL", "Enabled", 1)
	cu_autoheal_HpThreshold  = GetSettingNumber("AUTOHEAL", "HpThreshold", 60) / 100
	cu_autoheal_Employees    = GetSettingNumber("AUTOHEAL", "IncludeEmployees", 1)
	cu_autoheal_Thugs        = GetSettingNumber("AUTOHEAL", "IncludeThugs", 1)
	cu_autoheal_PreferOwn    = GetSettingNumber("AUTOHEAL", "PreferPlayerOwned", 1)
	cu_autoheal_AllowNeutral = GetSettingNumber("AUTOHEAL", "AllowNeutral", 1)
	cu_autoheal_AllowCompetitor = GetSettingNumber("AUTOHEAL", "AllowCompetitor", 1)
	cu_autoheal_IncludeMain  = GetSettingNumber("AUTOHEAL", "IncludeMainChars", 0)
	cu_autoheal_Debug        = GetSettingNumber("AUTOHEAL", "DebugLog", 0)
	-- log only when the threshold changes, not every cycle
	if cu_autoheal_Debug == 1 and cu_autoheal_LastLog ~= cu_autoheal_HpThreshold then
		cu_autoheal_LastLog = cu_autoheal_HpThreshold
		LogMessage("@AUTOHEAL config loaded: enabled="..cu_autoheal_Enabled.." hpThreshold="..cu_autoheal_HpThreshold)
	end
end

-- Main entry. Returns 1 if it took over this sim's idle (issued treatment or
-- rest), otherwise nil so std_Idle continues normally. Kept cheap: non-player
-- sims exit after a couple of checks.
function Process(sim)
	cu_autoheal_LoadConfig()
	if cu_autoheal_Enabled == 0 then
		return nil
	end

	-- exclude the player's MAIN characters (the controllable party slots) unless allowed
	if cu_autoheal_IncludeMain == 0 then
		if DynastyIsPlayer(sim) and IsPartyMember(sim) then
			if cu_autoheal_Debug == 1 then
				if GetHPRelative(sim) < 1 then LogMessage("@AUTOHEAL skip "..GetName(sim).." = main/party char (IncludeMainChars=0)") end
			end
			return nil
		end
	end

	local category = cu_autoheal_Category(sim)
	if not category then
		return nil
	end

	-- resume an interrupted waylay once healed back up to the threshold
	if HasProperty(sim, "CU_WaylayDest") then
		if GetHPRelative(sim) >= cu_autoheal_HpThreshold then
			local wd = GetProperty(sim, "CU_WaylayDest")
			RemoveProperty(sim, "CU_WaylayDest")
			if wd and GetAliasByID(wd, "CU_WD") then
				if cu_autoheal_Debug == 1 then LogMessage("@AUTOHEAL "..GetName(sim).." healed -> resuming waylay") end
				-- MeasureStart, not MeasureRun: a MeasureRun issued from idle can be
				-- yanked by the camp's AI tree before the thug ever gets going
				MeasureCreate("CU_WLMeasure")
				MeasureStart("CU_WLMeasure", sim, "CU_WD", "WaylayForBooty")
				return 1
			end
		end
	end

	-- per-character manual override
	if HasProperty(sim, "AutoHealOff") then
		return nil
	end

	-- already seeking / waiting for a doctor, or still on the retry cooldown
	if HasProperty(sim, "WaitingForTreatment") then
		return nil
	end
	-- CU_HealNow (set by the waylay break-off) bypasses the retry throttle once,
	-- so a broken-off thug is treated this idle cycle, not after a stale cooldown
	if HasProperty(sim, "CU_HealNow") then
		RemoveProperty(sim, "CU_HealNow")
	elseif not ReadyToRepeat(sim, "cu_autoheal") then
		return nil
	end

	local kind = cu_autoheal_NeedsCare(sim)
	if cu_autoheal_Debug == 1 then
		LogMessage("@AUTOHEAL eval "..GetName(sim).." cat="..category.." hpRel="..GetHPRelative(sim).." thr="..cu_autoheal_HpThreshold.." need="..(kind or "none"))
	end
	if not kind then
		return nil
	end

	SetRepeatTimer(sim, "cu_autoheal", 1)   -- throttle retries (~1 game hour)
	local issued
	if kind == "disease" then
		issued = cu_autoheal_SeekHospital(sim, category)
	else
		-- HP injury: rest if a spot is free, otherwise a hospital (it heals HP too)
		issued = cu_autoheal_SeekRest(sim, category)
		if not issued then
			issued = cu_autoheal_SeekHospital(sim, category)
		end
	end
	-- only take over the idle if something was actually started; otherwise let
	-- std_Idle continue normally instead of standing idle
	if issued then
		return 1
	end
	return nil
end

-- "thug" (player rogue), "employee", or nil. Player FAMILY (dynasty,
-- non-party) is left to DynastyIdle, which already heals them; the gap this
-- library fills is employees and thugs, which have no heal at all.
function Category(sim)
	if IsDynastySim(sim) and DynastyIsPlayer(sim) then
		return nil
	end
	-- non-dynasty: only qualifies if working for a PLAYER-owned building
	if not SimGetWorkingPlace(sim, "CU_WP") then
		return nil
	end
	if not BuildingGetOwner("CU_WP", "CU_Boss") then
		return nil
	end
	if not DynastyIsPlayer("CU_Boss") then
		return nil
	end
	-- hospital staff are the treatment providers -- only auto-send a sick one
	-- while a healer is still working, so the last doctor is never pulled off
	-- duty (else every doctor becomes a waiting patient and nobody treats)
	if BuildingGetType("CU_WP") == GL_BUILDING_TYPE_HOSPITAL then
		if BuildingGetProducerCount("CU_WP", PT_MEASURE, "MedicalTreatment") < 1 then
			return nil
		end
	end
	local prof = SimGetProfession(sim)
	if prof == GL_PROFESSION_ROBBER or prof == GL_PROFESSION_THIEF then
		if cu_autoheal_Thugs == 1 then
			return "thug"
		end
		return nil
	end
	if cu_autoheal_Employees == 1 then
		return "employee"
	end
	return nil
end

-- "disease" = any named illness impact that only a doctor can clear -- takes
-- priority over "hp" (raw HP loss, which rest CAN recover). Detection uses the
-- same iterator HospitalCanCure cures from, so detection and cure stay in
-- lockstep; every real disease sets an iterator impact.
function NeedsCare(sim)
	for i, dis in diseases_GetDiseaseIterator() do
		if GetImpactValue(sim, dis.getName()) > 0 then
			return "disease"
		end
	end
	local hp = GetHPRelative(sim)
	if hp >= 0 and hp < cu_autoheal_HpThreshold then   -- hp>=0 guards the -1 error return
		return "hp"
	end
	return nil
end

-- light HP injury -> rest where this character type can; no free spot -> do
-- nothing (re-checked on a later idle cycle after the cooldown)
function SeekRest(sim, category)
	-- campfire rest at a robber camp -- works for family robbers AND hired thugs.
	-- MeasureStart, not MeasureRun: a MeasureRun gets overridden by the workshop
	-- or guard scheduler, so the sim never actually rests.
	if SimGetWorkingPlace(sim, "CU_Camp") then
		if BuildingHasUpgrade("CU_Camp", "Campfire") then
			if cu_autoheal_Debug == 1 then LogMessage("@AUTOHEAL "..GetName(sim).." -> rest at campfire (GetCured)") end
			MeasureCreate("CU_RestMeasure")
			MeasureStart("CU_RestMeasure", sim, "CU_Camp", "GetCured")
			return 1
		end
	end
	if GetHomeBuilding(sim, "CU_Home") then
		if GetFreeLocatorByName("CU_Home", "Bed", 1, 6, "CU_Bed") then
			if cu_autoheal_Debug == 1 then LogMessage("@AUTOHEAL "..GetName(sim).." -> rest in bed (GoToSleep)") end
			MeasureCreate("CU_RestMeasure")
			MeasureStart("CU_RestMeasure", sim, "CU_Home", "GoToSleep")
			return 1
		end
	end
	return nil
end

-- disease -> a suitable in-city hospital via the AttendDoctor measure. A
-- disease is only cleared by a doctor, so this path NEVER falls back to rest
-- (a sleeping sim stays sick and never re-evaluates). If no affordable,
-- in-stock hospital is reachable right now, do nothing -- the sim retries on
-- a later idle cycle, catching the hospital the moment it has the cure.
-- Returns 1 if a doctor visit was issued, nil otherwise.
function SeekHospital(sim, category)
	-- anchor the hospital search on the WORKPLACE's settlement, not the sim's
	-- current position: an employee out gathering would otherwise resolve to a
	-- random nearby settlement that may have no hospital. Fall back to the
	-- nearest settlement when there is no workplace city.
	if not (AliasExists("CU_WP") and GetSettlement("CU_WP", "CU_City")) then
		if not GetNearestSettlement(sim, "CU_City") then
			if cu_autoheal_Debug == 1 then LogMessage("@AUTOHEAL "..GetName(sim).." -> no city, will retry") end
			return nil
		end
	end
	if gameplayformulas_CheckMoneyForTreatment(sim) == 0 then
		if cu_autoheal_Debug == 1 then LogMessage("@AUTOHEAL "..GetName(sim).." -> cant afford treatment, will retry (NOT resting)") end
		return nil
	end
	if cu_autoheal_PickHospital(sim, "CU_City", "CU_Hosp") then
		-- MeasureStart is the engine's committed-action API (the channel the
		-- BaseTree uses for Privilege actions; AttendDoctor is one): unlike a
		-- plain MeasureRun, the workshop scheduler can't yank the sim back en
		-- route. Its 3rd arg becomes the measure's "Destination" alias, so
		-- AttendDoctor uses OUR chosen hospital, not a random one.
		if cu_autoheal_Debug == 1 then LogMessage("@AUTOHEAL "..GetName(sim).." -> MeasureStart AttendDoctor at "..GetName("CU_Hosp")) end
		MeasureCreate("CU_DocMeasure")
		MeasureStart("CU_DocMeasure", sim, "CU_Hosp", "AttendDoctor")
		return 1
	end
	if cu_autoheal_Debug == 1 then LogMessage("@AUTOHEAL "..GetName(sim).." -> no curable hospital in city, will retry (NOT resting; rest can't cure a disease)") end
	return nil
end

-- choose the best in-city hospital that has the cure in stock. Preference is
-- strictly tiered: OWN -> NEUTRAL (city/public, no dynasty owner) ->
-- COMPETITOR (another dynasty); within a tier the nearest wins. The player
-- need not own a hospital -- employees fall through to neutral, then a
-- rival's as last resort. No level gate: the doctor cures on stock, not
-- level (HospitalCanCure gates).
function PickHospital(sim, cityAlias, outAlias)
	-- class -1 (ANY) + FILTER_IGNORE, matching the working query in
	-- cityguard_CheckHP; ownership is handled per-hospital in the loop
	local count = CityGetBuildings(cityAlias, -1, GL_BUILDING_TYPE_HOSPITAL, -1, -1, FILTER_IGNORE, "CU_H")
	if cu_autoheal_Debug == 1 then LogMessage("@HOSPDBG city="..GetName(cityAlias).." hospitals_found="..count) end
	local bestOwn, bestOwnDist = nil, -1
	local bestNeu, bestNeuDist = nil, -1
	local bestCom, bestComDist = nil, -1
	local i = 0
	while i < count do
		local h = "CU_H"..i
		if AliasExists(h) then
			if cu_autoheal_HospitalCanCure(sim, h) then
				local dist = GetDistance(sim, h)
				if BuildingGetOwner(h, "CU_HB") then
					if DynastyIsPlayer("CU_HB") then
						if bestOwnDist < 0 or dist < bestOwnDist then bestOwnDist = dist; bestOwn = h end
					else
						if bestComDist < 0 or dist < bestComDist then bestComDist = dist; bestCom = h end
					end
				else
					-- no dynasty owner = a neutral / city hospital
					if bestNeuDist < 0 or dist < bestNeuDist then bestNeuDist = dist; bestNeu = h end
				end
			end
		end
		i = i + 1
	end

	-- AllowNeutral gates the non-owned fallback (neutral AND competitor);
	-- AllowCompetitor additionally gates the rival tier. Conditions are inlined
	-- rather than stored in a local -- Lua 4 has no boolean type.
	local chosen = nil
	if cu_autoheal_PreferOwn == 1 then
		-- strict tier order: own beats a closer neutral, neutral beats a closer competitor
		if bestOwn then
			chosen = bestOwn
		elseif bestNeu and cu_autoheal_AllowNeutral == 1 then
			chosen = bestNeu
		elseif bestCom and cu_autoheal_AllowNeutral == 1 and cu_autoheal_AllowCompetitor == 1 then
			chosen = bestCom
		end
	else
		-- PreferOwn off: own and neutral compete by distance; competitor still only as last resort
		if bestOwn and bestNeu and cu_autoheal_AllowNeutral == 1 then
			if bestOwnDist <= bestNeuDist then
				chosen = bestOwn
			else
				chosen = bestNeu
			end
		elseif bestOwn then
			chosen = bestOwn
		elseif bestNeu and cu_autoheal_AllowNeutral == 1 then
			chosen = bestNeu
		elseif bestCom and cu_autoheal_AllowNeutral == 1 and cu_autoheal_AllowCompetitor == 1 then
			chosen = bestCom
		end
	end

	if cu_autoheal_Debug == 1 then
		local sOwn = "-"
		local sNeu = "-"
		local sCom = "-"
		local sCho = "-"
		if bestOwn then sOwn = GetName(bestOwn) end
		if bestNeu then sNeu = GetName(bestNeu) end
		if bestCom then sCom = GetName(bestCom) end
		if chosen then sCho = GetName(chosen) end
		LogMessage("@HOSPDBG tiers own="..sOwn.." neutral="..sNeu.." competitor="..sCom.." chosen="..sCho.." (PreferOwn="..cu_autoheal_PreferOwn.." AllowNeutral="..cu_autoheal_AllowNeutral.." AllowCompetitor="..cu_autoheal_AllowCompetitor..")")
	end

	if chosen then
		CopyAlias(chosen, outAlias)
		return 1
	end
	return nil
end

-- a hospital qualifies if it can cure AT LEAST ONE of the sim's current
-- diseases, counting the same three sources the doctor draws from
-- (INVENTORY_STD, INVENTORY_SELL, and the managed-medicine "<Med>s" property,
-- where a producing hospital holds its cure). The doctor treats per-disease
-- on stock, so partial stock still qualifies; whatever remains is
-- re-evaluated on a later cycle. A sim with NO disease impacts (plain HP
-- treatment) qualifies anywhere: HP care needs no stock.
function HospitalCanCure(sim, hosp)
	local hasDisease = nil
	for i, dis in diseases_GetDiseaseIterator() do
		local name = dis.getName()
		if GetImpactValue(sim, name) > 0 then
			hasDisease = 1
			local product = dis.getMedicine()
			local std  = GetItemCount(hosp, product, INVENTORY_STD)
			local sell = GetItemCount(hosp, product, INVENTORY_SELL)
			local managed = product.."s"
			local prop = 0
			if HasProperty(hosp, managed) then
				prop = GetProperty(hosp, managed)
			end
			-- stock threshold matches the doctor exactly: ANY source > 0
			if std + sell + prop >= 1 then
				return 1
			end
		end
	end
	if not hasDisease then
		return 1
	end
	return nil
end
