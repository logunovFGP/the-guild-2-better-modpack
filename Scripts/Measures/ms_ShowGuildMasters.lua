-- guild house measure

-- -----------------------
-- Run
-- -----------------------
function Run()

	if BuildingGetType("") == GL_BUILDING_TYPE_GUILDHOUSE then
		CopyAlias("", "guildhouse")
	else
		GetInsideBuilding("", "guildhouse")
	end
	
	BuildingGetCity("guildhouse", "myCity")

	local year = GetProperty("guildhouse", "year")

	if year ~= nil then

		-- PatronLabel[1], PatronName[2],  ArtisanLabel[3], ArtisanName[4],
		-- ScholarLabel[5], ScholarName[6], ChiselerLabel[7], ChiselerName[8],
		-- PatronFlag[9], ArtisanFlag[10], ScholarFlag[11], ChiselerFlag[12]
		local textArray = {"","","","","","","","","","","","","","",""}

		local PatronMaster = GetProperty("guildhouse", "PatronMaster")
		if PatronMaster ~= nil and PatronMaster > 0 then
			
			if not GetAliasByID(PatronMaster, "Patron") or GetState("Patron", STATE_DEAD) then
				textArray[1] = "@L_GUILDHOUSE_MASTERLIST_PATRON_MALE_+0"
				textArray[2] = "@L_GUILDHOUSE_MASTERLIST_DEAD_+0"
			elseif SimGetGender("Patron") == GL_GENDER_MALE then
				textArray[1] = "@L_GUILDHOUSE_MASTERLIST_PATRON_MALE_+0"
				textArray[2] = GetName("Patron")
			else
				textArray[1] = "@L_GUILDHOUSE_MASTERLIST_PATRON_FEMALE_+0"
				textArray[2] = GetName("Patron")
			end
			
			if not DynastyIsShadow("Patron") then
				GetDynasty("Patron", "Dyn")
				local tmpflag = DynastyGetFlagNumber("Dyn") + 29
				textArray[9] = "@L$S[20"..tmpflag.."]"
			else
				textArray[9] = "@L$S[2045]"
			end
			
		else
			textArray[1] = "@L_GUILDHOUSE_MASTERLIST_PATRON_MALE_+0"
			textArray[2] = "@L_GUILDHOUSE_MASTERLIST_NO_ENTRY_+0"
			textArray[9] = "@L$S[2045]"
		end

		local ArtisanMaster = GetProperty("guildhouse", "ArtisanMaster")
		if ArtisanMaster ~= nil and ArtisanMaster > 0 then
		
			if not GetAliasByID(ArtisanMaster,"Artisan") or GetState("Artisan", STATE_DEAD) then
				textArray[3] = "@L_GUILDHOUSE_MASTERLIST_ARTISAN_MALE_+0"
				textArray[4] = "@L_GUILDHOUSE_MASTERLIST_DEAD_+0"
			elseif SimGetGender("Artisan") == GL_GENDER_MALE then
				textArray[3] = "@L_GUILDHOUSE_MASTERLIST_ARTISAN_MALE_+0"
				textArray[4] = GetName("Artisan")
			else
				textArray[3] = "@L_GUILDHOUSE_MASTERLIST_ARTISAN_FEMALE_+0"
				textArray[4] = GetName("Artisan")
			end
			
			if not DynastyIsShadow("Artisan") then
				GetDynasty("Artisan", "Dyn")
				local tmpflag = DynastyGetFlagNumber("Dyn") + 29
				textArray[10] = "@L$S[20"..tmpflag.."]"
			else
				textArray[10] = "@L$S[2045]"
			end
		else
			textArray[3] = "@L_GUILDHOUSE_MASTERLIST_ARTISAN_MALE_+0"
			textArray[4] = "@L_GUILDHOUSE_MASTERLIST_NO_ENTRY_+0"
			textArray[10] = "@L$S[2045]"
		end

		local ScholarMaster = GetProperty("guildhouse", "ScholarMaster")
		if ScholarMaster ~= nil and ScholarMaster > 0 then
		
			if not GetAliasByID(ScholarMaster,"Scholar") or GetState("Scholar", STATE_DEAD) then
				textArray[5] = "@L_GUILDHOUSE_MASTERLIST_SCHOLAR_MALE_+0"
				textArray[6] = "@L_GUILDHOUSE_MASTERLIST_DEAD_+0"
			elseif SimGetGender("Scholar") == GL_GENDER_MALE then
				textArray[5] = "@L_GUILDHOUSE_MASTERLIST_SCHOLAR_MALE_+0"
				textArray[6] = GetName("Scholar")
			else
				textArray[5] = "@L_GUILDHOUSE_MASTERLIST_SCHOLAR_FEMALE_+0"
				textArray[6] = GetName("Scholar")
			end
			
			if not DynastyIsShadow("Scholar") then
				GetDynasty("Scholar", "Dyn")
				local tmpflag = DynastyGetFlagNumber("Dyn") + 29
				textArray[11] = "@L$S[20"..tmpflag.."]"
			else
				textArray[11] = "@L$S[2045]"
			end
		else
			textArray[5] = "@L_GUILDHOUSE_MASTERLIST_SCHOLAR_MALE_+0"
			textArray[6] = "@L_GUILDHOUSE_MASTERLIST_NO_ENTRY_+0"
			textArray[11] = "@L$S[2008]"
		end

		local ChiselerMaster = GetProperty("guildhouse", "ChiselerMaster")
		if ChiselerMaster ~= nil and ChiselerMaster > 0 then
		
			if not GetAliasByID(ChiselerMaster, "Chiseler") or GetState("Chiseler", STATE_DEAD) then
				textArray[7] = "@L_GUILDHOUSE_MASTERLIST_CHISELER_MALE_+0"
				textArray[8] = "@L_GUILDHOUSE_MASTERLIST_DEAD_+0"
			elseif SimGetGender("Chiseler") == GL_GENDER_MALE then
				textArray[7] = "@L_GUILDHOUSE_MASTERLIST_CHISELER_MALE_+0"
				textArray[8] = GetName("Chiseler")
			else
				textArray[7] = "@L_GUILDHOUSE_MASTERLIST_CHISELER_FEMALE_+0"
				textArray[8] = GetName("Chiseler")
			end
			
			if not DynastyIsShadow("Chiseler") then
				GetDynasty("Chiseler", "Dyn")
				local tmpflag = DynastyGetFlagNumber("Dyn") + 29
				textArray[12] = "@L$S[20"..tmpflag.."]"
			else
				textArray[12] = "@L$S[2045]"
			end
		else
			textArray[7] = "@L_GUILDHOUSE_MASTERLIST_CHISELER_MALE_+0"
			textArray[8] = "@L_GUILDHOUSE_MASTERLIST_NO_ENTRY_+0"
			textArray[12] = "@L$S[2045]"
		end

		local Alderman = trade_GetAldermanOfGuildHouse("guildhouse")
		if Alderman~=0 then
		
			if not GetAliasByID(Alderman, "Alderman") or GetState("Alderman", STATE_DEAD) then
				textArray[13] = "@L_CHECKALDERMAN_ALDERMAN_MALE_+1"
				textArray[14] = "@L_GUILDHOUSE_MASTERLIST_DEAD_+0"
			elseif SimGetGender("Alderman") == GL_GENDER_MALE then
				textArray[13] = "@L_CHECKALDERMAN_ALDERMAN_MALE_+1"
				textArray[14] = GetName("Alderman")
			else
				textArray[13] = "@L_CHECKALDERMAN_ALDERMAN_FEMALE_+1"
				textArray[14] = GetName("Alderman")
			end
			
			if not DynastyIsShadow("Alderman") then
				GetDynasty("Alderman", "Dyn")
				local tmpflag = DynastyGetFlagNumber("Dyn") + 29
				textArray[15] = "@L$S[20"..tmpflag.."]"
			else
				textArray[15] = "@L$S[2045]"
			end
		else
			textArray[13] = "@L_CHECKALDERMAN_ALDERMAN_MALE_+1"
			textArray[14] = "@L_GUILDHOUSE_MASTERLIST_NO_ENTRY_+0"
			textArray[15] = "@L$S[2008]"
		end

		MsgBoxNoWait("dynasty", false,
					"@L_GUILDHOUSE_MASTERLIST_HEAD_+0",
					"@L_GUILDHOUSE_MASTERLIST_BODY_+0",
					GetID("myCity"), year, textArray[1], textArray[2], textArray[3], textArray[4], textArray[5], 
					textArray[6], textArray[7], textArray[8], textArray[9], textArray[10], textArray[11], textArray[12],
					textArray[13], textArray[14], textArray[15])

	else
		MsgBoxNoWait("dynasty", false,
					"@L_GUILDHOUSE_MASTERLIST_HEAD_+0",
					"@L_GUILDHOUSE_MASTERLIST_BODY_+1",
					GetID("myCity"))

	end
end
