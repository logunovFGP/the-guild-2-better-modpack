function GetPrivilegeList()
	return "CanApplyForLowestOffice"
end

function GetOldPrivilegeList()
	return ""
end

function GetCompletePrivilegeList()
	return ps_04_beisasse_GetPrivilegeList(), ps_04_beisasse_GetOldPrivilegeList()
end

function TakeTitle()
	f_StartHighPriorMusic(MUSIC_POSITIVE_EVENT)
	chr_SetNobilityImpactList("TitleHolder", ps_04_beisasse_GetPrivilegeList())

	local currenttitle = GetNobilityTitle("TitleHolder") + 1
	local buildinglevel = GetDatabaseValue("NobilityTitle", currenttitle, "maxresidencelevel")
	local maxworkshops = GetDatabaseValue("NobilityTitle", currenttitle, "maxworkshops")
	local BuildLabel = "_BUILDING_Residence"..buildinglevel.."_NAME_+0"
	local buildingcount = dyn_GetWorkshopCount("TitleHolder")
	local BodyLabel = "@L_CHARACTERS_3_TITLES_AQUIRE_MESSAGES_NEW_BODY_+4"
	DynastyGetMember("TitleHolder", 0, "Boss")
	
	local GenderLabel = 1
	if SimGetGender("Boss") == GL_GENDER_FEMALE then
		GenderLabel = 2
		BodyLabel = "@L_CHARACTERS_3_TITLES_AQUIRE_MESSAGES_NEW_FEMALE_BODY_+4"
	end
	
	local TitleLabel = "_CHARACTERS_3_TITLES_NAME_+"..(currenttitle * 2) - GenderLabel
	
	feedback_MessageCharacter("Boss",
						"@L_CHARACTERS_3_TITLES_AQUIRE_MESSAGES_NEW_PRIVILEGES_HEAD_+0",
						BodyLabel, TitleLabel, BuildLabel, maxworkshops, buildingcount, chr_GeneratePrivilegeListLabels(ps_04_beisasse_GetCompletePrivilegeList()))
	-- send msg to other dynasties
	feedback_MessageOtherDynastiesTitle("Boss", currenttitle)
end

function LooseTitle()
	chr_RemoveNobilityImpactList("TitleHolder", ps_04_beisasse_GetPrivilegeList())
end
 
