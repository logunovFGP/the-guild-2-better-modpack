function GetPrivilegeList()
	return	"DetainCharacter", "CommandCityGuard"
end

function InitOffice()
	SetOfficePrivileges( "Office", ps_obrist_GetPrivilegeList() )
	SetOfficeServants("Office", "CityGuard", 6, GL_PROFESSION_CITYGUARD)
end

function TakeOffice(Messages)
	if (Messages == 1) then
		local AthmoLabel = "@L_CHARACTERS_3_OFFICES_NAME_Obrist_ATHMO_+0"
		
		gameplayformulas_StartHighPriorMusic(MUSIC_POSITIVE_EVENT)
		feedback_MessageOffice("",
			ps_obrist_GetPrivilegeList,
			"@L_PRIVILEGES_OFFICE_GAIN_HEAD_+0",
			"@L_PRIVILEGES_OFFICE_GAIN_BODY", GetID(""), GetSettlementID(""), AthmoLabel)
	end

	chr_SetOfficeImpactList( "Office", ps_obrist_GetPrivilegeList() )
end

function LooseOffice(Messages)
	if (Messages == 1) then
		feedback_MessageOffice("",
			ps_obrist_GetPrivilegeList,
			"@L_PRIVILEGES_OFFICE_LOST_HEAD_+0",
			"@L_PRIVILEGES_OFFICE_LOST_BODY", GetID(""), GetSettlementID(""))
	end

	RemoveAllObjectDependendImpacts( "", "Office" )
end
 
