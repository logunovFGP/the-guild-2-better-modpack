function GetPrivilegeList()
	return	
end

function InitOffice()
	SetOfficePrivileges( "Office", ps_ratsdiener_GetPrivilegeList() )
end

function TakeOffice(Messages)
	if (Messages == 1) then
		local AthmoLabel = "@L_CHARACTERS_3_OFFICES_NAME_Ratsdiener_ATHMO_+0"
		f_StartHighPriorMusic(MUSIC_POSITIVE_EVENT)
		feedback_MessageOffice("",
			ps_ratsdiener_GetPrivilegeList,
			"@L_PRIVILEGES_OFFICE_GAIN_HEAD_+0",
			"@L_PRIVILEGES_OFFICE_GAIN_BODY", GetID(""), GetSettlementID(""), AthmoLabel)
	end

	achievements_Unlock("", "POLITICS_RATSDIENER")

	chr_SetOfficeImpactList( "Office", ps_ratsdiener_GetPrivilegeList() )
end

function LooseOffice(Messages)
	if (Messages == 1) then
		feedback_MessageOffice("",
			ps_ratsdiener_GetPrivilegeList,
			"@L_PRIVILEGES_OFFICE_LOST_HEAD_+0",
			"@L_PRIVILEGES_OFFICE_LOST_BODY", GetID(""), GetSettlementID(""))
	end

	RemoveAllObjectDependendImpacts( "", "Office" )
end
 
