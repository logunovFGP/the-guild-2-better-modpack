function Run()
	
	-- get your town hall
	GetSettlement("", "MyCity")
	if not CityGetRandomBuilding("MyCity", -1, GL_BUILDING_TYPE_TOWNHALL, -1, -1, FILTER_IGNORE, "Townhall") then
		return
	end

	local MeasureID = GetCurrentMeasureID("")
	local TimeOut = mdata_GetTimeOut(MeasureID)
	local Level = CityGetLevel("MyCity")
	local CityTreasure = GetMoney("MyCity")
	local CityUpgradeCost = gameplayformulas_GetCityUpgradeCost(Level)
	local citylabel = CityLevel2Label(Level)
	local nomorelvlup = false

	if Level>4 then
		-- secure that only one city can be the imperial capital in the scenario
		local	ImperialId = ScenarioGetImperialCapitalId()
		if (ImperialId>0 and ImperialId~=nil) or Level==6 then
			nomorelvlup=true
		end
	end

	local citizens = ms_levelupcity_GetValue(Level)[2]

	if nomorelvlup==true then
		MsgBoxNoWait("",false,
			"@L_MEASURE_LEVELUPCITY_HEAD_+0",
			"@L_MEASURE_LEVELUPCITY_BODY_+5", GetID("MyCity"), citylabel)
			
	elseif HasProperty("MyCity", "LevelUpPaid") and GetProperty("MyCity","LevelUpPaid") == 1 then
		GetScenario("scenario")
		local mapid = GetProperty("scenario", "mapid")
		local scenarioname = GetDatabaseValue("maps", mapid, "lordship")
		local lordid = f_GetDatabaseIdByName("Lordship", scenarioname)
		local lordlabel = "@L_SCENARIO_LORD_"..GetDatabaseValue("maps", mapid, "lordship").."_+1"
		MsgBoxNoWait("", false,
			"@L_MEASURE_LEVELUPCITY_HEAD_+0",
			"@L_MEASURE_LEVELUPCITY_BODY_+4", GetID("MyCity"), citylabel, lordlabel)
	
	elseif HasProperty("MyCity", "LevelUpCity") and GetProperty("MyCity", "LevelUpCity") == 1 then
		if CityTreasure < CityUpgradeCost then
			MsgBoxNoWait("", false,
				"@L_MEASURE_LEVELUPCITY_HEAD_+0",
				"@L_MEASURE_LEVELUPCITY_BODY_+0", GetID("MyCity"), CityUpgradeCost, citylabel)
		else
			local Result = MsgNews("",false,"@P"..
						"@B[1,@L_REPLACEMENTS_BUTTONS_JA_+0]"..
						"@B[C,@L_REPLACEMENTS_BUTTONS_NEIN_+0]",
						ms_levelupcity_AIDecision,  --AIFunc
						"default", --MessageClass
						2, --TimeOut
						"@L_MEASURE_LEVELUPCITY_HEAD_+0",
						"@L_MEASURE_LEVELUPCITY_BODY_+1", GetID("MyCity"), CityUpgradeCost, citylabel)

			if Result == 1 then
				local	ImperialId = ScenarioGetImperialCapitalId()
				if Level == 5 then
					if (ImperialId<1 or ImperialId == nil) then
						ScenarioSetImperialCapital("MyCity")
						SetProperty("MyCity", "ImperialCapital", 1)
						SetProperty("MyCity", "LevelUpPaid", 1)
						chr_SpendMoney("MyCity", CityUpgradeCost, "LevelUpPaid")
						SetMeasureRepeat(TimeOut)
					end
				else
					SetProperty("MyCity", "LevelUpPaid", 1)
					chr_SpendMoney("MyCity", CityUpgradeCost, "LevelUpPaid")
					SetMeasureRepeat(TimeOut)
				end
			end
		end
	
	else
		if CityTreasure < CityUpgradeCost then
			MsgBoxNoWait("", false,
				"@L_MEASURE_LEVELUPCITY_HEAD_+0",
				"@L_MEASURE_LEVELUPCITY_BODY_+2", GetID("MyCity"), CityUpgradeCost, citylabel, citizens)
		else
			MsgBoxNoWait("", false,
				"@L_MEASURE_LEVELUPCITY_HEAD_+0",
				"@L_MEASURE_LEVELUPCITY_BODY_+3", GetID("MyCity"), citylabel, citizens)
		end
	end
end

function GetValue(Level)
	if Level == 2 then
		return {0, 80}
	elseif Level == 3 then
		return {90, 130}
	elseif Level == 4 then
		return {140, 200}
	elseif Level == 5 then
		return {200, 300}
	elseif Level == 6 then
		return {260, 99999}
	end
end

function AIDecision()
	return 1
end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
end

