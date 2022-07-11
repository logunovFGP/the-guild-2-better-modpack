function GetPrivilegeList()
	return ""
end

function GetOldPrivilegeList()
	return ""
end

function GetCompletePrivilegeList()
	return ps_03_freisasse_GetPrivilegeList(), ps_03_freisasse_GetOldPrivilegeList()
end

function TakeTitle()
	gameplayformulas_StartHighPriorMusic(MUSIC_POSITIVE_EVENT)
	chr_SetNobilityImpactList("TitleHolder", ps_03_freisasse_GetPrivilegeList())

	local currenttitle = GetNobilityTitle("TitleHolder") + 1
	local buildinglevel = GetDatabaseValue("NobilityTitle", currenttitle, "maxresidencelevel")
	local maxworkshops = GetDatabaseValue("NobilityTitle", currenttitle, "maxworkshops")
	local BuildLabel = "_BUILDING_Residence"..buildinglevel.."_NAME_+0"
	local TitleLabel = "_CHARACTERS_3_TITLES_NAME_+"..(currenttitle * 2) - 1
	local buildingcount = dyn_GetWorkshopCount("TitleHolder")
	local BodyLabel = "@L_CHARACTERS_3_TITLES_AQUIRE_MESSAGES_NEW_BODY_+3"
	
	if SimGetGender("") == GL_GENDER_FEMALE then
		BodyLabel = "@L_CHARACTERS_3_TITLES_AQUIRE_MESSAGES_NEW_FEMALE_BODY_+3"
	end
	
	feedback_MessageCharacter("",
						"@L_CHARACTERS_3_TITLES_AQUIRE_MESSAGES_NEW_PRIVILEGES_HEAD_+0",
						BodyLabel, TitleLabel, BuildLabel, maxworkshops, buildingcount, chr_GeneratePrivilegeListLabels(ps_03_freisasse_GetCompletePrivilegeList()))
	-- send msg to other dynasties
	feedback_MessageOtherDynastiesTitle("")
end

function LooseTitle()
	chr_RemoveNobilityImpactList("TitleHolder", ps_03_freisasse_GetPrivilegeList())
end
 
