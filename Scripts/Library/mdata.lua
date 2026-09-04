-- -----------------------
-- Init
-- -----------------------
function Init()
 --needed for caching
end

function GetDuration(MeasureID)
	local Duration = GetDatabaseValue("Measures", MeasureID, "duration")
  -- local script = GetDatabaseValue("Measures",MeasureID,"script")
	--for artifact duration
	if (MeasureID >= 5000) and (MeasureID <= 6000) then
  -- if string.find(script, "Artefacts", 1, true) then --for artifact duration -- TODO: wait for AID Release to be able to properly test if this is a functional alternative to the ID check
		Duration = Duration + (chr_ArtifactsDuration("", Duration))
	end
	return Duration
end

function GetTimeOut(MeasureID)
	local TimeOut = GetDatabaseValue("Measures", MeasureID, "repeat_time")
  -- local script = GetDatabaseValue("Measures",MeasureID,"script")
	--for artifact timeout
	if (MeasureID >= 5000) and (MeasureID <= 6000) then
  -- if string.find(script, "Artefacts", 1, true) then --for artifact duration
		TimeOut = TimeOut - (chr_ArtifactsDuration("", TimeOut))
	end
	return TimeOut
end

function GetPrice(MeasureName, Title)
	local BasePrice = 50
	-- special cases:
	
	if MeasureName == "AdoptOrphan" then
		BasePrice = GL_BASE_PRICE_ADOPTORPHAN
	end
	
	-- default case:
	local Cost = Title * Title * BasePrice
	return Cost
end

-- The OSH API has no talent row of its own -- it can set a cooldown, a runtime
-- and a cost row, nothing else -- so a talent line has to borrow one of those.
-- Pass a slot the measure does not already fill: "runtime" (default) or "cost".
--
-- The talent is the one the measure's own script reads for its outcome. For the
-- social measures it is the talent field from gameplayformulas_CalcFavorWon,
-- which is what decides the favour actually won -- note CalcMinFavor disagrees
-- for a few IDs, and the two were never reconciled.
--
-- Each row pairs the skill constant with the name of its label row in Text.dbt.
-- The constants stay values and never become table keys: they are engine globals
-- and indexing a table with a nil key raises, where a nil value just returns.
-- The table is function-local like the ones in GamePlayFormulas.lua.
function ShowTalentOSH(MeasureID, Slot)

	local MeasureTalent = {
					[110]   = { CHARISMA,         "charisma" },			-- AssignToLaborOfLove
					[120]   = { EMPATHY,          "empathy" },			-- UseLaborOfLove
					[140]   = { SHADOW_ARTS,      "shadow_arts" },		-- AssignToThiefOfLove
					[150]   = { CHARISMA,         "charisma" },			-- AssignToDanceDivehouse
					[190]   = { CHARISMA,         "charisma" },			-- AssignToPoisonEnemy
					[440]   = { RHETORIC,         "rhetoric" },			-- CohabitWithCharacter
					[460]   = { RHETORIC,         "rhetoric" },			-- StartDialog
					[530]   = { RHETORIC,         "rhetoric" },			-- Flirt
					[540]   = { EMPATHY,          "empathy" },			-- HugCharacter
					[570]   = { EMPATHY,          "empathy" },			-- KissCharacter
					[590]   = { RHETORIC,         "rhetoric" },			-- ArrangeLiaison
					[620]   = { RHETORIC,         "rhetoric" },			-- ThreatCharacter
					[770]   = { RHETORIC,         "rhetoric" },			-- Marry
					[810]   = { SHADOW_ARTS,      "shadow_arts" },		-- FightRob
					[950]   = { CRAFTSMANSHIP,    "craftsmanship" },	-- Reparier
					[1170]  = { SECRET_KNOWLEDGE, "secret_knowledge" },	-- Verfluchen
					[1260]  = { FIGHTING,         "fighting" },			-- LeadCrusade
					[1520]  = { CHARISMA,         "charisma" },			-- TakeABath
					[1530]  = { CHARISMA,         "charisma" },			-- BewitchCharacter
					[1730]  = { BARGAINING,       "bargaining" },		-- DoGelage
					[1740]  = { BARGAINING,       "bargaining" },		-- OfferCredit
					[2300]  = { EMPATHY,          "empathy" },			-- MakeAPresent
					[2310]  = { RHETORIC,         "rhetoric" },			-- MakeACompliment
					[2320]  = { DEXTERITY,        "dexterity" },			-- InviteToDance
					[2391]  = { BARGAINING,       "bargaining" },		-- CollectDebts
					[20100] = { CRAFTSMANSHIP,    "craftsmanship" },	-- CreateWorkOfArt
					-- Not every measure runs on a talent. "level" reads the character
					-- level instead, which is what these actually scale with.
					[880]   = { "level",          "level" },			-- HushMoney
					[1690]  = { CHARISMA,         "charisma" },			-- JugglerBeg
					[1700]  = { CHARISMA,         "charisma" },			-- LayTarot
					[1720]  = { CHARISMA,         "charisma" }			-- TellFortune
					}

	local Entry = MeasureTalent[MeasureID]
	if not Entry or not Entry[1] then
		return false
	end

	local Label = "@L_ONSCREENHELP_7_MEASURES_TALENT_"..Entry[2].."_+0"

	-- GetOSHData runs with the hovering character bound to "", the same way
	-- ms_AttendDoctor.lua reads its HP there, so these are that character's.
	local Value
	if Entry[1] == "level" then
		Value = SimGetLevel("") or 0
	else
		Value = GetSkillValue("", Entry[1]) or 0
	end

	-- ponytail: temporary probe for the first in-game test. Lands in logfile.log
	-- as [TALENT] lines; a measure whose line never appears is one the panel does
	-- not call GetOSHData for. Delete this once the row is confirmed.
	LogMessage("@TALENT measure "..MeasureID.." talent "..Entry[2].." slot "..(Slot or "runtime").." level "..Value)

	if Slot == "cost" then
		OSHSetMeasureCost(Label, Value)
	else
		OSHSetMeasureRuntime(Label, Value)
	end

	return true
end
