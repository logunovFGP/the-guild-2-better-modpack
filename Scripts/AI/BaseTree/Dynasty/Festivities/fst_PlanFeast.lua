function Weight()
	if not ReadyToRepeat("dynasty", "AI_HostFeast") then
		return 0
	end

	if not AliasExists("FST_Home") or GetState("FST_Home", STATE_FEAST) then
		return 0
	end

	if not BuildingHasUpgrade("FST_Home", "Saloon") then
		return 0
	end

	if not BuildingGetOwner("FST_Home", "FST_Owner") or GetID("FST_Owner") ~= GetID("SIM") then
		return 0
	end

	if GetMoney("dynasty") < 8000 then
		return 0
	end

	local Season = GetSeason()
	if Season == EN_SEASON_AUTUMN or Season == EN_SEASON_SUMMER then
		return 40
	elseif Season == EN_SEASON_SPRING then
		return 20
	end
	return 10
end

function Execute()
	local Difficulty = ScenarioGetDifficulty()
	SetRepeatTimer("dynasty", "AI_HostFeast", 96 + 24 * (5 - Difficulty))
	MeasureRun("SIM", 0, "GiveAFeast", false)
end