function Run()

	if not GetSettlement("", "city") then
		return
	end

	-- get data for citizen and city level
	local LevelID = CityGetLevel("city")
	local Level = CityLevel2Label(LevelID) 
	local citizens = citylevel_GetValue(LevelID)
	local CurrentCitizens	= CityGetCitizenCount("city")
	local lvluptext = "_MEASURE_CITYTREASURE_LVLUP_+1"
	local nomorelvlup = false
	local ImperialId = ScenarioGetImperialCapitalId()
	
	if (ImperialId >0 and ImperialId ~= nil) then
		nomorelvlup = true
	end
	
	if Level == 6 or nomorelvlup then
		lvluptext = "_MEASURE_CITYTREASURE_LVLUP_+2"
	end

	local officebearer = false
	local Count = DynastyGetMemberCount("dynasty")

	for l=0, Count-1 do
		if DynastyGetMember("dynasty", l, "Member") then
			if GetHomeBuilding("Member", "Home") then
				BuildingGetCity("Home", "PlayerCity")
				if GetID("city") == GetID("PlayerCity") then
					if SimGetOfficeLevel("Member") >=0 then
						officebearer = true
					end
				end
			end
		end
	end

	if officebearer then
		
		if CityGetRandomBuilding("city", GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_TOWNHALL, -1, -1, FILTER_IGNORE, "Townhall") then
			BuildingGetNPC("Townhall", 1, "Usher")
		end
		
		-- get the needed data
		-- taxes
		local TotalIncome = GetProperty("city", "TotalIncome") or 0
		local TaxValue = GetProperty("city", "TaxValue") or 0
		local TaxRaw = GetProperty("city", "TaxRaw") or 0
		local TaxFood = GetProperty("city", "TaxFood") or 0
		local TaxHandi = GetProperty("city", "TaxHandi") or 0
		local TaxSchol = GetProperty("city", "TaxSchol") or 0
		local TaxHerbs = GetProperty("city", "TaxHerbs") or 0
		local TaxIron = GetProperty("city", "TaxIron") or 0
		-- other income
		local NobilityMoneyLY = GetProperty("city", "NobilityMoneyLY") or 0
		local FeesLY = GetProperty("city", "CityFeesLY") or 0
		local TrialsLY = GetProperty("city", "TrialIncomeLY") or 0
		-- costs
		local TotalCost = GetProperty("city", "TotalCost") or 0
		
		local Balance = TotalIncome - TotalCost
		local BalanceLabel = ""
		if Balance > 0 then
			BalanceLabel = "@L_CITY_PINGHOUR_CITY_TREASURY_BALANCE_PROFIT_+0"
		else
			BalanceLabel = "@L_CITY_PINGHOUR_CITY_TREASURY_BALANCE_LOSS_+0"
		end
		
		local OfficeMoney = GetProperty("city", "OfficeMoney") or 0
		local BuildingRepairs = GetProperty("city", "BuildingRepairs") or 0
		local Warcosts = GetProperty("city", "WarcostsLY") or 0
		local CostServants = GetProperty("city", "ServantCost") or 0
		local CostCityGuard = GetProperty("city", "CityGC") or 0
		local CostEliteGuard = GetProperty("city", "EliteGC") or 0
		
		-- church income
		local ChurchTithe = GetProperty("city", "TitheValue") or 0
		local ChurchTreasury = GetProperty("city", "ChurchTreasury") or 0
		local ChurchIncome = GetProperty("city", "ChurchIncome") or 0
		local UnemployedCost = GetProperty("city", "UnemployedCost") or 0
		
		local year = GetYear() - 1
		MsgBoxNoWait("dynasty", "Usher",
					"@L_CITY_PINGHOUR_CITY_TREASURY_BALANCE_HEAD_+0",
					"@L_CITY_PINGHOUR_CITY_TREASURY_BALANCE_BODY_+0", GetID("Usher"), GetID("city"), year, TaxValue, 
					TaxRaw, TaxFood, TaxHandi, TaxSchol, TaxHerbs, TaxIron, NobilityMoneyLY, FeesLY, TrialsLY, TotalIncome, 
					OfficeMoney, CostServants, CostCityGuard, CostEliteGuard, BuildingRepairs, Warcosts, TotalCost, 
					BalanceLabel, GetMoney("city"), ChurchTithe, ChurchIncome, UnemployedCost, ChurchTreasury, Balance)
					
	else
	
		local citytreasure = GetMoney("city")
		local replacement = ""
		if citytreasure < 10000 then
			replacement = "_MEASURE_CITYTREASURE_TEXT_+0"
		elseif citytreasure < 30000 then
			replacement = "_MEASURE_CITYTREASURE_TEXT_+1"
		elseif citytreasure < 80000 then
			replacement = "_MEASURE_CITYTREASURE_TEXT_+2"
		elseif citytreasure < 200000 then
			replacement = "_MEASURE_CITYTREASURE_TEXT_+3"
		else
			replacement = "_MEASURE_CITYTREASURE_TEXT_+4"
		end		
	
		MsgBoxNoWait("dynasty", "city", "@L_MEASURE_CITYTREASURE_HEAD_+0", "@L_MEASURE_CITYTREASURE_BODY", GetID("city"), replacement, Level, CurrentCitizens, lvluptext, citizens)
	end
end

function CleanUp()	
end
