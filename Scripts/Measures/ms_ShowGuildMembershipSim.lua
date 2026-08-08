function Run()

	if not AliasExists("Destination") then
		return
	end

	local label
	local label2 = "@L_MEASURE_SHOWGUILDMEMBERSHIP_NULL_+0"
	local label3 = "@L_CHECKALDERMAN_ALDERMAN"
	local BuildingClass
	local member = false
	local noguildhouse = false

	if trade_IsAlderman("Destination") then
		if HasProperty("Destination", "Alderman") then
			label2 = "@L_MEASURE_SHOWGUILDMEMBERSHIP_ALDERMAN_+0"
		end
	end

	if not HasProperty("Destination", "GuildFame") then
		SetProperty("Destination", "GuildFame", 0)
	end
	local SimFame = 0 + GetProperty("Destination", "GuildFame")

	if SimGetClass("Destination") == 1 then
		label = "_PATRON"
		BuildingClass = 1
	elseif SimGetClass("Destination") == 2 then
		label = "_ARTISAN"
		BuildingClass = 2
	elseif SimGetClass("Destination") == 3 then
		label = "_SCHOLAR"
		BuildingClass = 3
	elseif SimGetClass("Destination") == 4 then
		label = "_CHISELER"
		BuildingClass = 4
	else
		StopMeasure()
	end	

	GetSettlement("Destination", "my_settlement")
	if CityGetRandomBuilding("my_settlement", -1, GL_BUILDING_TYPE_GUILDHOUSE, -1, -1, FILTER_IGNORE, "guildhouse") then
		if chr_CheckGuildMaster("Destination","guildhouse") then
			label = "@L_GUILDHOUSE_MASTERLIST"..label
			member = true
		else
			label = "@L_GUILDHOUSE_MEMBER"..label
			local Count = CityGetBuildings("my_settlement", GL_BUILDING_CLASS_WORKSHOP, -1, -1, -1, FILTER_IGNORE, "Buildings")
			local Alias
			for l=0,Count-1 do
				Alias = "Buildings"..l
				if BuildingGetOwner(Alias, "BuildingOwner") then
					if GetID("BuildingOwner") == GetID("Destination") then
						member = true
						break
					end
				end
			end
		end
	else
		noguildhouse = true
	end

	if SimGetGender("Destination") == GL_GENDER_MALE then
		label = label.."_MALE_+0"
		label3 = label3.."_MALE_+1"
	else
		label = label.."_FEMALE_+0"
		label3 = label3.."_FEMALE_+1"
	end

	local fameleveldyn = "@L_GUILDHOUSE_FAME_DYNASTY_+"..dyn_GetFameLevel("Destination")

	GetScenario("scenario")
	local mapid = GetProperty("scenario", "mapid")
	local lordlabel = "@L_SCENARIO_LORD_"..GetDatabaseValue("maps", mapid, "lordship").."_+0"

	local impfameleveldyn = "@L_IMPERIAL_FAME_DYNASTY_+"..dyn_GetImperialFameLevel("Destination")

	if member then
		if trade_IsAlderman("Destination") then
			label2 = "@L_MEASURE_SHOWGUILDMEMBERSHIP_ALDERMAN_+0"
			MsgBoxNoWait("dynasty", "Destination",
						"@L_MEASURE_SHOWGUILDMEMBERSHIP_HEAD_+0",
						"@L_MEASURE_SHOWGUILDMEMBERSHIP_TEXT_+0",
						GetID("Destination"), label, GetID("my_settlement"), fameleveldyn, dyn_GetFame("Destination"), label2,
						lordlabel, impfameleveldyn, dyn_GetImperialFame("Destination"), SimFame)
		else
			MsgBoxNoWait("dynasty", "Destination",
						"@L_MEASURE_SHOWGUILDMEMBERSHIP_HEAD_+0",
						"@L_MEASURE_SHOWGUILDMEMBERSHIP_TEXT_+0",
						GetID("Destination"), label, GetID("my_settlement"), fameleveldyn, dyn_GetFame("Destination"), label2, 
						lordlabel, impfameleveldyn, dyn_GetImperialFame("Destination"), SimFame)
		end
	else
		if noguildhouse then
			if trade_IsAlderman("Destination") then
				MsgBoxNoWait("dynasty", "Destination",
							"@L_MEASURE_SHOWGUILDMEMBERSHIP_HEAD_+0",
							"@L_MEASURE_SHOWGUILDMEMBERSHIP_TEXT_+2",
							GetID("Destination"), GetID("my_settlement"), fameleveldyn, dyn_GetFame("Destination"), label3, 
							lordlabel, impfameleveldyn, dyn_GetImperialFame("Destination"), SimFame)
			else
				MsgBoxNoWait("dynasty", "Destination",
							"@L_MEASURE_SHOWGUILDMEMBERSHIP_HEAD_+0",
							"@L_MEASURE_SHOWGUILDMEMBERSHIP_TEXT_+2",
							GetID("Destination"), GetID("my_settlement"), fameleveldyn, dyn_GetFame("Destination"), label2, 
							lordlabel, impfameleveldyn, dyn_GetImperialFame("Destination"), SimFame)
			end				
		else
			if trade_IsAlderman("Destination") then
				MsgBoxNoWait("dynasty", "Destination",
							"@L_MEASURE_SHOWGUILDMEMBERSHIP_HEAD_+0",
							"@L_MEASURE_SHOWGUILDMEMBERSHIP_TEXT_+1",
							GetID("Destination"), fameleveldyn, dyn_GetFame("Destination"), label3,
							lordlabel, impfameleveldyn, dyn_GetImperialFame("Destination"), SimFame)
			else
				MsgBoxNoWait("dynasty", "Destination",
							"@L_MEASURE_SHOWGUILDMEMBERSHIP_HEAD_+0",
							"@L_MEASURE_SHOWGUILDMEMBERSHIP_TEXT_+1",
							GetID("Destination"), fameleveldyn, dyn_GetFame("Destination"), label2,
							lordlabel, impfameleveldyn, dyn_GetImperialFame("Destination"), SimFame)
			end
		end
	end	
end
