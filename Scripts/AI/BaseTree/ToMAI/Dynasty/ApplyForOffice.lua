function Weight()
	
	local Time = math.mod(GetGametime(),24)
	
	if GetRound() == 0 then
		return 0
	end
	
	if Time >= 16 then
		return 0
	end
	
	if not dyn_GetIdleMember("dynasty", "ApplySIM") then
		return 0
	end
	
	if not GetSettlement("ApplySIM", "CITY_OF_OFFICE") then
		return 0
	end
	
	local TimerName = "AI_Office"
	if not ReadyToRepeat("ApplySIM", TimerName) then
		return 0
	end
	
	local Level = SimGetMaxOfficeLevel("ApplySIM")
	local HighestLevel = CityGetHighestOfficeLevel("CITY_OF_OFFICE")
	
	if Level == HighestLevel or Level >= 6 then
		-- if this sim is already in the highest office - no further lookup needed here
		return 0
	else
		Level = Level + 1
	end
	
	if Level > 1 and GetNobilityTitle("ApplySIM") < 5 then
		return 0
	end

--  This included defence of current office!!
--	if SimIsAppliedForOffice("ApplySIM") then
--		return 0
--	end

	if GetNobilityTitle("ApplySIM") < 4 then
		return 0
	end

	-- check if i already applied
	local HasApplied = false
	local APPLICANTS = 2

	-- search through all offices and check if I am already an applicant
	CityPrepareOfficesToVote("CITY_OF_OFFICE", "OfficeList", false)
	local Size = ListSize("OfficeList")
	SimGetOffice("ApplySIM", "SimOffice")
	local MyOfficeID = GetID("SimOffice")
	for i=Size-1, 0, -1 do
		ListGetElement("OfficeList", i,"Office")
		if MyOfficeID ~= GetID("Office") then
			OfficePrepareSessionMembers("Office", "ApplicantList", APPLICANTS)
			local AppSize = ListSize("ApplicantList")
			for j=0, AppSize, 1 do
				ListGetElement("ApplicantList", j, "ListSim")
				if(GetID("ListSim") == GetID("ApplySIM")) then
					HasApplied = true
					break
				end
			end
		end	
		if HasApplied then
			break
		end
	end
	
	if HasApplied then
		SetRepeatTimer("ApplySIM", TimerName, 10)
		return 0
	end
	
	local Ret
	local Count = CityGetOfficeCountAtLevel("CITY_OF_OFFICE", Level)
	local Choice = 0
	local ApplicantCountBest = 4
	
	for i=0, Count-1 do
		Choice = Count-1 - i
		if SettlementGetOffice("CITY_OF_OFFICE", Level, Choice, "OFFICE") then
			Ret = ac_applyforoffice_CheckOffice("OFFICE")
			if Ret == "Apply" then
				if OfficeGetApplicantCount("OFFICE") < ApplicantCountBest then
					ApplicantCountBest = OfficeGetApplicantCount("OFFICE")	
					CopyAlias("OFFICE", "APPLY_OFFICE")
				end
			end
		end
	end
	
	if AliasExists("APPLY_OFFICE") then
		return 100
	else
		SetRepeatTimer("ApplySIM", TimerName, 12)
		return 0
	end	
end

function CheckOffice(Alias)
	if not OfficeGetAccessRights("OFFICE", "ApplySIM", 8) then
		return 0
	end
	
	if OfficeGetHolder("OFFICE", "OfficeHolder") then
		-- check office with a holder
		if GetDynastyID("ApplySIM") == GetDynastyID("OfficeHolder") then
			return 0
		end
		if DynastyGetDiplomacyState("ApplySIM", "OfficeHolder") == DIP_ALLIANCE then
			return 0
		end
	end
	
	if OfficeGetApplicantCount("OFFICE") > 3 then
		return 0
	end

	if DynastyIsShadow("ApplySIM") then
		if OfficeGetShadowApplicantCount("OFFICE") >= 3 then
			return 0
		end
	end

	return "Apply"
end

function Execute()
	MeasureRun("ApplySIM", "APPLY_OFFICE", "RunForAnOffice")
	return
end
